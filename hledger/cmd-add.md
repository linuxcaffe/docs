---
title: hledger add
---

# hledger add

add [OPTIONS] [-f JOURNALFILE] [DATE [DESCRIPTION [ACCOUNT1 [ETC..]]]]]
Add new transactions to a journal file, with interactive prompting.

Flags:

```
     --no-new-accounts      don't allow creating new accounts
```

General flags:
-f --file=[FMT:]FILE Use this as the journal file (- means stdin). If
not specified, $LEDGER_FILE or ~/.hledger.journal
will be used. If specified more than once, the
files will be read in order. Each file's format
(journal, csv, timeclock, timedot, rules..) is
inferred from the file extension or a FMT: prefix.
Some commands (add, import) write to the (first)
file, and expect it to be in journal format.

```
     --rules=RULESFILE      Use rules defined in this rules file for
                            converting subsequent CSV/SSV/TSV files. If not
                            specified, uses FILE.csv.rules for each FILE.csv.
     --alias=A=B|/RGX/=RPL  transform account names from A to B, or by
                            replacing regular expression matches
     --auto                 generate extra postings by applying auto posting
                            rules ("=") to all transactions
     --forecast[=PERIOD]    Generate extra transactions from periodic rules
                            ("~"), from after the latest ordinary transaction
                            until 6 months from now. Or, during the specified
                            PERIOD (the equals is required). Auto posting rules
                            will also be applied to these transactions. In
                            hledger-ui, also make future-dated transactions
                            visible at startup.
```
-I --ignore-assertions don't check balance assertions by default

```
     --txn-balancing=...    how to check that transactions are balanced:
                            'old':   - use global display precision
                            'exact': - use transaction precision (default)
     --infer-costs          infer conversion equity postings from costs
     --infer-equity         infer costs from conversion equity postings
     --infer-market-prices  infer market prices from costs
     --pivot=TAGNAME        use a different field or tag as account names
```
-s --strict do extra error checks (and override -I)

```
     --verbose-tags         add tags indicating generated/modified data
```
-h --help show command line help

```
     --tldr                 show command examples with tldr
     --info                 show the manual with info
     --man                  show the manual with man
     --version              show version information
     --debug=[1-9]          show this much debug output (default: 1)
     --pager=YN             use a pager when needed ? y/yes (default) or n/no
     --color=YNA --colour   use ANSI color ? y/yes, n/no, or auto (default)
```

Many hledger users edit their journals directly with a text editor, or
generate them from CSV. For more interactive data entry, there is the
add command, which prompts interactively on the console for new
transactions, and appends them to the main journal file (which should be
in journal format). Existing transactions are not changed. This is one
of the few hledger commands that writes to the journal file (see also
import).

To use it, just run hledger add and follow the prompts. You can add as
many transactions as you like; when you are finished, enter . or press
control-d or control-c to exit.

Features:

- add tries to provide useful defaults, using the most similar (by
description) recent transaction (filtered by the query, if any) as a
template.
- You can also set the initial defaults with command line arguments.
- Readline-style edit keys can be used during data entry.
- The tab key will auto-complete whenever possible - accounts,
payees/descriptions, dates (yesterday, today, tomorrow). If the input
area is empty, it will insert the default value.
- A parenthesised transaction code may be entered following a date.
- Comments and tags may be entered following a description or amount.
- If you make a mistake, enter < at any prompt to go one step backward.
- Input prompts are displayed in a different colour when the terminal
supports it.

Notes:

- If you enter a number with no commodity symbol, and you have declared
a default commodity with a D directive, you might expect add to add
this symbol for you. It does not do this; we assume that if you are
using a D directive you prefer not to see the commodity symbol
repeated on amounts in the journal.
- add creates entries in journal format; it won't work with timeclock or
timedot files.

Examples:

- Record new transactions, saving to the default journal file:

hledger add

- Add transactions to 2024.journal, but also load 2023.journal for
completions:

hledger add --file 2024.journal --file 2023.journal

- Provide answers for the first four prompts:

hledger add today 'best buy' expenses:supplies '$20'

There is a detailed tutorial at https://hledger.org/add.html.

add and balance assertions

Since hledger 1.43, you can add a balance assertion by writing
AMOUNT = BALANCE when asked for an amount. Eg 100 = 500.

Also, each time you enter a new amount, hledger re-checks all balance
assertions in the journal and rejects the new amount if it would make
any of them fail. You can run add with -I/--ignore-assertions to disable
balance assertion checking.

add and balance assignments

Since hledger 1.51, you can add a balance assignment by writing
= BALANCE (or ==, =* etc) when asked for an amount. The missing amount
will be calculated automatically.

add normally won't let you add a new posting which is dated earlier than
an existing balance assignment. (Because when add runs, existing balance
assignments have already been calculated and converted to amounts and
balance assertions.) You can allow it by disabling balance assertion
checking with -I.
