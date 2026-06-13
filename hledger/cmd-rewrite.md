---
title: hledger rewrite
---

# hledger rewrite

rewrite [OPTIONS] [QUERY] --add-posting "ACCT AMTEXPR" ...
Print all transactions, rewriting the postings of matched transactions.
For now the only rewrite available is adding new postings, like print

```
  --auto.
```

Flags:

```
     --add-posting='ACCT  AMTEXPR'  add a posting to ACCT, which may be
                                    parenthesised. AMTEXPR is either a literal
                                    amount, or *N which means the transaction's
                                    first matched amount multiplied by N (a
                                    decimal number). Two spaces separate ACCT
                                    and AMTEXPR.
     --diff                         generate diff suitable as an input for
                                    patch tool
```

General input flags:
-f --file=[FMT:]FILE Use this as the journal file (- means
stdin). If not specified, $LEDGER_FILE or
~/.hledger.journal will be used. If
specified more than once, the files will be
read in order. Each file's format (journal,
csv, timeclock, timedot, rules..) is
inferred from the file extension or a FMT:
prefix. Some commands (add, import) write
to the (first) file, and expect it to be in
journal format.

```
     --rules=RULESFILE              Use rules defined in this rules file for
                                    converting subsequent CSV/SSV/TSV files. If
                                    not specified, uses FILE.csv.rules for each
                                    FILE.csv.
     --alias=A=B|/RGX/=RPL          transform account names from A to B, or
                                    by replacing regular expression matches
     --auto                         generate extra postings by applying auto
                                    posting rules ("=") to all transactions
     --forecast[=PERIOD]            Generate extra transactions from periodic
                                    rules ("~"), from after the latest ordinary
                                    transaction until 6 months from now. Or,
                                    during the specified PERIOD (the equals is
                                    required). Auto posting rules will also be
                                    applied to these transactions. In
                                    hledger-ui, also make future-dated
                                    transactions visible at startup.
```
-I --ignore-assertions don't check balance assertions by default

```
     --txn-balancing=...            how to check that transactions are
                                    balanced:
                                    'old':   - use global display precision
                                    'exact': - use transaction precision
                                    (default)
     --infer-costs                  infer conversion equity postings from
                                    costs
     --infer-equity                 infer costs from conversion equity
                                    postings
     --infer-market-prices          infer market prices from costs
     --pivot=TAGNAME                use a different field or tag as account
                                    names
```
-s --strict do extra error checks (and override -I)

```
     --verbose-tags                 add tags indicating generated/modified
                                    data
```

General output flags (affecting some commands):
-b --begin=DATE include postings/transactions on/after
this date
-e --end=DATE include postings/transactions before this
date (with a report interval, will be
adjusted to following subperiod end)
-D --daily set report interval: 1 day
-W --weekly set report interval: 1 week
-M --monthly set report interval: 1 month
-Q --quarterly set report interval: 1 quarter
-Y --yearly set report interval: 1 year
-p --period=PERIODEXP set begin date, end date, and/or report
interval, with more flexibility

```
     --today=DATE                   override today's date (affects relative
                                    dates)
     --date2                        match/use secondary dates instead
                                    (deprecated)
```
-U --unmarked include only unmarked
postings/transactions
-P --pending include only pending
postings/transactions
-C --cleared include only cleared
postings/transactions
(-U/-P/-C can be combined)
-R --real include only non-virtual postings
-E --empty Show zero items, which are normally
hidden.
In hledger-ui & hledger-web, do the
opposite.

```
     --depth=DEPTHEXP               if a number (or -NUM): show only top NUM
                                    levels of accounts. If REGEXP=NUM, only
                                    apply limiting to accounts matching the
                                    regular expression.
```
-B --cost convert amounts to their cost/sale amount
(@/@@)
-V --market valuation mode: show amounts converted to
market value at period end(s) in their
default valuation commodity. Short for

```
                                    --value=end.
```
-X --exchange=COMM valuation mode: show amounts converted to
market value at period end(s) in the
specified commodity. Short for

```
                                    --value=end,COMM.
     --value=WHEN[,COMM]            valuation mode: show amounts converted to
                                    market value on the specified date(s) in
                                    their default valuation commodity or a
                                    specified commodity. WHEN can be:
                                    'then':     value on transaction dates
                                    'end':      value at period end(s)
                                    'now':      value today
                                    YYYY-MM-DD: value on given date
```
-c --commodity-style=S Override a commodity's display style.
Eg: -c '$1000.' or -c '1.000,00 EUR'

