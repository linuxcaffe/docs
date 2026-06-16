---
title: WIKILINKS
caption: Wikilink resolution algorithm, _wikilinkCache, term: link implementation
toc: true
---

# WIKILINKS (dev)

Developer reference for wikilink and term: link internals. For user-facing syntax see [[docs:WIKILINKS]].

---

## Resolution algorithm

`_resolveWikilinkSelector(sel)` — called on click and for `data-autolabel` spans:

1. If `sel` contains `:` or is a bare integer → used as-is (full nb selector, e.g. `preciousfinds.ca:2`, `42`)
2. Otherwise → search via `/api/list?q=<text>` — resolved with **title first, filename stem fallback**:
   - Exact title match (case-insensitive)
   - Filename stem match — `[[1b]]` resolves to `1b.md` even if its `title:` is `"1-1b — Wide shot"`

`_resolveWikilinks(container)` — called after rendering. For `data-autolabel` spans, resolves the selector then fetches the note title via `/api/note` to set as display text. Falls back to leaving the text as-is on failure.

Results are cached in `_wikilinkCache` with a `\x00` prefix key (separate from selector-keyed display-title entries). Cache is session-scoped — persists across note switches, cleared on page reload.

---

## Pre-processing

Wikilinks are converted to `<span>` placeholders before marked parses the body, so the markdown parser never sees them as plain text:

```javascript
.replace(/\[\[([^\]|]+)(?:\|([^\]]+))?\]\]/g, (_, target, label) =>
    `<span class="nb-wiki-link" data-selector="${target}" ...>${label || target}</span>`)
```

Fenced code blocks and inline code are split out first — links inside backticks are left untouched.

---

## term: link implementation

`term:` links execute arbitrary shell commands in the built-in terminal pane. The click handler:

1. Extracts the URL from `href="term:..."` 
2. Decodes percent-encoding via `decodeURIComponent`
3. Substitutes `{variable}` placeholders with current-note context values
4. Sends the command to the terminal pane (opens pane if not already open)

**Placeholder substitution** happens at click time — not at render time. Values reflect the note that is open when the link is clicked, not when the page was rendered. This matters for templates: a `term:` link in a template is resolved fresh each time it's used.

**Percent-encoding requirement:** CommonMark disallows spaces in unquoted link URLs. Spaces and quotes in the href must be percent-encoded; the click handler decodes them before passing to the shell.

```markdown
[hledger register "Bank:"](term:hledger%20register%20%22Bank:%22)
```

Use `urllib.parse.quote` (Python) or `encodeURIComponent` (JS) when generating term: links programmatically. The `org-to-nb-notes.py` tool handles this for `$ hledger` lines in org tutorial files.

**Safety note:** `term:` links execute arbitrary shell commands. They are nb-web-only — Quartz does not evaluate the `term:` scheme and the raw link appears as literal text in static builds.

---

## Inline query implementation (`{{provider: query}}`)

Inline `{{...}}` patterns are detected in `_resolveInlineQueries` during `_enrichRendered`. Each span gets:

- `data-provider` — the provider name (`hledger`, `tw`, `nb`, `date`, `inline`)
- `data-query` — the query string

Non-inline providers (`hledger`, `tw`, `nb`, `date`) fire in parallel — they're cheap single-value lookups. `inline` includes are sequential (see [[docs:RENDER_PIPELINE#1a]]).

`_iq_strip` — strips hledger report formatting (separators, commodity padding, column headers) down to a plain value suitable for inline text. Multiple result rows are joined with ` · `. This is why multi-row queries collapse into unreadable strings — use codeblocks for reports with more than one or two rows.

Patterns inside `` `code` `` or fenced blocks are never evaluated — code split happens before `_resolveInlineQueries`.

**Depth guard for `{{inline:}}`:** included notes never nest. `{{inline:}}` patterns in included content are silently dropped to prevent infinite recursion.
