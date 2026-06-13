---
title: hledger aregister
---

# hledger aregister

aregister [OPTIONS] ACCTPAT [QUERY]
Show the transactions and running balances in one account, with each
transaction on one line.

Flags:

```
     --txn-dates            filter strictly by transaction date, not posting
                            date. Warning: this can show a wrong running
                            balance.
     --no-elide             don't show only 2 commodities per amount
     --cumulative           accumulation mode: show running total from report
                            start date
```
-H --historical accumulation mode: show historical running
total/balance (includes postings before report
start date) (default)

```
     --invert               display all amounts with reversed sign
     --heading=YN           show heading row above table: yes (default) or no
```
-w --width=N set output width (default: terminal width). -wN,M
sets description width as well.

```
     --align-all            guarantee alignment across all lines (slower)
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

aregister shows the overall transactions affecting a particular account
(and any subaccounts). Each report line represents one transaction in
this account. Transactions before the report start date are included in
the running balance (--historical mode is the default). You can suppress
this behaviour using the --cumulative option.

This is a more "real world", bank-like view than the register command
(which shows individual postings, possibly from multiple accounts, not
necessarily in historical mode). As a quick rule of thumb:

- aregister is best when reconciling real-world asset/liability accounts
- register is best when reviewing individual revenues/expenses.

Note this command's non-standard, and required, first argument; it
specifies the account whose register will be shown. You can write the
account's name, or (to save typing) a case-insensitive infix regular
expression matching the name, which selects the alphabetically first
matched account. (For example, if you have assets:personal checking and
assets:business checking, hledger areg checking would select
assets:business checking.)

Transactions involving subaccounts of this account will also be shown.
aregister ignores depth limits, so its final total will always match a
historical balance report with similar arguments.

Any additional arguments are standard query arguments, which will limit
the transactions shown. Note some queries will disturb the running
balance, causing it to be different from the account's real-world
running balance.

An example: this shows the transactions and historical running balance
during july, in the first account whose name contains "checking":

$ hledger areg checking date:jul

Each aregister line item shows:

- the transaction's date (or the relevant posting's date if different,
see below)
- the names of all the other account(s) involved in this transaction
(probably abbreviated)
- the total change to this account's balance from this transaction
- the account's historical running balance after this transaction.

Transactions making a net change of zero are not shown by default; add
the -E/--empty flag to show them.

For performance reasons, column widths are chosen based on the first
1000 lines; this means unusually wide values in later lines can cause
visual discontinuities as column widths are adjusted. If you want to
ensure perfect alignment, at the cost of more time and memory, use the
--align-all flag.

By default, aregister shows a heading above the data. However, when
reporting in a language different from English, it is easier to omit
this heading and prepend your own one. For this purpose, use the
--heading=no option.

This command also supports the output destination and output format
options. The output formats supported are txt, csv, tsv (Added in 1.32),
html, fods (Added in 1.41) and json.

aregister and posting dates

aregister always shows one line (and date and amount) per transaction.
But sometimes transactions have postings with different dates. Also, not
all of a transaction's postings may be within the report period. To
resolve this, aregister shows the earliest of the transaction's date and
posting dates that is in-period, and the sum of the in-period postings.
In other words it will show a combined line item with just the earliest
date, and the running balance will (temporarily, until the transaction's
last posting) be inaccurate. Use register -H if you need to see the
individual postings.

There is also a --txn-dates flag, which filters strictly by transaction
date, ignoring posting dates. This too can cause an inaccurate running
balance.
