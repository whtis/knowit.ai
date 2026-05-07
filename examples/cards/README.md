# Domain example: credit cards

The first domain we built. Answers *"which card should I use for this purchase?"*.

## Where the knowledge base lives

Recommended: `~/Documents/<your-vault>/cards/` (Obsidian / iCloud sync, visible
across devices). Point your adapter config at that path. **Don't commit real
card data to this repo** — `.gitignore` is set up for that.

## Frontmatter schema

See [`_template.md`](_template.md) and [`_example.md`](_example.md).

| Field | Meaning |
|-------|---------|
| `bank` / `name` | Issuing bank + product name |
| `network` | visa / mastercard / unionpay / jcb / amex |
| `status` | active / dormant / cancelled |
| `annual_fee.base` / `annual_fee.waiver` | Base annual fee + waiver condition |
| `billing_day` / `due_day` | Statement / payment-due day (for "when's it cheapest to spend?") |
| `rewards[]` | Each entry: `scenario` (keyword), `rate`, `cap` (upper limit), `note` (caveat) |
| `priority_tags[]` | Hint that this card should win when these tags hit |
| `risks[]` | Anti-patterns (large prepaid-card spend, cash-out, etc.) |

## Body sections

- `## Current promos` — time-bound offers with a date + `#new` tag. The cron-driven fetcher (see [`docs/automation.md`](../../docs/automation.md)) appends here.
- `## Past promos` — expired offers, kept for reference
- `## Notes` — anything else

## System prompt

[`system-prompt.md`](system-prompt.md) tells the LLM how to read the schema,
the response style, and which `risks[]` entries to surface as warnings.
