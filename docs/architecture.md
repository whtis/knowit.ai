# Architecture

Three layers, strictly decoupled. The interface between each layer is plain
text — there's no schema protocol in the middle, the LLM handles structure
itself.

## Big picture

```
                ┌─────────────────────────────────────────────┐
                │  IM platform: Feishu / Telegram / Discord  │
                │           (user sends a message)            │
                └───────────────────────┬─────────────────────┘
                                        │ message event
                                        ▼
   ┌─────────────────────────────────────────────────────────┐
   │ Adapter layer — adapters/<platform>/listen.sh           │
   │   Job: flatten the IM protocol into (question, reply)   │
   │   Doesn't know the domain. Doesn't know the business.   │
   └────────────────────────┬────────────────────────────────┘
                            │ ./core/ask.sh "question"
                            ▼
   ┌─────────────────────────────────────────────────────────┐
   │ Core — core/ask.sh                                      │
   │   Job: assemble system prompt, lock down tools,         │
   │        invoke `claude -p`. Generic. No platform / domain│
   └────────────────────────┬────────────────────────────────┘
                            │ Read / Glob / Grep
                            ▼
   ┌─────────────────────────────────────────────────────────┐
   │ Knowledge — your markdown files                         │
   │   One rule per .md, frontmatter for structure +         │
   │   freeform body. Drop in Obsidian / iCloud for sync.    │
   └─────────────────────────────────────────────────────────┘
                            ▲
                            │ paired system prompt
                            │
   ┌─────────────────────────────────────────────────────────┐
   │ Domain — examples/<name>/                               │
   │   _template.md     : empty schema                       │
   │   _example.md      : one filled-in sample row           │
   │   system-prompt.md : how the LLM should read & reply    │
   └─────────────────────────────────────────────────────────┘
```

## What each layer knows

| Layer | Knows | Doesn't know |
|-------|-------|--------------|
| Adapter | Platform protocol (how to send/receive) | What the user is asking, what the KB looks like |
| Core | `claude` CLI calling convention, common reply style | Specific platform, specific domain |
| Domain (system-prompt) | Schema fields, answer rules, risk warnings | How user messages arrive, where answers go |
| Knowledge (md files) | Real-world facts | How they get queried, who reads the answer |

## Why not Agent SDK / LangChain

- The RAG need here is trivial (grep + read is enough). No vector store required.
- A Claude.ai subscription can power `claude -p` — **zero token cost**. Agent SDK forces per-token billing.
- ~100 lines of bash replace a Python service. Lower ops burden.

## Why markdown, not a database

- Cross-device sync is built in (Obsidian / iCloud / Dropbox)
- You can edit the KB on your phone (humans read it too, not just the bot)
- Diff/git friendly — you can see what changed at a glance
- LLMs handle markdown frontmatter natively, no extra parsing layer

## Limitations

- **Single user.** Multi-user means routing in the adapter and identity isolation in core.
- **Latency 5–15s** per question (`claude -p` cold start). Not the snappy IM feel — better suited as IDE-embedded or with streaming output.
- **Manual KB upkeep.** The LLM doesn't proactively notice "there's a new card" — pair with a cron-driven fetcher (see [`automation.md`](automation.md)) if you want push-style updates.
