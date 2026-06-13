---
title: hledger roi
---

# hledger roi

roi [OPTIONS] [QUERY]
Shows the time-weighted (TWR) and money-weighted (IRR) rate of return on
your investments.

Flags:

```
     --cashflow                 show all amounts that were used to compute
                                returns
     --investment=QUERY         query to select your investment transactions
     --profit-loss=QUERY --pnl  query to select profit-and-loss or
                                appreciation/valuation transactions
```

General input flags:
-f --file=[FMT:]FILE Use this as the journal file (- means stdin).
If not specified, $LEDGER_FILE or
~/.hledger.journal will be used. If specified
more than once, the files will be read in
order. Each file's format (journal, csv,
timeclock, timedot, rules..) is inferred from
the file extension or a FMT: prefix. Some
commands (add, import) write to the (first)
file, and expect it to be in journal format.

```
     --rules=RULESFILE          Use rules defined in this rules file for
                                converting subsequent CSV/SSV/TSV files. If not
                                specified, uses FILE.csv.rules for each
                                FILE.csv.
     --alias=A=B|/RGX/=RPL      transform account names from A to B, or by
                                replacing regular expression matches
     --auto                     generate extra postings by applying auto
                                posting rules ("=") to all transactions
     --forecast[=PERIOD]        Generate extra transactions from periodic
                                rules ("~"), from after the latest ordinary
                                transaction until 6 months from now. Or, during
                                the specified PERIOD (the equals is required).
                                Auto posting rules will also be applied to
                                these transactions. In hledger-ui, also make
                                future-dated transactions visible at startup.
```
-I --ignore-assertions don't check balance assertions by default

```
     --txn-balancing=...        how to check that transactions are balanced:
                                'old':   - use global display precision
                                'exact': - use transaction precision (default)
     --infer-costs              infer conversion equity postings from costs
     --infer-equity             infer costs from conversion equity postings
     --infer-market-prices      infer market prices from costs
     --pivot=TAGNAME            use a different field or tag as account names
```
-s --strict do extra error checks (and override -I)

```
     --verbose-tags             add tags indicating generated/modified data
```

General output flags (affecting some commands):
-b --begin=DATE include postings/transactions on/after this
date
-e --end=DATE include postings/transactions before this
date (with a report interval, will be adjusted
to following subperiod end)
-D --daily set report interval: 1 day
-W --weekly set report interval: 1 week
-M --monthly set report interval: 1 month
-Q --quarterly set report interval: 1 quarter
-Y --yearly set report interval: 1 year
-p --period=PERIODEXP set begin date, end date, and/or report
interval, with more flexibility

```
     --today=DATE               override today's date (affects relative
                                dates)
     --date2                    match/use secondary dates instead
                                (deprecated)
```
-U --unmarked include only unmarked postings/transactions
-P --pending include only pending postings/transactions
-C --cleared include only cleared postings/transactions
(-U/-P/-C can be combined)
-R --real include only non-virtual postings
-E --empty Show zero items, which are normally hidden.
In hledger-ui & hledger-web, do the opposite.

```
     --depth=DEPTHEXP           if a number (or -NUM): show only top NUM
                                levels of accounts. If REGEXP=NUM, only apply
                                limiting to accounts matching the regular
                                expression.
```
-B --cost convert amounts to their cost/sale amount
(@/@@)
-V --market valuation mode: show amounts converted to
market value at period end(s) in their default
valuation commodity. Short for --value=end.
-X --exchange=COMM valuation mode: show amounts converted to
market value at period end(s) in the specified
commodity. Short for --value=end,COMM.

```
     --value=WHEN[,COMM]        valuation mode: show amounts converted to
                                market value on the specified date(s) in their
                                default valuation commodity or a specified
                                commodity. WHEN can be:
                                'then':     value on transaction dates
                                'end':      value at period end(s)
                                'now':      value today
                                YYYY-MM-DD: value on given date
```
-c --commodity-style=S Override a commodity's display style.
Eg: -c '$1000.' or -c '1.000,00 EUR'

```
     --pretty[=YN]              Use box-drawing characters in text output?
                                The optional 'y'/'yes' or 'n'/'no' arg requires
                                =.
```

General help flags:
-h --help show command line help

```
     --tldr                     show command examples with tldr
     --info                     show the manual with info
     --man                      show the manual with man
     --version                  show version information
     --debug=[1-9]              show this much debug output (default: 1)
     --pager=YN                 use a pager when needed ? y/yes (default) or
                                n/no
     --color=YNA --colour       use ANSI color ? y/yes, n/no, or auto
                                (default)
```

At a minimum, you need to supply a query (which could be just an account
name) to select your investment(s) with --inv, and another query to
identify your profit and loss transactions with --pnl.

If you do not record changes in the value of your investment manually,
or do not require computation of time-weighted return (TWR), --pnl could
be an empty query (--pnl "" or --pnl STR where STR does not match any of
your accounts).

This command will compute and display the internalized rate of return
(IRR, also known as money-weighted rate of return) and time-weighted
rate of return (TWR) for your investments for the time period requested.
IRR is always annualized due to the way it is computed, but TWR is
reported both as a rate over the chosen reporting period and as an
annual rate.

