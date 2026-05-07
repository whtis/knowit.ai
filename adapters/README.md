# Adapters — 把 IM 平台接到 core/ask.sh

每个 adapter 干两件事:

1. **接收**用户消息 → 解析出 `(question, reply_handle)`
2. 把 `question` 喂给 `core/ask.sh`,拿到答案后用 `reply_handle` **推回去**

约定:每个 adapter 一个独立目录,放自己的 `listen.sh`(或等价物)和
`config.example.sh`(把账号/凭证字段列清楚,但不带真实值)。

## 已实现

- [`stdin/`](stdin/) — 终端 REPL,最小验证 core/ask.sh 能跑(零外部依赖)
- [`lark/`](lark/) — 飞书机器人,WebSocket 长连 + idempotent reply

## 占位

- [`telegram/`](telegram/) — 待实现,大致思路:`getUpdates` 长轮询或 webhook + `sendMessage` 回包
- 微信:个人号没官方 API,只能走第三方 hook 库,合规风险高,暂不打算做

## 想加新 adapter?

最小骨架:

```bash
adapters/<platform>/
├── README.md
├── config.example.sh    # 必填环境变量列表
└── listen.sh            # 调 ../../core/ask.sh
```

参考 `lark/listen.sh` 不到 70 行,大部分 IM 协议改一改就能套上。
