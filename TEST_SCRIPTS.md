---
title: TEST_SCRIPTS
caption: Writing test scripts for the nb-web test codeblock
toc: true
---

# Test Scripts

The `test` codeblock runs bash scripts from `~/.nb/.test/` — embedding live system checks directly in notes. See [[CODEBLOCKS#test — Embedded Assertions|CODEBLOCKS]] for the codeblock syntax.

---

## How It Works

Scripts are called with no arguments. They receive context about the current note as environment variables. Exit code and stdout together determine what the note displays:

| Exit code | stdout | Result |
|---|---|---|
| 0 | empty | **Invisible** (Form 2) or silent reset (Form 1) |
| 0 | has content | Output rendered as markdown |
| non-zero | anything | Output rendered as markdown with red left border |

Output is rendered as full markdown — headings, tables, lists, blockquotes, `{{hledger: query}}` inline expressions, `[[wikilinks]]`, `term:` links, and `note:` links all work.

---

## Script Location

All scripts live in `~/.nb/.test/`. Browse them with:

````markdown
```nav
~/.nb/.test
```
````

Scripts are resolved by name — `.sh` extension is optional:

```test
hl-ok        # finds ~/.nb/.test/hl-ok.sh
hl-ok.sh     # same
```

---

## Context Variables

Every script receives these environment variables:

| Variable | Example value | Notes |
|---|---|---|
| `NB_DIR` | `/home/djp/.nb` | nb root directory |
| `NB_NOTE_SELECTOR` | `accts:guide/review.md` | Currently open note |
| `NB_NOTEBOOK` | `accts` | Notebook portion of selector |
| `NB_NOTE_PATH` | `/home/djp/.nb/accts/guide/review.md` | Absolute path to note file |

Scripts that touch hledger should resolve the journal explicitly — Flask's subprocess environment may not match a login shell:

```bash
journal="${HLEDGER_FILE:-$HOME/.hledger.journal}"
[ ! -f "$journal" ] && exit 0
hledger bal -f "$journal" ...
```

---

## Writing Scripts

### Passing silently

Exit 0 with no output. The block disappears from the note entirely (Form 2).

```bash
#!/usr/bin/env bash
# Pass silently when disk is healthy
pct=$(df "$HOME" | awk 'NR==2 { gsub(/%/,""); print $5 }')
[ "${pct:-0}" -lt 80 ] && exit 0
echo "### ⚠ Disk ${pct}% full"
df -h "$HOME" | awk 'NR==1||NR==2'
```

### Markdown output

Scripts can output any markdown — headings, tables, blockquotes, inline code. The rendered output blends with note content.

```bash
echo "| Account | Balance |"
echo "|---|---:|"
hledger bal -f "$journal" --flat --depth 1 -O csv --no-total \
  | tail -n +2 \
  | while IFS=, read -r acct amt _; do
      echo "| \`${acct//\"/}\` | ${amt//\"/} |"
    done
echo ""
echo "> *as of $(date '+%Y-%m-%d')*"
```

### Scoped to current note

Use `NB_NOTEBOOK` to scope checks to the notebook the note lives in:

```bash
[ -z "$NB_NOTEBOOK" ] && exit 0
nb_path="$NB_DIR/$NB_NOTEBOOK"
[ ! -d "$nb_path/.git" ] && exit 0
status=$(git -C "$nb_path" status --short 2>/dev/null)
[ -z "$status" ] && exit 0
echo "### Uncommitted changes in \`$NB_NOTEBOOK\`"
echo '```'
echo "$status"
echo '```'
```

---

## Bundled Scripts

| Script | Form | Purpose |
|---|---|---|
| `hl-test` | 2 | hledger binary self-test; silent when all 245 pass; surfaces failing test names |
| `hl-ok` | 2 | Silent when journal is clean; shows `hledger check` errors |
| `hl-strict` | 2 | `hledger check --strict`; explains undeclared commodity errors |
| `hl-optional` | 2 | Radar sweep — all 5 optional checks; silent when all pass |
| `hl-ordereddates` | 2 | Transactions out of date order within a file |
| `hl-recentassertions` | 2 | Balance assertions older than 7 days; guides reconciliation |
| `hl-tags` | 2 | Undeclared tag names (opt-in strict check) |
| `hl-payees` | 2 | Undeclared payees (opt-in strict check) |
| `hl-uniqueleafnames` | 2 | Two accounts share a leaf name (opt-in strict check) |
| `hl-budget-has-periodic` | 2 | Guides setup if no `~ monthly` rules found |
| `hl-budget-balanced` | 2 | Detects unbalanced budget transactions; computes fix amount |
| `hl-budget-include-check` | 2 | Verifies periodic journal is included in main journal |
| `hl-budget-has-actuals` | 2 | Checks that actual transactions exist to compare against budget |
| `hl-budget-has-income` | 2 | Checks that income postings exist in the budget |
| `hl-budget-runs` | 2 | Verifies `hledger bal --budget` runs without error |
| `nb-dirty` | 2 | Silent when committed; lists dirty files in current notebook |
| `note-disk-warn` | 2 | Silent under 80% disk usage; warns above that |
| `note-slow` | 2 | Silent for fast notes; notice (no red border) when file >50 KB or ≥5 inline includes |
| `tw-due` | 2 | Silent with no due tasks; lists overdue/today tasks |
| `hl-recent-txn` | 1 | `hl-recent-txn \| Recent transactions` — last 14 days from journal |
| `note-context` | 1 | `note-context \| Note context` — markdown table of all context vars |
| `hl-balances` | 1 | `hl-balances \| Account balances` — depth-1 balance table |

Browse and edit them in-place:

````markdown
```nav
~/.nb/.test
```
````

---

## Placement Patterns

**Health dashboard** — drop Form 2 checks at the top of a hub note. They're invisible when everything is fine; they surface when something needs attention:

```markdown
{{test: hl-ok}}
{{test: nb-dirty}}
{{test: note-disk-warn}}
{{test: tw-due}}

# My Hub Note
...
```

Wait — the syntax is a fenced block, not an inline expression. Correct form:

````markdown
```test
hl-ok
```

```test
nb-dirty
```
````

**On-demand reference** — Form 1 in a journal note or guide section:

````markdown
```test
hl-recent-txn | Recent transactions
```

```test
hl-balances | Account balances
```
````

**Invisible guardrail** — embed a check in a setup or onboarding note. New users see the error; experienced users with everything configured see nothing:

````markdown
```test
hl-ok
```

## Your Journal
...
````

---

## Status Panels

The most powerful pattern: a dedicated `status.md` note containing only Form 2 test blocks, included at the top of any note via `{{inline:}}`.

```markdown
{{inline: accts:status.md}}

# My Note
...
```

`status.md` has **zero visual footprint** when everything is healthy — the inline renders nothing, and the note appears exactly as if the line wasn't there. The moment any test fails, its output surfaces right at the top of whatever note you happen to be reading.

Because `{{inline:}}` runs the full rendering pipeline on included content, test blocks in `status.md` receive the **host note's context** — `NB_NOTEBOOK` reflects the notebook you're currently in, so `nb-dirty` reports on the right notebook automatically.

### Creating a status file

A status file is just a note with tightly-packed Form 2 blocks and nothing else:

````markdown
```test
hl-ok
```
```test
nb-dirty
```
```test
note-disk-warn
```
````

No headings, no prose — the file should be entirely invisible when healthy. Give it a name that makes its scope clear: `status.md`, `accts:status.md`, `home:status.md`.

### Scoped status files

Different notebooks have different concerns. Include the right status file in each context:

```markdown
{{inline: accts:status.md}}     ← hledger journal health, uncommitted accts changes
{{inline: home:status.md}}      ← disk space, overdue tasks, nb-dirty for home
```

Or include multiple in a master hub note to get a unified view across all concerns.

### The key insight

You would never know a note had a status panel until errors started appearing. The diagnostic layer is woven into the note invisibly — no separate dashboard to remember to check, no polling, no notification system. The note itself becomes aware of problems in its context.

---

## Good Test Output

A well-written Form 2 script is invisible when everything is fine and informative when it isn't. These conventions make failure output consistent, readable, and actionable.

### Anatomy of a good error block

**`hl-budget-has-periodic.sh`** is the reference example — read it before writing a new script.

````markdown
### ⚠ Short description of the problem

One sentence: what is wrong and why it matters. No preamble, no "note that".

**Fix** — what to do, named specifically:

```ledger
~ monthly from 2025-01-01
    Expenses:Food   CAD 800
    [Budget]
```

If a second fix exists, name it **Fix 2** with a concrete example.

An embedded block lets the user verify the fix without leaving the note:

```test
hl-budget-include-check
```

[Open actual-filename.journal](note:/absolute/path/to/file)
````

### Rules

**Heading** — always `### ⚠` (H3, warning sign, space, short phrase). This is what appears in book TOCs.

**First line of body** — one sentence of context. Why does this matter? What breaks if you ignore it? No "Note:" or "Warning:".

**Fix blocks** — `**Fix**` or `**Fix 1**` / `**Fix 2**` for alternatives. Always include a concrete code block. `ledger` fence for journal snippets; `bash` for shell commands.

**Verify block** — if there is a cheaper test that confirms the fix worked, embed it as a `test` block right after the fix. The user sees it pass (and vanish) in the same note.

**Open link — last line** — always end with `[Open actual-filename.ext](note:/absolute/path)`. Use `$(basename "$journal")` to show the real filename, not a generic label like "journal". The link lets the user jump directly to the file they need to edit.

**Related files at the bottom** — when a note documents this design, link to the scripts themselves so the reader can read the reference implementation.

### What to avoid

- Long preambles or repeated context before the fix
- Generic `[Open journal](note:...)` — use the actual filename
- Skipping the verify block when a quick check exists
- Output on exit 0 (causes the block to render instead of disappear)

---

## Test Script Files

Browse and edit all scripts in place:

````markdown
```nav
~/.nb/.test
```
````

Key scripts — read these for reference before writing new ones:

- [hl-test.sh](note:/home/djp/.nb/.test/hl-test.sh) — "is the tool intact?" check; complements hl-ok which checks data, not binary
- [hl-ok.sh](note:/home/djp/.nb/.test/hl-ok.sh) — simplest Form 2: silent pass, one check, raw error fallback
- [hl-strict.sh](note:/home/djp/.nb/.test/hl-strict.sh) — multiple fix options (A/B/C), handles bare-number commodity `""`
- [hl-optional.sh](note:/home/djp/.nb/.test/hl-optional.sh) — radar sweep of all 5 optional checks; surfaces failures, defers to individual scripts for fixes
- [hl-ordereddates.sh](note:/home/djp/.nb/.test/hl-ordereddates.sh) — out-of-order date check; explains secondary-date workaround
- [hl-recentassertions.sh](note:/home/djp/.nb/.test/hl-recentassertions.sh) — stale assertion check; shows `hledger close --assert` workflow
- [hl-tags.sh](note:/home/djp/.nb/.test/hl-tags.sh) — undeclared tags; warns about accidental tags in comments
- [hl-payees.sh](note:/home/djp/.nb/.test/hl-payees.sh) — undeclared payees; links to `payees` command for discovery
- [hl-uniqueleafnames.sh](note:/home/djp/.nb/.test/hl-uniqueleafnames.sh) — duplicate leaf names; shows grep to find all affected postings
- [hl-budget-has-periodic.sh](note:/home/djp/.nb/.test/hl-budget-has-periodic.sh) — gold standard: heading, context, fix block, embedded verify, open link
- [hl-budget-balanced.sh](note:/home/djp/.nb/.test/hl-budget-balanced.sh) — computes fix amount, shows mtime so user knows if edit landed
- [hl-budget-include-check.sh](note:/home/djp/.nb/.test/hl-budget-include-check.sh) — used as an embedded verify block inside hl-budget-has-periodic
- [nb-dirty.sh](note:/home/djp/.nb/.test/nb-dirty.sh) — uses `NB_NOTEBOOK` context var; scoped to current notebook
- [note-disk-warn.sh](note:/home/djp/.nb/.test/note-disk-warn.sh) — minimal Form 2 shown in the Writing Scripts section above
- [note-slow.sh](note:/home/djp/.nb/.test/note-slow.sh) — informational notice (exit 0, no red border) for large files or books with many chapters
- [hl-recent-txn.sh](note:/home/djp/.nb/.test/hl-recent-txn.sh) — Form 1 (label, on-demand); markdown table output
- [hl-balances.sh](note:/home/djp/.nb/.test/hl-balances.sh) — Form 1 with table and blockquote timestamp

---

## Books — the diagnostic TOC

When Form 2 test blocks are embedded in chapter notes inside a `type: book`, something remarkable happens: failing checks produce `### ⚠ Heading` output that gets picked up by the book's TOC rebuild. The table of contents becomes simultaneously a chapter navigator and a live health dashboard — diagnostic entries appear in the navigation, positioned exactly where the problem lives in the document.

A healthy book shows a clean TOC. A book with configuration problems shows `⚠` entries inline with chapter headings. No separate dashboard, no extra code — it's an emergent property of the test + inline + TOC pipeline.

See [[BOOKS]] for the full pattern, design guidance, and The Bookkeeper's Guide as a worked example.
