---
title: hledger check
---

# hledger check

check [OPTIONS] [CHECKS]
Check for various kinds of errors in your data.


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

hledger provides a number of built-in correctness checks to help
validate your data and prevent errors. Some are run automatically, some
when you enable --strict mode; or you can run any of them on demand by
providing them as arguments to the check command. check produces no
output and a zero exit code if all is well. Eg:

hledger check # run basic checks
hledger check -s # run basic and strict checks
hledger check ordereddates payees # run basic checks and two others

If you are an Emacs user, you can also configure flycheck-hledger to run
these checks, providing instant feedback as you edit the journal.

Here are the checks currently available. They are generally checked in
the order they are shown here, and only the first failure will be
reported.

Basic checks

These important checks are performed by default, by almost all hledger
commands:

- parseable - data files are in a supported format, with no syntax
errors and no invalid include directives. This ensures that all files
exist and are readable.

- autobalanced - all transactions are balanced, after automatically
inferring missing amounts and conversion rates and then converting
amounts to cost. This ensures that each transaction's journal entry is
well formed.

- assertions - all balance assertions in the journal are passing.
Balance assertions are a strong defense against errors, catching many
problems. This check is on by default, but if it gets in your way, you
can disable it temporarily with -I/--ignore-assertions, or as a
default by adding that flag to your config file. (Then use -s/--strict
or hledger check assertions when you want to enable it).

Strict checks

When the -s/--strict flag is used (AKA strict mode), all commands will
perform the following additional checks (and assertions, above). These
provide extra error-catching power to help you keep your data clean and
correct:

- balanced - like autobalanced, but implicit conversions between
commodities are not allowed; all conversion transactions must use cost
notation or equity postings. This prevents wrong conversions caused by
typos.

- commodities - all commodity symbols used must be declared. This guards
against mistyping or omitting commodity symbols.

- accounts - all account names used must be declared. This prevents the
use of mis-spelled or outdated account names.

Other checks

These are not wanted by everyone, but can be run using the check
command:

- tags - all tags used must be declared. This prevents mis-spelled tag
names. Note hledger fairly often finds unintended tags in comments.

- payees - all payees used in transactions must be declared. This will
force you to declare any new payee name before using it. Most people
will probably find this a bit too strict.

- ordereddates - within each file, transactions must be ordered by date.
This is a simple and effective error catcher. It's not included in
strict mode, but you can add it by running
hledger check -s ordereddates. If enabled, this check is performed
before balance assertions.

- recentassertions - all accounts with balance assertions must have one
that's within the 7 days before their latest posting. This will
encourage adding balance assertions for your active asset/liability
accounts, which in turn should encourage you to reconcile regularly
with those real world balances - another strong defense against
errors. (hledger close --assert >>$LEDGER_FILE is a convenient way to
add new balance assertions. Later these become quite redundant, and
you might choose to remove them to reduce clutter.)

- uniqueleafnames - no two accounts may have the same last account name
part (eg the checking in assets:bank:checking). This ensures each
account can be matched by a unique short name, easier to remember and
to type.

Custom checks

You can build your own custom checks with add-on command scripts. See
also Cookbook > Scripting. Here are some examples from hledger/bin/:

- hledger-check-tagfiles - all tag values containing / exist as file
paths

- hledger-check-fancyassertions - more complex balance assertions are
passing
