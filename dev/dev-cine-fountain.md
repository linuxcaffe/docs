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

### `[[shot-id]]` and Fountain notes — happy coincidence

Fountain's note syntax `[[ ]]` excludes content from final PDF (shown in draft mode only).
Shot cues are production annotations, not creative script — semantically identical behaviour.
Keep `[[1c]]` syntax as-is; it's Fountain-valid and does the right thing on export.

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

| Step | Work | Branch |
|------|------|--------|
| 0 | This doc | — |
| 0.5 | `feature/fountain` branch off master | done |
| 1 | Swap `_parseScriptBody` → fountain-js; full spec rendering in-browser | feature/fountain |
| 2 | Courier Prime confirmed loading; margin/CSS pass | feature/fountain |
| 3 | `/api/cine/export-fountain` — concatenate scenes in alias order → `.fountain` download | feature/fountain |
| 4 | afterwriting PDF — Flask route, `npm install afterwriting`, download button | feature/fountain |
| 5 | CodeMirror + fountain-mode editor (later sprint) | feature/fountain-editor |

Steps 1–4 are a single feature sprint. Step 5 is the "super easy input" payoff.

---

*Created 2026-07-01. See also: `claude:project_nbweb_cine.md` memory, `~/dev/nbweb-cine/`.*
