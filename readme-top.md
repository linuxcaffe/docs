---
title: README — top
caption: the README's header, intro, TL;DR and why
---
- Project: https://github.com/linuxcaffe/nb-web
- Issues:  https://github.com/linuxcaffe/nb-web/issues

# nb-web README

A browser-based interface for [nb](https://github.com/xwmx/nb) — the plain-text, git-backed, CLI note-taking tool.

nb is built for working with a collection of text files — fast, scriptable, entirely at home in a terminal. nb-web puts a rich browser UI on top of that same collection: Markdown, `.txt`, `.csv` files rendered and edited in place, images and audio embedded inline, all without changing what's on disk. The original `nb` keeps working exactly as it always has — nb-web doesn't replace it, it runs on top of it, calling the same CLI underneath every click.

There is no database. No import format to get locked into, no export button standing between you and your own words. Every note, every config, every theme is a plain file you could open in `vi` and read without translation. nb-web renders it, makes it clickable, hands you an editor when you want one — but the files were always yours, and they still are.

nb-web is free and open source, and it runs locally — the Flask process behind it lives on your machine, not someone else's. Nothing leaves the computer unless you tell git to push it somewhere.

If you already enjoy working with nb, or with text files as your primary way of thinking, nb-web will feel like the same tool with a window added — not a rewrite, not a migration. It's not trying to be everyone's note app.

---

## TL;DR

- Create notes quickly with as much or as little markdown, with keyboard, mouse or mobile
- Browse, search, and edit all your nb notebooks in a split-pane, Markdown-rendering web UI
- Full CRUD: add notes, bookmarks, todos, and contacts with per-notebook templates
- **Wikilinks** — `[[Note Title]]` links between notes, resolved live on click
- **Terminal links** — `[label](term:command)` in any note runs a shell command in the built-in terminal pane
- **Live codeblocks** — embed Taskwarrior queries, hledger reports, git logs, and timeclock status directly in notes
- **Git sync** — commit, push, and pull per notebook; one-repo branch-per-notebook model
- **Plugins** — extend the UI without touching core; ships with Codeblocks, Specialty, Contacts, Archive and Quartz, with hledger, cine and Claude plugins alongside
- **Archive** — export any notebook as a portable `.nbz` file; import on any machine
- Installable as a **PWA** (Epiphany / GNOME Web recommended); works offline via service worker
- Your notes stay plain Markdown files in `~/.nb/` — nb-web never locks you in

---

## Why this exists

nb is an exceptionally capable note-taking tool, but it lives entirely in the terminal. Browsing a large notebook, following wikilinks, previewing images, or editing a long note are all friction-heavy at the CLI. Reaching for a GUI editor means leaving nb's git-backed, plain-text world.

nb-web closes that gap. It wraps nb's CLI via a local Flask API, giving you a real browser UI — with rendered Markdown, clickable wikilinks, tag filtering, and live data widgets — while keeping every note as a plain file in `~/.nb/`. The CLI and the browser UI coexist: anything you do in one is immediately visible in the other.

The sync model is explicit and notebook-scoped. nb-web talks to git directly rather than calling `nb sync`, so you always know exactly what is being pushed and where.

---

## What this means for you

Your notes are always a browser tab away — searchable, readable, and editable — while remaining plain Markdown files you can grep, script, and back up like any other text. You get the power of a polished UI, both at the desktop with full keyboard support, and finger friendly and compact for mobile use, without giving up the permanence of plain text or the safety of git.

---

## Feature tour
