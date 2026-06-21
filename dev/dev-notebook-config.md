---
title: notebook config
caption: "config hierarchy: .nb.md → .{notebook}.md → .{folder}.md — implemented + planned"
toc: true
processed: true
---

# NOTEBOOK CONFIG

> Developer documentation for nb-web. See [[docs:DEVELOPERS.md]] for the full index.

## What's implemented (2026-06-19) #implemented

A three-level config hierarchy is live. Files live inside the things they configure,
travel with the notebooks, are git-backed, and are editable in-app via Changes or Edit.

### Resolution chain

```
note frontmatter
  → .{folder}.md         folder config (inside the folder it configures)
    → .{notebook}.md     notebook manifest (inside the notebook root)
      → .nb.md           global config (~/.nb/.nb.md)
        → nb-settings.json   deployment/machine config (non-portable, stays local)
```

First match per key wins at each level. `_merge_configs(base, override)` does a
deep merge — child dicts win over parent dicts key-by-key.

### Backend functions (`app.py`)

| Function | What it does |
|----------|-------------|
| `_global_config()` | Reads `~/.nb/.nb.md` frontmatter |
| `_notebook_config(notebook)` | Reads `.{notebook}.md`, merges over global |
| `_folder_config(notebook, note_path)` | Walks from note up to notebook root, merges all folder configs over notebook config |
| `_merge_configs(base, override)` | Deep merge; override wins; recurse into nested dicts |
| `_load_constraints(note_path)` | Returns merged constraint dict for a note path |
| `_normalize_constraint(val)` | Converts rich dict or legacy string to JS widget string |

### File convention

Config files are **dotfiles named after what they configure**, living **inside** the
thing they configure:

```
~/.nb/.nb.md                                  ← global
~/.nb/Takeout/.Takeout.md                     ← notebook manifest
~/.nb/Takeout/shots/.shots.md                 ← folder config
~/.nb/Takeout/storylines/film-school/.film-school.md  ← subfolder config
```

Every config file MUST carry `config: <name>` in frontmatter — the identifier of what
it configures. This is the hook for admin tooling (see Admin path below).

### Naming convention — the stub #pattern

The **stub** (the base name, e.g. `shots`) stays the same across three related files:

| File | Role | Example |
|------|------|---------|
| `shots/` | the directory itself | folder |
| `.shots.md` | config dotfile (`type: dotfile`) | machine-read; not indexed by nb, but wikilinks resolve — see [[dev-wikilinks]] |
| `shots.md` | dashboard note | human-read; pinned via `pinned: shots.md` in config |

This scales uniformly across all four config levels:

| Level | Config file | Dashboard | Stub |
|-------|-------------|-----------|------|
| Global | `~/.nb/.nb.md` | — | `nb` |
| Notebook | `~/.nb/accts/.accts.md` | `accts.md` | `accts` |
| Folder | `~/.nb/accts/reports/.reports.md` | `reports.md` | `reports` |
| Subfolder | `~/.nb/accts/reports/2026/.2026.md` | `2026.md` | `2026` |

**Why it matters:**
- Template placeholders (`{{title}}`, `{{folder}}`) resolve to the stub in all creation paths
- `pinned: {{title}}.md` in the template defaults the config to pin the matching dashboard note
- `config tree` uses the stub to identify config files in the tree walk
- `front config:` finds all config files regardless of level

**`type: dotfile`** — all config files carry `type: dotfile` in frontmatter. The backend registers it as an FM type (indicator `⚙`) so config files are visually distinct in any list that shows them.

### What goes where

| Field | Level | Notes |
|-------|-------|-------|
| `config:` | all levels | Required; names what this file configures |
| `codeblock_access:` | `.nb.md` | Global security policy; merged into `/api/nb-settings` response |
| `access:` | all levels | Access floor; inherits up the chain; `access: username` for person-specific |
| `access_badge:` | all levels | `true` → show resolved access level in cmd-output-bar (diagnostic) |
| `checks:` | all levels | Prefix(es) of `.checks/` scripts to auto-inject as Type-1 fences at render time |
| `pinned:` | folder, notebook | Filename stem always sorted to top of list |
| `tag_color:` | folder, notebook | Map tag names to hex colours (values must be quoted) |
| `prepend_date:` | folder, notebook | `false` to suppress YYYYMMDD prefix on new note filenames |
| `default_type:` | folder | Type for new notes in this folder |
| `sort:` | folder, notebook | Default sort for list panel |
| `plugins:` | notebook | Active plugins for this notebook |
| `cine:` / `hledger:` | notebook | Plugin config blocks (absorb `.nb-cine.json` etc.) |
| `types:` | notebook | Renderer + access per type |
| `constraints:` | folder | Field validation schema (see below) |

