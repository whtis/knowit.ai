#!/usr/bin/env bash
# adapters/lark/listen.sh — 飞书 WebSocket 监听 + 三种入站:
#   1) 普通文本 → 走 core/ask.sh 查询
#   2) /note <内容> → 走 core/note.sh 直接 append 到 inbox.md(零 LLM)
#   3) 图片 → 下载到本地缓存,走 core/note.sh --image 让 claude 视觉提取
# 用法:
#   cp config.example.sh config.sh && 编辑 config.sh
#   ./listen.sh                                       # 前台
#   nohup ./listen.sh > ../../logs/listen.log 2>&1 &  # 后台

set -euo pipefail

ADAPTER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$ADAPTER_DIR/../.." && pwd)"
export REPO_ROOT

CONFIG="$ADAPTER_DIR/config.sh"
[[ ! -f "$CONFIG" ]] && { echo "缺 config.sh,先 cp config.example.sh config.sh 并填值" >&2; exit 1; }
# shellcheck disable=SC1090
source "$CONFIG"

ASK="$REPO_ROOT/core/ask.sh"
NOTE="$REPO_ROOT/core/note.sh"
LOG_DIR="$REPO_ROOT/logs"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/knowit/images"
mkdir -p "$LOG_DIR" "$CACHE_DIR"

log() { echo "[$(date '+%F %T')] $*" >&2; }

# 通用回复函数
reply() {
  local mid="$1" text="$2"
  lark-cli im +messages-reply \
    --as bot \
    --message-id "$mid" \
    --text "$text" \
    --idempotency-key "$mid" \
    >> "$LOG_DIR/reply.log" 2>&1 \
    || log "回复失败 msg=$mid,看 logs/reply.log"
}

# 调 ask/note 的统一包装(应用 gtimeout、错误捕获)
run_with_timeout() {
  local out errfile="$LOG_DIR/$1.err"; shift
  if command -v gtimeout >/dev/null; then
    out=$(gtimeout 120 "$@" 2>>"$errfile") || out="(执行失败,看 logs/${errfile##*/})"
  else
    out=$("$@" 2>>"$errfile") || out="(执行失败,看 logs/${errfile##*/})"
  fi
  echo "$out"
}

log "启动 lark adapter (owner=$MY_OPEN_ID, knowledge=$KNOWLEDGE_DIR, cache=$CACHE_DIR)"

lark-cli event +subscribe \
  --as bot \
  --event-types "im.message.receive_v1" \
  --quiet \
| while IFS= read -r line; do
    [[ -z "$line" || "${line:0:1}" != "{" ]] && continue

    sender_id=$(echo "$line"   | jq -r '.event.sender.sender_id.open_id // empty')
    msg_id=$(echo "$line"      | jq -r '.event.message.message_id // empty')
    chat_type=$(echo "$line"   | jq -r '.event.message.chat_type // empty')
    msg_type=$(echo "$line"    | jq -r '.event.message.message_type // empty')
    raw_content=$(echo "$line" | jq -r '.event.message.content // empty')

    [[ "$sender_id" != "$MY_OPEN_ID" ]] && continue

    case "$msg_type" in

      text)
        question=$(echo "$raw_content" | jq -r '.text // empty' \
                   | sed 's/@_user_[^ ]* //g; s/^[[:space:]]*//; s/[[:space:]]*$//')
        [[ -z "$question" ]] && continue

        # /note 前缀走 inbox 直写
        if [[ "$question" == /note\ * || "$question" == /note ]]; then
          note_text="${question#/note}"
          note_text="${note_text# }"
          if [[ -z "$note_text" ]]; then
            reply "$msg_id" "用法: /note <要记的内容>"
            continue
          fi
          log "NOTE: $note_text (msg=$msg_id)"
          answer=$(run_with_timeout note "$NOTE" --knowledge-dir "$KNOWLEDGE_DIR" -- "$note_text")
          reply "$msg_id" "$answer"
          continue
        fi

        # 普通问答
        log "Q: $question (chat=$chat_type, msg=$msg_id)"
        ASK_ARGS=(--knowledge-dir "$KNOWLEDGE_DIR" --system-prompt "$SYSTEM_PROMPT")
        [[ -n "${MODEL:-}" ]] && ASK_ARGS+=(--model "$MODEL")
        answer=$(run_with_timeout ask "$ASK" "${ASK_ARGS[@]}" -- "$question")
        log "A: ${#answer} chars,推回飞书"
        reply "$msg_id" "$answer"
        ;;

      image)
        image_key=$(echo "$raw_content" | jq -r '.image_key // empty')
        if [[ -z "$image_key" ]]; then
          log "image_key 缺失,跳过 msg=$msg_id"
          continue
        fi

        img_name="${msg_id}.jpg"
        img_path="$CACHE_DIR/$img_name"
        log "IMG msg=$msg_id key=$image_key,下载中..."

        # lark-cli --output 只接 relative path,所以 cd 进缓存目录后再下
        if ! ( cd "$CACHE_DIR" && lark-cli im +messages-resources-download \
                 --as bot \
                 --message-id "$msg_id" \
                 --file-key "$image_key" \
                 --type image \
                 --output "$img_name" \
                 >> "$LOG_DIR/download.log" 2>&1 ); then
          log "下载失败 msg=$msg_id,看 logs/download.log"
          reply "$msg_id" "(图片下载失败)"
          continue
        fi

        if [[ ! -s "$img_path" ]]; then
          log "下载后文件为空 $img_path"
          reply "$msg_id" "(图片下载失败:文件为空)"
          continue
        fi

        log "IMG ok,size=$(wc -c < "$img_path") bytes,调 note.sh 视觉提取"
        NOTE_ARGS=(--knowledge-dir "$KNOWLEDGE_DIR" --image "$img_path"
                   --system-prompt "$SYSTEM_PROMPT")
        [[ -n "${MODEL:-}" ]] && NOTE_ARGS+=(--model "$MODEL")
        answer=$(run_with_timeout note "$NOTE" "${NOTE_ARGS[@]}")
        log "A: ${#answer} chars,推回飞书"
        reply "$msg_id" "$answer"
        ;;

      *)
        log "跳过 $msg_type id=$msg_id"
        ;;
    esac
  done
