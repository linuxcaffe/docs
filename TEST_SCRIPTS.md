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

Output is rendered as full markdown — headings, tables, lists, blockquotes, `{{hledger: query}}` inline expressions, `[[wikilinks]]`, and `term:` links all work.

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
hledger-ok        # finds ~/.nb/.test/hledger-ok.sh
hledger-ok.sh     # same
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
| `hledger-ok` | 2 | Silent when journal is clean; shows `hledger check` errors |
| `nb-dirty` | 2 | Silent when committed; lists dirty files in current notebook |
| `disk-warn` | 2 | Silent under 80% disk usage; warns above that |
| `tw-due` | 2 | Silent with no due tasks; lists overdue/today tasks |
| `recent-txn` | 1 | `recent-txn \| Recent transactions` — last 14 days from journal |
| `note-context` | 1 | `note-context \| Note context` — markdown table of all context vars |
| `hledger-balances` | 1 | `hledger-balances \| Account balances` — depth-1 balance table |

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
{{test: hledger-ok}}
{{test: nb-dirty}}
{{test: disk-warn}}
{{test: tw-due}}

# My Hub Note
...
```

Wait — the syntax is a fenced block, not an inline expression. Correct form:

````markdown
```test
hledger-ok
```

```test
nb-dirty
```
````

**On-demand reference** — Form 1 in a journal note or guide section:

````markdown
```test
recent-txn | Recent transactions
```

```test
hledger-balances | Account balances
```
````

**Invisible guardrail** — embed a check in a setup or onboarding note. New users see the error; experienced users with everything configured see nothing:

````markdown
```test
hledger-ok
```

## Your Journal
...
````
