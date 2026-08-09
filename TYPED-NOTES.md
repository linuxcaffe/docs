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
---
```

`source:` records which project this reports page belongs to. No `help:` key needed — `type: reports` alone gets the **?** button explaining the pair relationship automatically (see "Type Help Popovers" below).

---

## Project Notes

`type: project` gets one extra interactive element: the **+ Today** button in the header strip. Clicking it checks whether today's date heading (`## YYYY-MM-DD`) already exists in the note body — if not, it appends one before opening the editor. This keeps diary-style project logs organised without manual heading management.

The same behaviour is also available via `date_headers: true` frontmatter on any note type — see [[docs:foldable]].

---

## Type Help Popovers

Click the **?** at the far right of the preview toolbar to open a short, topic-specific popover — plain markdown, `xref:` for depth, live `note:` links. Dismiss by clicking **?** again or anywhere outside the popover.

**Two file-naming conventions, depending on whether a topic is tied to a real note type:**

```
~/.nb/.lib/help-type-project.md    ← type-specific: auto-loads for every type: project note
~/.nb/.lib/help-type-reports.md    ← type-specific: auto-loads for every type: reports note
~/.nb/.lib/help-nb.md              ← generic: not tied to any type:, still reachable as bare "nb"
~/.nb/.lib/help-help.md            ← generic: not tied to any type:, still reachable as bare "help"
```

**Type-targeted help happens automatically — no `help:` FM needed at all.** If a note's own `type:` value exactly matches a `help-type-<type>.md` file's `<type>`, every note of that type picks it up for free (checked live, only if the file actually exists — a type with no matching file contributes nothing, no wasted lookup). This is how `type: project`/`type: reports` notes get their help without a template author ever setting anything — the filename convention itself is the wiring. The match is against the literal `type:` value (`_FM_TYPES` in `app.py`), so it's plural-sensitive: name the file after the real FM value, not a display label.

**A topic that isn't a real note type** (a domain like `nb` — there's no `type: nb`) doesn't use the `help-type-` prefix — name it `help-<subject>.md` instead. A bare topic still finds it: bare-word lookup tries `help-type-<subject>.md` first, and falls back to `help-<subject>.md` if that doesn't exist — so `help: nb` keeps working as a plain word, no selector needed, regardless of which naming form the underlying file actually uses. Only auto-derivation (the type-matching above) is strict to the `help-type-` form specifically. (`help` itself *is* a real registered type as of 2026-08-09 — `help-type-help.md` is self-describing: a `type: help` note auto-derives its own help from itself.)

**Every `.lib/help-*.md` file carries `type: help`** — registered in `_FM_TYPES` (with a ❓ indicator) specifically so these are queryable, not just individually fetchable. `.lib` is exempted from the usual "dotfolders aren't real notebooks" rule for `fm` queries only (`_run_front_query`) — every other dotfolder (`.users`, `.rules`, `.checks`, etc.) is still rejected. A `.lib` file that needs restricting encodes it in a `-<level>` filename suffix (`user-mgmt-admin.md`) rather than frontmatter `access:`, and that convention is enforced for `fm` queries the same way it already was for direct fetches — a query won't surface anything a direct link to the same file wouldn't:

```fm
.lib type:help
```

**`help:` — the manual, nearest-wins override.** Set it on a note's own frontmatter, or cascade it via `.{folder}.md` → `.{notebook}.md` → the global `.nb.md` (same walk-up chain as `access:`/`xref:`/`checks:` — a note's own value always wins, otherwise the nearest dotfile up the chain does). The value can be:
- a **bare topic** (`help: project`, or `help: nb`) → tries `.lib/help-type-<topic>.md` first, falls back to `.lib/help-<topic>.md`
- a **real note selector**, anything containing `:` (`help: Takeout:folder/file.md`) → fetched and rendered directly, no fallback (there's nothing to fall back to)
- a **list mixing either form** (`help: [hledger, nb, "Takeout:folder/file.md"]`) → each entry resolves and renders in order, concatenated with a divider; empty entries are skipped silently

The global config always has one (`help: nb`), so the override chain never bottoms out with no help at all — unless something closer in the chain explicitly squelches it with `help: ''`.

**`help_add:` — accumulate instead of override.** Same shape as `check_add:`/`cfg_attr_add:`: unions across `.nb.md` → `.{notebook}.md` → `.{foldername}.md` (every level contributes, none replace each other), layered on top of whatever `help:` resolves to rather than competing with it. Use `help_add:` when a whole notebook or folder should always show a shared topic *in addition to* whatever else resolves.

**Final resolution order**: auto type-derived entry → `help_add:` union → `help:`'s own nearest-wins value/list, deduplicated. A `type: project` note in a notebook with `help_add: onboarding` would show, in order: the project help, the onboarding topic, then whatever `help:` resolves to (the note's own, or the global default) — real targeted help from zero FM keys, with room to layer on more.
