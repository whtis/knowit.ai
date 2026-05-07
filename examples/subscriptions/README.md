# Domain example: subscription tracker

Proves the architecture isn't just a credit-card thing — the same pattern
applies to subscription tracking with almost no changes.

## Typical questions

- "What's billing me this month?"
- "Do I have duplicate subscriptions?"
- "Which one should I cancel?" (based on `usage_score`)
- "How do I cancel Netflix?" (returns `cancel_url`)

## Cross-domain ties

The `payment` field references a card name from the `cards/` domain — the seed
of multi-domain queries. Future support for *"which subscriptions are charged
to my Young card?"* lives here.

## Status

Schema + one example row. If you fork this repo, this is a drop-in domain you
can use as-is.
