---
title: TABS
caption: a row of tabs linking a set of related notes
topic: tabs
category: linking
help_for: [key:tabs]
toc: true
processed: true
---

# Tab strip

## Summary

A `tabs:` list in a note's frontmatter shows a row of tabs above the note, one per listed note or
folder; the current note's tab is highlighted, and clicking another opens it. Put `tabs:` in a
notebook or folder config and every note there gets the same strip.

## How it works

```yaml
---
title: Users
tabs: [users.md, tools.md, rules.md, lib.md, checks.md]
---
```

Tab labels come from each note's `alias:`, then `title:`, then filename stem, so a short `alias:`
keeps tabs compact. Folder tabs use the folder's name.

`tabs:` **cascades** from notebook and folder config: set it once in a notebook's
`.{notebook}.md` or a folder's `.{folder}.md` and every note in that scope gets the strip. A
note's own `tabs:` overrides the inherited one.

## Reference

| Entry | Resolves to |
|-------|-------------|
| `other.md` | a note in the same folder as the current note |
| `../folder/file.md` | a path relative to the current note |
| `notebook:path/file.md` | a note in another notebook (full path required) |
| `subfolder/` | a folder tab: opens that subfolder and its pinned note |
| `notebook:folder/` | a folder in another notebook (full path required) |

## For developers

`_buildTabs` in `main.js`; `tabs` is in `_FM_BLOCK_KEYS` (`app.py`), which is how it cascades.

