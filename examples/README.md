# Examples — 不同 domain 的玩法

每个子目录是一个独立 domain。要新增 domain,复制一个目录 + 改三个文件:

```
examples/
├── <your-domain>/
│   ├── README.md          # 这个 domain 解决什么问题
│   ├── _template.md       # frontmatter schema(空字段)
│   ├── _example.md        # 一个完整示例条目(可贡献回上游)
│   └── system-prompt.md   # 告诉 LLM 怎么读 schema + 回复风格
```

## 已有

- [`cards/`](cards/) — 信用卡决策(刷哪张卡返现最高)
- [`subscriptions/`](subscriptions/) — 订阅追踪(本月扣费、该退订什么)

## 你可以做的(灵感)

- `medications/` — 家庭药箱:有效期、适用症、互斥
- `warranties/` — 家电/数码保修期、发票存档
- `visas/` — 各国签证有效期 + 入境次数 + 续签门槛
- `restaurants/` — 常去餐厅的偏好菜、人均、营业时间
- `shortcuts/` — 常用 CLI 命令 + 标志位备忘
- `gifts/` — 给特定人送过什么、对方喜好

**核心抽象**:任何"我有一堆零散规则,想随时被推荐最优解"的领域都能塞进来。
