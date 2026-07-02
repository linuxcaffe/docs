---
title: Cine — Fountain Screenwriting Adoption
type: dev
tags: cine, fountain, screenwriting, planned
status: wip
---

# Cine — Fountain Screenwriting Adoption

Plan for replacing the home-grown `_parseScriptBody` with full Fountain spec compliance.
Goal: super easy authoring input, industry-standard PDF output.

## Current state (as of 2026-07-01)

`_parseScriptBody` in `nbweb-cine.js` is a ~40-line hand-rolled parser covering ~40% of Fountain:
- ✅ Character (indent ≥ 3 + all-caps regex — non-standard, should be any all-caps line)
- ✅ Parenthetical (`(...)` after character)
- ✅ Action (default fallback)
- ✅ Dialogue (line after character)
- ✅ `[[shot-id]]` superscripts (these are Fountain *notes* — excluded from final PDF, semantically correct)
- ❌ Transitions (`SMASH CUT TO:`, `> right-align >`)
- ❌ Centered text (`> CENTER THIS <`)
- ❌ Dual dialogue (`CHARACTER ^`)
- ❌ Lyrics (`~`)
- ❌ Sections (`#`, `##`, `###`)
- ❌ Synopses (`=`)
- ❌ Forced elements (`.`, `@`, `!`)
- ❌ Boneyard (`/* */`)
- ❌ Title page

CSS already has `.nb-cine-screenplay` with Courier Prime, Hollywood margins. Slug line is
synthesized from `int_ext:`, `loc:`, `day_night:` FM fields — this is intentional and should stay.

**Branch for this work:** `feature/fountain` off `master` in `~/dev/nbweb-cine/`.

---

## The Fountain spec

Standard by John August & Stu Maschwitz. Canonical reference: **fountain.io**. Stable — no versioning drama.

| Element | Syntax | Notes |
|---------|--------|-------|
| Scene heading | `INT. COFFEE SHOP - DAY` | auto-detected; `.forced` to override |
| Action | default paragraph | |
| Character | `ALL CAPS` on own line | `@forced lower` possible |
| Dialogue | line(s) after character | |
| Parenthetical | `(quietly)` between char and dialogue | |
| Transition | `SMASH CUT TO:` (all-caps + colon) or `> text >` | |
| Dual dialogue | `CHARACTER ^` | side-by-side columns |
| Centered | `> CENTER THIS <` | |
| Lyrics | `~I'm singin' in the rain` | |
| Notes | `[[draft note]]` | draft-mode only; **shot cues already use this** |
| Boneyard | `/* excluded entirely */` | never printed |
| Section | `# Act One` `## Sequence` `### Beat` | outline structure |
| Synopsis | `= one-line beat note` | draft only |
| Title page | `Title:\nAuthor:` before first blank line | |
| Page break | `===` | |
| Emphasis | `*italic*` `**bold**` `_underline_` | |

### `[[filename]]` shot cues — triple semantic convergence (intentional, not coincidental)

`[[filename-stem]]` in a scene body is simultaneously:
1. **Fountain note** — draft-only, excluded from final PDF. Shot cues are production
   annotations, not creative script — exactly what Fountain notes are for.
2. **nb wikilink** — resolved by main.js `_enrichRendered`, links to the shot note file.
3. **Screenplay superscript** — rendered inline as a small cue marker; displays the shot's
   `alias:` value via `data-autolabel` (not the filename).

**Three-identifier model — every production note:**

| Identifier | Field | Meaning | Mutable? |
|-----------|-------|---------|---------|
| filename stem | file on disk | stable wikilink anchor | never |
| `alias:` | FM field | compact stripboard code | yes |
| `title:` | FM field | human description | yes |

Shot: `shot:` FM = filename stem (e.g. `SP-peek`), `alias:` = stripboard code (e.g. `5d`).
Character: `alias:` = actor filename stem (the casting link — change it to recast).
Actor: `alias:` = callsheet code. One actor, multiple roles = two character cards, same `alias:`.

