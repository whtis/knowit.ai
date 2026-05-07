# Lark/飞书 Adapter

通过 `lark-cli` 的 WebSocket 长连接订阅飞书消息事件,转发到 `core/ask.sh`,
回复用 `im +messages-reply` 推回原消息线程。

## 前置

1. 在 [飞书开放平台](https://open.feishu.cn/app) 创建一个企业自建应用
2. 启用事件订阅 → 添加 `接收消息 v2.0 (im.message.receive_v1)`
3. 启用 IM 权限 → `im:message`、`im:message:send_as_bot` 等
4. 装 lark-cli:`npm i -g @larksuite/cli`,然后 `lark-cli config init` + `lark-cli auth login`

## 配置

```bash
cp config.example.sh config.sh
# 编辑 config.sh,填:
# - MY_OPEN_ID:你自己的 open_id(`lark-cli auth status` 里的 userOpenId)
# - KNOWLEDGE_DIR:你的 markdown 知识库目录
# - SYSTEM_PROMPT:domain 的 system prompt 文件路径
```

## 运行

```bash
# 前台调试
./listen.sh

# 后台常驻
nohup ./listen.sh > ../../logs/listen.log 2>&1 &
echo $! > ../../logs/listen.pid
```

## 安全

- `MY_OPEN_ID` 过滤:只有你自己 DM bot 才会触发,任何人 @ bot 都被忽略
- `idempotency-key` 用 message_id:重启不会重发
- 不处理图片/语音/文件,纯文本

## token 维护

`lark-cli` 的 access token 7 天过期,过期后跑 `lark-cli auth login` 重新授权即可。
长期常驻可以加 cron 每周一次自动 refresh。
