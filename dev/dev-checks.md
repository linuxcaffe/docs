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

## Virtual checks — `checks:` config key #implemented #pattern

Virtual checks inject Type-1 check fences automatically at render time. No fence needed in
the note body — the config chain provides them.

### Where to set it

```yaml
# In ~/.nb/.nb.md (global — fires on every note everywhere)
checks: nb-

# In ~/.nb/accts/.accts.md (notebook — fires on every accts: note)
checks: hl-entry-day

# In ~/.nb/accts/guide/.guide.md (folder — fires on every note in guide/)
checks: hl-

# In any individual note's frontmatter (per-note override)
checks: hl-entry-week
```

Resolution: note FM wins, then folder config walk-up (innermost first), then notebook
config, then global. Same chain as `access:`.

### Values

| Value | Effect |
|-------|--------|
| `hl-` | All scripts with prefix `hl-` (trailing-dash glob) |
| `hl-entry-day` | Exact script name |
| `[nb-, hl-]` | Multiple prefixes — one Type-1 fence per entry |
| `checks:` (bare) | `null` — suppresses inherited checks |
| `checks: ""` | Empty string — suppresses inherited checks |

### Suppression

A child config or note can silence inherited checks by setting `checks:` to null or empty:

```yaml
# In a folder config — suppresses notebook-level checks for this folder only
checks:
# or equivalently (see gotcha below):
checks: ""
```

> #gotcha **Prefer `checks:` (bare) over `checks: ""`** — the manual YAML fallback parser
> (used when pyyaml is unavailable) reads `checks: ""` as the literal string `'""'`, which
> is not empty and not null. The suppression check misses it and tries to run `""` as a
> script name. `checks:` (bare null) parses to `''` in both paths and suppresses reliably.

### How it works (frontend)

`_virtualTestPrefix(note)` in `main.js`:
1. Skips if `note.meta.type === 'dotfile'` — config files are the source, not consumers
2. Reads `note.meta.checks` (per-note FM) if present; else `note.effective_checks` (from backend)
3. Normalises to array of prefix strings; empty/null → returns `''`
4. Returns `` ```check\n{prefix}\n``` `` fences joined by newline, prepended to `note.body`

The fences are prepended to `note.body` before `_renderMarkdown`. The codeblock renderer
hydrates them as Type-1 blocks (auto-run, silent on pass).

### How it works (backend)

`GET /api/note` returns `effective_checks: nb_meta.get('checks')` where `nb_meta` is the
full `_folder_config(notebook, fpath)` result — the same merged chain used for
`effective_access`. Both fields travel together in the note response.

### Type 1 vs Type 2

Virtual checks are always **Type 1** (auto-run, no label, silent on pass). They are
invisible when passing — they only surface on failure. This is deliberate: a dashboard
with `checks: hl-` should look clean 99% of the time and only shout when something breaks.

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

## nb-web automated test suite #planned

Unit tests, integration tests, and CI pipeline documentation will live here when the
suite is established.
