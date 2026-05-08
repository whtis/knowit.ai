#!/usr/bin/env bash
# core/note.sh — 把零散信息写入 inbox.md
#
# 两种模式:
#   1) 纯文本: 直接 append 一行带时间戳的 markdown,**不走 LLM**(零幻觉)
#         core/note.sh --knowledge-dir <kb> -- "招行 5 月加油返 10%"
#
#   2) 图片(可带文字 caption): 调 claude 视觉提取 → Edit 写入 inbox.md
#         core/note.sh --knowledge-dir <kb> --image <path> [--system-prompt <file>] \
#                      -- "可选的文字说明"
#
# inbox.md 由本脚本保证存在(不存在自动创建模板),所以 LLM 只需要 Edit 权限,不用 Write。

set -euo pipefail

KNOWLEDGE_DIR=""
IMAGE_PATH=""
SYSTEM_PROMPT_FILE=""
MODEL=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --knowledge-dir)  KNOWLEDGE_DIR="$2";    shift 2 ;;
    --image)          IMAGE_PATH="$2";       shift 2 ;;
    --system-prompt)  SYSTEM_PROMPT_FILE="$2"; shift 2 ;;
    --model)          MODEL="$2";            shift 2 ;;
    --) shift; break ;;
    -*) echo "unknown flag: $1" >&2; exit 2 ;;
    *)  break ;;
  esac
done

[[ -z "$KNOWLEDGE_DIR"   ]] && { echo "缺 --knowledge-dir" >&2; exit 2; }
[[ ! -d "$KNOWLEDGE_DIR" ]] && { echo "knowledge dir not found: $KNOWLEDGE_DIR" >&2; exit 2; }

INBOX="$KNOWLEDGE_DIR/inbox.md"
TEXT="${*:-}"
TS=$(date '+%Y-%m-%d %H:%M')

# 保证 inbox.md 存在
if [[ ! -f "$INBOX" ]]; then
  cat > "$INBOX" <<'INIT'
# Inbox

零散记录,后续 triage 归档到对应 domain。

---

INIT
fi

# 模式 1:纯文本,不需要 LLM
if [[ -z "$IMAGE_PATH" ]]; then
  [[ -z "$TEXT" ]] && { echo "缺文本或 --image" >&2; exit 2; }
  printf -- '- [%s] %s\n' "$TS" "$TEXT" >> "$INBOX"
  echo "已记入 inbox: $TEXT"
  exit 0
fi

# 模式 2:图片 → claude 视觉提取
[[ ! -f "$IMAGE_PATH" ]] && { echo "image not found: $IMAGE_PATH" >&2; exit 2; }

DOMAIN_PROMPT=""
if [[ -n "$SYSTEM_PROMPT_FILE" && -f "$SYSTEM_PROMPT_FILE" ]]; then
  DOMAIN_PROMPT=$(cat "$SYSTEM_PROMPT_FILE")
fi

SYSTEM=$(cat <<EOF
$DOMAIN_PROMPT

---
[由 note.sh 注入的图片入库规则]

用户发了一张图,可能是促销海报、菜单、账单、说明书、截图等。

执行步骤:
1. 用 Read 工具读 $IMAGE_PATH 看清内容
2. **隐私守门**:如果识别到身份证号、银行卡号(完整 16-19 位)、护照号、人脸近照,
   不要把原文/原图细节抄到 inbox.md。回复用户:"识别到敏感信息(类别 X),已跳过入库,
   请确认是否需要手动记录"
3. 否则用 Edit 工具往 $INBOX 末尾追加(在文末空行后追加,不要破坏现有格式):
     - [$TS] {一句话摘要} {{若用户附了文字 caption,也括起来}}
       - {关键事实 1}
       - {关键事实 2}
       - 来源: image (msg_id 见日志)
4. 写完后回复用户一句话告诉他记了什么(给他确认),格式:
     "已记到 inbox: {摘要} ({关键字段, 如金额/日期/适用条件})"
5. 回复保持简短,1-3 行,中文,不要 markdown 标题

注意:
- 优先把识别到的**原文**保留进 inbox(尤其是数字、日期、条件文字),不要只写你的"理解"
  这样以后 triage 时人可以核对
- inbox.md 只是收件箱,不要试图自动分类到 cards/*.md 等具体 domain——那是 triage 阶段的事
EOF
)

cd "$HOME"

CMD=(claude
  --append-system-prompt "$SYSTEM"
  --permission-mode dontAsk
  --no-session-persistence
  --allowed-tools Read Edit Glob Grep
  --add-dir "$KNOWLEDGE_DIR"
  --add-dir "$(dirname "$IMAGE_PATH")"
)
[[ -n "$MODEL" ]] && CMD+=(--model "$MODEL")

USER_MSG="(用户发了一张图,路径 $IMAGE_PATH)"
[[ -n "$TEXT" ]] && USER_MSG="$USER_MSG 附文字: $TEXT"

exec "${CMD[@]}" -p -- "$USER_MSG"
