---
title: "xref — Cross-Reference Enrichment"
type: doc
---

# xref — Cross-Reference Enrichment

`xref:` is nb-web frontmatter that automatically cross-references the headings of a note against titles in another notebook (or folder). Words that match become clickable reference indicators — small superscript links that open the matched note.

It's designed for knowledge fusion: a guide that lives in one notebook (`accts:`) can surface relevant deep-reference notes from another (`hledger:`) without manual wikilinks on every heading.

---

## Quick start

Add `xref:` to any note's frontmatter:

```yaml
---
title: "Review"
xref: hledger:
---
```

Every significant word in every heading will be matched against note titles in the `hledger` notebook. Matches appear as small `[1]` `[2]` superscripts after the word, linking directly to the matched note.

---

## Syntax

### Single target — whole notebook

```yaml
xref: hledger:
```

Scans all top-level `.md` files in the `hledger` notebook.

### Single target — folder scope

```yaml
xref: accts:tutorial/
```

Scans only `~/.nb/accts/tutorial/*.md`. Useful when a notebook is large and you only want to cross-reference a specific section.

### Multiple targets

```yaml
xref: [hledger:, accts:tutorial/]
```

A YAML list. Each target is fetched independently (in parallel); ref numbers are assigned sequentially across all targets. The word `[1]` might come from `hledger:`, `[2]` from `accts:tutorial/`, etc.

**YAML note:** `hledger:` (trailing colon) inside a YAML flow sequence is parsed by some tools as a mapping key rather than a plain string. nb-web detects and unwraps this automatically, so the syntax above works as written — no quoting needed.

---

## Domain stop words

Universal English stop words are always ignored (articles, prepositions, auxiliaries, common noise words like "use", "file", "note").

For domain-specific stop words — words that are common in your content but shouldn't trigger refs — use `xref-ignore:`:

```yaml
xref-ignore: ["journal", "account", "transaction"]
```

Words in this list are excluded from heading scans on the current note. They're note-level, so they only suppress matches in this note, not in the target index.

---

## How matching works

### The stem index

When you open an xref-enabled note, nb-web calls `/api/xref` with:
- `target=hledger:` (or folder-scoped)
- `stems=reconcili,anomali,period,balance,...` — the stemmed words from your headings

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

## Annotation vocabulary

The killer feature: if a note's *annotation sidecar* contains free text, those words are indexed too.

Suppose `hledger:check.md` has the title "hledger check". The heading "Verify integrity" in your guide won't match "check" or "hledger" directly. But if the annotation sidecar for `hledger:check.md` contains:

```
verify integrity validate structural soundness journal errors
```

Then "Verify" and "integrity" will both match, and `[N]` indicators will appear on that heading.

Annotations are the private back-of-house layer (never published, not in `.index`). Using them as vocabulary enrichment lets you tune xref precision without editing published content.

---

## Visual indicator

Matching words get a superscript injected inline:

```html
Reconciliation<sup class="nb-xref-ref" data-xref-sel="hledger:5">[1]</sup>
```

- Displayed as small, muted monospace superscript (`[1]`, `[2]`, …)
- Opacity 0.5 at rest, 1.0 on hover
- Click opens the matched note in the preview pane (same as any note click)
- Numbering is per-note, sequential across all xref targets, in heading order

---

## Books and inline notes

Notes with `type: book` that use `{{inline:}}` to pull in chapter files work fully — xref scans headings across every chapter.

The loading sequence for a book:

1. **Eager inlines** (chapters near the viewport) load sequentially; `nb-inlines-settled` fires when they're done.
2. xref wakes up, checks whether deferred chapters remain, and if so calls `forceAll()` — triggering every outstanding inline fetch immediately rather than waiting for the user to scroll.
3. `nb-inlines-complete` fires when the last chapter resolves.
4. xref scans all headings across all chapters.

The side effect: opening a book with `xref:` front-loads all chapter fetches rather than loading them lazily on scroll. On a local server this is imperceptible; the status pill counts them all down at once up front.

For best performance on very long books, add `xref:` to individual chapter notes instead of the book root — chapters have no inlines to force and xref runs immediately.

---

## Limitations

- **Top-level files only** — folder-scoped targets scan one directory; nested subdirectories are not recursed.
- **Titles and annotations only** — index vocabulary comes from note title and annotation sidecar; note body text is not indexed.
- **Heading text nodes only** — xref only injects into `<h1>`–`<h6>` text. Body paragraphs and codeblocks are untouched.
- **Cache is mtime-based** — the index refreshes when the target directory's mtime changes. Adding or editing a note in the target notebook invalidates the cache automatically.

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

---

See also: [[wikilinks]] for manual cross-references, [[bookkeeper]] for the canonical example of xref in action.
