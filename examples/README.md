# Examples — different domains, same pattern

Each subdirectory is a self-contained domain. To add a new one, copy any
existing folder and edit three files:

```
examples/
├── <your-domain>/
│   ├── README.md          # what this domain is for
│   ├── _template.md       # frontmatter schema (empty fields)
│   ├── _example.md        # one fully filled-in sample row
│   └── system-prompt.md   # tells the LLM how to read the schema + reply style
```

## Bundled

- [`cards/`](cards/) — credit card decisions (which card maximizes cashback)
- [`subscriptions/`](subscriptions/) — subscription tracking (what's billing this month, what to cancel)

## Ideas worth building

- `medications/` — home medicine cabinet: expiry, indications, conflicts
- `warranties/` — appliance / electronics warranty terms, receipts
- `visas/` — per-country expiry, entries left, renewal thresholds
- `restaurants/` — go-to dishes, average price, hours for the places you frequent
- `shortcuts/` — common CLI commands + flag cheat sheets
- `gifts/` — what you've given to whom, their preferences

**The abstraction:** any domain where you have *scattered rules* and want
*point-in-time recommendations* fits this pattern.
