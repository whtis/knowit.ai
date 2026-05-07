# Automation (optional)

The LLM is reactive — it answers when you ask. This optional layer makes it
proactive: **a scheduled agent that watches the outside world and writes
updates back into your markdown knowledge base.**

## Example: weekly credit-card promo crawl

```bash
# crontab or launchd
0 9 * * 1 cd ~/path/to/repo && claude -p \
  --append-system-prompt "$(cat docs/automation/cards-fetch-prompt.md)" \
  --allowed-tools Read Edit WebFetch \
  --add-dir "$KNOWLEDGE_DIR" \
  -- "Sweep each bank's official promo page, append any unrecorded promos to the matching card's '## Current promos' section, tag #new."
```

The system prompt embeds the per-card promo URLs. The agent will:

- `WebFetch` each URL
- `Grep` the existing markdown to dedupe against past promos
- `Edit` to append new entries with a `#new` tag

You glance at the `#new` tag in Obsidian on Monday morning. That's the loop.

## Why doesn't the IM bot do this itself

Adapters are passive — they wait for user messages, they don't run on cron.
**Automation is a separate entry point.** It shares the knowledge layer with the
ask path but uses a different execution route (write privileges, broader tools).

## Security

- The scheduled agent gets **broader** tool access (`Edit`, `WebFetch`), so
  scope it tightly: pass `--add-dir "$KNOWLEDGE_DIR"`, never `--add-dir $HOME`.
- Hardcode the URL list (e.g. `docs/automation/cards-urls.txt`) instead of
  letting the LLM discover URLs freely. Limits prompt-injection blast radius.

## Status

This file documents the pattern. The concrete fetcher prompt
(`docs/automation/cards-fetch-prompt.md`) isn't checked in yet — add it when
you actually need it.