Price directives will be taken into account if you supply appropriate
--cost or --value flags (see VALUATION).

Note, in some cases this report can fail, for these reasons:

- Error (NotBracketed): No solution for Internal Rate of Return (IRR).
Possible causes: IRR is huge (>1000000%), balance of investment
becomes negative at some point in time.
- Error (SearchFailed): Failed to find solution for Internal Rate of
Return (IRR). Either search does not converge to a solution, or
converges too slowly.

Examples:

- Using roi to compute total return of investment in stocks:
https://github.com/simonmichael/hledger/blob/master/examples/investing/roi-unrealised.ledger

- Cookbook > Return on Investment: https://hledger.org/roi.html

Spaces and special characters in --inv and --pnl

Note that --inv and --pnl's argument is a query, and queries could have
several space-separated terms (see QUERIES).

To indicate that all search terms form single command-line argument, you
will need to put them in quotes (see Special characters):

$ hledger roi --inv 'term1 term2 term3 ...'

If any query terms contain spaces themselves, you will need an extra
level of nested quoting, eg:

$ hledger roi --inv="'Assets:Test 1'" --pnl="'Equity:Unrealized Profit and
Loss'"

Semantics of --inv and --pnl

Query supplied to --inv has to match all transactions that are related
to your investment. Transactions not matching --inv will be ignored.

In these transactions, ROI will conside postings that match --inv to be
"investment postings" and other postings (not matching --inv) will be
sorted into two categories: "cash flow" and "profit and loss", as ROI
needs to know which part of the investment value is your contributions
and which is due to the return on investment.

- "Cash flow" is depositing or withdrawing money, buying or selling
assets, or otherwise converting between your investment commodity and
any other commodity. Example:

2019-01-01 Investing in Snake Oil
assets:cash -$100
investment:snake oil

2020-01-01 Selling my Snake Oil
assets:cash $10
investment:snake oil = 0

- "Profit and loss" is change in the value of your investment:

2019-06-01 Snake Oil falls in value
investment:snake oil = $57
equity:unrealized profit or loss

All non-investment postings are assumed to be "cash flow", unless they
match --pnl query. Changes in value of your investment due to "profit
and loss" postings will be considered as part of your investment return.

Example: if you use --inv snake --pnl equity:unrealized, then postings
in the example below would be classifed as:

2019-01-01 Snake Oil #1
assets:cash -$100 ; cash flow posting
investment:snake oil ; investment posting

2019-03-01 Snake Oil #2
equity:unrealized pnl -$100 ; profit and loss posting
snake oil ; investment posting

2019-07-01 Snake Oil #3
equity:unrealized pnl ; profit and loss posting
cash -$100 ; cash flow posting
snake oil $50 ; investment posting

IRR and TWR explained

"ROI" stands for "return on investment". Traditionally this was computed
as a difference between current value of investment and its initial
value, expressed in percentage of the initial value.

However, this approach is only practical in simple cases, where
investments receives no in-flows or out-flows of money, and where rate
of growth is fixed over time. For more complex scenarios you need
different ways to compute rate of return, and this command implements
two of them: IRR and TWR.

Internal rate of return, or "IRR" (also called "money-weighted rate of
return") takes into account effects of in-flows and out-flows, and the
time between them. Investment at a particular fixed interest rate is
going to give you more interest than the same amount invested at the
same interest rate, but made later in time. If you are withdrawing from
your investment, your future gains would be smaller (in absolute
numbers), and will be a smaller percentage of your initial investment,
so your IRR will be smaller. And if you are adding to your investment,
you will receive bigger absolute gains, which will be a bigger
percentage of your initial investment, so your IRR will be larger.

As mentioned before, in-flows and out-flows would be any cash that you
personally put in or withdraw, and for the "roi" command, these are the
postings that match the query in the--inv argument and NOT match the
query in the--pnl argument.

If you manually record changes in the value of your investment as
transactions that balance them against "profit and loss" (or "unrealized
gains") account or use price directives, then in order for IRR to
compute the precise effect of your in-flows and out-flows on the rate of
return, you will need to record the value of your investement on or
close to the days when in- or out-flows occur.

In technical terms, IRR uses the same approach as computation of net
present value, and tries to find a discount rate that makes net present
value of all the cash flows of your investment to add up to zero. This
could be hard to wrap your head around, especially if you haven't done
discounted cash flow analysis before. Implementation of IRR in hledger
should produce results that match the =XIRR formula in Excel.

Second way to compute rate of return that roi command implements is
called "time-weighted rate of return" or "TWR". Like IRR, it will
account for the effect of your in-flows and out-flows, but unlike IRR it
will try to compute the true rate of return of the underlying asset,
compensating for the effect that deposits and withdrawas have on the
apparent rate of growth of your investment.

TWR represents your investment as an imaginary "unit fund" where
in-flows/ out-flows lead to buying or selling "units" of your investment
and changes in its value change the value of "investment unit". Change
in "unit price" over the reporting period gives you rate of return of
your investment, and make TWR less sensitive than IRR to the effects of
cash in-flows and out-flows.

References:

- Explanation of rate of return
- Explanation of IRR
- Explanation of TWR
- IRR vs TWR
- Examples of computing IRR and TWR and discussion of the limitations of
both metrics
