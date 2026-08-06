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
carries over to the others.

Story and plotline card headers also show a `+` — a placeholder for a not-yet-built action, not
live yet.

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
- [ ] Treatment export (planned — storyline order → downloadable prose document)
- [ ] The `+` stub on story/plotline headers (placeholder only, no action wired yet)