`nb-settings.json` keeps: server port, git remote URL, plugin file paths, PTY
settings — anything machine-specific that should NOT travel with notebooks.

### Folder configs and constraints

Each folder's `.{folder}.md` carries a `constraints:` block that defines the
frontmatter schema for its `default_type` notes. Constraint types:

```yaml
constraints:
  alias:
    required: true
    pattern: '^\d+[a-z]+$'     # regex on string value
    note: human explanation     # not enforced, for docs
  day_night:
    required: true
    type: enum
    values: [D, N]
  desc:
    required: false
    type: multiline             # → 'area' widget
  scene:
    required: true
    type: integer
```

Supported `type:` values: `string`, `integer`, `enum` (+ `values:`), `multiline`,
`boolean`. `pattern:` for regex on strings.

**Constraints apply to `default_type` notes only** — other types in the same folder
are skipped by the validator.

**Dot-notation inheritance** — a constraint value of `scene.loc` means "this field
is inherited from the note referenced by the `scene` field, field `loc`". The
Changes panel renders inherited fields as read-only displays, not editable inputs.
`nb-constraints.sh` (not yet written) must resolve these cross-note references
before validating.

```yaml
constraints:
  loc:       scene.loc        # read-only in Changes; sourced from referenced scene
  day_night: scene.day_night
```

**Legacy `.constraints.md`** — still read for backward compat. `_load_constraints()`
merges it as the lower-priority layer; folder config `constraints:` wins.
`_normalize_constraint()` converts both formats to the JS widget string the Changes
button expects (`select a,b,c`, `bool`, `area`, `date`, `text`).

### Notebook manifests absorbing plugin JSON

`.{notebook}.md` now supersedes the old separate JSON plugin config files. Fallback
chain (JSON wins until migrated):

```python
# hledger — in _hledger_config_for_notebook()
if '.nb-hledger.json' exists: use it
else: read hledger: block from _notebook_config()

# cine — in api_cine_data()
if '.nb-cine.json' exists: use it
else: read cine: block from _notebook_config()
```

New notebooks should put plugin config in the manifest. Existing notebooks keep
working until JSON files are removed.

**The list builder is a third consumer.** #gotcha The `/api/notebooks` list
endpoint (app.py ~line 6433) builds the per-notebook `cine:` and `hledger:`
fields that the JS plugin `detect` functions read. It has its own inline loading
code — separate from `_hledger_config_for_notebook()` and `api_cine_data()`.
When the JSON files were deleted without updating the list builder, `nb.cine`
came back `null` and the entire cine plugin deactivated (storylines, shots,
stripboard all gone).

Rule: before retiring a legacy JSON config file, grep every reference to it in
`app.py`. All three consumers must be updated atomically:

| Consumer | Location | Fallback added? |
|----------|----------|----------------|
| `_hledger_config_for_notebook()` | app.py | ✓ |
| `api_cine_data()` | app.py | ✓ |
| `/api/notebooks` list builder | app.py ~line 6433 | ✓ (2026-06-21) |

### Admin path — `front` finds all config files

`/api/front-query` now scans dotfiles (including NB_DIR root for `.nb.md`).
Combined with the `config:` field convention, an admin dashboard note can list
every config file across all notebooks:

````
```front
read: admin
config: | Config files
```
````

Each result is clickable → opens in preview → **Changes** (guided, constraint-driven)
or **Edit** (raw YAML, access-gated). This is the intended settings UI — no dedicated
panel needed.

To scope to one notebook: `Takeout: config: | Takeout configs`

---

## Vision — what this file could become

```
~/.nb/home/.home.md
~/.nb/docs/.docs.md
~/.nb/preciousfinds.ca/.preciousfinds.ca.md
```

It's a standard nb-web Markdown file — YAML frontmatter, optional body. nb doesn't index it (dotfile). It's already tracked in the `~/.nb/` config repo so it travels with the notebook setup. The `_notebook_config(notebook)` function reads and parses it on every relevant request — no restart needed, changes take effect immediately.

