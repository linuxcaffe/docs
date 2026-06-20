---
title: CODEBLOCKS
caption: Live interactive widgets rendered from fenced code blocks in notes
toc: true
processed: true
---

# Codeblocks

[[#Block Types|Block Types]] · [[#Block Controls|Block Controls]] · [[#Access Gates|Access Gates]] · [[#tw — Taskwarrior|tw]] · [[#nb — nb Panel|nb]] · [[#git — Git Log|git]] · [[#hledger — Accounting|hledger]] · [[#chart — Financial Charts|chart]] · [[#nav — Folder Navigator|nav]] · [[#gallery — Image Gallery|gallery]] · [[#front — Frontmatter Filter|front]] · [[#test — Embedded Assertions|test]] · [[#t — Timeclock|t]] · [[#cine — Film Production|cine]]

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

## FM-mode — Blocks Declared in Frontmatter

Any codeblock type can be promoted out of the note body into the **toolbar strip** (between the TOC bar and body) by declaring it in frontmatter. The FM field name is the codeblock language tag; the value is the query — identical to what you'd write inside the fence.

```yaml
---
front: type:item
---
```

is equivalent to writing ` ```front\ntype:item\n``` ` in the body, except the block appears in `#nb-fm-blocks` (above the body, collapsed by default) rather than floating in the text.

**Multiple blocks** — each key that matches a registered codeblock lang gets its own slot:

```yaml
---
front: type:shot loc:LG
tw:    project:film status:pending
---
```

**Boolean shorthand** — `true` means an empty query (block with no filter):

```yaml
---
front: true
---
```

**Collapse state** — FM-mode blocks start collapsed. State is then persisted per-block in `localStorage` the same as body blocks.

**The model** — the same promotion pattern as `toc: true`, which moved the Table of Contents from a body block into the persistent toolbar strip.

---

## Block Controls

Every block header carries the same universal controls:

| Control | Action |
|---------|--------|
| **▼/▶** | Collapse / expand the block body. State is persisted in `localStorage` keyed on block type + query, so collapsed blocks stay collapsed across reloads and note switches. |
| **↻** | Refresh — re-fetch data on demand |
| **+** | Open inline add form (where supported: `tw`, `hledger`). Hidden when the current user is below the configured write level for that block type; also hidden when the note has `lock: yes` frontmatter. |
| **⎋** | Launch external app (where supported: `t`) |

---

## Access Gates

Block types fall into two categories: those with a **codeblock-level gate** (the tool itself requires a minimum level), and those gated **by destination** (the tool is neutral; the target notebook or dotfolder determines access).

**Codeblock-level gate** — if you're below the required level, the block silently doesn't exist. No placeholder, no error, no lock icon. A `test` block with an explicit label is the one exception: the button still appears, and clicking it tells you what level you need.

**Destination gate** — `nav` and `nb` have no level of their own. They show what the target allows. A nav block pointing at a dotfolder the user can't access vanishes silently — the same disappearing magic as everything else.

**Write gate** — the `+` (add) and `✎` (edit) buttons are simply absent from the header. The block still shows your data; you just can't write to it.

### Per-block override

Add `read:` and `write:` lines anywhere in the fence body to override the defaults for that specific block:

````markdown
```hledger
read: office
write: tech
bal expenses --monthly
```
````

These lines are stripped before the query runs — they never reach hledger. Any level string works: `guest`, `user`, `office`, `admin`, `tech`. `write:` can be omitted to leave the write default unchanged.

### Default levels

| Block | Read gate | Write gate | Notes |
|-------|-----------|------------|-------|
| `hledger`, `chart` | `office` | `admin` | `chart` has no write |
| `tw` | `user` | `user` | |
| `git`, `t`, `test`, `tui` | `user` | none | read-only |
| `front` | `admin` | none | system-wide metadata search |
| `nav`, `nb` | — | none | gated by destination, not tool |

**`nav`** respects the target's own access level: a dotfolder requires admin+; a regular notebook follows its `.<notebook>.md` config `access:` field. A 403 from the destination → silent removal, never an error banner.

**`front`** is admin-gated by default because it queries frontmatter across all notebooks — a broad view of the whole system that lower-level users shouldn't have by default.

See [[docs:dev/dev-security.md]] for the full access level scheme.

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

The hidden-dir form (`~/.nb/.*`) uses a raw filesystem listing — useful for browsing `~/.nb/.test` (check scripts), `~/.nb/.templates`, etc.

**Controls:** **▼/▶** collapse (persists in `localStorage` by starting path) · **↻** refresh · breadcrumb segments are clickable.

**Default collapsed** on first render for hidden-dir paths.

---

### gallery — Image Gallery

````markdown
```gallery
med
```
````

Renders a CSS grid of images from the nearest `images/` folder, found by walking up from the current note's location. Click any image to open a full-screen lightbox with keyboard navigation (← → Esc).

**Sizes** — the first word sets the cell width:

| Size | Cell width |
|------|-----------|
| `thumb` | 80 px |
| `small` | 140 px |
| `med` | 220 px |
| `large` | 320 px |

Grid columns auto-fill the available width at the chosen cell size.

**Path argument** — optional second word overrides the folder search:

````markdown
```gallery
med .
```

```gallery
large pfinds:items/photos/
```
````

| Path | Behaviour |
|------|-----------|
| *(absent)* | Walk up from note dir; use first `images/` found |
| `.` | Look only for `images/` in the current note's folder; vanish silently if absent |
| `notebook:path/` | Use that specific folder directly |

**FM-mode** — declare in frontmatter to surface the gallery in the toolbar strip above the body (collapses to a header bar, invisible when no images exist):

```yaml
gallery: med .
```

The `.` form is ideal for dashboard templates: the block is completely invisible until an `images/` folder appears next to the note — no empty placeholder, no error.

**Lightbox controls:** click any thumbnail to open · ← / → to navigate · Esc or click outside to close.

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

### config — Config Inheritance Tree

````markdown
```config
access: .
```
````

Visualises the configuration resolution chain from the global root (`~/.nb/.nb.md`) down to the current note's notebook and folder. Each level shows only what it **contributes** — inheritance is implied by indentation. Gated: `admin` read level.

**Syntax:**

| Form | Meaning |
|------|---------|
| `field: .` | Walk to current note's location; show `field` contributions |
| `field: Notebook:folder/` | Walk to a specific target |
| *(bare)* | Walk to current location; show all contributed keys |

**Output:**

```
● 🌐 ~/.nb/.nb.md                 codeblock_access, …
  ● 📒 Takeout/.Takeout.md        access, plugins, cine
    ● 📁 shots/.shots.md          default_type, sort, constraints
    ○ 📁 schedule/                (no config file)
```

`●` nodes are clickable — opens the config file in the preview pane for editing via **Changes** or **Edit**. `○` nodes have no config file yet.

When a `field` is specified, only nodes that actually set that field show a value beside them:

````markdown
```config
access: .
```
````

Useful for tracing where `access:`, `default_type:`, or any other setting is actually coming from. Admin-only — does not appear for lower access levels.

**Config file convention:** every config file must carry `config: <name>` in its frontmatter (the name of what it configures). This makes them queryable via `front`:

````markdown
```front
read: admin
config: | All config files
```
````

---

### test — Embedded Assertions

Script-driven checks embedded directly in notes. Scripts live in `~/.nb/.checks/` and run via the nb-web Flask server — no terminal needed. Browse the bundled scripts with a `nav` block:

````markdown
```nav
~/.nb/.test
```
````

**Form 1 — on-demand (with label):**

````markdown
```check
hl-recent-txn | Recent transactions
```
````

Renders a `▶ Recent transactions` button. Click to run; output replaces the button area.

**Form 2 — automatic (no label):**

````markdown
```check
hl-ok
```
````

Runs at render time. **Exit 0 + no output → block vanishes completely.** Output or non-zero exit → renders as full markdown. A note peppered with Form 2 blocks is invisible when everything is healthy.

**Form 3 — group (multiple scripts, one per line):**

````markdown
```check
hl-ok
tw-due
nb-dirty
```
````

All run in parallel. All pass → block vanishes. Any fail → `N of M checks failed` header with a collapsible toggle row per failure. Add a label to auto-run as a button instead:

````markdown
```check
hl-ok | Health checks
tw-due
nb-dirty
```
````

A bare `| Label` line sets the group label without labelling individual scripts:

````markdown
```check
| Dashboard checks
hl-ok
tw-due
```
````

---

#### Bundled scripts

| Script | Form | Purpose |
|--------|------|---------|
| `hl-test` | 2 | hledger binary self-test; silent when all 245 pass |
| `hl-ok` | 2 | Silent when journal is clean; shows `hledger check` errors |
| `hl-strict` | 2 | `hledger check --strict`; explains undeclared commodity errors |
| `hl-optional` | 2 | Radar sweep — all 5 optional checks; silent when all pass |
| `hl-ordereddates` | 2 | Transactions out of date order within a file |
| `hl-recentassertions` | 2 | Balance assertions older than 7 days |
| `hl-tags` | 2 | Undeclared tag names |
| `hl-payees` | 2 | Undeclared payees |
| `hl-uniqueleafnames` | 2 | Two accounts share a leaf name |
| `hl-budget-has-periodic` | 2 | Guides setup if no `~ monthly` rules found |
| `hl-budget-balanced` | 2 | Detects unbalanced budget transactions |
| `hl-budget-include-check` | 2 | Verifies periodic journal is included in main journal |
| `hl-budget-has-actuals` | 2 | Checks that actual transactions exist |
| `hl-budget-has-income` | 2 | Checks that income postings exist in the budget |
| `hl-budget-runs` | 2 | Verifies `hledger bal --budget` runs without error |
| `nb-dirty` | 2 | Silent when committed; lists dirty files in current notebook |
| `note-disk-warn` | 2 | Silent under 80% disk; warns above that |
| `note-slow` | 2 | Notice when file >50 KB or ≥5 inline includes |
| `tw-due` | 2 | Silent with no due tasks; lists overdue/today tasks |
| `note-approved` | 2 | Amber banner when `approved:` frontmatter is blank |
| `hl-recent-txn` | 1 | Last 14 days of transactions — on demand |
| `note-context` | 1 | Markdown table of all context variables — on demand |
| `hl-balances` | 1 | Depth-1 balance table — on demand |

**Form 4 — glob prefix (dangling dash):**

A script name ending in `-` expands to all matching scripts in `~/.nb/.checks/` at render time:

````markdown
```check
nb-schem-
```
````

Runs every `nb-schem-*.sh` script as a group. Add a new script to the family and it appears automatically — no codeblock edits needed. Works in single-line and multi-line forms:

````markdown
```check
| nb checks
nb-config-
nb-schem-
nb-ref-
```
````

---

**Script naming convention:**

Scripts use hyphen-separated names. The prefix is the application domain; sub-families add a second level separated by another hyphen. The dangling-dash glob runs an entire family.

| Prefix | App | Example families |
|--------|-----|-----------------|
| `hl-` | hledger | `hl-budget-`, `hl-health-` |
| `nb-` | nb / nb-web | `nb-config-`, `nb-schem-`, `nb-ref-` |
| `tw-` | Taskwarrior | — |
| `note-` | system/global | — |

---

#### Placement patterns

**Health dashboard** — Form 2 blocks at the top of a hub note. Invisible when healthy; surface on failure:

````markdown
```check
hl-ok
```
```check
nb-dirty
```
```check
tw-due
```

# My Hub Note
````

**On-demand reference** — Form 1 in a journal or guide:

````markdown
```check
hl-recent-txn | Recent transactions
```
```check
hl-balances | Account balances
```
````

**Invisible guardrail** — embed a check in a setup note. New users see the error; experienced users with everything configured see nothing.

---

#### Status panels

A dedicated `status.md` note containing only Form 2 blocks, included anywhere via `{{inline:}}`:

```markdown
{{inline: accts:status.md}}

# My Note
```

`status.md` has **zero visual footprint when everything is healthy** — the inline renders nothing. The moment any check fails, its output surfaces right at the top of whatever note you're reading. Because `{{inline:}}` runs the full render pipeline on the included content, test blocks in `status.md` receive the **host note's context** — `nb-dirty` reports on the right notebook automatically.

Different notebooks have different concerns:

```markdown
{{inline: accts:status.md}}     ← journal health, uncommitted changes
{{inline: home:status.md}}      ← disk space, overdue tasks
```

---

#### Books — the diagnostic TOC

When Form 2 blocks are embedded in chapter notes inside a `type: book`, failing checks produce `### ⚠ Heading` output that gets picked up by the book's TOC rebuild. The table of contents becomes simultaneously a chapter navigator and a live health dashboard — `⚠` entries appear inline with chapter headings, positioned exactly where the problem lives.

A healthy book shows a clean TOC. A book with problems shows `⚠` entries. No separate dashboard, no extra code — an emergent property of the test + inline + TOC pipeline.

See [[docs:BOOKS]] for the full pattern.

---

#### Self-censoring includes

`{{inline:}}` silently respects access levels — inaccessible content renders as nothing, leaving the note looking normal to lower-level users.

**Markdown notes** — any note with `access:` frontmatter self-censors when inlined:

```yaml
---
title: Q4 Payroll Summary
access: admin
---
```

```markdown
{{inline: accts:q4-payroll.md}}
```

Users below `admin` see an empty render. The note is not visible, not 403'd — just absent.

**`.lib/` components** — HTML and other non-markdown files declare their level in the filename suffix:

```markdown
{{inline: .lib:dashboard-user.html}}
{{inline: .lib:dashboard-office.html}}
{{inline: .lib:dashboard-admin.html}}
```

Each file renders for users at that level and above; others see nothing. Stack multiple inlines for additive tiers — guest through admin each see their appropriate layer accumulate.

See [[docs:dev/dev-security.md#ii-access-control]] and `.rules/access.md` for the full convention.

---

Developer internals and script authoring: [[docs:dev/dev-codeblocks.md]]
