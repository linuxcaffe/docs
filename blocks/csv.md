---
title: csv — Spreadsheet Table
caption: an editable spreadsheet grid inside a note
type: topic
topic: block-csv
category: live-blocks
help_for: [block:csv]
processed: true
---

# csv — Spreadsheet Table

## Summary

A `csv` block turns comma-separated rows into a spreadsheet grid right in the note: the first row
is the column headers, the rest is data. Edit cells, add and remove rows and columns from the
right-click menu, then click **Save** to write the grid back into the note. Name a template after
`csv` (`csv materials`) for a fixed set of columns, a totals row and a pick-list. The data stays in
the note as plain text.

## How it works

````markdown
```csv
Item,Qty,Length
Cedar 2x6,40,12'
Cedar 5/4 decking,60,12'
Joist hanger,24,
```
````

This is Pat's lumber order for the Jones deck, live (pulled in from
[[features:examples/jobs/jones-deck.md|the job note]], so it's read-only here):

{{inline: features:examples/jobs/jones-deck.md#Lumber order}}

**Editing.** Click a cell to change it. Right-click for the grid's menu: insert or delete rows and
columns, copy and paste. Column widths fit the content. Click the header to fold the block away.

**Saving.** Edits aren't saved by themselves: click **Save** in the block's header (or press
`Ctrl+Enter` after clicking in the grid) when you're done. It writes back every grid in the note at
once, rewriting each `csv` block's rows. A grid inside a chapter pulled in with `{{inline:}}` has
no **Save**: open the chapter's own note to edit it.

**More than one block** in a note is fine; each gets its own grid.

## Reference

- **The first row is always the header.** A block needs at least two lines: one line on its own
  (`csv materials` in the body, or just a header row) is read as the name of a price list to show,
  not a grid (see [[docs:blocks/csv/templates.md|csv templates]]).
- Cells are split on commas, so a cell can't contain one; quotes around a cell are removed.
- Spreadsheet formulas (`=SUM(B1:B3)`) work in the grid; they're saved as written.
- In frontmatter, `csv:` shows a price list in the header strip, not a grid; see
  [[docs:blocks/csv/templates.md|csv templates]].
- A `.csv` file opens as a full-page spreadsheet of its own; see [[docs:blocks/csv/files.md|csv files]].

## For developers

Not a plugin renderer: `marked` leaves a multi-line `csv` fence as `<pre><code class="language-csv">`
and `_renderCsvBlocks` (`main.js`) swaps in a Jspreadsheet CE grid (`_buildCsvBarblock` for the
header). `_saveCsvBlocks` rewrites the note's blocks in order from its own grids
(`_ownGrids`, which leaves out chapters and the annotation footer) and saves with `PUT /api/note`.
The one-line form is the codeblocks plugin's `csv` entry (`_loadCsvCatalogBlock`). Codeblock
architecture: [[docs:dev/dev-codeblocks.md]] #REVIEW.
