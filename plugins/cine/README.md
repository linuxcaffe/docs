- Project: https://github.com/linuxcaffe/nbweb-cine
- Issues:  https://github.com/linuxcaffe/nbweb-cine/issues

# NbWeb-cine

From first idea to closing credits — a film production plugin for [nb-web](https://github.com/linuxcaffe/nb-web) that puts every tool a filmmaker needs into plain text files you own completely.

*📷 screenshot: full UI overview*

---

## TL;DR

- **Storylines board** — develop structure before writing a scene; drag story cards across plotline tracks
- **Fountain screenplay** — write in the open standard; render with proper margins, Courier Prime, and slug lines
- **One-click export** — download `.fountain` or a print-ready PDF directly from a cover note
- **Shot listing** — press `Ctrl+[` in any scene to create and link a shot note instantly
- **Draggable stripboard** — colour-coded by INT/EXT + DAY/NIGHT; every drag writes back to git
- **Live call sheets** — generated from the current schedule; no spreadsheets, no copy-paste
- **ATL/BTL budget** — hledger double-entry, recalculated on demand from current shot data
- Every note is a plain Markdown file in a git repository you control

---

## Why this exists

Traditional film production software — Movie Magic, StudioBinder, Celtx — locks your schedule, script, and call sheets inside proprietary formats and subscription paywalls. When the project wraps, the data is stranded. When the pricing changes, you're held hostage.

NbWeb-cine takes the opposite position: **your production data is just files**. A shot is a Markdown file. A scene is a Markdown file. Actor contacts, location notes, story cards — all plain text, readable in any editor, version-controlled by git, searchable from the command line. The production lives in a folder. You own it completely.

The plugin is a set of lenses on that folder. The same shot file that appears as a draggable strip on the stripboard appears as a verbose card on the call sheet and as an inline cue in the screenplay — the data never changes, only the view does. Renumber a scene by changing one field. Recast an actor by changing one field. Restructure your entire shooting order by dragging strips. The git history records every decision.

## What this means for you

This removes all barriers to beginning screenwriters and filmmakers, with access to all the tools needed to make a movie from start to finish.

---

## The workflow

```
Idea  →  Storylines  →  Screenplay  →  Shot List  →  Schedule  →  Budget  →  Credits
```

Each stage has its own folder in your notebook and its own doc in [`docs/`](docs/). This README walks the arc; follow the links for the full picture.

---

### 1. Storylines

Before writing a scene, develop what the story *is* on the **storylines board** — a 2D canvas of plotline tracks and draggable story cards. Write a card per beat; drag it between tracks to reshape act structure; switch to script-view to read the cards as a flowing prose treatment.

*📷 screenshot: storylines board*

→ **[docs/STORYLINES.md](docs/STORYLINES.md)** — board layout, story cards, named orders, treatment export

---

### 2. Screenplay

Write scenes in [Fountain](https://fountain.io) — the open plain-text format used by working screenwriters worldwide. NbWeb-cine renders scenes with proper Hollywood margins, Courier Prime font, and full Fountain spec: slug lines, action, dialogue, parentheticals, transitions, centered text, sections, and synopses.

A **cover note** (`type: script`) assembles all your scenes in order, shows a title page with scene count and estimated runtime, and exports with one click to `.fountain` or a print-ready PDF.

*📷 screenshot: screenplay view and title page*

Shot cues written as `[[filename]]` in scene bodies appear inline as superscript alias codes and link directly to the shot note. They are valid Fountain notes — excluded from the final PDF automatically.

→ **[docs/SCREENPLAY.md](docs/SCREENPLAY.md)** — Fountain syntax, `type: script`, export options, Courier Prime, paper size

---

### 3. Shot listing

Press **Ctrl+[** in any scene to open the Insert Shot dialog. NbWeb-cine suggests the next alias, pre-fills the location, and inserts `[[filename]]` at the cursor. The new shot file opens immediately for camera, lighting, and art department notes.

*📷 screenshot: Ctrl+[ dialog and shot card*

Every shot carries three independent identifiers: a stable **filename** (the wikilink anchor — never changes), a mutable **alias** (the stripboard code), and a **title** (human description). Renumber shots freely; the links in your script never break.

→ **[docs/SHOTLISTING.md](docs/SHOTLISTING.md)** — shot frontmatter, three-identifier model, codeblock queries, field lookups

---

### 4. Scheduling

The **stripboard** is a draggable, colour-coded grid — one strip per shot, grouped by shoot day. Drag a strip to a new position; the sequence is written back to frontmatter in a single git commit. Lock a shot to pin it in place. Move it to UNSCHEDULED to take it off the board without deleting it.

*📷 screenshot: stripboard*

Day notes set shoot hours per department, feeding directly into per-hour resource costing in the budget.

→ **[docs/SCHEDULING.md](docs/SCHEDULING.md)** — stripboard, day notes, lock, UNSCHEDULED zone, call sheet assembly

---

### 5. Budget

The live budget total sits at the top of the stripboard. When the schedule changes, hit **↻** to recompute — ATL cast costs, BTL location fees, equipment day rates, per-hour resources. All costs live in [hledger](https://hledger.org/) journals: plain text, git-tracked, queryable for any report.

*📷 screenshot: budget total and hledger output*

Cast rates flow through the CHARACTER → actor chain: change the actor on a character card and the budget updates. Cost data lives in annotation sidecars visible only to admin-level users — the same notebook serves the whole crew without exposing rates.

→ **[docs/BUDGET.md](docs/BUDGET.md)** — ATL/BTL costing, gen-budget.py, hledger integration, access levels

---

## Installation

### Option 1 — Clone and symlink

```bash
git clone https://github.com/linuxcaffe/nbweb-cine ~/dev/nbweb-cine
ln -s ~/dev/nbweb-cine/nbweb-cine.js ~/dev/nb-web/plugins/nbweb-cine.js
```

Then add to `nb-web/nb-settings.json`:

```json
{ "url": "/plugins/nbweb-cine.js", "enabled": true }
```

### Option 2 — nb-web plugin manager *(coming soon)*

```
nbweb:plugin?url=https://github.com/linuxcaffe/nbweb-cine
```

### Option 3 — Manual

Copy `nbweb-cine.js` into your nb-web `plugins/` directory and register it in `nb-settings.json` as above. No build step required.

**PDF export** requires [afterwriting](https://github.com/ifrost/afterwriting-labs):

```bash
cd ~/dev/nb-web && npm install afterwriting
```

**Courier Prime** font (recommended; falls back to Courier New):

```bash
sudo apt-get install fonts-courier-prime
```

The plugin activates automatically for any notebook that contains a `.nb-cine.json` project anchor file.

---

## Project status

Working and in active use. The full workflow — develop story → write script → list shots → schedule → budget → call sheets → export — is functional.

See individual docs for detailed feature status:
[STORYLINES](docs/STORYLINES.md) · [SCREENPLAY](docs/SCREENPLAY.md) · [SHOTLISTING](docs/SHOTLISTING.md) · [SCHEDULING](docs/SCHEDULING.md) · [BUDGET](docs/BUDGET.md)

---

## docs/

| Doc | Contents |
|-----|----------|
| [STORYLINES.md](docs/STORYLINES.md) | Story development board — lanes, cards, named orders |
| [SCREENPLAY.md](docs/SCREENPLAY.md) | Fountain pipeline — render, export `.fountain` + PDF |
| [SHOTLISTING.md](docs/SHOTLISTING.md) | Shot notes, codeblock queries, call sheets |
| [SCHEDULING.md](docs/SCHEDULING.md) | Stripboard, day notes, drag & resequence |
| [BUDGET.md](docs/BUDGET.md) | ATL/BTL costing, hledger integration |
| [CONFIGURATION.md](docs/CONFIGURATION.md) | Frontmatter field reference, `.nb-cine.json`, access levels |
| [DEVELOPERS.md](docs/DEVELOPERS.md) | Plugin architecture, Flask endpoints, adding note types |

---

## Metadata

- **License:** [AGPL v3](LICENSE)
- **Language:** JavaScript (plugin) · Python (Flask extensions)
- **Requires:** [nb](https://github.com/xwmx/nb) · [nb-web](https://github.com/linuxcaffe/nb-web)
- **Optional:** afterwriting · fonts-courier-prime
- **Platforms:** Linux
- **Version:** see [CHANGES.md](CHANGES.md)
