---
title: CODEBLOCKS
caption: Live interactive widgets rendered from fenced code blocks in notes
---

# Codeblocks

[[#Block Types|Block Types]] · [[#Block Controls|Block Controls]] · [[#tw — Taskwarrior|tw]] · [[#nb — nb Panel|nb]] · [[#git — Git Log|git]] · [[#hledger — Accounting|hledger]] · [[#t — Timeclock|t]]

---

Live codeblocks are delivered by the **NbWeb-codeblocks** plugin — enabled by default and listed in **Menu → Plugins**. Disabling it there removes all live block rendering; fences revert to plain static code display.

Write a fenced code block with a recognised language tag and nb-web renders it as a live, interactive widget instead of static code.

````markdown
```tw
status:pending due:today
```

```hledger
bal -p thisweek
```

```nb
backlinks
```

```git
nb-web log --oneline -10
```
````

These blocks are **local-first**: no cloud, no sync service. Data comes from your actual tools — Taskwarrior, hledger, timeclock, git — via the nb-web Flask server running alongside the app.

---

## Block Controls

Every block header carries the same universal controls:

| Control | Action |
|---------|--------|
| **▼/▶** | Collapse / expand the block body. State is persisted in `localStorage` keyed on block type + query, so collapsed blocks stay collapsed across reloads and note switches. |
| **↻** | Refresh — re-fetch data on demand |
| **+** | Open inline add form (where supported: `tw`, `hledger`) |
| **⎋** | Launch external app (where supported: `t`) |

---

## Block Types

### tw — Taskwarrior

````markdown
```tw
project:myproject +next
```
````

Renders a live task table from any `task` filter or report expression.

- Columns auto-hide when empty (project, priority, due, tags)
- Click any **ID** to expand `task information` inline (one at a time)
- **+** button opens an inline form to create tasks with description, project, due, priority, tags
- Override column selection with a `columns:` line in the fence body:

````markdown
```tw
columns:id,description,due
+work
```
````

---

### nb — nb Panel

````markdown
```nb
notebooks
```
````

Embeds a live nb panel. Supported commands:

| Command | What it shows |
|---------|--------------|
| `notebooks` | All notebooks with note count and last-modified age; click any to switch |
| `backlinks [N]` | Notes that wiki-link `[[to this note]]`; N caps results (default 20) |

The active notebook is highlighted in the `notebooks` view. `backlinks` uses ripgrep when available for speed.

---

### git — Git Log

````markdown
```git
nb-web log --oneline -10
```
````

The first word is a repo **alias** configured in `nb-settings.json`; the rest is the git subcommand and flags. Useful for dev-journal notes, project planning pages, or any note that lives alongside a codebase.

**Configuration** — add repo aliases to `nb-settings.json`:

```json
{
  "git_repos": {
    "nb-web":    "~/dev/nb-web",
    "myproject": "~/dev/myproject"
  }
}
```

Permitted subcommands (read-only): `branch`, `describe`, `diff`, `log`, `ls-files`, `remote`, `shortlog`, `show`, `stash`, `status`, `tag`.

---

### hledger — Accounting

````markdown
```hledger
bal expenses --monthly -3
```
````

Any hledger subcommand: `bal`, `reg`, `is`, `bs`, `cf`. Positive and negative amounts are coloured. The **+** button opens an inline journal entry form.

Requires `hledger` on `$PATH`. See [hledger-codeblock](https://github.com/linuxcaffe/hledger-codeblock) — this block is also released as a standalone package.

---

### t — Timeclock

````markdown
```t
today
```
````

Shows the clocked-in account, elapsed time, and a period report. The argument is a period expression (`today`, `thisweek`, `lastmonth`). The **⎋** button opens the full timeclock UI.

---

## Broader Context

The NbWeb-codeblocks plugin is nb-web's implementation of the [mkd-codeblocks](https://codeberg.org/linuxcaffe/mkd-codeblocks) project — a collection of independently distributable live-query widgets designed as self-contained drop-ins for any markdown note app. The `hledger` block is already released as a standalone package; the others are planned for extraction as the project matures.
