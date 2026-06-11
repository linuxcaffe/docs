---
title: DEVELOPERS
caption: nb-web internals, rendering pipeline, extension points
---

# DEVELOPERS

[[#Markdown|Markdown]] · [[#Wikilinks|Wikilinks]] · [[#term: Links|term: Links]] · [[#Hashtags|Hashtags]] · [[#Code Blocks|Code Blocks]] · [[#Images|Images]] · [[#UUIDs|UUIDs]]

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

## Wikilinks

```markdown
[[Page Title]]
[[notebook:selector]]
[[Title|display text]]
```

Resolution order (both nb-web and Quartz-compatible):

1. Exact title match (case-insensitive, via `/api/list?q=`)
2. Filename stem fallback — `[[1b]]` resolves to `1b.md` even if its `title:` differs

The stem fallback means `title:` frontmatter is free to be any descriptive string without breaking links. Bare integer IDs (`[[42]]`) and full nb selectors (`[[preciousfinds.ca:2]]`) also work, but are nb-web-only.

---

## term: Links

Clicking a `term:` link opens the terminal pane and runs the command.

```markdown
[label](term:command%20with%20args)
```

**Important:** CommonMark disallows spaces in unquoted link URLs. Percent-encode spaces and quotes in the href; the click handler decodes them with `decodeURIComponent` before passing to the shell.

```markdown
[hledger balance](term:hledger%20balance)
[hledger register "Bank:"](term:hledger%20register%20%22Bank:%22)
```

The label shown to the user is the unencoded plain text; only the URL part needs encoding.

Placeholder variables are substituted at click time:

| Variable | Resolves to |
|----------|-------------|
| `{file}` | Full path of the current note |
| `{dir}` | Directory containing the current note |
| `{name}` | Filename stem (no extension) |
| `{selector}` | nb selector of the current note |
| `{notebook}` | Active notebook name |
| `{title}` | Note title from frontmatter |

Example — open the current note's folder in a file manager:

```markdown
[Open folder](term:xdg-open%20{dir})
```

**Safety:** `term:` links execute arbitrary shell commands. Only embed them in notes you control. The tutorial notes in `accts:tutorial/` limit themselves to read-only `hledger` reporting commands.

---

## Hashtags

`#tag` anywhere in note body text (outside code) is styled as a clickable tag chip. Clicking runs a notebook search for that tag. Multi-part tags using `/` are supported: `#project/alpha`.

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
