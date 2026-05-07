# 自动化(可选)

LLM 是被动的,你问它才答。这一层让它主动:**定时跑一个 agent,把外部世界的变化
回写到你的 markdown 知识库**。

## 例子:每周抓信用卡新活动

```bash
# crontab 或 launchd
0 9 * * 1 cd ~/path/to/repo && claude -p \
  --append-system-prompt "$(cat docs/automation/cards-fetch-prompt.md)" \
  --allowed-tools Read Edit WebFetch \
  --add-dir "$KNOWLEDGE_DIR" \
  -- "扫一遍 cards/ 里每张卡的官网活动页,把没记录过的新活动追加到对应 md 的'当前活动' section,打 #new tag"
```

system prompt 里告诉它每张卡的官方活动页 URL。它会:
- WebFetch 拉每个 URL
- Grep 现有 md 里的活动列表去重
- Edit 追加新活动 + `#new` 标签

你周一早上扫一眼 Obsidian 看 `#new` tag 就行。

## 为什么不让 IM bot 自己干

Adapter 是被动的(等 user 消息),做不了 cron。**这是不同的 entry point**,跟 ask
共用 knowledge layer 但走不同的执行路径。

## 安全

- 给定时 agent **更宽**的工具权限(Edit / WebFetch),所以只让它操作 `KNOWLEDGE_DIR`,
  绝对不要 `--add-dir $HOME`。
- 写死 URL 列表(`docs/automation/cards-urls.txt`),不让 LLM 自由上网,降低 prompt
  injection 风险。

## 状态

模板/思路在这,具体 prompt 文件 `docs/automation/cards-fetch-prompt.md` 还没写,
有需要再加。
