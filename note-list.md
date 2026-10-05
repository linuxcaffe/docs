---
title: NOTE LIST
caption: the list of notes on the left, and the preview on the right
topic: note-list
category: basics
help_for: [page:list, key:pinned]
toc: true
processed: true
---

# Note list and preview

## Summary

The left pane lists the notes in the current notebook or folder; click one (or move with the
arrow keys) to show it on the right. Folders come first, then pinned notes, then the rest. The
row above the list filters by type (notes, bookmarks, todos, contacts, folders, images), the
**⇅** button changes the sort, and Ctrl-click selects several notes to move, export or delete
together.

## How it works

Each row shows a note's icon, title and first line; its number is its position in the folder's
`.index`. Clicking a folder opens it, and the breadcrumb above the list shows where you are: click any part
of it, or press `←`, to go back up. Opening a link to a note (a bookmark, a shared URL, a refresh)
shows that note's notebook and folder in the list.

### Filtering by type

The chips under the toolbar show one kind of item: **all**, 📝 notes, 🔖 bookmarks, ✔ todos,
🪪 contacts, 📂 folders, 🌄 images. With todos, **open** / **closed** narrow it further. The
counts above the list break the current view down by type.

### Sorting

**⇅** sorts the list:

| Sort | Order |
|---|---|
| Default | newest added first |
| A → Z, Z → A | by title |
| Newest first | most recently added first |
| Oldest first | the notebook's own order (`.index`): use it for hand-ordered notebooks |

Plugins can add sorts of their own (the hledger plugin adds **Account hierarchy**). The button
lights up when the sort isn't the notebook's default; a notebook sets its default with `sort:` in
its config, see [[docs:NOTEBOOKS.md#Defaults|Notebooks → Defaults]].

### Pinned notes

Pinned notes sit at the top, under the folders. Pin a note from the preview toolbar's 📌, or give
it `pinned: true`: it's pinned the first time it's opened. Pins are remembered per browser.

### Selecting several notes

Ctrl-click (Cmd-click on a Mac) adds a note to the selection; Shift-click selects a range. The
preview then offers **Move**, **Export** and **Delete** for all of them. `Escape` clears the
selection.

## Reference

- **List options (☰)**: *Show filenames* instead of titles, *Light mode*, *Import files…*,
  *Link file…*.
- **Plugin buttons**: plugins add buttons to the list header (⚙ the archive panel, ⚡ the
  wizard panel).
- **Keyboard**: `↑`/`↓` move through the list, `→`/`Enter` go into the preview or a folder, `←`
  goes back up; see [[docs:KEYBOARD]].
- **The preview** renders Markdown, images, audio, video, PDFs and more, each by its type; see
  [[docs:TYPED-NOTES]].

## For developers

- [[docs:dev/dev-notebook-config.md#List defaults|Notebook config: list defaults]]
- [[docs:dev/dev-architecture.md#Excerpt rendering|Architecture: excerpts]]

`_list_notes` (`app.py`) builds the list; `renderList` and `_getSortedNotes` (`main.js`) draw and
sort it; the list header menus and multi-select live in `ui-chrome.js`.

