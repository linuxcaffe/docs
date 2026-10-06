---
title: HELP
caption: the ? button, and how help finds what to show
type: topic
topic: help
category: basics
help_for: [type:help, key:help, key:help_add, key:help_for, key:help_header]
toc: true
processed: true
---

# Help

## Summary

The **?** at the far right of the toolbar opens help for whatever you're looking at: the note's
type, the live blocks in it, its frontmatter keys, its notebook. Each topic shows a short summary,
with **More** for the full page and **Try it** for a live example you can edit. The help comes
from the same docs you can read in the `docs:` notebook, so there's one copy of everything.

## How it works

Click **?** to open the popover; click it again, or anywhere outside, to close it. Its top line
comes from `help_header:` (links to the project, Help, Basics and the docs); following one closes
the popover. Below it, each topic for this note starts folded to a one-line heading (its title and
caption); click one to open its summary. On topic notes and tour pages, a line of **Basics** links
(Notebooks, Note list, Search and tags, Editor, Keyboard, Help) opens those topics right there.

### Where the topics come from

Help is gathered from these places, in this order, without repeats:

1. **The note's type**: a `type: project` note gets `.lib/help-type-project.md` automatically, if
   that file exists.
2. **A tour page's own topic**: a note with `topic:` (a `features:` page) gets that topic next.
3. **Docs topics that say they apply** (`help_for:`, below).
4. **`help_add:`** from the global, notebook and folder configs, all added together.
5. **`help:`**, the note's own value, or else the nearest one up the config chain.

### `help_for:` — a docs topic says where it applies

Each topic note in `docs:` lists the places it explains:

```yaml
help_for: [type:project, block:timedot, key:timeframe, notebook:accts]
```

| Context | Matches a note that… |
|---|---|
| `type:<type>` | has that `type:` |
| `block:<lang>` | contains a fenced codeblock in that language |
| `key:<key>` | has that frontmatter key, its own or inherited from a config (a folder's `tabs:` counts) |
| `notebook:<name>` | is in that notebook |

| `page:<page>` | is shown on that page's own **?**: `editor` (the editor toolbar), `terminal` (the terminal's title bar), `notebooks` (a notebook's details on the Notebooks page) |

`check:` and `plugin:` contexts are for help on check findings and plugins (not built yet).
Adding help somewhere new is one line in the topic note. A topic note's own `access:` hides it from
anyone below that level.

A topic note is laid out in layers: a one-line `caption:`, then `## Summary`, `## How it works`,
`## Reference` and `## For developers`. The popover shows the caption and Summary; **More** opens
the whole note. With a `category:`, **Try it** opens its page in the `features:` notebook.

### `help:` and `help_add:` — set it by hand

`help:` overrides: the note's own value wins, otherwise the nearest `.{folder}.md`, then
`.{notebook}.md`, then the global `.nb.md`. The global config has `help: nb`, so there's always
something, unless a closer level sets `help: ''`. A value can be:

- a **bare topic** (`help: project`, `help: nb`): tries `.lib/help-type-<topic>.md`, then
  `.lib/help-<topic>.md`
- a **note selector**, anything with a `:` (`help: docs:wikilinks.md`): shown directly
- a **list** of either: each shown in order

`help_add:` adds instead of replacing: every level's `help_add:` is collected, so a notebook or
folder can always show a shared topic as well as whatever else applies.

## Reference

- **`.lib` help files** carry `type: help` (❓ in the list), so `fm` can list them:
  `.lib type:help`. A restricted one encodes its level in the filename (`user-mgmt-admin.md`)
  rather than `access:`.
- **Type files are named after the literal `type:` value**, plural included:
  `help-type-reports.md` for `type: reports`. A topic that isn't a type is `help-<subject>.md`.
- **`help_header:`** is one line of Markdown, nearest wins (note → folder → notebook → global
  `.nb.md`). With a header set, every note has a **?**, even one with no topics.
- **The topic notebook** is `docs` unless `.nb.md` sets `help_topics: <notebook>`; the tour's
  notebook (for **Try it** and the Basics line) is `features` unless it sets `features_notebook:`.
- **The Basics line** follows the chapters of `features:basics/basics.md`, in order.
- **Topics are re-read** when a file in the topic notebook changes; no restart needed.

## For developers

- [[docs:dev/dev-architecture.md#.lib inline components|Architecture: .lib components]]
- [[docs:dev/dev-notebook-config.md|Notebook config (the cascade)]]

`_resolve_help_list` and `_help_for_matches` (`app.py`) build `effective_help`; `_showTypeHelp`
(`main.js`) draws the popover. nb-web `CLAUDE.md` invariants 31–33 and 66. Design:
[[claude:nb-web_help_single_source_design_2026-10-04.md]].

