---
title: notebook config
caption: ".<notebook>.md — per-notebook config vision: themes, UI, plugins, access, workflow"
toc: true
processed: true
---

# NOTEBOOK CONFIG

> Developer documentation for nb-web. See [[docs:DEVELOPERS.md]] for the full index.

The notebook config file is a small dotfile in each notebook's root:

```
~/.nb/home/.home.md
~/.nb/docs/.docs.md
~/.nb/preciousfinds.ca/.preciousfinds.ca.md
```

It's a standard nb-web Markdown file — YAML frontmatter, optional body. nb doesn't index it (dotfile). It's already tracked in the `~/.nb/` config repo so it travels with the notebook setup. The `_notebook_config(notebook)` function reads and parses it on every relevant request — no restart needed, changes take effect immediately.

**Already implemented:** `access:` (notebook-wide access floor) and `user:` on individual notes (inherits owner's level). The infrastructure is there. Everything below is what comes next.

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

**`theme:`** — a named style preset applied when this notebook is active. Could reference a CSS class on `<body>` or a mini override stylesheet. Ideas:
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
