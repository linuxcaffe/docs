---
title: TYPED NOTES
caption: Rich headers and actions on notes with a recognized type field
toc: true
processed: true
---

# Typed Notes

[[#Overview|Overview]] · [[#Setting a Type|Setting a Type]] · [[#Type Reference|Type Reference]] · [[#Dashboard and Dotfile Pairs|Dashboard and Dotfile Pairs]] · [[#Project and Report Pairs|Project and Report Pairs]] · [[#Project Notes|Project Notes]] · [[#Type Help Popovers|Type Help Popovers]]

---

Notes with a recognised `type:` frontmatter value get a **rich header strip** rendered above the note body — an icon, a label, and contextual pills drawn from other FM fields. The strip replaces the plain title display and makes the note's role immediately visible without reading the body.

This is provided by the **NbWeb-specialty** plugin, loaded globally for all notebooks.

---

## Setting a Type

Add `type:` to any note's frontmatter:

```yaml
---
title: Hansen House — Phase 1
type: project
status: active
client: Hansen Family
---
```

If the type is recognised, the specialty header renders automatically when the note is opened. Unknown types fall back to plain rendering.

---

## Type Reference

| Type | Icon | Header shows |
|------|------|-------------|
| `project` | 🏗️ | Status pill · client · **+ Today** date button |
| `report` | 📊 | Status pill · client |
| `invoice` | 🧾 | Invoice number · due date · status pill |
| `quote` | 📋 | Status pill · client |
| `budget` | 💰 | Status pill · client |
| `reports` | 📊 | Actions injected by accounting plugin (Quote · Invoice buttons) |
| `tools` | 🔧 | Label only |
| `materials` | 📦 | Label only |
| `transport` | 🚗 | Label only |
| `dashboard` | 🗂️ | File count · folder count · sync status · config link |
| `dotfile` | ⚙️ | Scope · parent name · field count · dashboard link |

**FM fields used by the header** — declare these in frontmatter to populate the pills:

| Field | Used by |
|-------|---------|
| `status:` | project, report, invoice, quote, budget |
| `client:` | project, report, quote, budget |
| `invoice_num:` | invoice |
| `due:` | invoice |
| `help:` | any — adds **?** button; see [[#Type Help Popovers]] |

---

## Dashboard and Dotfile Pairs

Every notebook and folder has a natural pair of notes:

| Note | Type | Role |
|------|------|------|
| `djp.md` | `dashboard` | Front of house — visible, pinned, shows live counts |
| `.djp.md` | `dotfile` | Back of house — hidden config, carries rules and access |

The **dashboard** header shows a live count of files and folders in the same scope, the current sync status (clickable to open the sync dialog), and a **[config]** link to its dotfile pair.

The **dotfile** header shows its config scope (global / notebook / folder), the parent name, a count of configured keys, and a **[dashboard]** link back to its front-of-house note.

nb-web derives the pair automatically from the filename: `djp.md` ↔ `.djp.md`. You don't wire them manually — the link is implicit in the `.` prefix convention.

See [[docs:FOLDER-CONFIG]] for how to create and edit config dotfiles.

---

## Project and Report Pairs

`type: project` and `type: report` are designed to work as a named pair:

| Note | Type | Role |
|------|------|------|
| `name.md` | `project` | Living document — accumulates freely, date-sectioned |
| `name-reports.md` | `reports` | Output page — holds one or more curated reports, hand-edited |

The project is the workspace; the reports page is what you show someone. Both get the specialty header, and each shows a navigation chip linking to the other. The naming convention (`-reports` suffix) is the only wiring required — no explicit link needed.

**Recommended frontmatter for the reports note:**
```yaml
---
type: reports
source: name.md
help: report
---
```

`source:` records which project this reports page belongs to. `help: report` adds a **?** button explaining the pair relationship — useful in templates to orient first-time users.

---

## Project Notes

`type: project` gets one extra interactive element: the **+ Today** button in the header strip. Clicking it checks whether today's date heading (`## YYYY-MM-DD`) already exists in the note body — if not, it appends one before opening the editor. This keeps diary-style project logs organised without manual heading management.

The same behaviour is also available via `date_headers: true` frontmatter on any note type — see [[docs:foldable]].

---

## Type Help Popovers

Any typed note can show a **?** button in its specialty header by adding a `help:` key to frontmatter:

```yaml
---
type: report
help: report
---
```

Clicking **?** opens a small popover fetched from `.lib/help-type-<topic>.md`. The content is plain markdown — prose, links, whatever is useful. Dismiss by clicking **?** again or anywhere outside the popover.

**Creating help content** — add a file to `~/.nb/.lib/`:

```
~/.nb/.lib/help-type-report.md     ← loaded when help: report
~/.nb/.lib/help-type-project.md    ← loaded when help: project
~/.nb/.lib/help-type-mytype.md     ← any topic name works
```

The help file is a full nb note — it can have `xref:` in its own frontmatter, and any `note:` links inside it are live and clickable in the popover. This means the help text stays concise while depth is a click away through xref.

**Typical use** — put `help: <type>` in a template's default frontmatter. Users see the **?** button when they first open a note of that type; they remove the `help:` key (or just ignore it) once they're oriented.

**Cascading** — `help:` also resolves through the same walk-up chain as `access:`/`xref:`/`checks:`: a note's own `help:` always wins, otherwise it falls through to `.{folder}.md` → `.{notebook}.md` → the global `.nb.md`. This means a whole folder or notebook can get a default help topic without setting `help:` on every note individually — and the global config always has one (`help: nb` → `.lib/help-type-nb.md`), so the cascade never bottoms out with no help at all. Note: the **?** button itself currently only renders in a note's specialty header (project/report/dashboard/dotfile types) — an ordinary note doesn't get a toolbar help button yet even though `help:` resolves for it.
