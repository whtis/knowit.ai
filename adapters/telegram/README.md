# Telegram Adapter (TODO)

Stub. The natural choice for users outside mainland China.

## Implementation sketch

Minimal-deps version (pure bash + curl):

```
listen.sh:
  while true:
    updates = curl https://api.telegram.org/bot<TOKEN>/getUpdates?offset=$NEXT
    for each update:
      question = update.message.text
      if update.message.from.id != $MY_USER_ID: skip
      answer = ../../core/ask.sh ...
      curl -d ... https://api.telegram.org/bot<TOKEN>/sendMessage
      NEXT = update.update_id + 1
```

Or use the `python-telegram-bot` library — a few dozen lines is plenty.

## Want to build it?

PRs welcome. Copy `adapters/lark/listen.sh` as the skeleton; swap the two
`lark-cli` calls for the Telegram API equivalents.
