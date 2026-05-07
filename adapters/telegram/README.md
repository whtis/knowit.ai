# Telegram Adapter (TODO)

占位。海外用户首选。

## 实现思路

最小依赖版本(纯 bash + curl):

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

或者用 `python-telegram-bot` 库,几十行就够。

## 想做的话

PR welcome。骨架照 `adapters/lark/listen.sh` 抄,把 lark-cli 的两步换成 telegram API。
