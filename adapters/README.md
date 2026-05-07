# Adapters — wiring an IM platform into core/ask.sh

Each adapter does two things:

1. **Receive** a user message → parse it into `(question, reply_handle)`
2. Feed `question` to `core/ask.sh`, then use `reply_handle` to **send the answer back**

Convention: one adapter per directory, owning its own `listen.sh` (or
equivalent) and a `config.example.sh` listing every credential / env var with
placeholder values.

## Implemented

- [`stdin/`](stdin/) — terminal REPL, the smallest possible smoke test for `core/ask.sh` (no external deps)
- [`lark/`](lark/) — Feishu / Lark bot, persistent WebSocket + idempotent reply

## Stubs

- [`telegram/`](telegram/) — TODO. Sketch: `getUpdates` long-polling or webhook + `sendMessage` to reply.
- WeChat: personal accounts have no official API. Third-party hook libraries exist but carry compliance risk — not planned.

## Adding a new adapter

Minimal skeleton:

```bash
adapters/<platform>/
├── README.md
├── config.example.sh    # env vars to fill in
└── listen.sh            # calls ../../core/ask.sh
```

`lark/listen.sh` is under 70 lines — most IM protocols slot in with small tweaks.
