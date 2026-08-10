# STORYLINES.md

*Story development board — [NbWeb-cine](../README.md)*

---

[insert screenshot — full storylines board]

## Overview

Before writing a scene, develop what the story *is* on the storylines board — a 2D canvas of
plotline tracks (`type: plotline`) and draggable story cards (`type: story`). Write a card per
beat; drag it between tracks to reshape act structure; promote a card to the master storyline
track to build your film's actual spine in order. One master note per production
(`type: storyline`, e.g. `film-school.md`) anchors the whole board.

**Three views of the same board — Board, Story, Script — plus a fourth, Note**, all reachable
from one shared header (🧵 title, then the view-switcher). Board is the drag-and-drop canvas.
Story reads the promoted spine as prose cards. Script reads it as a flowing linear treatment.
Note is the master storyline note's *own* written description — the production's premise, not
generated from card data — reachable by clicking the title from any of the other three views,
or directly from any story/plotline card's own header (its title jumps straight to the
storyline that owns it, landing on Note).

A **zoom control** rides alongside the view-switcher (small/medium/large, shown as three
concentric squares filling in) — on Story it steps title+description → title+first few
sentences → title+first paragraph; on Script it steps description → first paragraph →
the full card body. Board, Story, and Script share one size preference, so zooming in on one
carries over to the others. At min zoom, the Board's own row heights additionally squeeze to
fit every lane on screen without vertical scrolling — but only shrink, never grow past the
normal min-zoom row height, so a short lane list on a tall screen isn't stretched out.

Story and plotline card headers also show a `+` — a placeholder for a not-yet-built action, not
live yet. On the Board itself, each plotline row's own add-story button lives corner-pinned in
its own sticky lane label (not a header-wide "+ Story" pill) — stays reachable when a long lane
is scrolled horizontally, and doesn't force the row taller.

The Board is a full-screen overlay — nothing behind it (the note's own toolbar, list pane) is a
valid click target while it's open, so it covers the whole viewport rather than leaving that
chrome visible-but-inert above it. Long lanes scroll horizontally via a deliberately fat,
finger-friendly scrollbar rather than relying on the native one alone.

**`lock:` on the master storyline note doubles as a board lock** — toggled from a 🔒/🔓 button
in the shared header (Board, Story, Script, or Note — whichever view it's clicked from writes
the same field on the same note). Locked makes the board fully read-only: drag-reorder
disabled, save/load order controls hidden, every add/demote button hidden.

**`type: milestone` notes get the same specialty header as story/plotline** — title-click back
to the owning storyline, the mini Board/Story/Script switcher, previously fell through to
generic markdown with no connection back to the board at all.

## Status

- [x] Lanes (type: storyline) with colour tints
- [x] Story cards (type: story) — drag across lanes and positions
- [x] Inline card creation per lane
- [x] Named storyline orders (save/restore arc snapshots)
- [x] Script-view — read card bodies as prose treatment
- [x] Body peek panel while dragging
- [x] Milestone cards on the master storyline track
- [x] Unified Board/Story/Script/Note header, shared across the whole board (2026-08-06)
- [x] Note view — the master storyline note's own written description, previously unreachable
- [x] Story/plotline headers link back to their owning storyline note and its Board/Story/Script views
- [x] Content-density zoom (title+desc → title+excerpt → title+full), shared across views
- [x] Full-screen board overlay + fat horizontal scrollbar (2026-08-06)
- [x] `lock:` on the master storyline note → fully read-only board (2026-08-06)
- [x] type:milestone specialty header + preview card, modeled on type:story (2026-08-06)
- [x] Min-zoom row-height squeeze to fit all lanes on screen (2026-08-06)
- [ ] Treatment export (planned — storyline order → downloadable prose document)
- [ ] The `+` stub on story/plotline headers (placeholder only, no action wired yet)
