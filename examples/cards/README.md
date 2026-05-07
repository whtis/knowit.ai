# 示例 domain:信用卡

最先做出来的 domain。回答"这笔消费用哪张卡更划算"。

## 知识库放哪

推荐放 `~/Documents/<your-vault>/cards/`(Obsidian/iCloud 同步,跨设备可见),
然后 adapter 配置里指向它。**不要把真实卡片提交到这个仓库**,通过 .gitignore 隔离。

## frontmatter schema

见 [`_template.md`](_template.md) 和 [`_example.md`](_example.md)。

| 字段 | 说明 |
|------|------|
| `bank` / `name` | 发卡行中文名 + 卡产品名 |
| `network` | visa / mastercard / unionpay / jcb / amex |
| `status` | active / dormant / cancelled |
| `annual_fee.base` / `annual_fee.waiver` | 基础年费 + 免年费条件 |
| `billing_day` / `due_day` | 账单日 / 还款日(用来回答"什么时候刷最划算") |
| `rewards[]` | 每个权益: `scenario`(场景关键词)、`rate`(返现率)、`cap`(上限)、`note`(限制) |
| `priority_tags[]` | 命中这些场景时优先推这张卡 |
| `risks[]` | 风控/陷阱(大额刷储值、套现等) |

## 正文 sections

- `## 当前活动` —— 时效性活动,带日期 + `#new` 标签;定时抓取脚本(见 `docs/automation.md`)会写到这里
- `## 历史活动` —— 已结束,留作参考
- `## 备注` —— 杂项

## system prompt

[`system-prompt.md`](system-prompt.md) —— 告诉 LLM 怎么读 schema、回复风格、风控提醒规则。
