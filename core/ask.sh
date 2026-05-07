#!/usr/bin/env bash
# core/ask.sh — domain 无关的决策引擎
# 把"知识库目录 + 领域 system prompt + 一行问题"丢给 claude -p,返回答案
#
# 用法:
#   core/ask.sh \
#     --knowledge-dir <path>            # 必填,markdown 知识库目录
#     --system-prompt <file>            # 必填,domain 专属 system prompt 文件
#     [--model sonnet|opus|haiku]       # 可选,默认 claude 当前会话模型
#     [--turns 6]                       # 可选,最大 agent turn 数,默认 6
#     -- "<question>"

set -euo pipefail

MODEL=""
TURNS="6"
KNOWLEDGE_DIR=""
SYSTEM_PROMPT_FILE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --knowledge-dir)   KNOWLEDGE_DIR="$2";   shift 2 ;;
    --system-prompt)   SYSTEM_PROMPT_FILE="$2"; shift 2 ;;
    --model)           MODEL="$2";           shift 2 ;;
    --turns)           TURNS="$2";           shift 2 ;;
    --) shift; break ;;
    -*) echo "unknown flag: $1" >&2; exit 2 ;;
    *)  break ;;
  esac
done

if [[ -z "$KNOWLEDGE_DIR" || -z "$SYSTEM_PROMPT_FILE" ]]; then
  echo "用法: $0 --knowledge-dir <dir> --system-prompt <file> [--model X] [--turns N] -- \"问题\"" >&2
  exit 2
fi
[[ ! -d "$KNOWLEDGE_DIR"      ]] && { echo "knowledge dir not found: $KNOWLEDGE_DIR" >&2;      exit 2; }
[[ ! -f "$SYSTEM_PROMPT_FILE" ]] && { echo "system prompt not found: $SYSTEM_PROMPT_FILE" >&2; exit 2; }

QUESTION="${*:-}"
[[ -z "$QUESTION" ]] && { echo "缺少问题" >&2; exit 2; }

DOMAIN_PROMPT=$(cat "$SYSTEM_PROMPT_FILE")

# 通用尾巴:解释知识库结构和回复风格,所有 domain 共用
COMMON_TAIL=$(cat <<EOF

---
[由 ask.sh 注入的通用规则]
知识库位置: $KNOWLEDGE_DIR
- 用 Read/Glob/Grep 工具读这个目录,基于实际文件回答
- 忽略 README.md 和以 _ 开头的元文件(_template.md / _example.md 等),除非用户明确要求
- 回复保持 IM 体感:中文、简短、先结论再 1-2 行理由,不要 markdown 标题
- 不要解释你做了什么(如"我读了 xxx 目录")
- 知识库为空或无匹配,直说"知识库里没相关条目"
EOF
)

SYSTEM="$DOMAIN_PROMPT
$COMMON_TAIL"

cd "$HOME"

CMD=(claude
  --append-system-prompt "$SYSTEM"
  --permission-mode dontAsk
  --no-session-persistence
  --allowed-tools Read Glob Grep
  --add-dir "$KNOWLEDGE_DIR"
)
[[ -n "$MODEL" ]] && CMD+=(--model "$MODEL")

exec "${CMD[@]}" -p -- "$QUESTION"
