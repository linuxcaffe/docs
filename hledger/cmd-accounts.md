---
title: hledger accounts
---

# hledger accounts

accounts [OPTIONS] [QUERY..]
List the account names used or declared in the journal.

Flags:
-u --used list accounts used
-d --declared list accounts declared

```
     --undeclared           list accounts used but not declared
     --unused               list accounts declared but not used
     --find                 list the first account matched by the first
                            argument (a case-insensitive infix regexp)
     --directives           show as account directives, for use in journals
     --locations            also show where accounts were declared
     --types                also show account types when known
```
-l --flat list/tree mode: show accounts as a flat list
(default)
-t --tree list/tree mode: show accounts as a tree

```
     --drop=N               flat mode: omit N leading account name parts
```

General input flags:
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

General output flags (affecting some commands):
-b --begin=DATE include postings/transactions on/after this date
-e --end=DATE include postings/transactions before this date
(with a report interval, will be adjusted to
following subperiod end)
-D --daily set report interval: 1 day
-W --weekly set report interval: 1 week
-M --monthly set report interval: 1 month
-Q --quarterly set report interval: 1 quarter
-Y --yearly set report interval: 1 year
-p --period=PERIODEXP set begin date, end date, and/or report interval,
with more flexibility

```
     --today=DATE           override today's date (affects relative dates)
     --date2                match/use secondary dates instead (deprecated)
```
-U --unmarked include only unmarked postings/transactions
-P --pending include only pending postings/transactions
-C --cleared include only cleared postings/transactions
(-U/-P/-C can be combined)
-R --real include only non-virtual postings
-E --empty Show zero items, which are normally hidden.
In hledger-ui & hledger-web, do the opposite.

```
     --depth=DEPTHEXP       if a number (or -NUM): show only top NUM levels
                            of accounts. If REGEXP=NUM, only apply limiting to
                            accounts matching the regular expression.
```
-B --cost convert amounts to their cost/sale amount (@/@@)
-V --market valuation mode: show amounts converted to market
value at period end(s) in their default valuation
commodity. Short for --value=end.
-X --exchange=COMM valuation mode: show amounts converted to market
value at period end(s) in the specified commodity.
Short for --value=end,COMM.

```
     --value=WHEN[,COMM]    valuation mode: show amounts converted to market
                            value on the specified date(s) in their default
                            valuation commodity or a specified commodity. WHEN
                            can be:
                            'then':     value on transaction dates
                            'end':      value at period end(s)
                            'now':      value today
                            YYYY-MM-DD: value on given date
```
-c --commodity-style=S Override a commodity's display style.
Eg: -c '$1000.' or -c '1.000,00 EUR'

```
     --pretty[=YN]          Use box-drawing characters in text output? The
                            optional 'y'/'yes' or 'n'/'no' arg requires =.
```

General help flags:
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

This command lists account names - all of them by default, or just the
ones which have been used in transactions (-u/--used), or declared with
account directives (-d/--declared), or used but not declared
(--undeclared), or declared but not used (--unused), or just the first
one matched by a pattern (--find, returning a non-zero exit code if it
fails).

You can add query arguments to select a subset of transactions or
accounts.

With --directives, it shows valid account directives which could be
pasted into a journal file. This is useful together with --undeclared
when updating your account declarations to satisfy
hledger check accounts.

With --locations, it also shows the file and line number of each
account's declaration, if any, and the account's overall declaration
order; these may be useful when troubleshooting account display order.

With --types, it also shows each account's type, if it's known. (See
Declaring accounts > Account types.)

It shows a flat list by default. With --tree, it uses indentation to
show the account hierarchy. In flat mode you can add --drop N to omit
the first few account name components. Account names can be
depth-clipped with depth:N or --depth N or -N.

Examples:

$ hledger accounts
assets:bank:checking
assets:bank:saving
assets:cash
expenses:food
expenses:supplies
income:gifts
income:salary
liabilities:debts

$ hledger accounts --undeclared --directives >> $LEDGER_FILE
$ hledger check accounts
