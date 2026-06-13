---
title: hledger stats
---

# hledger stats

stats [OPTIONS] [QUERY]
Show journal and performance statistics.

Flags:
-1 show a single line of output
-v --verbose show more detailed output
-o --output-file=FILE write output to FILE.

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

The stats command shows summary information for the whole journal, or a
matched part of it. With a reporting interval, it shows a report for
each report period.

It also shows some performance statistics:

- how long the program ran for
- the number of transactions processed per second
- the peak live memory in use by the program to do its work
- the peak allocated memory as seen by the program

By default, the output is reasonably discreet; it reveals the main file
name, your activity level, and the speed of your machine.

With -v/--verbose, more details are shown: the full paths of all files,
and the names of the commodities you work with.

With -1, only one line of output is shown, in a machine-friendly
tab-separated format: the program version, the main journal file name,
and the performance stats,

The run time of stats is similar to that of a balance report.

Example:

$ hledger stats -f examples/1ktxns-1kaccts.journal
Main file : .../1ktxns-1kaccts.journal
Included files : 0
Txns span : 2000-01-01 to 2002-09-27 (1000 days)
Last txn : 2002-09-26 (7827 days ago)
Txns : 1000 (1.0 per day)
Txns last 30 days : 0 (0.0 per day)
Txns last 7 days : 0 (0.0 per day)
Payees/descriptions : 1000
Accounts : 1000 (depth 10)
Commodities : 26
Market prices : 1000
Runtime stats : 0.12 s elapsed, 8266 txns/s, 4 MB live, 16 MB alloc

$ hledger stats -1 -f examples/10ktxns-1kaccts.journal
1.50.99-g0835a2485-20251119, mac-aarch64 10ktxns-1kaccts.journal 0.66 s
elapsed 15244 txns/s 28 MB live 86 MB alloc

This command supports the -o/--output-file option (but not
-O/--output-format).
