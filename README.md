# knowit.ai

> 你的零散规则塞进 markdown,IM 里随时问"我现在该 X 不"——LLM 给推荐。
> 用 Claude Code 订阅,**零 API token 成本**,100 行 shell。

## 这是什么

一个**模板**,不是产品。展示一种很简单但还没什么人写的范式:

- 你的零散规则(信用卡返现、订阅扣费、家电保修...)放进 markdown,带 frontmatter
- 一个常驻 IM 机器人,问它就给推荐
- LLM 用的是 **Claude Code CLI**(走 Pro/Max 订阅,不烧 API token)
- 跨设备同步靠 Obsidian/iCloud,手机也能改

第一个跑通的 domain 是"信用卡决策"——"我现在 200 块超市消费,刷哪张卡返现最高"。
但同样的范式可以套到任何"我有零散规则,想随时被推荐最优解"的领域。

## 三层架构

```
IM 平台 ─► adapters/<platform>/  ─► core/ask.sh ─► claude -p ─► markdown 知识库
                                       ▲
                                       │
                            examples/<domain>/system-prompt.md
```

详见 [`docs/architecture.md`](docs/architecture.md)。

## 5 分钟跑起来

### 1. 装好依赖

- macOS / Linux,bash + jq
- [Claude Code CLI](https://docs.claude.com/code) 已登录(`claude` 能跑就行)
- [`@larksuite/cli`](https://www.npmjs.com/package/@larksuite/cli)(只用 lark adapter 时)

### 2. 先用 stdin REPL 玩玩,不接 IM

```bash
git clone https://github.com/whtis/knowit.ai && cd knowit.ai
./adapters/stdin/repl.sh --domain cards
> 周末超市消费 200 块,刷哪张卡划算
# 直接打印 LLM 回答
```

(此时知识库就是仓库自带的 `examples/cards/_example.md`,只用来 demo)

### 3. 接你自己的真知识库

```bash
mkdir -p ~/Documents/notes/cards
cp examples/cards/_template.md ~/Documents/notes/cards/招行-young.md
# 填字段...

./adapters/stdin/repl.sh \
  --knowledge-dir ~/Documents/notes/cards \
  --system-prompt examples/cards/system-prompt.md
```

### 4. 接飞书

```bash
cd adapters/lark
cp config.example.sh config.sh
# 编辑 config.sh,填 MY_OPEN_ID / KNOWLEDGE_DIR / SYSTEM_PROMPT
./listen.sh
```

详见 [`adapters/lark/README.md`](adapters/lark/README.md)。

## 已有 domain

- [`examples/cards/`](examples/cards/) — 信用卡决策
- [`examples/subscriptions/`](examples/subscriptions/) — 订阅追踪

加新 domain 见 [`examples/README.md`](examples/README.md)——三个文件搞定。

## 已有 adapter

- [`adapters/stdin/`](adapters/stdin/) — 终端 REPL,无依赖
- [`adapters/lark/`](adapters/lark/) — 飞书机器人(已实现)
- [`adapters/telegram/`](adapters/telegram/) — TODO,PR welcome

## FAQ

**Q: 为什么不用 Anthropic API / Agent SDK?**
A: 那两条路按 token 付费。直接调 `claude -p` 走的是你 Claude.ai 订阅额度,
个人用基本不要钱。代价是要本地常驻进程(或一台 always-on 的小机器)。

**Q: 安全?**
A: Adapter 默认只响应 `MY_OPEN_ID`(你自己的 ID)发的消息;LLM 工具权限严格限于
`Read/Glob/Grep`,只能访问知识库目录;`config.sh` 和 `logs/` 已 gitignore。

**Q: 能多用户用吗?**
A: 不能。这是个**单人助手**。多用户要在 adapter 加路由 + 在 core 加身份隔离,
而且 Claude.ai 订阅条款不允许第三方使用你的认证,要走 API 计费。

**Q: 准确性?**
A: LLM 会基于知识库推理,但活动适用条件(节假日、最低消费、用户名单白)很多隐藏
细节。**关键决策(大额消费)请自己复核**。

## License

MIT(暂定)
