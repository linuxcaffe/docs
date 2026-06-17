---
title: frontmatter editor
caption: Changes button + front codeblock — guided frontmatter editing with .constraints.md
processed: true
toc: true
---

# Frontmatter Editor (dev)

Universal guided frontmatter editing — a toolbar button on every note card, plus an optional inline `front changes` codeblock. No raw YAML editing required. Body content is never touched.

---

## Architecture overview

Three components work together:

| Component | File | Role |
|-----------|------|------|
| `.constraints.md` | per-folder or notebook root | field → widget type mapping |
| `GET /api/note/constraints` | `app.py` | walks up, merges, returns JSON |
| Changes button + panel | `main.js` | toolbar button → form → save |
| `front changes` codeblock | `nbweb-codeblocks.js` | inline alternative, same helpers |
| `NbWeb.fmUtils` | `nbweb-codeblocks.js` | shared parseFields/patch/widget |

---

## .constraints.md

A dotfile (not indexed by nb) placed in a folder or notebook root. Standard YAML frontmatter — one line per field:

```yaml
---
category: select exec,creative,tech
dept:      select grip,camera,lighting,sound,makeup,wardrobe,sfx,transport,art
unit:      select day,hour,week,flat
lock:      bool
type:      select resource,character,cast,location,shot,scene,storyline,report
---
```

**Constraint string format:**

| Value | Widget rendered |
|-------|----------------|
| `select a,b,c` | `<select>` dropdown |
| `bool` | checkbox |
| `date` | `<input type=date>` |
| `area` | `<textarea>` |
| *(anything else or absent)* | `<input type=text>` |

**Scope and walk-up merge:**

```
~/.nb/Takeout/resources/.constraints.md   ← folder-scoped (wins)
~/.nb/Takeout/.constraints.md             ← notebook-wide (fallback)
```

Flask walks from the note's directory up to the notebook root, merging files (folder entries override notebook entries for the same key). Notes in folders without a `.constraints.md` get only the notebook-wide constraints.

---

## API endpoint

```
GET /api/note/constraints?selector=Takeout:shots/2
```

Returns a flat JSON object:

```json
{
  "type":     "select resource,character,cast,location,shot",
  "category": "select exec,creative,tech",
  "unit":     "select day,hour,week,flat",
  "lock":     "bool"
}
```

**Backend helper:** `_load_constraints(note_path: Path) → dict` in `app.py`. Called by `api_note_constraints()`. Processes root-first so deeper entries win.

---

## Changes toolbar button

Added to `#nb-preview-actions` in `index.html` — sits left of Edit in the grey toolbar bar, always visible regardless of note scroll depth.

**Visibility rules** (wired in `renderPreview` in `main.js`):
- Hidden if `note.meta` is empty (no frontmatter)
- Hidden if `note.locked` is true
- Resets panel state on every note navigation

**Flow:**

1. Click **Changes** → `_toggleFmChangesPanel(note, btn)`
2. Parallel fetch: `GET /api/note` (for `raw` content) + `GET /api/note/constraints`
3. `NbWeb.fmUtils.parseFields(raw)` extracts ordered field list (skips block scalars)
4. `NbWeb.fmUtils.widget(key, value, constraint)` builds each input
5. Panel opens as `#nb-changes-panel` — a static HTML div flush under the toolbar
6. **Save** → `NbWeb.fmUtils.patch(raw, updates)` → `PUT /api/note` → reload note
7. **Cancel** → panel hides, no write

---

## NbWeb.fmUtils

Exported from `nbweb-codeblocks.js` so `main.js` can reuse without duplication:

```javascript
NbWeb.fmUtils = {
    parseFields(raw),   // → [{key, value}] from frontmatter, block scalars excluded
    patch(raw, updates),// → new raw string, body preserved exactly
    widget(key, value, constraint), // → DOM input element with data-fm-key
}
```

**`parseFields`** — uses `indexOf('\n---', 3)` (not regex) to locate the FM boundary, so the body is never ambiguous. Skips lines whose value is `|` or `>` (block scalar headers).

**`patch`** — slices raw into `head` (opening `---` through FM content) and `tail` (`\n---` onward including body). Only patches `head`; concatenates `head + tail`. The body survives unchanged even if it contains `---` lines.

**`widget`** — returns a DOM element with `data-fm-key` set for Save to collect. Checkbox returns `String(checked)` (`'true'`/`'false'`).

---

## front changes codeblock (inline)

An alternative entry point — places the editor at a specific point in the note body, useful in long notes:

````markdown
```front
changes |Edit Resource
```
````

The `front` codeblock dispatches to `_loadFrontChanges(el)` when the body starts with `changes`. Uses the same `NbWeb.fmUtils` helpers. Renders a collapsed button that expands to the same form inline.

The toolbar Changes button covers the universal case; the codeblock is optional.

---

## CSS classes

| Class | Purpose |
|-------|---------|
| `#nb-changes-panel` | Static toolbar panel — flush under grey bar, `background: var(--bg2)` |
| `.nb-front-changes` | Codeblock wrapper |
| `.nb-front-changes-panel` | Inline codeblock panel |
| `.nb-front-changes-form` | Two-column grid (label + widget) |
| `.nb-front-changes-row` | `display: contents` — one field row |
| `.nb-front-changes-label` | Monospace field key |
| `.nb-front-changes-actions` | Save/Cancel button row |

---

## Adding constraints to a new notebook

1. Create `~/.nb/<notebook>/.constraints.md` with relevant fields
2. Optionally add folder-scoped `.constraints.md` for subfolder-specific dropdowns
3. No restart needed — constraints are fetched live per note

## Access control

Server rejects `PUT /api/note` if the session user lacks write access. The button is hidden for locked notes (`note.locked`). No other client-side gating — server is the authority.
