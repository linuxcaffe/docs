---
title: XREF
caption: xref internals — stemming algorithm, API reference, forceAll() book behavior
toc: true
---

# XREF internals

Developer reference for the `xref:` cross-reference feature. User docs: [[xref]].

---

## How matching works

### The stem index

When an xref-enabled note opens, nb-web calls `/api/xref` with:
- `target=hledger:` (or folder-scoped)
- `stems=reconcili,anomali,period,balance,...` — stemmed words extracted from headings

On the server, every target note is indexed once (cached until its directory mtime changes). The index maps **word stems → note entries**. A note's title and its annotation sidecar text are both indexed.

### Stemming rules

Both Python (server) and JavaScript (client) apply the same suffix-stripping rules, in order:

| Suffix removed | Replacement |
|---|---|
| `ations`, `ation` | (none) |
| `ings`, `ing` | (none) |
| `ions`, `ion` | (none) |
| `ments`, `ment` | (none) |
| `ness` | (none) |
| `ities`, `ity` | (none) |
| `ies` | `y` |
| `ves` | `f` |
| `ed`, `ly`, `er` | (none) |
| `es`, `s` | (none) |

Each word must be at least 4 characters before stemming; the resulting stem must be at least 3 characters.

### Prefix matching

After stemming, a heading word stem matches an index stem if:
- **Exact match** — always matches, regardless of length
- **Prefix match** — either stem starts with the other, and the shared prefix is ≥ 5 characters

This handles plurals, conjugations, and compound forms without a full morphological analyser.

---

## Books and forceAll()

`type: book` notes use `{{inline:}}` to pull in chapters lazily (viewport-driven). xref needs all headings before it can inject references, so it hooks into the inline loading sequence:

1. **Eager inlines** (chapters near the viewport) load sequentially; `nb-inlines-settled` fires when done.
2. xref checks whether deferred chapters remain; if so calls `forceAll()` — triggers every outstanding inline fetch immediately rather than waiting for the user to scroll.
3. `nb-inlines-complete` fires when the last chapter resolves.
4. xref scans all headings across all chapters.

Side effect: opening a book with `xref:` front-loads all chapter fetches. On a local server this is imperceptible; the status pill counts them all down at once up front. For very long books, add `xref:` to individual chapter notes instead of the book root to avoid forcing all fetches eagerly.

---

## API reference

```
GET /api/xref?target=<target>&stems=<stem1>,<stem2>,...
```

| Parameter | Description |
|---|---|
| `target` | `notebook:` or `notebook:folder/` |
| `stems` | Comma-separated list of already-stemmed words to look up |

Returns a JSON object keyed by stem, each value an array of `{selector, title}` entries:

```json
{
  "reconcili": [
    {"selector": "hledger:reconciliation.md", "title": "hledger reconciliation"}
  ],
  "anomali": [
    {"selector": "hledger:check.md", "title": "hledger check"}
  ]
}
```

The cache is per-target-string and invalidated by directory mtime. No auth required (nb-web is a local tool).
