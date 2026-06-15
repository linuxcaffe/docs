---
title: CODEBLOCKS
caption: Codeblock renderer internals — architecture, external blocks, mkd-codeblocks
toc: true
---

# CODEBLOCKS (dev)

Developer reference for the codeblock renderer system. For user-facing codeblock docs see [[CODEBLOCKS]]. For writing test scripts see [[TESTING]].

---

## Architecture

Codeblock renderers are registered via the `codeblockRenderers` extension point in any NbWeb plugin. See [[PLUGINS#codeblockRenderers]] for the full API.

The skeleton/hydrate pattern applies to all blocks:
- `html(text)` — synchronous placeholder stamped at markdown parse time
- `render(container)` — async hydration after the DOM is ready

All block renderers wire into `NbWeb.statusPill` for render progress tracking. See [[RENDER_PIPELINE#_StatusPill]] for the pill API.

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

For writing and testing scripts see [[TESTING]].

---

## mkd-codeblocks

`NbWeb-codeblocks` is nb-web's implementation of the [mkd-codeblocks](https://github.com/linuxcaffe/mkd-codeblocks) project — a collection of independently distributable live-query widgets designed as self-contained drop-ins for any markdown note app.

The `hledger` block is already released as a standalone package ([hledger-codeblock](https://github.com/linuxcaffe/hledger-codeblock)). The others (`tw`, `nb`, `git`, `t`, `nav`, `front`, `test`) are planned for extraction as the project matures.
