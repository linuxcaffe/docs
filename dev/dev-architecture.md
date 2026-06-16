---
title: ARCHITECTURE
caption: "Non-feature-specific internals: rendering stages, frontmatter keys, images, UUIDs, hashtags"
toc: true
---

# ARCHITECTURE

> Developer documentation for nb-web. See [[docs:DEVELOPERS]] for the full index.

## Overview

nb-web is a single Flask process (`app.py`) serving a single-page app (`index.html` + `main.js` + `nav.js`). The backend shells out to nb and git for all note operations — it keeps no database of its own. Notes live in `~/.nb/` as plain files, indexed by nb's `.index` files. A service worker caches the frontend for offline use; the cache key is the git commit hash, so deploying new code automatically invalidates old caches. Per-notebook preferences and app settings are stored in `~/.nb/nb-settings.json`.

---

## Markdown rendering pipeline

Every note body passes through the same two-stage rendering pipeline, regardless of notebook or note type.

**Stage 1 — pre-processing** (`_renderMarkdown`, before marked):
- `[[docs:wikilinks]]` and `#hashtags` are converted to `<span>` placeholders so the markdown parser never sees them as plain text.
- Fenced code blocks and inline code are split out first, so links and tags inside backticks are left untouched.

**Stage 2 — enrichment** (`_enrichRendered`, after the HTML is in the DOM):
- `<a href>` tags are classified and wired: external links get `target=_blank`; `term:` links get a terminal handler; nb-selector links navigate to the target note.
- Wikilink `<span>` elements are resolved to note selectors and made clickable.
- UUID-like strings are detected and linked.
- Plugin-registered codeblock renderers are invoked.

See [[docs:RENDER_PIPELINE]] for the full pipeline redesign plan and tier details.

---

## Hashtags

`#tag` anywhere in note body text (outside code) is styled as a clickable tag chip. Clicking runs a notebook search for that tag. Multi-part tags using `/` are supported: `#project/alpha`.

Implementation: hashtags are matched in Stage 1 before marked runs, converted to `<span class="nb-tag" data-tag="...">` placeholders, then wired as clickable in Stage 2.

---

## Frontmatter keys

Special keys recognised by nb-web beyond standard `title:`, `tags:`, and `type:`:

| Key | Value | Behaviour |
|-----|-------|-----------|
| `pinned: yes` | `yes` | Note is auto-pinned whenever it is opened, as if you had clicked the pin toolbar button. Unpinning via the toolbar also clears this key from the file. |
| `toc: true` | `true` | Generates a collapsible Table of Contents at the top of the rendered note. The TOC header bar shows the note's file path, size, and last-modified date. Headings become anchor links; clicking scrolls the page without changing the URL hash. Defaults to collapsed. |
| `lock: yes` | `yes` | Marks the note read-only in the editor. The `+` Add button on live codeblocks also checks this flag — it shows a 🔒 indicator for 2.5 s if clicked while locked. |
| `xref:` | `notebook:` or list | Cross-reference: injects `[N]` indicators on heading words that match note titles in the target notebook/folder. See [[docs:dev/dev-xref]]. |
| `xref-ignore:` | list of strings | Words to exclude from xref heading scans on this note. |
| `alias:` | string | Short mutable display label for the note — overrides `title:` in wikilink display. Useful when a short identifier (scene number, draft version) changes over time while the filename stays fixed. |
| `draft: true` | `true` | Marks a note as a draft — not published by Quartz. |

---

## Code block taxonomy

Two categories of fenced code blocks:

| Fence language | Behaviour |
|----------------|-----------|
| `ledger`, `journal`, plain ` ``` ` | Static syntax highlight via Prism |
| `hledger`, `tw`, `nb`, `git`, `t`, `cine` | **Live widget** — data fetched from local tools |

**Rule of thumb for tutorial/example content:** use ` ```ledger ` (not ` ```hledger `) so example journal entries display as static code rather than being executed against the user's real journal.

Static blocks pass through marked unchanged and are highlighted by Prism on the client. Live blocks are converted to `<div class="nb-*-block">` placeholders in Stage 1, then hydrated by their renderer in Stage 2. See [[docs:dev/dev-codeblocks]] and [[docs:dev/dev-codeblock-authoring]].

---

## Images

Relative image paths in notes are rewritten to `/api/file?selector=…` at render time, so images resolve correctly regardless of the browser's base URL. Absolute URLs (`https://`) and data URIs pass through unchanged.

The rewrite happens in `_renderMarkdown` (Stage 1) before marked processes the Markdown, using the note's selector to construct the correct `/api/file` URL.

---

## UUIDs

Bare UUID strings (8-4-4-4-12 hex format) in note bodies are auto-detected and rendered as linked references. Clicking resolves the UUID to its note or task.

Detection happens in Stage 2 (`_enrichRendered`), walking text nodes to find UUID-shaped strings and wrapping them in clickable `<span>` elements.

---

## Excerpt rendering

The excerpt shown in the list panel is the first non-empty line of the note body (after frontmatter is stripped). Edge cases:

**Calendar filter mode** — when the list is filtered by date via the calendar, the excerpt shown is the file's **modified date**, not the body text. Intentional; not a bug.

**Webpage notes** — notes routed through `_renderWebpage` (those with `caption`, `footnote`, `SEO`, `tags`, or `with_tags` in frontmatter) may show no excerpt in the list panel if the body is empty. Adding a bare `caption:` key routes a note through the webpage renderer cleanly; the title becomes the primary display element.

**`with_tags:` field** — pages with `with_tags:` are included in the webpage renderer detection condition. Values render as tag chips in the preview card.

---

## Tools

### org-to-nb-notes.py

`tools/org-to-nb-notes.py` — one-shot converter from an Org-mode tutorial file to a set of nb-formatted Markdown notes.

```bash
python3 tools/org-to-nb-notes.py <source.org> <nb-folder-path> [notebook-name]

# Example — hledger beginner tutorial into accts:tutorial/
python3 tools/org-to-nb-notes.py \
    ~/dev/awesome-hledger/contrib-resources/hledger-beginner-tutorial.org \
    ~/.nb/accts/tutorial \
    accts
```

Each H2 section in the org file becomes one note; the preamble (before the first H2) becomes `00_overview.md`. Filenames are `NN_slug.md` where `NN` is the section sequence number.

**Transformations applied:**

| Input | Output |
|-------|--------|
| Org `; prose` comment lines | Prose text (`;` prefix stripped) |
| `; ` lines inside code fences | Preserved — hledger comment syntax |
| ` ```ledger ` (pandoc commonmark output) | ` ```ledger ` (space removed) — Prism display only, **not** executed |
| `$ hledger cmd` lines | `[cmd](term:cmd%20url%20encoded)` clickable terminal link |
| `$ hledger cmd  # note` | term: link + `— *note*` annotation |
| Section title mentions in body text | `[[NN_slug\|Title]]` cross-wikilinks |
| H3 headings within a section | Demoted to H2 (sub-sections stay sub-sections) |

**Pandoc gotchas this script handles:**
- commonmark outputs ` ``` ledger` with a space before the language — the script strips it
- `--` flags in commands are converted to `–` (en-dash) by pandoc smart typography — restored in `_term_link`
- `term:` href spaces must be percent-encoded (`urllib.parse.quote`) — CommonMark disallows bare spaces in link URLs

**Output frontmatter:**
```yaml
---
title: "Section Title"
type: tutorial
tags: [hledger, tutorial]
---
```

After writing all notes the script updates `.index`, then runs `git add -A && git commit` in the notebook root.

**Dependencies:** `pandoc` on `$PATH`.
