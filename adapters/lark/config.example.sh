# adapters/lark/config.sh — 复制此文件为 config.sh 并填上真实值
# config.sh 已加入 .gitignore,不会被提交

# 你的飞书 open_id(只响应这个 ID 发来的消息,避免任何人触发)
# 取自 lark-cli auth status 的 userOpenId
export MY_OPEN_ID="ou_xxxxxxxxxxxxxxxxxxxxxxxx"

# 知识库目录(绝对路径)
export KNOWLEDGE_DIR="$HOME/Documents/<your-vault>/cards"

# 当前 domain 的 system prompt 文件(相对仓库根的路径,会自动展开)
export SYSTEM_PROMPT="$REPO_ROOT/examples/cards/system-prompt.md"

# 可选:指定模型(留空使用默认)
export MODEL=""
