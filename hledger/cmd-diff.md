---
title: hledger diff
---

# hledger diff

diff [OPTIONS] -f FILE1 -f FILE2 FULLACCOUNTTNAME
Compares a particular account's transactions in two input files. It
shows any transactions to this account which are in one file but not in
the other.


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

More precisely: for each posting affecting this account in either file,
this command looks for a corresponding posting in the other file which
posts the same amount to the same account (ignoring date, description,
etc).

Since it compares postings, not transactions, this also works when
multiple bank transactions have been combined into a single journal
entry.

This command is useful eg if you have downloaded an account's
transactions from your bank (eg as CSV data): when hledger and your bank
disagree about the account balance, you can compare the bank data with
your journal to find out the cause.

Examples:

$ hledger diff -f $LEDGER_FILE -f bank.csv assets:bank:giro
These transactions are in the first file only:

2014/01/01 Opening Balances
assets:bank:giro EUR ...
...
equity:opening balances EUR -...

These transactions are in the second file only:
