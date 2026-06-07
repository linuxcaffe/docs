---
title: WIKILINKS
caption: Linking between notes with [[wikilink]] syntax
---

# Wikilinks

[[#Basic Syntax|Basic Syntax]] · [[#Anchor Links|Anchor Links]] · [[#Backlinks|Backlinks]] · [[#Quartz Compatibility|Quartz Compatibility]]

---

nb-web supports `[[wikilink]]` syntax in note bodies for linking between notes. Click any wikilink in a rendered note to open the target.

---

## Basic Syntax

| Syntax | Effect |
|--------|--------|
| `[[Note Title]]` | Link by title; display text resolved automatically |
| `[[Note Title\|display text]]` | Link with custom display text |
| `[[notebook:id]]` | Link by explicit nb selector (e.g. `[[docs:3]]`) |
| `[[42]]` | Link by bare note ID within the current notebook |

Plain-title wikilinks are resolved within the current notebook first. Matching is case-insensitive — `[[shop]]` and `[[Shop]]` both find a note titled "Shop".

---

## Anchor Links

Append `#Heading Text` to jump directly to a section within a note:

| Syntax | Effect |
|--------|--------|
| `[[Page#Heading]]` | Open note and scroll to that heading |
| `[[Page#Heading\|label]]` | Same, with custom display text |
| `[[#Heading]]` | Scroll to a heading in the **current** note (no page reload) |

Heading matching is case-insensitive and compares against the heading text directly — use the heading words with spaces, not a slug.

```
[[#Contact Import]]   ✓  exact words, any case
[[#contact import]]   ✓  lowercase also works
[[#contact-import]]   ✗  slug/hyphen form does not match
```

---

## Backlinks

A `backlinks` codeblock shows all notes that link to the current note's title:

````markdown
```nb
backlinks
```
````

Results are found via ripgrep (fast) and capped at 20 by default. Pass a number to raise the limit:

````markdown
```nb
backlinks 50
```
````

See [[CODEBLOCKS]] for the full `nb` block reference.

---

## Quartz Compatibility

`[[Note Title]]` wikilinks are the recommended cross-linking syntax for any note that may be published via the NbWeb-quartz plugin. Quartz resolves them natively by title — no path, no extension needed.

| Syntax | nb-web | Quartz |
|--------|--------|--------|
| `[[Note Title]]` | ✓ title search in current notebook | ✓ native |
| `[[Note Title\|label]]` | ✓ | ✓ |
| `[[notebook:selector]]` | ✓ direct nb selector | ✗ |
| `[[42]]` | ✓ bare ID | ✗ |

See [[NbWeb-quartz]] for publishing workflow.
