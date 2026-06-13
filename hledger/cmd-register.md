---
title: hledger register
---

# hledger register

register [OPTIONS] [QUERY]
Show postings and their running total.

Flags:

```
     --cumulative           accumulation mode: show running total from report
                            start date (default)
```
-H --historical accumulation mode: show historical running
total/balance (includes postings before report
start date)
-A --average show running average of posting amounts instead
of total (implies --empty)
-m --match=DESC fuzzy search for one recent posting with
description closest to DESC
-r --related show postings' siblings instead

```
     --invert               display all amounts with reversed sign
     --sort=FIELDS          sort by: date, desc, account, amount, absamount,
                            or a comma-separated combination of these. For a
                            descending sort, prefix with -. (Default: date)
```
-w --width=N set output width (default: terminal width). -wN,M
sets description width as well.

```
     --align-all            guarantee alignment across all lines (slower)
     --base-url=URLPREFIX   in html output, generate links to hledger-web,
                            with this prefix. (Usually the base url shown by
                            hledger-web; can also be relative.)
```
-O --output-format=FMT select the output format. Supported formats:
txt, csv, tsv, html, fods, json.
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

The register command displays matched postings, across all accounts, in
date order, with their running total or running historical balance. (See
also the aregister command, which shows matched transactions in a
specific account.)

register normally shows line per posting, but note that multi-commodity
amounts will occupy multiple lines (one line per commodity).

It is typically used with a query selecting a particular account, to see
that account's activity:

$ hledger register checking
2008/01/01 income assets:bank:checking $1 $1
2008/06/01 gift assets:bank:checking $1 $2
2008/06/02 save assets:bank:checking $-1 $1
2008/12/31 pay off assets:bank:checking $-1 0

With --date2, it shows and sorts by secondary date instead.

For performance reasons, column widths are chosen based on the first
1000 lines; this means unusually wide values in later lines can cause
visual discontinuities as column widths are adjusted. If you want to
ensure perfect alignment, at the cost of more time and memory, use the
--align-all flag.

The --historical/-H flag adds the balance from any undisplayed prior
postings to the running total. This is useful when you want to see only
recent activity, with a historically accurate running balance:

$ hledger register checking -b 2008/6 --historical
2008/06/01 gift assets:bank:checking $1 $2
2008/06/02 save assets:bank:checking $-1 $1
2008/12/31 pay off assets:bank:checking $-1 0

The --depth option limits the amount of sub-account detail displayed.

The --average/-A flag shows the running average posting amount instead
of the running total (so, the final number displayed is the average for
the whole report period). This flag implies --empty (see below). It is
affected by --historical. It works best when showing just one account
and one commodity.

The --related/-r flag shows the other postings in the transactions of
the postings which would normally be shown.

The --invert flag negates all amounts. For example, it can be used on an
income account where amounts are normally displayed as negative numbers.
It's also useful to show postings on the checking account together with
the related account:

The --sort=FIELDS flag sorts by the fields given, which can be any of
account, amount, absamount, date, or desc/description, optionally
separated by commas. For example, --sort account,amount will group all
transactions in each account, sorted by transaction amount. Each field
can be negated by a preceding -, so --sort -amount will show
transactions ordered from smallest amount to largest amount.

$ hledger register --related --invert assets:checking

With a reporting interval, register shows summary postings, one per
interval, aggregating the postings to each account:

$ hledger register --monthly income
2008/01 income:salary $-1 $-1
2008/06 income:gifts $-1 $-2

Periods with no activity, and summary postings with a zero amount, are
not shown by default; use the --empty/-E flag to see them:

$ hledger register --monthly income -E
2008/01 income:salary $-1 $-1
2008/02 0 $-1
2008/03 0 $-1
2008/04 0 $-1
2008/05 0 $-1
2008/06 income:gifts $-1 $-2
2008/07 0 $-2
2008/08 0 $-2
2008/09 0 $-2
2008/10 0 $-2
2008/11 0 $-2
2008/12 0 $-2

Often, you'll want to see just one line per interval. The --depth option
helps with this, causing subaccounts to be aggregated:

$ hledger register --monthly assets --depth 1
2008/01 assets $1 $1
2008/06 assets $-1 0
2008/12 assets $-1 $-1

Note when using report intervals, if you specify start/end dates these
will be adjusted outward if necessary to contain a whole number of
intervals. This ensures that the first and last intervals are full
length and comparable to the others in the report.

With -m DESC/--match=DESC, register does a fuzzy search for one recent
posting whose description is most similar to DESC. DESC should contain
at least two characters. If there is no similar-enough match, no posting
will be shown and the program exit code will be non-zero.

Custom register output

register normally uses the full terminal width (or 80 columns if it
can't detect that). You can override this with the --width/-w option.

The description and account columns normally share the space equally
(about half of (width - 40) each). You can adjust this by adding a
description width as part of --width's argument, comma-separated:
--width W,D . Here's a diagram (won't display correctly in --help):

<--------------------------------- width (W)
---------------------------------->
date (10) description (D) account (W-41-D) amount (12) balance
(12)
DDDDDDDDDD dddddddddddddddddddd aaaaaaaaaaaaaaaaaaa AAAAAAAAAAAA
AAAAAAAAAAAA

and some examples:

$ hledger reg # use terminal width (or 80 on windows)
$ hledger reg -w 100 # use width 100
$ hledger reg -w 100,40 # set overall width 100, description width 40

This command also supports the output destination and output format
options The output formats supported are txt, csv, tsv (Added in 1.32),
and json.
