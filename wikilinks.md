---
title: WIKILINKS
caption: making connections across paragraphs, files and notebooks 
footnote:
tags: []
toc: true
SEO:
---

# Wikilinks

[[#Basic Syntax|Basic Syntax]] · [[#Anchor Links|Anchor Links]] · [[#Terminal Links|Terminal Links]] · [[#Inline Live Queries|Inline Queries]] · [[#Inline Note Includes|Inline Includes]] · [[#Backlinks|Backlinks]] · [[#Quartz Compatibility|Quartz Compatibility]] · [[#Display Label Priority|Display Label Priority]]

---

nb-web supports `[[wikilink]]` syntax in note bodies for linking between notes. Click any wikilink in a rendered note to open the target.

---

## Basic Syntax

| Syntax | Effect |
|--------|--------|
| `[[Note Title]]` | Link by title or filename stem; display text resolved automatically |
| `[[Note Title\|display text]]` | Link with custom display text |
| `[[notebook:id]]` | Link by explicit nb selector (e.g. `[[docs:3]]`) |
| `[[42]]` | Link by bare note ID within the current notebook |

Plain-text wikilinks are resolved within the current notebook. Matching is case-insensitive — `[[shop]]` and `[[Shop]]` both find a note titled "Shop".

### Resolution order

For a plain `[[text]]` wikilink, nb-web tries in order:

1. **Title match** — a note whose `title:` frontmatter (or inferred title) equals the text
2. **Filename stem match** — a note whose filename without extension equals the text

The filename-stem fallback means you can freely set a descriptive `title:` on a note without breaking existing links that use its short filename. For example, if `1b.md` has `title: 1-1b — Wide establishing shot`, the link `[[1b]]` still resolves because `1b` matches the filename stem `1b.md`.

### Display label priority

Once a wikilink resolves to a note, nb-web chooses its display label in this order:

1. **`alias:`** frontmatter field — a short mutable label (scene number, version code, etc.)
2. **`title:`** frontmatter field (or inferred title)
3. **Filename stem** as fallback

The `alias:` field is intended for content whose short identifier changes over time (scene numbers, draft versions) while the filename stays fixed. Change `alias: 4` to `alias: 7` and every `[[filename]]` link in the notebook immediately displays `7` — no link edits needed. Display labels are session-cached; Ctrl+R picks up alias changes.

---

## Anchor Links

Append `#Heading Text` to jump directly to a section within a note:

| Syntax | Effect |
|--------|--------|
| `[[Page#Heading]]` | Open note and scroll to that heading |
| `[[Page#Heading\|label]]` | Same, with custom display text |
| `[[#Heading]]` | Scroll to a heading in the **current** note (no page reload) |

Heading matching is case-insensitive and compares against the heading text directly — use the heading words with spaces, not a slug.

```
[[#Contact Import]]   ✓  exact words, any case
[[#contact import]]   ✓  lowercase also works
[[#contact-import]]   ✗  slug/hyphen form does not match
```

---

## Terminal Links

Any standard Markdown link with a `term:` URL runs a shell command in the built-in terminal pane when clicked:

```markdown
[label](term:command)
```

| Example | What it does |
|---------|-------------|
| `[Preview site](term:cd ~/dev/mysite && npx quartz build --serve)` | Starts a local Quartz preview server |
| `[Sync notes](term:nb sync)` | Runs nb sync in the terminal |
| `[Today's tasks](term:task due:today)` | Opens Taskwarrior filtered to today |
| `[Open task UI](term:task)` | Launches the Taskwarrior TUI |

Terminal links render with a `▶` prefix and monospace yellow styling so they're visually distinct from navigation links.

If the terminal pane is already open, the command is sent to the running session. If not, the pane opens first and then runs the command.

### File variables

Commands can reference the **current note** using `{variable}` placeholders, resolved at click time:

| Variable | Resolves to |
|----------|-------------|
| `{file}` | Full path to the note file — `/home/you/.nb/home/note.md` |
| `{dir}` | Directory containing the note — `/home/you/.nb/home` |
| `{name}` | Filename without extension — `note` |
| `{selector}` | nb selector — `home:42` |
| `{notebook}` | Notebook name — `home` |
| `{title}` | Note title from frontmatter |

```markdown
[Open in vim](term:vim {file})
[Run as script](term:bash {file})
[→ PDF](term:pandoc {file} -o {dir}/{name}.pdf)
[Git history](term:git -C {dir} log --oneline -- {file})
[Encrypt](term:nb encrypt {selector})
[Spellcheck](term:aspell check {file})
```

Variables are especially useful in **notebook templates** — a `[Run](term:bash {file})` link in a template gives every note in that notebook a run button automatically.

Terminal links work anywhere Markdown renders — note bodies, templates, requirements cards, and wikilinked docs. They are **not** published by Quartz (the `term:` scheme has no meaning in a static site).

---

## Inline Live Queries

`{{provider: query}}` — live data injected inline into note prose at render time.

```
Current cash: {{hledger: bal Assets:Cash --no-total}}
Pending tasks: {{tw: count status:pending +work}}
Today: {{date: %A, %B %d}}
```

| Provider | What it runs | Example |
|----------|-------------|---------|
| `hledger` | hledger query against the notebook's journal | `{{hledger: bal Assets:Cash --depth 1}}` |
| `tw` | Taskwarrior filter (returns count by default) | `{{tw: count due:today}}` |
| `nb` | nb count/list | `{{nb: count home:}}` |
| `date` | strftime format | `{{date: %Y-%m-%d}}` / `{{date: %A}}` |
| `inline` | Render another note's body in-place (see [[#Inline Note Includes]]) | `{{inline: ../notes/shared.md}}` |

Results appear as plain text inline. While loading, a `⋯` placeholder is shown. On error, the raw `{{...}}` is shown dimmed with the error in a tooltip.

Patterns inside `` `code` `` or fenced blocks are never evaluated.

### What works inline vs what needs a codeblock

Inline queries work best when the output is a **single value or a short flat list**. Queries that produce formatted reports — with headers, separator lines, or multiple account rows — will be collapsed into a `·`-joined string that rarely reads well in prose.

| Use inline `{{...}}` | Use a fenced codeblock |
|----------------------|----------------------|
| `bal Assets --depth 1 --no-total` | `bs`, `is`, `activity` (report format) |
| `bal Income -p thismonth --no-total` | `bal` without `--depth` on a deep tree |
| `tw: count status:pending` | `bal Assets Liabilities` (two rows) |
| `date: %A, %B %d` | any query where rows = insight |
| `files`, `stats` (single-line output) | multi-commodity balances |

The quick test: if `hledger <query>` in your terminal produces more than one or two lines of data, it belongs in a codeblock.

> **`--depth 1` is almost always required for inline `bal` queries.** Adding a period flag (`-p thismonth`) does not reduce depth — without `--depth 1` you get one line per leaf account, which `_iq_strip` joins into a wall of text. Always pair period filters with `--depth 1 --no-total` for inline use.

---

## Inline Note Includes

`{{inline: path}}` — render another note's body inline, as if its content were part of the current note.

```markdown
{{inline: ../shared/header.md}}
{{inline: accts:tutorial/06_credit_card_transactions.md}}
```

The path is resolved relative to the current note's location. You can use `../` to step up folders, or prefix with a notebook name (`accts:`) for cross-notebook includes. Frontmatter is stripped — only the body renders.

Included content is rendered in a bordered block (a left-rule bar with a slight background tint) so it's visually distinct from the surrounding note. Wikilinks, term: links, and inline queries inside the included note are all live — the full rendering pipeline runs on included content.

**Depth guard:** includes do not nest. If an included note itself contains `{{inline:}}` patterns, they are silently dropped to prevent infinite recursion.

**Not published:** `{{inline:}}` is nb-web-only. Quartz does not evaluate it; the raw `{{...}}` appears as literal text in static builds.

---

## Backlinks

A `backlinks` codeblock shows all notes that link to the current note's title:

````markdown
```nb
backlinks
```
````

Results are found via ripgrep (fast) and capped at 20 by default. Pass a number to raise the limit:

````markdown
```nb
backlinks 50
```
````

See [[CODEBLOCKS]] for the full `nb` block reference.

---

## Quartz Compatibility

`[[Note Title]]` wikilinks are the recommended cross-linking syntax for any note that may be published via the NbWeb-quartz plugin. Quartz resolves them natively by title — no path, no extension needed.

| Syntax | nb-web | Quartz |
|--------|--------|--------|
| `[[Note Title]]` | ✓ title → filename stem fallback | ✓ native |
| `[[Note Title\|label]]` | ✓ | ✓ |
| `[[filename-stem]]` | ✓ filename stem match (nb-web only) | ✗ |
| `[[notebook:selector]]` | ✓ direct nb selector | ✗ |
| `[[42]]` | ✓ bare ID | ✗ |

For notes that may be published to Quartz, prefer `[[Note Title]]` using the full descriptive title — Quartz resolves by title and filename natively, so descriptive titles work on both sides.

See [[NbWeb-quartz]] for publishing workflow.
