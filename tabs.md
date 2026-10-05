---
title: TABS
caption: a row of tabs linking a set of related notes
type: topic
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

Bare names are relative to the folder of whoever set them: a note's **own** `tabs:` to the note's
folder, a folder config's (`basics/.basics.md`) to that folder, the notebook config's to the
notebook root. So one config works for every note below it. `../` steps up a folder, and
`notebook:path` is always explicit. The `.md` can be left off (`note-list` means `note-list.md`).

## Reference

| Entry | Resolves to |
|-------|-------------|
| `other.md` or `other` | beside whoever set the tabs (the note, or the config's folder) |
| `../folder/file.md` | a path relative to the current note |
| `notebook:path/file.md` | a note in another notebook (full path required) |
| `subfolder/` | a folder tab: opens that subfolder and its pinned note |
| `notebook:folder/` | a folder in another notebook (full path required) |
| `notebook:/` | the notebook's top level |

## For developers

- [[docs:dev/dev-architecture.md#Tab strip|Architecture: tab strip]]
- [[docs:dev/dev-notebook-config.md|Notebook config]]

`_buildTabs` in `main.js`; `tabs` is in `_FM_BLOCK_KEYS` (`app.py`), which is how it cascades.