**Already implemented:** `access:` (notebook-wide access floor) and `user:` on individual notes (inherits owner's level). The infrastructure is there. Everything below is what comes next. #planned

---

## What this file could become

This is the place for everything that's *per-notebook but not per-note* — settings that would be too broad in note frontmatter and too specific to live in the global `nb-settings.json`. And because it's version-controlled in the config repo, it travels: clone your nb config, get all your notebook customisations for free.

---

## Visual identity — themes, icons, colour

Every notebook has its own personality. Why should they all look the same?

```yaml
---
icon: 📽
color: "#8b5cf6"
theme: warm
description: "Feature film shot list and production notes"
---
```

**`icon:`** — replaces the generic 📒 in the notebook selector, breadcrumb, and detail panel. Pick any emoji or short glyph. The `home` notebook could be 🏠, `accts` could be 💰, `preciousfinds.ca` could be ✨.

**`color:`** — accent hex applied to the notebook header, breadcrumb active state, and list selected-item highlight. Each notebook gets a distinct visual lane. Navigate between `docs` (blue) and `work` (amber) and *know* where you are without reading the breadcrumb.

**`theme:`** — a named style preset applied when this notebook is active. Could reference a CSS class on `<body>` or a mini override stylesheet. #decision CSS class on body is lightest — single stylesheet with `.theme-warm`, `.theme-code` etc.; no dynamic load needed. Ideas:
- `warm` — parchment tones, serif preview font (great for fiction, journals)
- `code` — high-contrast, wide monospace preview, dense list
- `shop` — image-forward, grid default, price badges
- `minimal` — zero chrome, full-bleed preview, no sidebar decoration
- `dark-hi` — extra high contrast dark, for accessibility

The theme only activates while this notebook is in scope. Switch notebooks, switch feel.

**`description:`** — one-liner shown in the detail panel and (optionally) as a tooltip on the selector icon. "Lena's vintage finds — inventory and pricing" beats a bare filename every time.

---

## List defaults

Stop fighting the list every time you open a notebook. Lock in what makes sense for *this* notebook's content:

```yaml
---
default_sort: newest
default_type: todo
default_view: calendar
default_folder: inbox
---
```

**`default_sort:`** — `newest`, `oldest`, `az`, `za`, `active-first`. A todo notebook should open newest-first. A contacts notebook wants `az`. A journal wants `oldest`.

**`default_type:`** — open filtered to `todo`, `note`, `bookmark`, `contact`, `image`, `folder`, or `all`. A task notebook that opens showing all notes including old closed todos is a mess. `default_type: todo` fixes it permanently.

**`default_view:`** — `list` (current default), `calendar` (for notebooks with dated entries or scheduled todos), `grid` (for image-heavy notebooks like `.images`). Imagine the `preciousfinds.ca` notebook opening to a grid of item images automatically.

**`default_folder:`** — drop straight into `inbox/` or `2026/` without clicking through every time.

These override the global defaults from `nb-settings.json` and the current per-notebook prefs (which are stored globally anyway and don't travel). Config-file defaults *do* travel.

---

## Add-note behaviour

```yaml
---
default_template: shop-item
auto_tags: [work, billable]
required_tags: true
add_types: [todo, note]
---
```

**`default_template:`** — skip the template picker entirely. Open "Add note" in the `preciousfinds.ca` notebook and it pre-selects `shop-item` template. Open it in `journal` and it pre-selects `daily-entry`. Zero friction.

**`auto_tags:`** — tags automatically prepended to every new note in this notebook. A `work` notebook auto-tags everything `#work`. A `billable` notebook auto-tags `#billable`. You can always remove them, but you never have to remember to add them.

**`required_tags:`** — warn (or block) save if the note has no tags. Great for notebooks where tags drive workflow (todos filtered by tag, contacts grouped by tag).

**`add_types:`** — restrict the type picker in the Add form to a subset. A pure todo notebook doesn't need Bookmark or Contact options cluttering the UI.

---

## UI suppression — reference and archive notebooks

Some notebooks are reference-only, archives, or shared read views. They shouldn't invite edits:

```yaml
---
hide_add: true
hide_edit: true
hide_delete: true
readonly_label: "Published — edit via preciousfinds.ca notebook"
---
```

**`hide_add:`** / **`hide_edit:`** / **`hide_delete:`** — remove the respective controls entirely for this notebook. No 🔒 lock needed — just convention enforced by the UI.

**`readonly_label:`** — replaces the edit/add controls with an explanatory string. "Archive — notes here are snapshots." Friendly, not cryptic.

This is different from the `.nb-lock` file (which is enforced server-side and blocks writes). Config-file suppression is a UI layer — softer, faster to toggle, no server-side enforcement. Both can coexist.

---

## Plugin configuration — per-notebook

This is the big one. Right now plugins read global settings from `nb-settings.json`. But a `contacts` notebook and a `clients` notebook might want very different contact display options. The config file makes per-notebook plugin config possible with zero new infrastructure — plugins just read their own keys from `_notebook_config()`.

```yaml
---
plugin_hledger:
  ledger_file: accts.ledger
  currency: CAD
  fiscal_year_start: "04-01"

plugin_cine:
  production: "Short Film 2026"
  fps: 24
  format: "2.39:1"

plugin_contacts:
  display_fields: [name, role, email, phone]
  group_by: role
---
```

Pattern in each plugin: read `notebook_config.get('plugin_hledger', {})` and merge with global defaults. Notebook wins, global is the fallback.

This means a `hledger` notebook can know which ledger file it maps to, a `cine` notebook carries its production metadata, and contacts can be displayed differently for `friends` vs `clients` — all without any UI. Just frontmatter.

---

## Cross-notebook wikilinks

```yaml
---
wikilink_scope: preciousfinds.ca
---
```

Resolve `[[Item Name]]` wikilinks against a specific notebook rather than the current one. For notebooks that heavily reference another — shop annotations referencing item notes, a film notebook referencing a contacts notebook — this saves typing the notebook prefix on every link.

---

## Publishing and nb-website integration

```yaml
---
publish: true
public_url: https://preciousfinds.ca
quartz_theme: preciousfinds
quartz_config:
  dateField: updated
  showToc: false
---
```

**`publish:`** — flag this notebook as a published nb-website source. nb-web could show a "View published" link in the detail panel, a publish-status badge, or a "Push to publish" action.

**`public_url:`** — where it lives when published. Shown in the detail panel as a live link.

**`quartz_config:`** — per-notebook Quartz overrides, merged with the global quartz config at build time. No more editing the global config when only one notebook needs a different date field.

---

## Workflow — archiving, pinning, and automation

```yaml
---
auto_archive_days: 90
pin: [42, home:17]
pre_add_command: "~/.local/bin/nb-inbox-check"
---
```

**`auto_archive_days:`** — nb-web badges notes older than N days without activity. Could also support actual archiving (moving to an `archive/` folder). Great for inbox-style notebooks that should stay lean.

**`pin:`** — note selectors always shown at the top of the list, above sort order. The README, the index note, the active project — always there.

**`pre_add_command:`** — run a script before the Add form opens. Could check inbox state, pre-populate a field from an external source, or validate something. Optional, runs async, failure is non-blocking.

---

## The resolution stack (access control + config)

With all of this, `_effective_access()` already has the right shape. The config file grows into a full notebook personality:

```
user: frontmatter          → ownership (already implemented)
note access: frontmatter   → explicit access override (already implemented)
.<notebook>.md access:     → notebook-wide floor (already implemented)
.<notebook>.md everything else → theme, defaults, plugin config, UI flags
```

The body of the config file (below the frontmatter) could eventually be a human-readable description of the notebook — rendered in the detail panel, used as the notebook's "about" page.

---

## Implementation order (rough)

| Priority | Feature | Effort |
|----------|---------|--------|
| High | `icon:` + `description:` in selector + detail panel | Small |
| High | `color:` accent on breadcrumb/header | Small |
| High | Per-notebook plugin config (read keys in plugins) | Small per plugin |
| Medium | `default_sort/type/view/folder:` overriding prefs | Medium |
| Medium | `hide_add/edit/delete:` UI suppression | Small |
| Medium | `default_template:` for Add form | Small |
| Medium | `publish:` + `public_url:` in detail panel | Small |
| Medium | `theme:` CSS preset switching | Medium |
| Lower | `auto_tags:` on new notes | Medium |
| Lower | `pin:` always-top notes | Medium |
| Lower | `wikilink_scope:` cross-notebook default | Medium |
| Lower | `auto_archive_days:` badging | Larger |
| Lower | `quartz_config:` merge at build time | Larger |

Start with the visual stuff — it's immediately satisfying and purely additive. Plugin config falls out naturally as plugins are extended. Workflow automation is the long tail.

---

> The notebook config file is nb-web's answer to the question: *"what if every notebook knew what it was for?"*
