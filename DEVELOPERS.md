---
title: DEVELOPERS
caption: nb-web developer documentation index
toc: true
processed: true
---

# DEVELOPERS

Developer documentation for nb-web, organised by feature area. Each section below links to a dedicated file in `dev/`.

---

## Index

| File | Scope |
|------|-------|
| [[dev/ARCHITECTURE]] | Rendering stages, frontmatter keys, images, UUIDs, hashtags — non-feature-specific internals |
| [[dev/RENDER_PIPELINE]] | Rendering architecture — pipeline stages, bottlenecks, redesign plan |
| [[dev/CODEBLOCKS]] | Writing, registering, and testing live codeblock widgets |
| [[dev/PLUGINS]] | Plugin system — writing plugins, dispatch, `listItemIcon`, toolbar hooks |
| [[dev/WIKILINKS]] | Wikilink resolution algorithm, `_wikilinkCache`, `term:` link handling |
| [[dev/TEMPLATES]] | `_resolve_template_vars`, placeholder API, annotation templates |
| [[dev/SYNC]] | Pull-then-push flow, `git-wire` internals, status API |
| [[dev/TESTING]] | Writing and running nb-web test scripts via the `test` codeblock |
| [[dev/CONTRIBUTING]] | Reporting issues, submitting changes, running from source |

---

## Pending migration

The sections below are the original DEVELOPERS.md content. Each will be moved to its `dev/` file and removed here as the ODC pass proceeds.

---

## Markdown

Every note body passes through the same two-stage rendering pipeline, regardless of notebook or note type.

**Stage 1 — pre-processing** (`_renderMarkdown`, before marked):
- `[[wikilinks]]` and `#hashtags` are converted to `<span>` placeholders so the markdown parser never sees them as plain text.
- Fenced code blocks and inline code are split out first, so links and tags inside backticks are left untouched.

**Stage 2 — enrichment** (`_enrichRendered`, after the HTML is in the DOM):
- `<a href>` tags are classified and wired: external links get `target=_blank`; `term:` links get a terminal handler; nb-selector links navigate to the target note.
- Wikilink `<span>` elements are resolved to note selectors and made clickable.
- UUID-like strings are detected and linked.
- Plugin-registered codeblock renderers are invoked.

---

## Hashtags

`#tag` anywhere in note body text (outside code) is styled as a clickable tag chip. Clicking runs a notebook search for that tag. Multi-part tags using `/` are supported: `#project/alpha`.

---

## Frontmatter

Special keys recognised by nb-web beyond standard `title:`, `tags:`, and `type:`:

| Key | Value | Behaviour |
|-----|-------|-----------|
| `pinned: yes` | `yes` | Note is auto-pinned whenever it is opened, as if you had clicked the pin toolbar button. Unpinning via the toolbar also clears this key from the file. |
| `toc: true` | `true` | Generates a collapsible Table of Contents at the top of the rendered note. The TOC header bar shows the note's file path, size, and last-modified date. Headings become anchor links; clicking scrolls the page without changing the URL hash. Defaults to collapsed. |
| `lock: yes` | `yes` | Marks the note read-only in the editor. The `+` Add button on live codeblocks also checks this flag — it shows a 🔒 indicator for 2.5 s if clicked while locked. |

---

## Code Blocks

Two categories:

| Fence language | Behaviour |
|----------------|-----------|
| `ledger`, `journal`, plain ` ``` ` | Static syntax highlight via Prism |
| `hledger`, `tw`, `nb`, `git`, `t`, `cine` | **Live widget** — data fetched from local tools |

See [[CODEBLOCKS]] for the full live-block reference.

**Rule of thumb for tutorial/example content:** use ` ```ledger ` (not ` ```hledger `) so example journal entries display as static code rather than being executed against the user's real journal.

---

## Images

Relative image paths in notes are rewritten to `/api/file?selector=…` at render time, so images resolve correctly regardless of the browser's base URL. Absolute URLs (`https://`) and data URIs pass through unchanged.

---

## UUIDs

Bare UUID strings (8-4-4-4-12 hex format) in note bodies are auto-detected and rendered as linked references. Clicking resolves the UUID to its note or task.

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
