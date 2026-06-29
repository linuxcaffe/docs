---
title: TYPED NOTES
caption: Rich headers and actions on notes with a recognized type field
toc: true
processed: true
---

# Typed Notes

[[#Overview|Overview]] · [[#Setting a Type|Setting a Type]] · [[#Type Reference|Type Reference]] · [[#Dashboard and Dotfile Pairs|Dashboard and Dotfile Pairs]] · [[#Project Notes|Project Notes]]

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
| `status:` | project, invoice, quote, budget |
| `client:` | project, quote, budget |
| `invoice_num:` | invoice |
| `due:` | invoice |

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

## Project Notes

`type: project` gets one extra interactive element: the **+ Today** button in the header strip. Clicking it checks whether today's date heading (`## YYYY-MM-DD`) already exists in the note body — if not, it appends one before opening the editor. This keeps diary-style project logs organised without manual heading management.

The same behaviour is also available via `date_headers: true` frontmatter on any note type — see [[docs:foldable]].
