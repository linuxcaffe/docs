---
title: codeblocks
caption: Codeblock renderer internals — architecture, external blocks, mkd-codeblocks
toc: true
---

# CODEBLOCKS (dev)

Developer reference for the codeblock renderer system. For user-facing codeblock docs see [[docs:CODEBLOCKS]]. For writing test scripts see [[docs:dev/dev-testing.md]].

---

## Architecture

Codeblock renderers are registered via the `codeblockRenderers` extension point in any NbWeb plugin. See [[docs:PLUGINS#codeblockRenderers]] for the full API.

The skeleton/hydrate pattern applies to all blocks:
- `html(text)` — synchronous placeholder stamped at markdown parse time
- `render(container)` — async hydration after the DOM is ready

All block renderers wire into `NbWeb.statusPill` for render progress tracking. See [[docs:RENDER_PIPELINE#_StatusPill]] for the pill API.

---

## External block renderers

Two codeblock types are provided by external plugins rather than `NbWeb-codeblocks`:

| Block | Plugin | Docs |
|-------|--------|------|
| `chart` | NbWeb-hledger (`~/dev/nbweb-hledger`) | `~/dev/nbweb-hledger/README.md` |
| `cine` | NbWeb-cine (`~/dev/nbweb-cine`) | `~/dev/nbweb-cine/README.md` |

When writing a new codeblock renderer that depends on an external tool or plugin, document the user-facing query syntax in the external plugin's README, and document the renderer internals here or in that plugin's own dev notes.

---

## test block internals

User-facing syntax and bundled scripts: [[docs:CODEBLOCKS#test — Embedded Assertions]].

### Exit code / output contract

| Exit | stdout | Result |
|------|--------|--------|
| 0 | empty | Block vanishes (Form 2) or silent reset (Form 1) |
| 0 | has content | Output rendered as markdown |
| non-zero | anything | Output rendered as markdown with red left border |

Output goes through the full render pipeline — headings, tables, wikilinks, `{{hledger:}}` inline expressions, `term:` and `note:` links all work inside test output.

### Context variables

Injected as environment variables by the Flask endpoint before running the script:

| Variable | Example | Notes |
|----------|---------|-------|
| `NB_DIR` | `/home/djp/.nb` | nb root |
| `NB_NOTE_SELECTOR` | `accts:guide/review.md` | Currently open note |
| `NB_NOTEBOOK` | `accts` | Notebook portion of selector |
| `NB_NOTE_PATH` | `/home/djp/.nb/accts/guide/review.md` | Absolute path |

Scripts that shell out to hledger should resolve the journal explicitly — Flask's subprocess environment may not match a login shell: #gotcha

```bash
journal="${HLEDGER_FILE:-$HOME/.hledger.journal}"
[ ! -f "$journal" ] && exit 0
```

### `subtest:` links

A script can output `[label](subtest:scriptname)` in its markdown. Renders as a toggle row; click fetches and expands the named script's output inline — no pre-run. `hl-optional` uses this: radar sweep of all 5 optional checks, each failure becomes a drill-down link to the dedicated script.

### Writing scripts

**Passing silently** — exit 0 with no output. Block disappears entirely.

```bash
#!/usr/bin/env bash
pct=$(df "$HOME" | awk 'NR==2 { gsub(/%/,""); print $5 }')
[ "${pct:-0}" -lt 80 ] && exit 0
echo "### ⚠ Disk ${pct}% full"
df -h "$HOME" | awk 'NR==1||NR==2'
```

**Amber banner** — informational notice (not a failure). Exit 0 with a `<div class="nb-alert-banner">`. Renders in the app's amber palette, no red border. `note-approved` is the reference implementation.

```bash
echo '<div class="nb-alert-banner">⚠ This note is pending approval.</div>'
```

**Scoped to current note** — use `NB_NOTEBOOK` to target the right git repo:

```bash
[ -z "$NB_NOTEBOOK" ] && exit 0
status=$(git -C "$NB_DIR/$NB_NOTEBOOK" status --short 2>/dev/null)
[ -z "$status" ] && exit 0
echo "### Uncommitted changes in \`$NB_NOTEBOOK\`"
```

### Good output anatomy #pattern

`hl-budget-has-periodic.sh` is the gold standard — read it before writing a new script.

```
### ⚠ Short description        ← always H3 + warning sign
                                ← one sentence: what's wrong and why it matters
**Fix** —                       ← concrete fix with a code block
```ledger
~ monthly ...
```

```test                         ← embedded verify block (shows pass/vanish in place)
hl-budget-include-check
```

[Open actual-filename.journal](note:/absolute/path)   ← always last line
```

**Rules:**
- Heading: always `### ⚠` (H3, warning sign, short phrase) — appears in book TOCs
- First body line: one sentence of context, no "Note:" or "Warning:" preamble
- Fix blocks: `**Fix**` or `**Fix 1**`/`**Fix 2**` with a concrete code block
- Verify block: embed the cheapest confirming test right after the fix
- Open link: last line, use the actual filename not a generic label
- No output on exit 0 — causes block to render instead of disappear #gotcha

### Reference scripts

Browse and edit in place:

````markdown
```nav
~/.nb/.test
```
````

Key reads before writing new scripts:

- `hl-budget-has-periodic.sh` — gold standard: heading, context, fix, embedded verify, open link
- `hl-ok.sh` — simplest Form 2: silent pass, one check, raw error fallback
- `hl-optional.sh` — radar sweep with `subtest:` drill-down links
- `note-approved.sh` — reference for amber `.nb-alert-banner`; reads frontmatter with awk
- `nb-dirty.sh` — `NB_NOTEBOOK` context var usage

---

## front block — implementation notes

Key lessons from the `front` codeblock (frontmatter filter/query block):

**Scope prefix parsing** — leading bare words (no colon) are notebook names; the first token containing `:` ends the notebook list and begins field:value filters. `Takeout shot:` → Takeout notebook, field `shot`. Parser: consume tokens from start until a `:` token is hit; remainder is filters.

**Pipe label parsing** — use `indexOf(' |')` (space + pipe), not `' | '` (which requires space after the pipe too). `raw.slice(pipeIdx + 2).trim()` gets the label regardless of spacing after the pipe.

**Recursive scan** — `read_index(notebook, folder)` only reads root `.index` — misses subfolders. For frontmatter queries across all notes, use `os.walk(nb_dir)` with `dirnames[:] = sorted(...)` to skip hidden dirs.

**CSS tooltips** — native `title=` attribute is ugly and browser-controlled. Use `data-tip` + CSS `::after { content: attr(data-tip); white-space: pre }` instead: instant, styled, no JS, matches theme. Standard pattern for all blocks going forward.

**`overflow:hidden` clips absolute children** — `overflow: hidden` on a block container clips absolutely-positioned tooltip children (they disappear below the fold). Fix: remove `overflow:hidden`, apply `border-radius` directly to first/last child via `:first-child`/`:last-child` selectors instead.

**Collapsible header conventions** — whole header bar is the collapse toggle (click handler on header div, not a child button). Refresh button right-justified via `margin-left: auto`. Default collapsed; restore open state via `wasOpen` flag before clearing `innerHTML`.

**API meta field** — return `{k: str(v) for k,v in meta.items()}` — stringify all values so YAML lists/dicts don't break JSON serialisation. Multiline YAML strings: collapse to single space in tooltip via `v.replace(/\n/g,' ')` in JS.

**`model: true` convention** — frontmatter key to mark exemplary/reference notes. `` ```front\nmodel:true | Model notes\n``` `` lists them across all notebooks.

---

## Access gates — implementation

User-facing behaviour: [[docs:CODEBLOCKS#Access Gates]]. Dev-security reference: [[docs:dev/dev-security.md#codeblock-gates]].

### Two gate models #pattern

**Codeblock-level gate** — the block type itself has a minimum read level in `codeblock_access`. Below that level, the block never fires: `_cbCan()` → `_cbDenyRead()` → `el.remove()` before any network request.

**Destination gate** — `nav` and `nb` have `null` read in `codeblock_access` (no tool-level gate). They fire unconditionally, but their backend endpoints enforce access by destination:
- `/api/fs/list` — dotfolders check `_DOT_OPEN` or admin+; regular notebook dirs check `_notebook_config(nb).access`
- `/api/notes` — already filtered by notebook config + per-note `access:` in `_list_notes()`

A 403 from a destination endpoint is caught in the load function and becomes `_cbDenyRead(el)` — silent removal, never an error banner. #invariant: users never see a 403 in the UI.

### Settings

`codeblock_access` in `nb-settings.json` — a passthrough dict in `_SETTINGS_SCHEMA`. Returned by `GET /api/nb-settings`. Current defaults:

```json
"codeblock_access": {
  "hledger": {"read": "office", "write": "admin"},
  "chart":   {"read": "office", "write": null},
  "tw":      {"read": "user",   "write": "user"},
  "git":     {"read": "user",   "write": null},
  "t":       {"read": "user",   "write": null},
  "test":    {"read": "user",   "write": null},
  "tui":     {"read": "user",   "write": null},
  "front":   {"read": "admin",  "write": null},
  "nav":     {"read": null,     "write": null},
  "nb":      {"read": null,     "write": null}
}
```

`null` read = destination-gated (no codeblock-level check). `null` write = no write controls exist.

### Frontend utilities (`nbweb-codeblocks.js`)

All live in the top of the IIFE, before any block-specific code:

| Function | Purpose |
|----------|---------|
| `_cbAccess` | Module-level dict, populated by a single `fetch('/api/nb-settings')` on plugin load |
| `_cbParseGates(text)` | Strips `read:` / `write:` lines from fence body; returns `{readLevel, writeLevel, query}` |
| `_cbGateAttrs(r, w)` | Produces `data-cb-read="…" data-cb-write="…"` attribute string for the block div |
| `_cbLevel(el, type, mode)` | Per-block attr wins over `_cbAccess[type][mode]` |
| `_cbCan(el, type, mode)` | `window.NbAuth?.is(level) ?? true` — fails open if auth not loaded |
| `_cbDenyRead(el)` | `el.remove()` — no trace |

### html() / render() wiring

Every `html:` function in `codeblockRenderers` calls `_cbParseGates(text)` and stores the results as `data-cb-read` / `data-cb-write` on the block div. The cleaned `query` (with gate lines removed) is stored in `data-query` / `data-cmd` / `data-period` as normal.

Every `_load*Block()` function begins with a read gate check:

```javascript
if (!_cbCan(el, 'blocktype', 'read')) { _cbDenyRead(el); return; }
```

Write buttons (`+`, `✎`) are conditionally created:

```javascript
if (_cbCan(el, 'hledger', 'write')) {
    const addBtn = ...
    acts.appendChild(addBtn);
}
```

### test block special case #pattern

Other block types auto-render so a denied read → silent removal is always correct. `test` blocks have two forms:

- **Form 2** (no label, auto-run): `el.remove()` — same as all other types
- **Form 1** (labeled button): block was explicitly surfaced by the note author; label still renders, clicking shows `🔒 Requires X access` via `_buildTestDenied(el, label, level)`

The form detection happens *before* the gate check in `_loadTestBlock` — parse label first, then decide.

### Backend enforcement

**Write endpoints** — `_cb_write_allowed(block_type)` in `app.py` reads `_settings.codeblock_access[type].write` and compares via `_level_gte()`:

- `api_hledger_add()` → 403 if insufficient
- `api_task_add()` → 403 if insufficient
- `api_task_action()` → 403 if insufficient

**Destination listing** — `/api/fs/list` enforces access by the path's first component:
- Dotfolder not in `_DOT_OPEN` → admin+
- Regular notebook dir → `_notebook_config(name).get('access', 'user')`

Frontend codeblock gate is UX; backend is the actual lock. #invariant

### 403 → silent removal #pattern

Any 403 from a destination endpoint in a load function must call `_cbDenyRead(el)` and return, not render an error. The user never learns the resource exists.

```javascript
const r = await fetch(`/api/fs/list?path=${encodeURIComponent(rawPath)}`);
if (r.status === 403) { _cbDenyRead(el); return; }
```

Applied in `_loadNavBlock` (rawPath and notebook paths) and `_loadFrontBlock`. Any new load function that calls a listing or content endpoint should follow this pattern.

---

## mkd-codeblocks

`NbWeb-codeblocks` is nb-web's implementation of the [mkd-codeblocks](https://github.com/linuxcaffe/mkd-codeblocks) project — a collection of independently distributable live-query widgets designed as self-contained drop-ins for any markdown note app.

The `hledger` block is already released as a standalone package ([hledger-codeblock](https://github.com/linuxcaffe/hledger-codeblock)). The others (`tw`, `nb`, `git`, `t`, `nav`, `front`, `test`) are planned for extraction as the project matures.
