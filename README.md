# knowit.ai

**English** · [中文](README.zh.md)

> Stash your scattered rules into markdown. From any IM, ask *"should I X right now?"* — get an LLM-powered recommendation.
>
> **🟢 Powered by your Claude.ai Pro/Max subscription. Zero API tokens.** ~100 lines of shell.

## Why subscription works

We don't use the Anthropic API or the Claude Agent SDK (which forces per-token
billing). We invoke `claude -p` directly — the
[Claude Code CLI](https://docs.claude.com/code) in non-interactive mode.
Claude Code CLI reuses your Claude.ai login, so each call draws from **the same
conversation quota you already pay for** with Pro/Max.

The trade-off: you need an always-on machine (Mac, Linux, a cheap mini-PC) that
can run the `claude` command. Personal single-user use is essentially free.
**You cannot turn this into a SaaS for other people** — Anthropic explicitly
forbids third parties from redistributing claude.ai login; that path requires
switching to API key billing.

## What this is

A **template**, not a product. It demonstrates a simple but underexplored pattern:

- Your scattered rules (credit card cashback, recurring subscriptions, appliance warranties...) live in markdown with frontmatter
- A long-running IM bot answers point-in-time questions like "what should I do?"
- The LLM is **Claude Code CLI** (uses Pro/Max subscription, no API tokens)
- Cross-device sync via Obsidian / iCloud — phone-editable

The first working domain is **credit card decisions** — *"I'm about to spend $30
at the supermarket on a Sunday, which card maximizes cashback?"*. The same
pattern fits anything where you have scattered rules and want point-in-time
recommendations.

## Three-layer architecture

```
IM platform ─► adapters/<platform>/ ─► core/ask.sh ─► claude -p ─► markdown KB
                                          ▲
                                          │
                              examples/<domain>/system-prompt.md
```

More in [`docs/architecture.md`](docs/architecture.md).

## 5-minute setup

### 1. Dependencies

- macOS / Linux, bash + jq
- [Claude Code CLI](https://docs.claude.com/code), logged in (you can run `claude`)
- [`@larksuite/cli`](https://www.npmjs.com/package/@larksuite/cli) (only for the Lark adapter)

### 2. Try the stdin REPL — no IM platform required

```bash
git clone https://github.com/whtis/knowit.ai && cd knowit.ai
./adapters/stdin/repl.sh --domain cards
> Should I use my Young card at the supermarket this weekend, $30?
# LLM answer prints directly
```

(Knowledge base here is the bundled `examples/cards/_example.md` — for demo only.)

### 3. Point at your own knowledge base

```bash
mkdir -p ~/Documents/notes/cards
cp examples/cards/_template.md ~/Documents/notes/cards/cmb-young.md
# fill the fields...

./adapters/stdin/repl.sh \
  --knowledge-dir ~/Documents/notes/cards \
  --system-prompt examples/cards/system-prompt.md
```

### 4. Wire it to Feishu / Lark

```bash
cd adapters/lark
cp config.example.sh config.sh
# edit config.sh: MY_OPEN_ID / KNOWLEDGE_DIR / SYSTEM_PROMPT
./listen.sh
```

See [`adapters/lark/README.md`](adapters/lark/README.md).

## Three ways to use the bot

Once wired up to your IM, three input shapes are handled:

| Send to bot | What happens | Latency |
|-------------|--------------|---------|
| Plain question — *"Should I use my Young card here?"* | `core/ask.sh` reads the KB, LLM recommends | ~10s |
| `/note <free text>` | Direct append to `inbox.md` with a timestamp. **No LLM.** Zero hallucination, zero latency | <1s |
| Image (screenshot of a promo, a receipt, a menu...) | `core/note.sh` downloads the image, Claude reads it via vision, structured fact extracted into `inbox.md`. Sensitive content (IDs, full card numbers, faces) is auto-skipped | ~30–45s |

Inbox entries are intentionally raw — a separate (manual or scheduled) triage
step files them into the right domain. Capture is fast and trustworthy; filing
is reviewed.

## Built-in domains

- [`examples/cards/`](examples/cards/) — credit card decisions
- [`examples/subscriptions/`](examples/subscriptions/) — subscription tracking

Adding a new domain is three files. See [`examples/README.md`](examples/README.md).

## Built-in adapters

- [`adapters/stdin/`](adapters/stdin/) — terminal REPL, zero deps
- [`adapters/lark/`](adapters/lark/) — Feishu / Lark bot
- [`adapters/telegram/`](adapters/telegram/) — TODO, PRs welcome

## FAQ

**Q: Why not the Anthropic API or Agent SDK?**
A: Both bill per token. Calling `claude -p` directly draws from your Claude.ai
subscription quota — for personal single-user use, essentially free. The cost:
you need an always-on local process (or a small server).

**Q: What about security?**
A: The adapter only responds to `MY_OPEN_ID` (your own ID); the read path is
restricted to `Read / Glob / Grep` against the knowledge directory; the write
path (image-to-inbox) adds `Edit` only on `inbox.md` (the file is pre-created
so `Write` is never granted); `config.sh` and `logs/` are gitignored. Images
are cached under `$XDG_CACHE_HOME/knowit/images/` and never committed.

**Q: Can multiple users share one bot?**
A: No — this is a **personal assistant**. Multi-user requires routing in the
adapter, identity isolation in core, and switching to API key billing per
Anthropic's terms.

**Q: How accurate is it?**
A: The LLM reasons from your knowledge base, but real-world conditions (holiday
rules, minimum spend, eligibility lists) often hide subtle gotchas.
**Verify any high-stakes recommendation yourself.**

## License

[MIT](LICENSE)
