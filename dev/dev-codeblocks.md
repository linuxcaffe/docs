---
title: codeblocks
caption: Codeblock renderer internals — architecture, external blocks, mkd-codeblocks
toc: true
---

# CODEBLOCKS (dev)

Developer reference for the codeblock renderer system. For user-facing codeblock docs see [[docs:CODEBLOCKS]]. For writing check scripts see [[docs:dev/dev-checks.md]].

---

## Architecture

Codeblock renderers are registered via the `codeblockRenderers` extension point in any NbWeb plugin. See [[docs:PLUGINS#codeblockRenderers]] for the full API.

The skeleton/hydrate pattern applies to all blocks:
- `html(text)` — synchronous placeholder stamped at markdown parse time
- `render(container)` — async hydration after the DOM is ready

All block renderers wire into `NbWeb.statusPill` for render progress tracking. See [[docs:RENDER_PIPELINE#_StatusPill]] for the pill API.

---

## "." current-location awareness #pattern

Several block types accept **`.`** as a shorthand for the current note's location, resolved at render time via `NbMain?.activeSelector?.()`.

| Block | `.` resolves to | Implementation |
|-------|----------------|----------------|
| `nav` | Current note's `notebook:folder` | `_navParseQuery(raw, currentSelector)` — exact `raw === '.'` branch |
| `fm` | Current notebook (scope prefix) | `_frontParseQuery(raw, currentSelector)` — dot token in notebook list |
| `git` | Current notebook (repo name) | Inline in `_loadGitBlock` before fetch |
| `cfg` | Current note's `notebook:folder/` | `_configParseQuery(raw, currentSelector)` — `!target \|\| target === '.'` |
| `gallery` | Current note's folder | `selector` param passed to `/api/gallery` with `path=.` |

**Selector extraction pattern** (used by `nav`, `fm`, `git`):
```javascript
const sel = NbMain?.activeSelector?.() || '';
const colon = sel.indexOf(':');
const notebook = colon >= 0 ? sel.slice(0, colon) : '';
const rel      = colon >= 0 ? sel.slice(colon + 1) : '';
const folder   = rel.split('/').length > 1 ? rel.split('/').slice(0, -1).join('/') : '';
```

**YAML gotcha** — any FM-mode codeblock query ending with `:` (e.g. `cfg: . access:`) is invalid YAML: PyYAML treats the trailing `:` as a nested mapping indicator and throws, silently falling back to the dumb line-split parser. Quote the value: `cfg: ". access:"`. #gotcha

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

A script can output `[label](subtest:scriptname)` in its markdown. Renders as a toggle row; click fetches and expands the named script's output inline — no pre-run. Use the full script name including subgroup: `(subtest:hl-opt-ordereddates)`, not `(subtest:hl-ordereddates)`.

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

```check                         ← embedded verify block (shows pass/vanish in place)
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

### `term:` links in output #planned

Test output goes through the full render pipeline — `term:` links work there exactly as they do in regular notes. A script can embed a one-click fix command alongside the `note:` open link:

```
[Apply in editor](term:$EDITOR%20${HLEDGER_FILE})
[Open budget.journal](note:/home/djp/.nb/...)    ← still last line
```

The `term:` URL must be percent-encoded. Generate it in bash:

```bash
cmd="hledger -f $journal check budget"
encoded=$(python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))" "$cmd")
echo "[Verify now](term:${encoded})"
```

Good candidates: open-in-editor, run-checker-after-fix, single-command remediation. Not for multi-step or destructive commands — those belong in prose. #pattern

### Reference scripts

Browse and edit in place:

````markdown
```nav
~/.nb/.test
```
````

Key reads before writing new scripts:

- `hl-budget-has-periodic.sh` — gold standard: heading, context, fix, embedded verify, open link
- `hl-core-journal.sh` — simplest Form 2: silent pass, one check, raw error fallback
- `hl-opt-*.sh` — the `hl-opt-` subgroup; `subtest:` drill-down links show the pattern
- `note-approved.sh` — reference for amber `.nb-alert-banner`; reads frontmatter with awk
- `nb-dirty.sh` — `NB_NOTEBOOK` context var usage

---

## gallery block — implementation notes

**Backend (`/api/gallery`):** Three path modes — walk-up (no `path` param), here-only (`path=.`), explicit (`path=nb:rel/`). Walk-up stops at `NB_DIR` boundary (`d.relative_to(NB_DIR)` raises `ValueError`). Returns `{'images': []}` for missing folders — no error, just an empty list — so the frontend can vanish cleanly.

**`_GALLERY_IMAGE_EXTS`** — module-level frozenset. Skips dotfiles and non-image extensions. `classify()` is not used here because the gallery lists files directly from the filesystem, not via nb's index.

**Frontend `_loadGalleryBlock(el)`:** parses `data-query` as `<size> [path]` with a single `indexOf(' ')` split. Fetches `/api/gallery?selector=<activeSelector>&path=<pathArg>`. Empty result → `el.innerHTML = ''` → block vanishes completely (no header, no spinner).

**`wasCollapsed` preservation** — same pattern as `_loadFrontBlock`: reads `el.classList.contains('nb-collapsed')` before clearing innerHTML, restores the class after building. `_initCollapseToggle` then reads localStorage to apply the persisted state.

**Lightbox `_galleryLightbox(images, activeUrl)`** — appended to `document.body`, not the block. `cur` index wraps with `((idx % len) + len) % len`. The `keydown` listener checks `document.getElementById('nb-gallery-lb')` on every key event — if the lightbox was removed (click-outside), the listener self-cleans on next key press rather than needing a MutationObserver.

**FM-mode + `.` path** — `gallery: med .` in frontmatter injects the block into `#nb-fm-blocks` via `_buildFmBlocks`. The empty-result vanish means the block is completely invisible on dashboards until an `images/` folder exists. No placeholder, no error state needed.

**Collapse key** — `_collapseKey` uses `block.dataset.query` (the raw fence text, e.g. `"med ."`) as the localStorage key. Different size/path combinations are independent collapse states.

---

## fm block — implementation notes

Key lessons from the `fm` codeblock (frontmatter filter/query block):

**Scope prefix parsing** — leading bare words (no colon) are notebook names; the first token containing `:` ends the notebook list and begins field:value filters. `Takeout shot:` → Takeout notebook, field `shot`. Parser: consume tokens from start until a `:` token is hit; remainder is filters.

**Pipe label parsing** — use `indexOf(' |')` (space + pipe), not `' | '` (which requires space after the pipe too). `raw.slice(pipeIdx + 2).trim()` gets the label regardless of spacing after the pipe.

**Recursive scan** — `read_index(notebook, folder)` only reads root `.index` — misses subfolders. For frontmatter queries across all notes, use `os.walk(nb_dir)` with `dirnames[:] = sorted(...)` to skip hidden dirs.

**CSS tooltips** — native `title=` attribute is ugly and browser-controlled. Use `data-tip` + CSS `::after { content: attr(data-tip); white-space: pre }` instead: instant, styled, no JS, matches theme. Standard pattern for all blocks going forward.

**`overflow:hidden` clips absolute children** — `overflow: hidden` on a block container clips absolutely-positioned tooltip children (they disappear below the fold). Fix: remove `overflow:hidden`, apply `border-radius` directly to first/last child via `:first-child`/`:last-child` selectors instead.

**Collapsible header conventions** — whole header bar is the collapse toggle (click handler on header div, not a child button). Refresh button right-justified via `margin-left: auto`. Default collapsed; restore open state via `wasOpen` flag before clearing `innerHTML`.

**API meta field** — return `{k: str(v) for k,v in meta.items()}` — stringify all values so YAML lists/dicts don't break JSON serialisation. Multiline YAML strings: collapse to single space in tooltip via `v.replace(/\n/g,' ')` in JS.

**`model: true` convention** — frontmatter key to mark exemplary/reference notes. `` ```fm\nmodel:true | Model notes\n``` `` lists them across all notebooks.

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
  "hl":    {"read": "office", "write": "admin"},
  "chart": {"read": "office", "write": null},
  "tw":    {"read": "user",   "write": "user"},
  "git":   {"read": "user",   "write": null},
  "t":     {"read": "user",   "write": null},
  "test":  {"read": "user",   "write": null},
  "tui":   {"read": "user",   "write": null},
  "fm":    {"read": "admin",  "write": null},
  "nav":   {"read": null,     "write": null},
  "nb":    {"read": null,     "write": null}
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
if (_cbCan(el, 'hl', 'write')) {
    const addBtn = ...
    acts.appendChild(addBtn);
}
```

### render() vs renderOne() for different behaviour #pattern

Most renderers use the same private loader for both paths: `render(container)` iterates body blocks and calls `_loadXBlock(el)`, while `renderOne(el)` is the same call routed through the FM lazy expand. Same function, two call sites.

The `timedot` renderer breaks this pattern intentionally — body and FM need genuinely different UIs:

```javascript
{
    lang: 'timedot',
    renderOne: async el => _loadTimedotBlock(el),    // FM: aggregate summary + filter
    render: async container => {
        ...blocks.map(el => _loadTimedotRawBlock(el)) // body: verbatim + ✎ inline edit
    },
}
```

Use this split when a block type has semantically different display needs in body vs FM context. The body block is data-entry; the FM block is overview. Same source format, different viewer.

### _CB_ICONS — text, image, and emoji variants

Block icons are defined in `_CB_ICONS` at the top of the IIFE:

```javascript
const _CB_ICONS = {
    hl:      { img: '.images:hledger-logo.png', alt: 'hledger' },  // image
    nav:     { text: 'NAV' },                                       // text chip
    timedot: { text: '⏱', emoji: true },                           // emoji
};
```

| Spec field | CSS class added | Renders as |
|------------|----------------|-----------|
| `img:` | `nb-cb-icon` (img element) | Logo image at 1.2em |
| `text:` only | `nb-cb-icon` (span) | Monospace chip with border, 0.65em |
| `text:` + `large: true` | + `nb-cb-icon--large` | Serif italic, 1.1em, no border |
| `text:` + `emoji: true` | + `nb-cb-icon--emoji` | Default font, 1.1em, no border |

Use `emoji: true` for any icon that is a Unicode emoji — it disables the monospace chip styling and lets the emoji render at a readable size.

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

Applied in `_loadNavBlock` (rawPath and notebook paths) and `_loadFmBlock`. Any new load function that calls a listing or content endpoint should follow this pattern.

---

## cfg block internals

User-facing syntax: [[docs:CODEBLOCKS#cfg — Config Inheritance Tree]].

**Endpoint:** `GET /api/config-tree?notebook=X&folder=Y&key=Z&selector=S`

Returns an ordered array of nodes from global root → target → note. Each node:
```json
{ "level": "global|notebook|folder|subfolder|note",
  "path": "/abs/path/.shots.md",
  "selector": "/abs/path/.shots.md",
  "exists": true,
  "contributes": { "key": "value", ... } }
```

`contributes` holds **only what that file itself sets** — not inherited values. The `key` param filters to a single field; the API returns `{key: value}` or `{}` per node. Inheritance is implied by position — the UI never shows inherited values explicitly.

The `note` level (appended last, highest priority) is the currently open note's own frontmatter. Pass `?selector=accts:16` to include it. Note-level node uses the selector as its display name, not the raw path.

**Selector:** absolute path for config files. `/api/note` handles absolute-path selectors via `elif selector.startswith('/')` — dotfiles open normally in the preview pane.

**`_configParseQuery(raw, currentSelector)`** — parses the codeblock body:
- `field: .` → key=field, notebook+folder resolved from `NbMain.activeSelector()`
- `field: Notebook:folder/` → key=field, explicit target
- bare → key='', target='.', resolves from active selector

**`NbMain.activeSelector()`** — accessed as bare `NbMain` (not `window.NbMain`) since `const NbMain` in `main.js` is not a `window` property. #gotcha

**Rendering — table layout** (`_configRender`): four columns — marker, icon (depth-indented), path/selector, value. Value column always rendered; `—` in muted gray when a level doesn't set the queried key. True column alignment via `<table border-collapse: collapse>`, not flex.

**Effective marker** (`▶` amber): the last node in the array (highest priority) that contributes the queried key. When no key specified, the deepest existing node. `◉` blue when `currentSelector` matches a node exactly (viewing a config file that has its own `config` block).

**`access: guest` in `.nb.md`** — global floor set to `guest`. Every notebook and folder gates up from there; the `cfg` block makes the chain visible and shows where the effective value comes from. #invariant

---

## test glob internals

User-facing syntax: [[docs:CODEBLOCKS#test — Embedded Assertions]] § Form 4.

**Endpoint:** `GET /api/test/glob?prefix=nb-schem-`

Returns sorted list of `*.sh` filenames in `~/.nb/.checks/` matching `{prefix}*.sh`. Prefix must end with `-` (enforced server-side). Returns `[]` if `TEST_DIR` doesn't exist.

**JS resolution:** `_resolveTestGlob(prefix)` — async fetch, returns `[]` on any error. Called lazily at render time (not during `_collectAutoRunScripts`), so glob blocks don't block the batch pre-collection phase.

**Naming convention:** `{app}-{family}-{check}.sh` where:
- `{app}` = domain prefix (`nb-`, `hl-`, `tw-`, `note-`)
- `{family}` = sub-group (`config`, `schem`, `ref`, `struct`)
- `{check}` = specific check name
- Dangling dash `nb-schem-` globs the family; `nb-` globs the whole domain

**`_collectAutoRunScripts`** skips glob lines (ends with `-`) — they can't be pre-batched without a network round trip. Glob blocks resolve their script list lazily in `_loadTestBlock` instead.

---

## FM-mode — implementation

**Concept:** any registered codeblock lang can be promoted out of the note body into the `#nb-fm-blocks` strip by declaring it as a frontmatter key. The field value becomes the block query.

**HTML slot:** `<div id="nb-fm-blocks" hidden></div>` — sits between `#nb-toc-bar` and `#nb-preview-content` in `index.html`. Hidden whenever the toolbar is hidden (editor, spreadsheet, PDF).

**Sibling CSS hide rule:**
```css
#nb-preview-toolbar[hidden] ~ * ~ #nb-fm-blocks { display: none !important; }
```
`~` matches any later sibling; the two-step form is explicit about the structure (toc-bar is the intermediate sibling).

### Lazy render-on-demand #pattern

FM blocks load their content **on first expand only** — no API calls fire at note-load time for collapsed blocks. This keeps note switching fast when a note has many FM blocks.

**Flow:**

1. `_buildFmBlocks` calls `r.html(query)` for each FM key → skeleton `<div class="nb-{lang}-block">` in DOM.
2. If the renderer has `renderOne`, `NbWeb.fmUtils.buildFmSkeleton(block, lang)` replaces the spinner with a real barblock header (correct icon, `…` in meta) and sets `data-fm-lazy='1'`.
3. Block starts collapsed (unless `nb-fm:…` key says it was open last session).
4. First click to expand → `renderer.renderOne(block)` fires → loader runs, rebuilds header + body → FM tracking re-wired on the new real header.
5. Blocks that were open last session call `renderOne` immediately (async, parallel with any eager blocks).

**`renderOne(el)` — the per-block loader method** (added to each renderer in `codeblockRenderers`):

```javascript
// Simple loaders — just call the private loader directly:
renderOne: async el => _loadNavBlock(el),

// Loaders that need a requirements check:
renderOne: async el => {
    const w = await NbWeb.checkWhich('task');
    return w.found ? _loadTwBlock(el) : NbWeb.renderRequirementsCard(el, '...');
},
```

`renderOne` is only called from the FM lazy path — body codeblocks still use `render(container)` via `NbWeb.renderCodeblocks`. **Adding `renderOne` to a new renderer is required for it to participate in lazy FM loading.** Without it the block falls through to the eager path.

**`NbWeb.fmUtils.buildFmSkeleton(block, lang)`** — builds a proper barblock header (calls `_buildBarHeader` with the right `cls` alias for `cfg`, which emits `nb-config-*` CSS rather than `nb-cfg-*` to avoid conflict with the dotfile form) and sets `data-fm-lazy`. Lives in `nbweb-codeblocks.js`, exported via `NbWeb.fmUtils` so `main.js` can call it without coupling to plugin internals.

**Eager path** (renderers without `renderOne` — currently `tui`, `check`): `r.render(wrap)` is called directly per renderer, scoped to `#nb-fm-blocks`. These renderers' `querySelectorAll` calls are type-specific enough that they never accidentally pick up lazy blocks from other renderers.

**`nb-fm:${cls}:${id}` localStorage key** — tracks open/closed state per FM block. Value `'1'` = user has opened it; absent = start collapsed. Independent of the `nb-collapse:${cls}:${id}` key used by body blocks.

**`check:` is explicitly excluded** — config-chain directive, not a display block:

```javascript
if (key === 'check') continue;
```

**`toc:` is included** — `toc` now has a registered renderer (`renderOne: el => _loadTocBlock(el)`). `toc: true` adds a TOC barblock to the FM strip; `_buildToc` in `_finishRendered` sets heading IDs as a side effect but suppresses the sidebar `#nb-toc-bar` when the FM renderer is registered.

**`timedot:` FM aggregation** — when `timedot:` appears in frontmatter with no `timedot_file:` set, `_loadTimedotBlock` queries `#nb-preview-content .nb-timedot-block` (body blocks only — FM blocks live in `#nb-fm-blocks`) and concatenates their `data-src` into one aggregate. This is safe: body blocks have `data-src` populated from parse time, before FM blocks are built. The `+` add button is suppressed in this mode since there is no single write target.

---

## mkd-codeblocks

`NbWeb-codeblocks` is nb-web's implementation of the [mkd-codeblocks](https://github.com/linuxcaffe/mkd-codeblocks) project — a collection of independently distributable live-query widgets designed as self-contained drop-ins for any markdown note app.

The `hl` block is already released as a standalone package ([hledger-codeblock](https://github.com/linuxcaffe/hledger-codeblock)). The others (`tw`, `nb`, `git`, `t`, `nav`, `fm`, `test`) are planned for extraction as the project matures. The `cfg` block is nb-web-specific (config chain resolution) and is not planned for standalone release.

---

## `.lib/` block extras — help buttons and open protocol #implemented

`~/.nb/.lib/` holds two kinds of barblock extension files, auto-discovered at startup
via `/api/lib/block-extras` and stored in `_blockExtras` in the plugin.

### File naming

| Pattern | Effect |
|---------|--------|
| `help-block-{lang}-{access}.md` | Adds `?` button to that lang's barblock header |
| `open-block-{lang}-{access}.sh` | Wires title-click + `⎋` button to run the script |

Access level follows the standard five-point scale; the highest level the current user
meets wins. Scripts must be executable (`chmod +x`).

### Open protocol — script stdout decides the action

The script prints exactly one line; `_dispatchLibOpen(out)` parses the prefix:

| Output line | Action |
|-------------|--------|
| `nb:<selector>` | `NbMain.openNote(selector)` — opens note in preview pane |
| `file:<path>` | `NbMain.openNote(path)` — same, for bare filesystem paths |
| `term:<cmd>` | `NbTerminal.run(cmd)` — runs command in the PTY terminal |
| `http://…` / `https://…` | `window.open(url, '_blank')` — new browser tab |

### Title-click routing

When `_blockExtras.open[lang]` is set, the barblock's clickable title routes through
`_execLibOpen` instead of its hardcoded default. Fallback chain:

```
title click
  → lib script exists?  yes → _execLibOpen → _dispatchLibOpen
                         no → block's hardcoded default (tw-web launch, hledger-web, etc.)
```

The `⎋` button and title click call the same `_execLibOpen` function — same action,
two entry points. When a lib script handles the title, the `⎋` button becomes redundant
(but is not hidden automatically).

### Example scripts

```bash
# open-block-hl-admin.sh — open hledger journal in nb-web preview
echo "nb:accts:hledger.journal"
```

```bash
# open-block-tw-admin.sh — launch tw-web (start if needed) and open it
NB_PORT="${NB_PORT:-5001}"
result=$(curl -sf -X POST "http://localhost:${NB_PORT}/api/tw/launch" 2>/dev/null)
url=$(python3 -c "import json,sys; print(json.loads(sys.stdin.read()).get('url',''))" <<< "$result" 2>/dev/null)
[ -n "$url" ] && echo "$url" || echo "http://localhost:5000"
```

### Loading state

- **Button trigger** (`⎋`): `disabled` during fetch
- **Title trigger** (span): `nb-lib-loading` class → `opacity: 0.45; pointer-events: none`

### Journal scoping — block carries its own resolution #invariant

`_execLibOpen(trigger, lang, { journal })` accepts an optional `journal` override.
For `hl` blocks, the title-click passes `el.dataset.hlJournalSel` directly:

```javascript
if (_blockExtras?.open?.hl) {
    _execLibOpen(nameEl, 'hl', { journal: el.dataset.hlJournalSel || '' });
    return;
}
```

`el.dataset.hlJournalSel` is set at block load time from the API response
(`d.journalSelector`). It is always the authoritative journal — the same one
the codeblock queried — regardless of which note or folder the block lives in.

**Why not derive from note FM?** A note in `Takeout:reports/` may have no
`journal:` FM but its hl block correctly queries the Takeout journal (via
the hledger config chain). Reading `effective_fm.journal` on the note would
miss this and fall through to the fallback, opening the wrong journal.

**Priority in `_execLibOpen`:**
```
journalOverride (from block dataset)   ← most specific, set by loader
  ?? effective_fm.journal               ← folder config propagation
  ?? meta.journal                       ← per-note FM override  
  ?? ''                                 ← script's own fallback logic
```

**Three-tier discovery in `open-block-hl-admin.sh`:**
```
NB_JOURNAL set    → echo "nb:$NB_JOURNAL"            (direct)
NB_NOTEBOOK set   → query /api/notes?type=journal     (discovery)
fallback          → echo "nb:accts:hledger.journal"   (hardcoded)
```

`type: journal` notes (`.md` files) are discoverable; raw `.journal` files
cannot carry YAML frontmatter. Companion portal notes (like `ledger.md` in
`Takeout/accounting/`) serve as the typed entry-point.

`journal:` in `_FM_BLOCK_KEYS` — propagates from folder config down to notes
via `effective_fm`. `journal` in `_FM_TYPES` — enables `type: journal` list
indicator (📒) and slim meta treatment.
