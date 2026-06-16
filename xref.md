---
title: "xref — Cross-Reference Enrichment"
type: doc
processed: true
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

Matching words get a small superscript injected inline — `[1]`, `[2]`, … — muted at rest, full opacity on hover. Click opens the matched note in the preview pane. Numbering is per-note, sequential across all xref targets, in heading order.

---

## Books and inline notes

Notes with `type: book` that use `{{inline:}}` to pull in chapter files work fully — xref scans headings across every chapter. Opening a book with `xref:` front-loads all chapter fetches rather than loading them lazily on scroll; on a local server this is imperceptible.

For best performance on very long books, add `xref:` to individual chapter notes instead of the book root — chapters have no inlines to force and xref runs immediately.

---

## Limitations

- **Top-level files only** — folder-scoped targets scan one directory; nested subdirectories are not recursed.
- **Titles and annotations only** — index vocabulary comes from note title and annotation sidecar; note body text is not indexed.
- **Heading text nodes only** — xref only injects into `<h1>`–`<h6>` text. Body paragraphs and codeblocks are untouched.
- **Cache is mtime-based** — the index refreshes when the target directory's mtime changes. Adding or editing a note in the target notebook invalidates the cache automatically.

---

See also: [[wikilinks]] for manual cross-references, [[bookkeeper]] for the canonical example of xref in action. Developer internals in [[dev/XREF]].
