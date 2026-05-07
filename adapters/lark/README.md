# Lark / Feishu Adapter

Subscribes to Feishu message events through the `lark-cli` WebSocket
connection, forwards each one to `core/ask.sh`, and replies via
`im +messages-reply` in the original message thread.

## Prerequisites

1. Create a custom enterprise app on the [Lark/Feishu open platform](https://open.feishu.cn/app)
2. Enable event subscriptions → add `Receive message v2.0 (im.message.receive_v1)`
3. Enable IM permissions → `im:message`, `im:message:send_as_bot`, etc.
4. Install the CLI: `npm i -g @larksuite/cli`, then run `lark-cli config init` followed by `lark-cli auth login`

## Configuration

```bash
cp config.example.sh config.sh
# edit config.sh and fill in:
# - MY_OPEN_ID:    your own open_id (the userOpenId from `lark-cli auth status`)
# - KNOWLEDGE_DIR: path to your markdown knowledge base
# - SYSTEM_PROMPT: path to the domain's system-prompt.md
```

## Run

```bash
# foreground (debugging)
./listen.sh

# background (production)
nohup ./listen.sh > ../../logs/listen.log 2>&1 &
echo $! > ../../logs/listen.pid
```

## Security

- `MY_OPEN_ID` filter: only your own DMs trigger the bot. Anyone else `@`-mentioning it is ignored.
- `idempotency-key` is the source `message_id`: a restart never double-sends.
- Text only — images, audio, and files are dropped.

## Token maintenance

`lark-cli`'s access token expires every 7 days. When it does, run
`lark-cli auth login` to re-authorize. For long-running deployments, schedule
a weekly refresh via cron.
