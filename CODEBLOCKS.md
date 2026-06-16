---
title: CODEBLOCKS
caption: Live interactive widgets rendered from fenced code blocks in notes
toc: true
processed: true
---

# Codeblocks

[[#Block Types|Block Types]] · [[#Block Controls|Block Controls]] · [[#tw — Taskwarrior|tw]] · [[#nb — nb Panel|nb]] · [[#git — Git Log|git]] · [[#hledger — Accounting|hledger]] · [[#chart — Financial Charts|chart]] · [[#nav — Folder Navigator|nav]] · [[#front — Frontmatter Filter|front]] · [[#test — Embedded Assertions|test]] · [[#t — Timeclock|t]] · [[#cine — Film Production|cine]]

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

The active notebook is highlighted in the `notebooks` view.

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

- **Account from query** — if the fence body contains an account name (e.g. `reg Assets:Bank`), the first account field in the form is pre-populated with it.
- **Date from filename** — if the currently open note is a daily note named `YYYYMMDD.md`, the date field is pre-filled from the filename instead of today's date.

**Bookkeeper panel**

The hledger panel (☰ → hledger) has a persistent **+ Add Transaction** section at the top that also applies both smart pre-fills above.

**Files tab**

The hledger panel's **Files** tab handles bulk import and export between daily notes and journal files:

- **Export** — scans `YYYYMMDD.md` daily notes for ` ```hledger ``` ` fenced blocks and writes their contents to a `.journal` file. Optionally filtered by date range.
- **Import** — parses an existing `.journal` file and appends each dated transaction block to the matching `YYYYMMDD.md` daily note (creating it if it doesn't exist), then commits.

**Static `ledger` blocks**

Use ` ```ledger ` (not ` ```hledger `) for example journal entries in tutorial or documentation notes. These render as static syntax-highlighted code via Prism — never executed against your real journal.

Requires `hledger` on `$PATH`. See also: [hledger-codeblock](https://github.com/linuxcaffe/hledger-codeblock) — this block is also released as a standalone package.

---

### chart — Financial Charts

````markdown
```chart
cashflow thisyear
```
````

Interactive Chart.js visualisations driven by hledger data. Requires the **NbWeb-hledger** plugin with a configured journal.

**Syntax:** `` ```chart\n<report> [period] [depth:N]\n``` ``

| Report | Chart | Description |
|--------|-------|-------------|
| `cashflow` | bar + line | Monthly income vs expenses, cumulative net change |
| `networth` | line | Assets, liabilities, and net worth over time |
| `expenses` | stacked bar | Monthly expense breakdown by category |
| `expenses-pie` | doughnut | Expense share by category for the period |
| `assets-pie` | doughnut | Asset allocation snapshot |
| `income-pie` | doughnut | Income sources for the period |

**Period** is any hledger period expression: `thismonth`, `thisyear`, `lastyear`, `last3months`, `2025`, `2025-01..2025-06`, etc.

**`depth:N`** controls account depth for category breakdown (default `2`).

**Header controls:**

| Control | Action |
|---------|--------|
| **▾ / ▸** | Collapse/expand |
| **mo / yr / prev** | Quick period switcher (reloads chart) |
| **◕ / ▦** | Doughnut ↔ bar toggle on `*-pie` and `expenses`; redraws from cached data |
| **↺** | Force reload from hledger |

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

Requires the **[NbWeb-cine](https://github.com/linuxcaffe/nbweb-cine)** plugin and a `.nb-cine.json` anchor file in the notebook.

````markdown
```cine
shots.strip | day: 1
```
````

**Syntax:** `field[.format] [: code, code, …] [| filter: value, …]`

| Query | Result |
|-------|--------|
| `shots` | Compact shot list — all shots, all days |
| `shots \| day: 1` | Shot list for shoot day 1 |
| `shots.strip` | Draggable stripboard — drag to resequence |
| `shots.strip \| day: 1` | Stripboard filtered to one day |
| `shots.sheet \| day: 1` | Call sheet cards — verbose, print-friendly |
| `scenes` | Scene index: all scenes, colour-coded by I/E · D/N |
| `storylines` | 2D story structure board — draggable cards across named lanes |
| `storylines.large` | Board with full card detail (scenes, metadata) |
| `actor.phone: JD, AM` | Field lookup — phone numbers for listed actors |
| `location.address: LG` | Field lookup — address for location LG |

Filters stack: `shots.sheet | day: 1, actor: JD`. See the [NbWeb-cine README](https://github.com/linuxcaffe/nbweb-cine) for the full query reference, frontmatter schemas, and storylines board documentation.

---

### nav — Folder Navigator

````markdown
```nav
accts:guide/
```
````

Renders a stateful folder navigator in the preview pane. Clicking folders drills in; clicking notes opens them. The breadcrumb header is fully clickable.

| Format | Example | Navigates to |
|--------|---------|-------------|
| nb selector | `accts:guide/` | Notebook folder |
| Filesystem path | `~/.nb/accts/guide` | Same, via path |
| Hidden dir path | `~/.nb/.test` | Raw filesystem listing |

The hidden-dir form (`~/.nb/.*`) uses a raw filesystem listing — useful for browsing `~/.nb/.test` (test scripts), `~/.nb/.templates`, etc.

**Controls:** **▼/▶** collapse (persists in `localStorage` by starting path) · **↻** refresh · breadcrumb segments are clickable.

**Default collapsed** on first render for hidden-dir paths.

---

### front — Frontmatter Filter

````markdown
```front
shot: | All shots
```
````

Renders a collapsible list of notes matching frontmatter field conditions. Results are clickable — opening the note in the preview pane. Hover any row to see all frontmatter fields in a tooltip.

**Scope prefix** — leading bare words (no colon) name notebooks to search. No prefix = all notebooks.

**Filter conditions** (AND logic):

| Syntax | Meaning |
|--------|---------|
| `field:value` | Field equals value (case-insensitive) |
| `field:` | Field exists (any value) |
| `field:""` | Field absent or empty |

**`\| Label`** — optional label shown in the header bar.

**Examples:**

````markdown
```front
shot: | All shots
```

```front
Takeout type:shot loc:LG | Lee Gardens shots
```

```front
model:true | Example notes
```
````

---

### test — Embedded Assertions

Script-driven checks embedded directly in notes. Scripts live in `~/.nb/.test/`. See [[docs:dev/dev-testing]] for how to write scripts; see [[docs:CODEBLOCKS#test — Bundled Scripts|TESTING]] for the bundled script reference.

**Form 1 — on-demand (with label):**

````markdown
```test
hl-recent-txn | Recent transactions
```
````

Renders a `▶ Recent transactions` button. Click to run; output replaces the button area.

**Form 2 — automatic (no label):**

````markdown
```test
hl-ok
```
````

Runs at render time. **Exit 0 + no output → block vanishes completely.** Output or non-zero exit → renders as full markdown. A note peppered with Form 2 blocks is invisible when everything is healthy.

**Form 3 — group (multiple scripts, one per line):**

````markdown
```test
hl-ok
tw-due
nb-dirty
```
````

All run in parallel. All pass → block vanishes. Any fail → `N of M checks failed` header with a **collapsible toggle row per failure**.

Add a label to the first line (Form 1 group) to render a button instead of auto-running:

````markdown
```test
hl-ok | Health checks
tw-due
nb-dirty
```
````

A bare `| Label` line sets the group label without labelling any individual script:

````markdown
```test
| Dashboard checks
hl-ok
tw-due
```
````

**Script naming convention:**

| Prefix | App |
|--------|-----|
| `hl-` | hledger |
| `nb-` | nb |
| `tw-` | Taskwarrior |
| `note-` | system/global |

---

Developer internals: [[docs:dev/dev-codeblocks]]
