#!/usr/bin/env bash
# adapters/stdin/repl.sh — 终端 REPL,验证 core/ask.sh 能跑,不依赖任何 IM 平台
#
# 用法:
#   ./repl.sh --domain cards         # 用 examples/cards/system-prompt.md
#   ./repl.sh --knowledge-dir ~/notes/cards \
#             --system-prompt ./my-prompt.md

set -euo pipefail

ADAPTER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$ADAPTER_DIR/../.." && pwd)"

DOMAIN=""
KNOWLEDGE_DIR=""
SYSTEM_PROMPT=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --domain)         DOMAIN="$2";         shift 2 ;;
    --knowledge-dir)  KNOWLEDGE_DIR="$2";  shift 2 ;;
    --system-prompt)  SYSTEM_PROMPT="$2";  shift 2 ;;
    -h|--help) sed -n '2,8p' "$0"; exit 0 ;;
    *) echo "unknown: $1" >&2; exit 2 ;;
  esac
done

# --domain 是糖,自动找 examples/<domain>/{,_example 的目录} + system-prompt.md
if [[ -n "$DOMAIN" ]]; then
  SYSTEM_PROMPT="${SYSTEM_PROMPT:-$REPO_ROOT/examples/$DOMAIN/system-prompt.md}"
  # 知识库默认就用 examples 里的示例(只用来 demo,正式用 --knowledge-dir 指你的真目录)
  KNOWLEDGE_DIR="${KNOWLEDGE_DIR:-$REPO_ROOT/examples/$DOMAIN}"
fi

[[ -z "$KNOWLEDGE_DIR" || -z "$SYSTEM_PROMPT" ]] && {
  echo "需要 --domain <name> 或 (--knowledge-dir + --system-prompt)" >&2
  exit 2
}

echo "REPL 启动 (knowledge=$KNOWLEDGE_DIR, prompt=$SYSTEM_PROMPT)"
echo "输入问题回车提问,Ctrl-D 退出"
echo "----"

while IFS= read -r -p "> " question; do
  [[ -z "$question" ]] && continue
  "$REPO_ROOT/core/ask.sh" \
    --knowledge-dir "$KNOWLEDGE_DIR" \
    --system-prompt "$SYSTEM_PROMPT" \
    -- "$question"
  echo
done
