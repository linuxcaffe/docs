---
title: testing
caption: "check script naming, output model, grouping by namespace; nb-web automated suite planned"
toc: true
processed: true
---

# TESTING

> Developer documentation for nb-web. See [[docs:DEVELOPERS.md]] for the full index.

For the `check` codeblock syntax, exit codes, and context variables, see:

- [[docs:CODEBLOCKS#test — Embedded Assertions]] — syntax, bundled scripts, placement patterns, status panels
- [[docs:dev/dev-codeblocks.md#test-block-internals]] — exit code contract, context vars, writing scripts, output anatomy

---

## Test script naming convention #pattern

Test scripts live in `~/.nb/.checks/` and follow a **hierarchical namespace** using `-`
as the separator. The namespace path reads left to right from broadest to most specific:

```
hl-                     all hledger tests
hl-core-                hledger core validity (hl-core-journal, hl-core-test)
hl-entry-               posting cadence sub-group
hl-entry-day.sh         one specific daily posting check
hl-opt-                 optional checks sub-group
hl-opt-ordereddates.sh  one specific optional check
nb-                     all nb tests
sys-                    system health (disk, process, version)
```

### Trailing-dash glob #pattern

A `test` block body ending with `-` fires every script whose name starts with that prefix:

````markdown
```check
hl-entry-
```
````

fires `hl-entry-day.sh`, `hl-entry-week.sh` — the whole subgroup.

```check
hl-
```

fires every hledger test in `.checks/`. This replaces any hand-written bundler script.

### Grouping — namespace over bundled scripts #pattern

The old pattern was a wrapper script that called other scripts. **Don't do this.**
Grouping is done entirely by naming — no exceptions:

1. **Namespace prefix** — `hl-entry-` is a group. The trailing-dash glob covers it.
2. **Sub-sub-groups are encouraged** — `hl-budget-has-` is a valid group within `hl-budget-`.
3. **Codeblock cluster** — multiple `check` blocks in one note, each focused on one script.

If a conceptual subgroup emerges within an existing set, rename the scripts to reflect
it. `hl-opt-tags.sh` + `hl-opt-payees.sh` → clearly the `hl-opt-` subgroup.

---

## Preferred output model #pattern

Key properties of a well-written Form 2 check:
- **Form 2** (no label, auto-run, silent on pass) — failure output IS the signal
- **Collect all failures** before reporting — never fail-fast in a grouped test
- **Markdown output** with links to subtests and relevant files
- **`subtest:` links** — `[description](subtest:scriptname)` lets the user drill into one failure
- **`note:` links** — link to the journal or source file for quick access
- **Guard at top** — `[ ! -f "$journal" ] && exit 0` for missing prerequisites
- **Counter `n`** for the summary line: `N of M failed`

```bash
#!/usr/bin/env bash
# hl-example — Form 2: runs multiple checks; silent when all pass.

journal="${HLEDGER_FILE:-$HOME/.hledger.journal}"
[ ! -f "$journal" ] && exit 0

desc_ordereddates="transactions out of date order"
desc_recentassertions="balance assertions older than 7 days"

links=""
n=0

for check in ordereddates recentassertions; do
  result=$(hledger check "$check" -f "$journal" 2>&1)
  [ -z "$result" ] && continue
  n=$((n + 1))
  desc_var="desc_${check}"
  links="${links}- [hledger check ${check} — ${!desc_var}](subtest:hl-opt-${check})
"
done

[ "$n" -eq 0 ] && exit 0

cat << EOF
### ⚠ Checks — ${n} of 2 failed

${links}
[Open $(basename "$journal")](note:${journal})
EOF
exit 1
```

### Why this model works

- The summary line (`N of M failed`) gives immediate scope.
- `subtest:` links are clickable in the nb-web check result panel — user goes straight to the broken check with one click, without having to re-run or navigate. Use the full new script name (`hl-opt-ordereddates`, not `hl-ordereddates`).
- `note:` link opens the source file in nb-web for inspection/edit.
- Silent pass means dashboards using Form 2 stay clean; noise only appears on failure.

---

## Virtual checks — `check:`/`check_add:`/`check_skip:` config keys #implemented #pattern

> #gotcha This section previously documented a `checks:` (plural) config key throughout. That
> field name is legacy — still read as a fallback if `check:` (singular) is entirely absent
> (`nb_meta.get('check') if nb_meta.get('check') is not None else nb_meta.get('checks')`,
> `app.py`), but `check:` is what every current example, script, and the `check_add:`/
> `check_skip:` fields below actually use. Corrected 2026-07-17 while documenting
> `check-sweep.py` — see [[docs:dev/dev-check-sweep.md]].

Virtual checks inject Type-1 check fences automatically at render time. No fence needed in
the note body — the config chain provides them.

### Where to set it

```yaml
# In ~/.nb/.nb.md (global — fires on every note everywhere)
check: nb-

# In ~/.nb/accts/.accts.md (notebook — fires on every accts: note)
check: hl-entry-day

# In ~/.nb/accts/guide/.guide.md (folder — fires on every note in guide/)
check: hl-

# In any individual note's frontmatter (per-note override)
check: hl-entry-week
```

Resolution: note FM wins, then folder config walk-up (innermost first), then notebook
config, then global. Same chain as `access:`.

### `check_add:` and `check_skip:` — union and subtract, never override

`check:` at any level in the chain **replaces** whatever came before it — the note FM's own
`check:` wins outright over the notebook's, with no way to add to it. `check_add:` and
`check_skip:` exist for exactly that case: both **union across every level of the chain**
(global + notebook + folder + note), rather than the innermost value replacing outer ones.

```yaml
# notebook dotfile
check: [hl-, syntax-]
check_skip: [hl-]   # union from any level; a note in this notebook can ALSO add its own check_skip:
```

`check_skip:` supports the same trailing-dash family-prefix matching as `check:` itself — a
skip entry ending in `-` matches any token that equals it or starts with it, not just an exact
name.

### Values

| Value | Effect |
|-------|--------|
| `hl-` | All scripts with prefix `hl-` (trailing-dash glob) |
| `hl-entry-day` | Exact script name |
| `[nb-, hl-]` | Multiple prefixes — one Type-1 fence per entry |
| `check:` (bare) | `null` — suppresses inherited checks |
| `check: ""` | Empty string — suppresses inherited checks |

### Suppression

A child config or note can silence inherited checks by setting `check:` to null or empty:

```yaml
# In a folder config — suppresses notebook-level checks for this folder only
check:
# or equivalently (see gotcha below):
check: ""
```

> #gotcha **Prefer `check:` (bare) over `check: ""`** — the manual YAML fallback parser
> (used when pyyaml is unavailable) reads `check: ""` as the literal string `'""'`, which
> is not empty and not null. The suppression check misses it and tries to run `""` as a
> script name. `check:` (bare null) parses to `''` in both paths and suppresses reliably.

### How it works (frontend)

`_virtualTestPrefix(note)` in `main.js`:
1. Reads `note.meta.check` (per-note FM) if present; else `note.effective_checks` (from backend)
2. Unions in `note.meta.check_add`/`note.effective_check_add` from every level of the chain
3. Subtracts `note.meta.check_skip`/`note.effective_check_skip` (trailing-dash family matching)
4. Normalises to array of prefix strings; empty/null → returns `''`
5. Returns `` ```check\n{prefix}\n``` `` fences joined by newline, prepended to `note.body`

The fences are prepended to `note.body` before `_renderMarkdown`. The codeblock renderer
hydrates them as Type-1 blocks (auto-run, silent on pass).

### How it works (backend)

`GET /api/note` returns `effective_checks` (`nb_meta.get('check')`, falling back to the legacy
`nb_meta.get('checks')` only if `check` is entirely absent), `effective_check_add`, and
`effective_check_skip`, where `nb_meta` is the full `_folder_config(notebook, fpath)` result —
the same merged chain used for `effective_access`. All three fields travel together in the note
response.

### Type 1 vs Type 2

Virtual checks are always **Type 1** (auto-run, no label, silent on pass). They are
invisible when passing — they only surface on failure. This is deliberate: a dashboard
with `check: hl-` should look clean 99% of the time and only shout when something breaks.

If you need a labeled button (Type 2), put the block explicitly in the note body.

---

## Script environment #pattern

Every check script receives the full Flask process environment plus these nb-web additions:

| Variable | Example | Description |
|----------|---------|-------------|
| `NB_DIR` | `/home/djp/.nb` | Root nb notebooks directory |
| `NB_APP_DIR` | `/home/djp/dev/nb-web` | Flask app directory — use to locate `nb-settings.json` etc. |
| `NB_NOTEBOOK` | `accts` | Current notebook name (empty if no note context) |
| `NB_NOTE_PATH` | `/home/djp/.nb/accts/2025.md` | Absolute path to current note file (empty if none) |
| `NB_NOTE_SELECTOR` | `accts:42` | nb selector for current note (empty if none) |
| `NO_COLOR` | `1` | Suppresses ANSI colour in subprocesses |

Guard pattern — exit silently if required context is absent:

```bash
if [ -z "$NB_NOTEBOOK" ]; then exit 0; fi
nb_path="$NB_DIR/$NB_NOTEBOOK"
if [ ! -d "$nb_path" ]; then exit 0; fi
```

---

## Exit codes and severity #pattern

| Code | Colour | Border | Use when |
|------|--------|--------|----------|
| `0` | — | none | Pass — no output, block removed |
| `1` | red | solid red | Error — action required |
| `2` | amber | solid amber | Warn — advisory, non-urgent |

---

## Response package header #pattern

The first line of stdout may be a `#!` metadata line. The renderer strips it before display:

```bash
echo '#! fix:nb-sync-add-remote'
echo '**Notebook unwired** — no git remote, sync disabled.'
exit 2
```

`fix:script-name` appends an inline `[→ run fix](subtest:script-name)` link to the output. Other keys are reserved for future use.

---

## Snooze — `check_timeout:` FM key #pattern

When a note has `check_timeout: 10` in its frontmatter, the dismiss button becomes a snooze button. Clicking it suppresses that check for 10 minutes (stored in `localStorage`). Auto-runs silently skip snoozed checks; button-triggered runs always fire.

The script is unaware of snooze state — the renderer handles it entirely.

---

## Rendering behaviour — pending state and grouped display #pattern

**No pending spinner.** Placeholder `.nb-test-block` divs (one per resolved `check:` token)
start empty and are hidden via `.nb-test-block:empty { display: none; }` — nothing is shown
while a check's fetch is in flight. A silent pass never becomes visible at all; a failure's
output pops into place, once, at the block's existing position (top of the note body, where
`_virtualTestPrefix` spliced the fences in). This replaced an earlier version that set a
`⟳` spinner synchronously before the fetch — harmless for a real button, but for the common
silent-auto-run case it meant every check flashed a line+spinner and then collapsed, even
checks that were skipped for that note. (`plugins/nbweb-codeblocks.js` `_loadTestBlock`)

**Grouped failures start collapsed.** A multi-script `check` block (dangling-dash glob or
an explicit multi-line group) that produces failures renders a header row
(`.nb-group-headrow`) — fold arrow, optional domain icon, "N of M checks failed", dismiss
`×` pinned to the row's right edge via flex layout (not absolute positioning, which used to
drift out of alignment against the bordered/padded group box). The list of individual
failing scripts (`.nb-group-body`) starts **hidden** — click the header to expand it. This
keeps a note with many independent check families from stacking a wall of expanded failures
above the fold; each family collapses to one line until the user asks to see more.
(`_runGroupTest`)

**Domain icon hoisting.** `_checkDomainIcon(script)` is computed for every failing script in
the group. If every failure shares the same icon (e.g. an `hl-` glob where several hledger
checks fail), it's hoisted once onto the header line instead of repeated on every subtest
row — a "12 of 23 failed" group doesn't need the same logo 12 times. Mixed-domain groups
(explicit multi-script blocks combining prefixes) keep the per-row icons, since there the
icon is the only thing distinguishing one failing script's family from another's.

---

## nb-web automated test suite #planned

Unit tests, integration tests, and CI pipeline documentation will live here when the
suite is established.
