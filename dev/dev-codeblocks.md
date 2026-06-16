---
title: CODEBLOCKS
caption: Codeblock renderer internals — architecture, external blocks, mkd-codeblocks
toc: true
---

# CODEBLOCKS (dev)

Developer reference for the codeblock renderer system. For user-facing codeblock docs see [[docs:CODEBLOCKS]]. For writing test scripts see [[docs:dev/dev-testing]].

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

Context variables injected into every test script as environment variables:

| Variable | Value |
|---|---|
| `NB_DIR` | `~/.nb` |
| `NB_NOTE_SELECTOR` | Selector of the currently open note |
| `NB_NOTEBOOK` | Notebook portion of the selector |
| `NB_NOTE_PATH` | Absolute path to the note file |

`subtest:` links — a script can output `[label](subtest:scriptname)` in its markdown. These render as toggle rows that fetch and expand the named script's full output on click — no pre-run needed. `hl-optional` uses this pattern: runs a radar sweep of all optional hledger checks and surfaces each failure as a drill-down link.

For writing and testing scripts see [[docs:dev/dev-testing]].

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

## mkd-codeblocks

`NbWeb-codeblocks` is nb-web's implementation of the [mkd-codeblocks](https://github.com/linuxcaffe/mkd-codeblocks) project — a collection of independently distributable live-query widgets designed as self-contained drop-ins for any markdown note app.

The `hledger` block is already released as a standalone package ([hledger-codeblock](https://github.com/linuxcaffe/hledger-codeblock)). The others (`tw`, `nb`, `git`, `t`, `nav`, `front`, `test`) are planned for extraction as the project matures.