**Ctrl+[ workflow (already implemented):**
- In scene edit mode, Ctrl+[ opens the Insert Shot dialog
- Dialog auto-suggests next alias; writer sets filename and title
- Inserts `[[filename]]` at cursor; displays as alias via `data-autolabel` on render
- On PDF export: `[[filename]]` is a Fountain note → excluded from final script

This means shot cue syntax requires zero special markup beyond what Fountain already defines.

---

## Ecosystem / resources

### Parsers (pick one for the renderer)
- **fountain-js** (npm) — browser-side tokenizer → structured JSON tokens. Drop-in replacement
  for `_parseScriptBody`. Mature, handles full spec.
- **afterwriting** (github: ifrost/afterwriting-labs) — Node.js CLI. Fountain → PDF / HTML / FDX.
  Use server-side for export, not rendering.

### Editor UX references
- **Better Fountain** (VS Code extension) — syntax highlighting, live preview, outline panel.
  Best reference for what a Fountain editor should feel like.
- **Highland 2** (quoteunquoteapps.com/highland-2) — John August's app. Cleanest authoring UX.
- **Slugline** — another clean Fountain-native Mac app.

### Output / delivery
- **Courier Prime** — free open-source Courier replacement designed for screenplays (John August /
  Quote-Unquote Apps). Already referenced in `.nb-cine-screenplay` CSS — confirm it loads.
- **afterwriting PDF** — wraps wkhtmltopdf; produces Courier 12pt, WGA-standard margins.
  `afterwriting --source file.fountain --pdf output.pdf`
- **Final Draft FDX** — afterwriting also exports `.fdx`; studios and ADs often require it.

---

## Key design decisions (settled)

**Slug from FM, not from Fountain body.**
`int_ext:`, `loc:`, `day_night:` frontmatter stays as source of truth. Scenes remain queryable,
filterable, schedulable. Slug is synthesized at render and export time. Scene bodies contain
everything *after* the slug line — action, dialogue, etc.

**Replace `_parseScriptBody` with fountain-js.**
40 lines of approximation → full spec. fountain-js tokens map cleanly to existing chunk types
plus all the missing ones. The function signature stays the same; only the implementation changes.

**Editor enhancement is a later phase.**
The textarea works for authoring today. CodeMirror + fountain-mode is the "super easy input"
end state — live highlighting, auto-indent dialogue, auto-cap after character line. Design output
first, then make input delightful.

---

## Build order

| Step | Work | Status |
|------|------|--------|
| 0 | This doc | ✅ 2026-07-01 |
| 0.5 | `feature/fountain` branch off master | ✅ 2026-07-01 |
| 1 | Full Fountain tokeniser + renderer inline in `nbweb-cine.js` | ✅ 2026-07-01 |
| 1.5 | Shot-cue links: `[[filename]]` + `data-autolabel`; fix badly-formed alias links in scene files | ✅ 2026-07-02 |
| 1.6 | Shot template: `shot:` = filename stem, `alias:` = stripboard code; `filename` var in JS | ✅ 2026-07-02 |
| 2 | Courier Prime `@font-face` + Flask route; WGA margin/spacing CSS pass | ✅ 2026-07-02 |
| 2.5 | `type: script` specialty header — title page, scene count, export stubs, markdown toggle | ✅ 2026-07-02 |
| 3 | `/api/cine/export-fountain` — scenes in alias order → `.fountain` download; `⬇ .fountain` button wired | ✅ 2026-07-02 |
| 4 | afterwriting PDF — `/api/cine/export-pdf`, `_build_fountain` helper, wire `⬇ PDF` button | ✅ 2026-07-02 |
| 4.5 | Print CSS — `break-inside: avoid` on speech blocks; `break-before: page` on `===` breaks | deferred |
| 5 | CodeMirror + fountain-mode editor (later sprint) | feature/fountain-editor |

### `type: script` note — FM fields

| Field | Purpose |
|-------|---------|
| `type: script` | triggers title-page renderer |
| `title:` | film title — shown large on header |
| `author:` | writer credit |
| `copyright:` | year |
| `draft:` | e.g. "First Draft", "Revised Draft" |
| `wga_reg:` | (future) WGA registration number |
| `contact:` | (future) writer/agent contact for title page |

Body: `{{inline: Notebook:script/scene.md}}` blocks define scene order for assembled renderer.
Non-numeric `alias:` values (e.g. `ref`) are skipped in auto-concat and page estimates.

Steps 1–4 are a single feature sprint. Step 5 is the "super easy input" payoff.

### Pagination note

On-screen pagination (splitting into multiple page boxes) is not worth it — accurate line-height counting per element is fragile. Screen view scrolls; that's conventional (Highland 2, Slugline do the same). `afterwriting` handles true pagination for PDF export. Print CSS (step 4.5) adds `break-inside: avoid` on dialogue blocks so browser print/PDF doesn't orphan them.

### Courier Prime install

```bash
sudo apt-get install -y fonts-courier-prime
```

Served via `/fonts/courier-prime/<face>.otf` Flask route (app.py). Falls back to Courier New until installed.

---

*Created 2026-07-01. See also: `claude:project_nbweb_cine.md` memory, `~/dev/nbweb-cine/`.*