```
     --pretty[=YN]                  Use box-drawing characters in text
                                    output? The optional 'y'/'yes' or 'n'/'no'
                                    arg requires =.
```

General help flags:
-h --help show command line help

```
     --tldr                         show command examples with tldr
     --info                         show the manual with info
     --man                          show the manual with man
     --version                      show version information
     --debug=[1-9]                  show this much debug output (default: 1)
     --pager=YN                     use a pager when needed ? y/yes (default)
                                    or n/no
     --color=YNA --colour           use ANSI color ? y/yes, n/no, or auto
                                    (default)
```

This is a start at a generic rewriter of transaction entries. It reads
the default journal and prints the transactions, like print, but adds
one or more specified postings to any transactions matching QUERY. The
posting amounts can be fixed, or a multiplier of the existing
transaction's first posting amount.

Examples:

$ hledger-rewrite.hs ^income --add-posting '(liabilities:tax) *.33 ; income
tax' --add-posting '(reserve:gifts) $100'
$ hledger-rewrite.hs expenses:gifts --add-posting '(reserve:gifts) *-1"'
$ hledger-rewrite.hs -f rewrites.hledger

rewrites.hledger may consist of entries like:

= ^income amt:<0 date:2017
(liabilities:tax) *0.33 ; tax on income
(reserve:grocery) *0.25 ; reserve 25% for grocery
(reserve:) *0.25 ; reserve 25% for grocery

Note the single quotes to protect the dollar sign from bash, and the two
spaces between account and amount.

More:

$ hledger rewrite [QUERY] --add-posting "ACCT AMTEXPR" ...
$ hledger rewrite ^income --add-posting '(liabilities:tax) *.33'
$ hledger rewrite expenses:gifts --add-posting '(budget:gifts) *-1"'
$ hledger rewrite ^income --add-posting '(budget:foreign currency)
*0.25 JPY; diversify'

Argument for --add-posting option is a usual posting of transaction with
an exception for amount specification. More precisely, you can use '*'
(star symbol) before the amount to indicate that that this is a factor
for an amount of original matched posting. If the amount includes a
commodity name, the new posting amount will be in the new commodity;
otherwise, it will be in the matched posting amount's commodity.

Re-write rules in a file

During the run this tool will execute so called "Automated Transactions"
found in any journal it process. I.e instead of specifying this
operations in command line you can put them in a journal file.

$ rewrite-rules.journal

Make contents look like this:

= ^income
(liabilities:tax) *.33

= expenses:gifts
budget:gifts *-1
assets:budget *1

Note that '=' (equality symbol) that is used instead of date in
transactions you usually write. It indicates the query by which you want
to match the posting to add new ones.

$ hledger rewrite -f input.journal -f rewrite-rules.journal >
rewritten-tidy-output.journal

This is something similar to the commands pipeline:

$ hledger rewrite -f input.journal '^income' --add-posting '(liabilities:tax)
*.33' \
| hledger rewrite -f - expenses:gifts --add-posting 'budget:gifts *-1'
\

```
                                                --add-posting 'assets:budget
                                                *1'       \
```
> rewritten-tidy-output.journal

It is important to understand that relative order of such entries in
journal is important. You can re-use result of previously added
postings.

Diff output format

To use this tool for batch modification of your journal files you may
find useful output in form of unified diff.

$ hledger rewrite --diff -f examples/sample.journal '^income' --add-posting
'(liabilities:tax) *.33'

Output might look like:

--- /tmp/examples/sample.journal
+++ /tmp/examples/sample.journal
@@ -18,3 +18,4 @@
2008/01/01 income
- assets:bank:checking $1
+ assets:bank:checking $1
income:salary
+ (liabilities:tax) 0
@@ -22,3 +23,4 @@
2008/06/01 gift
- assets:bank:checking $1
+ assets:bank:checking $1
income:gifts
+ (liabilities:tax) 0

If you'll pass this through patch tool you'll get transactions
containing the posting that matches your query be updated. Note that
multiple files might be update according to list of input files
specified via --file options and include directives inside of these
files.

Be careful. Whole transaction being re-formatted in a style of output
from hledger print.

See also:

https://github.com/simonmichael/hledger/issues/99

rewrite vs. print --auto

This command predates print --auto, and currently does much the same
thing, but with these differences:

- with multiple files, rewrite lets rules in any file affect all other
files. print --auto uses standard directive scoping; rules affect only
child files.

- rewrite's query limits which transactions can be rewritten; all are
printed. print --auto's query limits which transactions are printed.

- rewrite applies rules specified on command line or in the journal.
print --auto applies rules specified in the journal.
