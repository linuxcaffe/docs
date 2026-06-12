---
title: CODEBLOCKS
caption: Live interactive widgets rendered from fenced code blocks in notes
toc: true
---

# Codeblocks

[[#Block Types|Block Types]] · [[#Block Controls|Block Controls]] · [[#tw — Taskwarrior|tw]] · [[#nb — nb Panel|nb]] · [[#git — Git Log|git]] · [[#hledger — Accounting|hledger]] · [[#chart — Financial Charts|chart]] · [[#nav — Folder Navigator|nav]] · [[#test — Embedded Assertions|test]] · [[#t — Timeclock|t]] · [[#cine — Film Production|cine]]

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
| **+** | Open inline add form (where supported: `tw`, `hledger`). If the note has `lock: yes` in its frontmatter, the button shows 🔒 for 2.5 s instead of opening the form. |
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

Any hledger subcommand: `bal`, `reg`, `is`, `bs`, `cf`. Positive and negative amounts are coloured.

**Add Transaction (`+` button)**

Opens an inline posting form. Two smart pre-fills happen automatically:

- **Account from query** — if the fence body contains an account name (e.g. `reg Assets:Bank`), the first account field in the form is pre-populated with it. hledger command words, flags, and query filters (`date:`, `amt:`, etc.) are skipped; the first remaining alphanumeric-or-colon token is used.
- **Date from filename** — if the currently open note is a daily note named `YYYYMMDD.md`, the date field is pre-filled from the filename instead of today's date.

**Bookkeeper panel**

The hledger panel (☰ → hledger or via a `hledger` codeblock) has a persistent **+ Add Transaction** section at the top that also applies both smart pre-fills above.

**Files tab**

The hledger panel's **Files** tab handles bulk import and export between daily notes and journal files:

- **Export** — scans `YYYYMMDD.md` daily notes in the active notebook for ` ```hledger ``` ` fenced blocks and writes their contents to a `.journal` file. Optionally filtered by date range.
- **Import** — parses an existing `.journal` file and appends each dated transaction block to the matching `YYYYMMDD.md` daily note (creating the note if it doesn't exist), then commits.

**Static `ledger` blocks**

Use ` ```ledger ` (not ` ```hledger `) for example journal entries in tutorial or documentation notes. These are rendered as static syntax-highlighted code via Prism — never executed against your real journal.

Requires `hledger` on `$PATH`. See [hledger-codeblock](https://github.com/linuxcaffe/hledger-codeblock) — this block is also released as a standalone package.

---

### chart — Financial Charts

````markdown
```chart
cashflow thisyear
```
````

Interactive Chart.js visualisations driven by hledger data. Requires the **NbWeb-hledger** plugin with a configured journal.

**Syntax:** `` ```chart\n<report> [period] [depth:N]\n``` ``

**Report types:**

| Report | Chart | Description |
|--------|-------|-------------|
| `cashflow` | bar + line | Monthly income vs expenses, cumulative net change |
| `networth` | line | Assets, liabilities, and net worth over time |
| `expenses` | stacked bar | Monthly expense breakdown by category |
| `expenses-pie` | doughnut | Expense share by category for the period |
| `assets-pie` | doughnut | Asset allocation snapshot |
| `income-pie` | doughnut | Income sources for the period |

**Period** is any hledger period expression: `thismonth`, `thisyear`, `lastyear`, `last3months`, `2025`, `2025-01..2025-06`, etc.

**`depth:N`** controls account depth for category breakdown (default `2`):

````markdown
```chart
expenses thisyear depth:3
```
````

**Header controls** — every chart block has:

- **▾ / ▸** — click title or toggle to collapse/expand
- **mo / yr / prev** — quick period switcher (reloads chart, no re-fetch on toggle)
- **◕ / ▦** — doughnut ↔ bar toggle (only on `*-pie` and `expenses`; redraws from cached data)
- **↺** — force reload from hledger

---

### t — Timeclock

````markdown
```t
today
```
````

Shows the clocked-in account, elapsed time, and a period report. The argument is a period expression (`today`, `thisweek`, `lastmonth`). The **⎋** button opens the full timeclock UI.

---

### cine — Film Production

Requires the **[NbWeb-cine](https://github.com/linuxcaffe/nbweb-cine)** plugin installed and a `.nb-cine.json` anchor file in the notebook. See the NbWeb-cine README for the full query reference.

````markdown
```cine
shots.strip | day: 1
```
````

#### Query syntax

```
field[.format] [: code, code, …] [| filter: value, …]
```

#### Key queries

| Query | Result |
|-------|--------|
| `shots` | Compact shot list — all shots, all days |
| `shots \| day: 1` | Shot list for shoot day 1 |
| `shots.strip` | Draggable stripboard — drag to resequence |
| `shots.strip \| day: 1` | Stripboard filtered to one day |
| `shots.sheet \| day: 1` | Call sheet cards — verbose, print-friendly |
| `scenes` | Scene index: all scenes, colour-coded by I/E · D/N |
| `storylines` | 2D story structure board — draggable cards across named lanes |
| `storylines.large` | Same board with full card detail (scenes, metadata) |
| `actor.phone: JD, AM` | Field lookup — phone numbers for listed actors |
| `location.address: LG` | Field lookup — address for location LG |

Filters stack: `shots.line | day: 1, actor: JD`

---

The **+** button on a `storylines` block adds a story card inline — type a title, press Enter. The **▦/▤** toggle switches between small and large card views; preference is saved per notebook.

---

### nav — Folder Navigator

````markdown
```nav
accts:guide/
```
````

Renders a stateful folder navigator in the preview pane. Clicking folders drills in; clicking notes opens them. The breadcrumb header is fully clickable — navigate back up to any level or to the notebooks root.

**Query formats:**

| Format | Example | Navigates to |
|--------|---------|-------------|
| nb selector | `accts:guide/` | Notebook folder |
| Filesystem path | `~/.nb/accts/guide` | Same, via path |
| Hidden dir path | `~/.nb/.test` | Raw filesystem listing |

The hidden-dir form (`~/.nb/.*`) uses a raw filesystem listing — useful for browsing `~/.nb/.test` (test scripts), `~/.nb/.templates`, etc. Files open in the preview pane; the selector is derived from the absolute path.

**Controls:**

- **▼ / ▶** (top-left) — collapse / expand; state persists in `localStorage` keyed by the starting path
- **↻** — refresh current location without resetting navigation
- Breadcrumb: `nb › notebook › folder` — each segment is clickable; current location is bold

**Default collapsed:** the hidden-dir (`~/.nb/.*`) variant defaults collapsed on first render.

---

### test — Embedded Assertions

Script-driven checks embedded directly in notes. Scripts live in `~/.nb/.test/` and are plain bash. See [[TEST_SCRIPTS]] for the full reference.

**Form 1 — on-demand (with label):**

````markdown
```test
recent-txn | Recent transactions
```
````

Renders a `▶ Recent transactions` button. Click to run the script; output replaces the button area. Resets after a passing run (no output + exit 0).

**Form 2 — automatic (no label):**

````markdown
```test
hledger-ok
```
````

Runs at render time. **If exit 0 and no output: the block vanishes completely** — invisible in the note. If there is output or a non-zero exit, the output renders as full markdown (wikilinks, `{{hledger:}}` inline queries, `term:` links all work).

A note can be peppered with Form 2 blocks; you'd never know they were there unless something needs attention.

**Script context vars** injected as environment variables:

| Variable | Value |
|---|---|
| `NB_DIR` | `~/.nb` |
| `NB_NOTE_SELECTOR` | Selector of the currently open note |
| `NB_NOTEBOOK` | Notebook portion of the selector |
| `NB_NOTE_PATH` | Absolute path to the note file |

---

## Broader Context

The NbWeb-codeblocks plugin is nb-web's implementation of the [mkd-codeblocks](https://github.com/linuxcaffe/mkd-codeblocks) project — a collection of independently distributable live-query widgets designed as self-contained drop-ins for any markdown note app. The `hledger` block is already released as a standalone package; the others are planned for extraction as the project matures.
