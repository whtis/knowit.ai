#!/usr/bin/env bash
# adapters/lark/listen.sh — 飞书 WebSocket 监听 + idempotent reply
# 用法:
#   cp config.example.sh config.sh && 编辑 config.sh
#   ./listen.sh                          # 前台
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
LOG_DIR="$REPO_ROOT/logs"
mkdir -p "$LOG_DIR"

log() { echo "[$(date '+%F %T')] $*" >&2; }

log "启动 lark adapter (owner=$MY_OPEN_ID, knowledge=$KNOWLEDGE_DIR)"

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
    [[ "$msg_type"  != "text"        ]] && { log "跳过 $msg_type id=$msg_id"; continue; }

    question=$(echo "$raw_content" | jq -r '.text // empty' \
               | sed 's/@_user_[^ ]* //g; s/^[[:space:]]*//; s/[[:space:]]*$//')
    [[ -z "$question" ]] && continue

    log "Q: $question (chat=$chat_type, msg=$msg_id)"

    ASK_ARGS=(--knowledge-dir "$KNOWLEDGE_DIR" --system-prompt "$SYSTEM_PROMPT")
    [[ -n "${MODEL:-}" ]] && ASK_ARGS+=(--model "$MODEL")

    if command -v gtimeout >/dev/null; then
      answer=$(gtimeout 90 "$ASK" "${ASK_ARGS[@]}" -- "$question" 2>>"$LOG_DIR/ask.err" \
               || echo "(查询失败,看 logs/ask.err)")
    else
      answer=$("$ASK" "${ASK_ARGS[@]}" -- "$question" 2>>"$LOG_DIR/ask.err" \
               || echo "(查询失败,看 logs/ask.err)")
    fi

    log "A: ${#answer} chars,推回飞书"

    lark-cli im +messages-reply \
      --as bot \
      --message-id "$msg_id" \
      --text "$answer" \
      --idempotency-key "$msg_id" \
      >> "$LOG_DIR/reply.log" 2>&1 \
      || log "回复失败,看 logs/reply.log"
  done
