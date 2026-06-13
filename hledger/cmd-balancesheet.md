---
title: hledger balancesheet
---

# hledger balancesheet

balancesheet [OPTIONS] [QUERY]
Show the end balances in asset and liability accounts. Amounts are shown
with normal positive sign, as in conventional financial statements.

Flags:

```
     --sum                  calculation mode: show sum of posting amounts
                            (default)
     --valuechange          calculation mode: show total change of value of
                            period-end historical balances (caused by deposits,
                            withdrawals, market price fluctuations)
     --gain                 calculation mode: show unrealised capital
                            gain/loss (historical balance value minus cost
                            basis)
     --count                calculation mode: show the count of postings
     --change               accumulation mode: accumulate amounts from column
                            start to column end (in multicolumn reports)
     --cumulative           accumulation mode: accumulate amounts from report
                            start (specified by e.g. -b/--begin) to column end
```
-H --historical accumulation mode: accumulate amounts from
journal start to column end (includes postings
before report start date) (default)
-l --flat list/tree mode: show accounts as a flat list
(default). Amounts exclude subaccount amounts,
except where the account is depth-clipped.
-t --tree list/tree mode: show accounts as a tree. Amounts
include subaccount amounts.

```
     --drop=N               in list mode, omit N leading account name parts
     --declared             include non-parent declared accounts (best used
                            with -E)
```
-A --average show a row average column (in multicolumn
reports)
-T --row-total show a row total column (in multicolumn reports)

```
     --summary-only         display only row summaries (e.g. row total,
                            average) (in multicolumn reports)
```
-N --no-total omit the final total row

```
     --no-elide             in tree mode, don't squash boring parent accounts
     --format=FORMATSTR     use this custom line format (in simple reports)
```
-S --sort-amount sort by amount instead of account code/name
-% --percent express values in percentage of each column's
total

```
     --layout=ARG           how to show multi-commodity amounts:
                            'wide[,WIDTH]': all commodities on one line
                            'tall'        : each commodity on a new line
                            'bare'        : bare numbers, symbols in a column
     --base-url=URLPREFIX   in html output, generate hyperlinks to
                            hledger-web, with this prefix. (Usually the base
                            url shown by hledger-web; can also be relative.)
```
-O --output-format=FMT select the output format. Supported formats:
txt, html, csv, tsv, json.
-o --output-file=FILE write output to FILE. A file extension matching
one of the above formats selects that format.

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

This command displays a balance sheet, showing historical ending
balances of asset and liability accounts. (To see equity as well, use
the balancesheetequity command.)

Accounts declared with the Asset, Cash or Liability type are shown (see
account types). Or if no such accounts are declared, it shows top-level
accounts named asset or liability (case insensitive, plurals allowed)
and their subaccounts.

Example:

$ hledger balancesheet
Balance Sheet 2008-12-31

|| 2008-12-31
====================++============
Assets ||
--------------------++------------
assets:bank:saving || $1
assets:cash || $-2
--------------------++------------
|| $-1
====================++============
Liabilities ||
--------------------++------------
liabilities:debts || $-1
--------------------++------------
|| $-1
====================++============
Net: || 0

This command is a higher-level variant of the balance command, and
supports many of that command's features, such as multi-period reports.
It is similar to hledger balance -H assets liabilities, but with smarter
account detection, and liabilities displayed with their sign flipped.

This command also supports the output destination and output format
options The output formats supported are txt, csv, tsv (Added in 1.32),
html, and json.
