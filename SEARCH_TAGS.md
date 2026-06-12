---
title: SEARCH_TAGS
caption: Full-text search, tag filtering, and cross-notebook search
toc: true
---

# Search and Tags

[[#Search|Search]] · [[#Tag Filter|Tag Filter]] · [[#Combining Filters|Combining Filters]] · [[#Cross-Notebook Search|Cross-Notebook Search]]

---

## Search

The **search bar** filters the note list by full-text content as you type.

- Focus it with `/` or `s` (keyboard shortcut), or click the field
- Matches note titles, body text, and frontmatter
- The active query appears as a token in the command bar — click `×` to clear

Search is scoped to the current notebook by default. Switch to **all** in the scope selector to search across every notebook at once.

---

## Tag Filter

The **tags field** filters by one or more `#tags`.

- Focus it with `#` (keyboard shortcut), or click the field
- Type a tag name — matching begins immediately
- Tags are sourced from frontmatter `tags:` lists and inline `#hashtags` in note bodies

Just type bare tag names — no `#` needed. The field adds it automatically.

**Positive tags** (AND logic) — all must be present:

`friend local` → notes tagged both `#friend` and `#local`

**Negative tags** (prefix with `-`) — exclude notes carrying that tag:

`recipes -tested` → recipes not yet tested  
`-draft` → everything except drafts

Positive and negative tags can be freely mixed. Negative-only queries (`-draft`) start from all notes and subtract.

The active tag query appears as a `--tags` token in the command bar — click `×` to clear.

---

## Combining Filters

Search and tags work together — both are applied simultaneously. A note must match the search query **and** carry the specified tags to appear in the list.

The type filter (note / todo / bookmark / contact / …) in the Add bar also stacks with search and tags, letting you narrow to e.g. `#project` todos matching "deploy".

---

## Cross-Notebook Search

Select **all** from the notebook scope selector to search across all notebooks at once. The note list shows results from every notebook, each prefixed with its notebook name.

The `--all` scope is also available as a token in the command bar — click it or change the scope selector to return to a single notebook.

> **Tip:** `/` then a search term is the fastest way to find any note regardless of which notebook you're in — switch scope to `all` first if you're not sure where it lives.
