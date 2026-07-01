---
title: CBQL — Codeblock Query Language
caption: Declarative queries embedded in codeblock parameters
toc: true
status: planned
---

# CBQL — Codeblock Query Language

[[#Concept|Concept]] · [[#Syntax|Syntax]] · [[#Parameters|Parameters]] · [[#Timeframe|Timeframe]] · [[#Variable Resolution|Variable Resolution]] · [[#Renderer Behaviour|Renderer Behaviour]] · [[#Pub/Sub Extension|Pub/Sub Extension]] · [[#Open Questions|Open Questions]]

---

## Concept

CBQL is a declarative query layer embedded in codeblock parameters. Any codeblock type gains a **query mode**: when `source:` is present, the renderer fetches and aggregates matching typed blocks from the source before rendering. Without `source:`, the block renders its inline content as today.

The codeblock **type** is the output format (`csv`, `table`, `timeline`, `chart`). The query parameters are the input selector. Backwards compatible — existing blocks are unaffected.

The underlying model: typed codeblocks scattered across dated sections in a project note are **timestamped records** (events). The project note is an event log. A reports page with CBQL blocks is a **projection** — a materialized view assembled from matching events.

---

## Syntax

```
```csv
source: name.md
filter: type=expense
timeframe: current
```
```

Parameters are declared inside the fenced block as YAML-style key/value pairs. The renderer strips them before processing content; they are never rendered as-is.

---

## Parameters

| Parameter | Description |
|-----------|-------------|
| `source:` | Where to read events from. Single note selector, notebook query, or filter expression (see [[#Pub/Sub Extension]]) |
| `filter:` | Narrow which blocks to include. Comma-separated `key=value` pairs matched against block content |
| `timeframe:` | Which slice of the event stream to include. See [[#Timeframe]] |

All parameters are optional. A block with no parameters renders inline content normally.

---

## Timeframe

Timeframe defines which portion of the event stream is included. Two named values are always available:

| Value | Meaning |
|-------|---------|
| `current` | Everything after the last `> INVOICED` marker in the source note |
| `historical` | Everything before the last `> INVOICED` marker (or between markers) |

### The INVOICED marker

In the Nathan model, timedot and project notes contain `> INVOICED` lines that mark invoice boundaries — the point at which accumulated work was billed. This marker is the natural partition between billable-and-open (current) and billed-and-closed (historical).

`current` is the default when `timeframe:` is omitted and a `source:` is present.

Explicit date ranges are also valid for one-off reporting:

```
timeframe: 2026-Q2
timeframe: 2026-01-01..2026-03-31
```

---

## Variable Resolution

`timeframe:` and `filter:` values can be **late-bound** — resolved from the note's own FM at render time rather than hardcoded in the block.

```yaml
---
type: reports
source: name.md
period: 2026-Q2
---
```

```
```table
source: ${source}
timeframe: ${period}
filter: type=milestone
```
```

The renderer resolves `${key}` against the containing note's FM before executing the query. This means the note declares its reporting window once; every CBQL block in it inherits automatically. Changing `period:` in FM regenerates all blocks.

---

## Renderer Behaviour

1. Parse block content for CBQL parameters (strip before rendering)
2. If `source:` present: fetch source note(s) raw markdown via `/api/note`
3. Scan fenced blocks in source for type matching `filter:`
4. Restrict to `timeframe:` window (locate `> INVOICED` markers or parse date range)
5. Pass collected records to the block's normal renderer as if they were inline content
6. Render output

If source is unavailable or returns no matches, render an empty state (not an error).

---

## Pub/Sub Extension

`source:` can be a query expression rather than a single note selector:

```
source: notebook:hansen           ← all notes in notebook
source: filter:client=Hansen      ← FM query across all notes
source: type:project              ← all project-typed notes
```

A subscriber note aggregating blocks from multiple sources gets cross-project views without explicit links. Publishers (project notes) declare nothing — they just use typed codeblocks naturally.

**Index requirement**: scanning codeblock content across many notes is heavier than FM field scanning (which the existing `query:` block already does). A codeblock index — maintained as notes are saved — is needed before this is fast at scale. Build the index before volume makes it slow, not after.

---

## Block Types as Output Formats

The codeblock type declares how aggregated records are rendered, not what they contain:

| Type | Output |
|------|--------|
| `csv` | Tabular data, downloadable |
| `table` | Rendered HTML table |
| `timeline` | Chronological event list with dates |
| `chart` | Visual (bar, line — TBD) |
| `sum` | Single aggregate value (total hours, total cost) |

The same query with different block types produces different views of the same underlying records.

---

## Open Questions

- Exact syntax for `filter:` — YAML map vs comma-separated `k=v` vs mini-expression?
- How does the renderer identify "typed blocks" in source? By fenced block info string (`` ```decision ``) — confirm this is the convention
- `${variable}` resolution scope — note FM only, or also notebook dotfile config?
- `timeframe: historical` with multiple INVOICED markers — return all historical, or only the most recent invoice period?
- Consumer block caching — re-fetch on every render, or cache until source note is modified?

---

#planned #wip
