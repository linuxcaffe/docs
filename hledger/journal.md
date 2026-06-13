---
title: hledger — Journal Format
---

## Journal cheatsheet

```
# Here is the main syntax of hledger's journal format
# (omitting extra Ledger compatibility syntax).

###############################################################################

# 1. These are comment lines, for notes or temporarily disabling things.
; They begin with # or ;

comment
Or, lines can be enclosed within "comment" / "end comment".
This is a block of
commented lines.
end comment

# Some journal entries can have semicolon comments at end of line	 ; like this
# Some of them require 2 or more spaces before the semicolon.

###############################################################################

# 2. Directives customise processing or output in some way.
# You don't need any directives to get started.
# But they can add more error checking, or change how things are displayed.
# They begin with a word, letter, or symbol.
# They are most often placed at the top, before transactions.

account assets		 ; Declare valid account names and display order.
account assets:savings	 ; A subaccount. This one represents a bank account.
account assets:checking	 ; Another. Note, 2+ spaces after the account name.
account assets:receivable	 ; Accounting type is inferred from english names,
account passifs		 ; or declared with a "type" tag, type:L
account expenses		 ; type:X
; A follow-on comment line, indented.
account expenses:rent	 ; Expense and revenue categories are also accounts.
; Subaccounts inherit their parent's type.

commodity $0.00	      ; Declare valid commodities and their display styles.
commodity 1.000,00 EUR

decimal-mark .	      ; The decimal mark used in this file (if ambiguous).

payee Whole Foods	      ; Declare a valid payee name.

tag trip		      ; Declare a valid tag name.

P 2024-03-01 AAPL $179  ; Declare a market price for AAPL in $ on this date.

include other.journal   ; Include another journal file here.

# Declare a recurring "periodic transaction", for budget/forecast reports
~ monthly	 set budget goals  ; <- Note, 2+ spaces before the description.
(expenses:rent)      $1000
(expenses:food)	$500

# Declare an auto posting rule, to modify existing transactions in reports
= revenues:consulting
liabilities:tax:2024:us	   *0.25  ; Add a tax liability & expense
expenses:tax:2024:us		  *-0.25  ; for 25% of the revenue.

###############################################################################

# 3. Transactions are what it's all about.
# They are dated events, usually movements of money between 2 or more accounts.
# They begin with a numeric date.
# Here is their basic shape:
#
# DATE DESCRIPTION    ; The transaction's date and optional description.
#	  ACCOUNT1  AMOUNT  ; A posting of an amount to/from this account, indented.
#	  ACCOUNT2  AMOUNT  ; A second posting, balancing the first.
#	  ...		    ; More if needed. Amounts must sum to zero.
#			    ; Note, 2+ spaces between account names and amounts.

2024-01-01 opening balances	  ; At the start, declare pre-existing balances this way.
assets:savings	  $10000  ; Account names can be anything. lower case is easy to type.
assets:checking	   $1000  ; assets, liabilities, equity, revenues, expenses are common.
liabilities:credit card  $-500  ; liabilities, equity, revenues balances are usually negative.
equity:start			  ; One amount can be left blank. $-10500 is inferred here.
; Some of these accounts we didn't declare above,
; so -s/--strict would complain.

2024-01-03 ! (12345) pay rent
; Additional transaction comment lines, indented.
; There can be a ! or * after the date meaning "pending" or "cleared".
; There can be a parenthesised (code) after the date/status.
; Amounts' sign shows direction of flow.
assets:checking	   $-500  ; Minus means removed from this account (credit).
expenses:rent		    $500  ; Plus means added to this account (debit).

; Keeping transactions in date order is optional (but helps error checking).

2024-01-02 Gringott's Bank | withdrawal  ; Description can be PAYEE | NOTE
assets:bank:gold	 -10 gold
assets:pouch		  10 gold

2024-01-02 shopping
expenses:clothing	   1 gold
expenses:wands	   5 gold
assets:pouch		  -6 gold

2024-01-02 receive gift
revenues:gifts	  -3 "Chocolate Frogs"	; Complex commodity symbols
assets:pouch		   3 "Chocolate Frogs"	; must be in double quotes.

2024-01-15 buy some shares, in two lots		      ; Cost can be noted.
assets:investments:2024-01-15	    2.0 AAAA @ $1.50  ; @  means per-unit cost
assets:investments:2024-01-15-02  3.0 AAAA @@ $4    ; @@ means total cost
; ^ Per-lot subaccounts are sometimes useful.
assets:checking		  $-7

2024-01-15 assert some account balances on this date
; Balances can be asserted in any transaction, with =, for extra error checking.
; Assertion txns like this one can be made with hledger close --assert --show-costs
;
assets:savings		    $0			 = $10000
assets:checking		    $0			 =   $493
assets:bank:gold		     0 gold		 =    -10 gold
assets:pouch			     0 gold		 =	4 gold
assets:pouch			     0 "Chocolate Frogs" =	3 "Chocolate Frogs"
assets:investments:2024-01-15	     0.0 AAAA		 =	2.0 AAAA @  $1.50
assets:investments:2024-01-15-02   0.0 AAAA		 =	3.0 AAAA @@ $4
liabilities:credit card	    $0			 =  $-500

2024-02-01 note some event, or a transaction not yet fully entered, on this date
; Postings are not required.

# Consistent YYYY-MM-DD date format is recommended,
# but you can use . or / and omit leading zeros if you prefer.
2024.01.01
2024/1/1

```

## Comments

Lines in the journal will be ignored if they begin with a hash (#) or a
semicolon (;). (See also Other syntax.) hledger will also ignore regions beginning with a comment line and ending with an end comment line
(or file end). Here's a suggestion for choosing between them:

• # for top-level notes

• ; for commenting out things temporarily

• comment for quickly commenting large regions (remember it's there, or

```
you might get confused)

```
Eg:

```
# a comment line
; another commentline
comment
A multi-line comment block,
continuing until "end comment" directive
or the end of the current file.
end comment

```
Some hledger entries can have same-line comments attached to them, from
; (semicolon) to end of line. See Transaction comments, Posting comments, and Account comments below.

## Transactions

Transactions are the main unit of information in a journal file. They
represent events, typically a movement of some quantity of commodities
between two or more named accounts.

Each transaction is recorded as a journal entry, beginning with a simple date in column 0. This can be followed by any of the following optional fields, separated by spaces:

• a status character (empty, !, or *)

• a code (any short number or text, enclosed in parentheses)

• a description (any remaining text until end of line or a semicolon)

• a comment (any remaining text following a semicolon until end of

```
line, and any following indented lines beginning with a semicolon)

```
• 0 or more indented posting lines, describing what was transferred and

```
the accounts involved (indented comment lines are also	 allowed,  but
not blank lines or non-indented lines).

```
Here's a simple journal file containing one transaction:

```
2008/01/01 income
assets:bank:checking   $1
income:salary	      $-1

```

## Dates

## Simple dates

Dates in the journal file use simple dates format: YYYY-MM-DD or
YYYY/MM/DD or YYYY.MM.DD, with leading zeros optional. The year may be
omitted, in which case it will be inferred from the context: the current transaction, the default year set with a Y directive, or the current date when the command is run. Some examples: 2010-01-31,
2010/01/31, 2010.1.31, 1/31.

(The UI also accepts simple dates, as well as the more flexible smart
dates documented in the hledger manual.)

## Posting dates

You can give individual postings a different date from their parent
transaction, by adding a posting comment containing a tag (see below)
like ; date:DATE. (There's also a Ledger-compatible syntax, ; [DATE],
which can be convenient.)

This is probably the best way to control posting dates precisely. Eg
in this example the expense should appear in May reports, and the deduction from checking should be reported on 6/1 for easy bank reconciliation:

```
2015/5/30
expenses:food	    $10	 ; food purchased on saturday 5/30
assets:checking	 ; bank cleared it on monday, date:6/1

$ hledger -f t.j register food
2015-05-30		      expenses:food		     $10	   $10

$ hledger -f t.j register checking
2015-06-01		      assets:checking		    $-10	  $-10

```
DATE should be a simple date; if the year is not specified it will use
the year of the transaction's date.
The date: tag must have a valid simple date value if it is present, eg
a date: tag with no value is not allowed.

## Status

Transactions (or individual postings within a transaction) can have a
status mark, which is a single character before the transaction description (or posting account name), separated from it by a space, indicating one of three statuses:

mark status
──────────────────

```
unmarked
```
! pending
* cleared

When reporting, you can filter by status with the -U/--unmarked,
-P/--pending, and -C/--cleared flags (and you can combine these, eg -UP
to match all except cleared things). Or you can use the status:, status:!, and status:* queries, or the U, P, C keys in hledger-ui.

(Note: in Ledger the "unmarked" state is called "uncleared"; in hledger
we renamed it to "unmarked" for semantic clarity.)

Status marks are optional, but can be helpful eg for reconciling with
real-world accounts. Some editor modes provide highlighting and shortcuts for working with status. Eg in Emacs ledger-mode, you can toggle
transaction status with C-c C-e, or posting status with C-c C-c.

What "uncleared", "pending", and "cleared" actually mean is up to you.
Here's one suggestion:

status meaning
──────────────────────────────────────────────────────────────────────────
uncleared recorded but not yet reconciled; needs review
pending tentatively reconciled (if needed, eg during a big reconciliation)
cleared complete, reconciled as far as possible, and considered correct

With this scheme, you would use -PC to see the current balance at your
bank, -U to see things which will probably hit your bank soon (like uncashed checks), and no flags to see the most up-to-date state of your
finances.

## Code

After the status mark, but before the description, you can optionally
write a transaction "code", enclosed in parentheses. This is a good
place to record a check number, or some other important transaction id
or reference number.

## Description

After the date, status mark and/or code fields, the rest of the line
(or until a comment is begun with ;) is the transaction's description.
Here you can describe the transaction (called the "narration" in traditional bookkeeping), or you can record a payee/payer name, or you can
leave it empty.

Transaction descriptions show up in print output and in register reports, and can be listed with the descriptions command.

You can query by description with desc:DESCREGEX, or pivot on description with --pivot desc.

## Payee and note

Sometimes people want a dedicated payee/payer field that can be queried
and checked more strictly. If you want that, you can write a | (pipe)
character in the description. This divides it into a "payee" field on
the left, and a "note" field on the right. (Either can be empty.)

You can query these with payee:PAYEEREGEX and note:NOTEREGEX, list
their values with the payees and notes commands, or pivot on payee or
note.

Note: in transactions with no | character, description, payee, and note
all have the same value. Once a | is added, they become distinct. (If
you'd like to change this behaviour, please propose it on the mail
list.)

If you want more strict error checking, you can declare the valid payee
names with payee directives, and then enforce these with hledger check
payees. (Note: because of the above, for this you'll need to ensure
every transaction description contains a | and therefore a checkable
payee name, even if it's empty.)

## Transaction comments

Text following ;, after a transaction description, and/or on indented
lines immediately below it, form comments for that transaction. They
are reproduced by print but otherwise ignored, except they may contain
tags, which are not ignored.

```
2012-01-01 something  ; a transaction comment
; a second line of transaction comment
expenses   1
assets

```

## Postings

A posting is an addition of some amount to, or removal of some amount
from, an account. Each posting line begins with at least one space or
tab (2 or 4 spaces is common), followed by:

• (optional) a status character (empty, !, or *), followed by a space

• (required) an account name (any text, optionally including single

```
spaces.  If anything follows the account name on the same  line,  the
account name must be ended by two or more spaces.)

```
• (optional) an amount

• (optional) a same-line posting comment, beginning with a semicolon

```
(;).

```
If the amount is positive, it is being added to the account; if negative, it is being removed from the account.

The posting amounts in a transaction must sum up to zero, indicating
that the inflows and outflows are equal. We call this a balanced
transaction. (You can read more about the details of transaction balancing below.)

If no amount is written, it will be calculated automatically from the
other postings in the transaction, so as to balance the transaction.
In other words, in any transaction you can leave one posting amountless
to save typing.

## Debits and credits

The traditional accounting concepts of debit and credit of course exist
in hledger, but we represent them with numeric sign. Positive and negative posting amounts represent debits and credits respectively.

You don't need to remember that, but if you would like to - eg for
helping newcomers or for talking with your accountant - here's a handy
mnemonic:

debit / plus / left / short words
credit / minus / right / longer words

## Account names

Accounts are the main way of categorising things in hledger. As in
Double Entry Bookkeeping, they can represent real world accounts (such
as a bank account), or more abstract categories such as "money spent on
food" or "money borrowed from Frank".

Account names are flexible. They may be capitalised or not; they may
contain letters, numbers, punctuation, symbols, or single spaces; they
may be in any language.

Typically we use the five traditional accounting categories as the
starting point for account names. In english they are:

assets, liabilities, equity, revenues, expenses

These will be discussed more in Account types below. In hledger docs
you may see them referred to as A, L, E, R, X for short.

## Two space delimiter

Note the two or more spaces delimiter that's sometimes required after
account names. hledger's account names, inherited from Ledger, are
very permissive; they may contain pretty much any kind of text, including single spaces and semicolons. Because of this, they must be terminated by two or more spaces if there is anything following them on the
same line. For example, if an amount, balance assignment, or same-line
comment follows an account name, they must be preceded by two or more
spaces, else they would be considered part of the account name:

```
bad:     assets:accounts receivable $10	     ; <- too close!
good:    assets:accounts receivable  $10

bad:     assets:accounts receivable =$1000     ; <- too close!
good:    assets:accounts receivable  =$1000

bad:     assets:accounts receivable ; comment.   <- too close!
good:    assets:accounts receivable  ; comment

```
This two-space delimiter appears in a few places in hledger, such as
after account names in postings or account directives; also after the
period expression in periodic transaction rules. When you are starting
out, expect it to catch you out at least once. It's annoying sometimes, but it lets us use expressive account names while still keeping
the syntax light.

## Account hierarchy

For more precise reporting, we usually divide accounts into more detailed subaccounts, subsubaccounts, and so on, by writing a full colon
between account name parts. For example, instead of writing assets and
expenses, we might write assets:bank:checking and expenses:food. From
these names hledger will infer this hierarchy of five accounts:

```
assets
assets:bank
assets:bank:checking
expenses
expenses:food

```
Or as an outline:

```
assets
bank
checking
expenses
food

```
hledger reports can summarise the account tree to any depth, so you can
make your subcategories as detailed as you like. But don't go overboard, especially when getting started; simpler categories can be less
work.

## Other account name features

Enclosing the account name in parentheses or brackets, like (expenses:food), enables a non-standard bookkeeping feature: virtual postings.

Account names can be rewritten and restructured, temporarily or permanently, by account aliases.

## Amounts

After the account name, there is usually an amount. (Remember: between
account name and amount, there must be two or more spaces.)

hledger's amount format is flexible, supporting several international
formats. Here are some examples. Amounts have a number (the "quantity"):

```
1

```
..and usually a currency symbol or commodity name (more on this below),
to the left or right of the quantity, with or without a separating
space:

```
$1
4000 AAPL
3 "green apples"

```
Amounts can be preceded by a minus sign (or a plus sign, though plus is
the default), The sign can be written before or after a left-side commodity symbol:

```
-$1
$-1

```
One or more spaces between the sign and the number are acceptable when
parsing (but they won't be displayed in output):

```
+ $1
$-      1

```
Scientific E notation is allowed:

```
1E-6
EUR 1E3

```

## Decimal marks

A decimal mark can be written as a period or a comma:

```
1.23
1,23

```
Both of these are common in international number formats, so hledger is
not biased towards one or the other. Because hledger also supports
digit group marks (eg thousands separators), this means that a number
like 1,000 or 1.000 containing just one period or comma is ambiguous.
In such cases, hledger by default assumes it is a decimal mark, and
will parse both of those as 1.

To help hledger parse such ambiguous numbers more accurately, if you
use digit group marks, we recommend declaring the decimal mark explicitly. The best way is to add a decimal-mark directive at the top of
each data file, like this:

```
decimal-mark .

```
Or you can declare it per commodity with commodity directives, described below.

hledger also accepts numbers like 10. with no digits after the decimal
mark (and will sometimes display numbers that way to disambiguate them
- see Trailing decimal marks).

## Digit group marks

In the integer part of the amount quantity (left of the decimal mark),
groups of digits can optionally be separated by a digit group mark - a
comma or period (whichever is not used as decimal mark), or a space
(several Unicode space variants, like no-break space, are also accepted). So these are all valid amounts in a journal file:

```
$1,000,000.00
EUR 2.000.000,00
INR 9,99,99,999.00
1 000 000.00   ; <- ordinary space
1 000 000.00   ; <- no-break space

```

## Commodity

Amounts in hledger have both a "quantity", which is a signed decimal
number, and a "commodity", which is a currency symbol, stock ticker, or
any word or phrase describing something you are tracking.

If the commodity name contains non-letters (spaces, numbers, or punctuation), you must always write it inside double quotes ("green apples",
"ABC123").

If you write just a bare number, that too will have a commodity, with
name ""; we call that the "no-symbol commodity".

Actually, hledger combines these single-commodity amounts into more
powerful multi-commodity amounts, which are what it works with most of
the time. A multi-commodity amount could be, eg: 1 USD, 2 EUR, 3.456
TSLA. In practice, you will only see multi-commodity amounts in
hledger's output; you can't write them directly in the journal file.

By default, the format of amounts in the journal influences how hledger
displays them in output. This is explained in Commodity display style
below.

## Costs

After a posting amount, you can note its cost (when buying) or selling
price (when selling) in another commodity, by writing either @ UNITPRICE or @@ TOTALPRICE after it. This indicates a conversion transaction, where one commodity is exchanged for another.

(You might also see this called "transaction price" in hledger docs,
discussions, or code; that term was directionally neutral and reminded
that it is a price specific to a transaction, but we now just call it
"cost", with the understanding that the transaction could be a purchase
or a sale.)

Costs are usually written explicitly with @ or @@, but can also be inferred automatically for simple multi-commodity transactions. Note, if
costs are inferred, the order of postings is significant; the first
posting will have a cost attached, in the commodity of the second.

As an example, here are several ways to record purchases of a foreign
currency in hledger, using the cost notation either explicitly or implicitly:

1. Write the price per unit, as @ UNITPRICE after the amount:

```
2009/1/1
assets:euros     �100 @ $1.35  ; one hundred euros purchased at $1.35 each
assets:dollars		   ; balancing amount is -$135.00

```
2. Write the total price, as @@ TOTALPRICE after the amount:

```
2009/1/1
assets:euros     �100 @@ $135  ; one hundred euros purchased at $135 for the lot
assets:dollars

```
3. Specify amounts for all postings, using exactly two commodities, and

```
let hledger infer the price that balances the transaction.  Note the
effect of posting order: the price is added to first posting, making
it �100 @@ $135, as in example 2:

2009/1/1
assets:euros     �100	   ; one hundred euros purchased
assets:dollars  $-135	   ; for $135

```
Amounts can be converted to cost at report time using the -B/--cost
flag; this is discussed more in the Cost reporting section.

Note that the cost normally should be a positive amount, though it's
not required to be. This can be a little confusing, see discussion at
--infer-market-prices: market prices from transactions.

## Balance assertions

hledger supports Ledger-style balance assertions in journal files.
These look like, for example, = EXPECTEDBALANCE following a posting's
amount. Eg here we assert the expected dollar balance in accounts a
and b after each posting:

```
2013/1/1
a   $1 =  $1
b      = $-1

2013/1/2
a   $1 =  $2
b  $-1 = $-2

```
After reading a journal file, hledger will check all balance assertions
and report an error if any of them fail. Balance assertions can protect you from, eg, inadvertently disrupting reconciled balances while
cleaning up old entries. You can disable them temporarily with the
-I/--ignore-assertions flag, which can be useful for troubleshooting or
for reading Ledger files. (Note: this flag currently does not disable
balance assignments, described below).

## Assertions and ordering

hledger calculates and checks an account's balance assertions in date
order (and when there are multiple assertions on the same day, in parse
order). Note this is different from Ledger, which checks assertions
always in parse order, ignoring dates.

This means in hledger you can freely reorder transactions, postings, or
files, and balance assertions will usually keep working. The exception
is when you reorder multiple postings on the same day, to the same account, which have balance assertions; those will likely need updating.

## Assertions and multiple files

If an account has transactions appearing in multiple files, balance assertions can still work - but only if those files are part of a hierarchy made by include directives.

If the same files are specified with two -f options on the command
line, the assertions in the second will not see the balances from the
first.

To work around this, arrange your files in a hierarchy with include.
Or, you could concatenate the files temporarily, and process them like
one big file.

Why does it work this way ? It might be related to hledger's goal of
stable predictable reports. File hierarchy is considered "permanent",
part of your data, while the order of command line options/arguments is
not. We don't want transient changes to be able to change the meaning
of the data. Eg it would be frustrating if tomorrow all your balance
assertions broke because you wrote command line arguments in a different order. (Discussion welcome.)

## Assertions and costs

Balance assertions ignore costs, and should normally be written without
one:

```
2019/1/1
(a)	$1 @ �1 = $1

```
We do allow costs to be written in balance assertion amounts, however,
and print shows them, but they don't affect whether the assertion
passes or fails. This is for backward compatibility (hledger's close
command used to generate balance assertions with costs), and because
balance assignments do use costs (see below).

## Assertions and commodities

The balance assertions described so far are "single commodity balance
assertions": they assert and check the balance in one commodity, ignoring any others that may be present. This is how balance assertions
work in Ledger also.

If an account contains multiple commodities, you can assert their balances by writing multiple postings with balance assertions, one for
each commodity:

```
2013/1/1
usd   $-1
eur   �-1
both

2013/1/2
both	0 = $1
both	0 = �1

```
In hledger you can make a stronger "sole commodity balance assertion"
by writing two equals signs (== EXPECTEDBALANCE). This also asserts
that there are no other commodities in the account besides the asserted
one (or at least, that their current balance is zero):

```
2013/1/1
usd   $-1  == $-1  ; these sole commodity assertions succeed
eur   �-1  == �-1
both	  ;==  $1  ; this one would fail because 'both' contains $ and �

```
It's less easy to make a "sole commodities balance assertion" (note the
plural) - ie, asserting that an account contains two or more specified
commodities and no others. It can be done by

1. isolating each commodity in a subaccount, and asserting those

2. and also asserting there are no commodities in the parent account

```
itself:

2013/1/1
usd	      $-1
eur	      �-1
both	0 == 0	 ; nothing up my sleeve
both:usd   $1 == $1	 ; a dollar here
both:eur   �1 == �1	 ; a euro there

```

## Assertions and subaccounts

All of the balance assertions above (both = and ==) are "subaccount-exclusive balance assertions"; they ignore any balances that exist in
deeper subaccounts.

In hledger you can make "subaccount-inclusive balance assertions" by
adding a star after the equals (=* or ==*):

```
2019/1/1
equity:start
assets:checking	 $10
assets:savings	 $10
assets		  $0 ==* $20  ; assets + subaccounts contains $20 and nothing else

```

## Assertions and status

Balance assertions always consider postings of all statuses (unmarked,
pending, or cleared); they are not affected by the -U/--unmarked /
-P/--pending / -C/--cleared flags or the status: query.

## Assertions and virtual postings

Balance assertions always consider both real and virtual postings; they
are not affected by the --real/-R flag or real: query.

## Assertions and auto postings

Balance assertions are affected by the --auto flag, which generates
auto postings, which can alter account balances. Because auto postings
are optional in hledger, accounts affected by them effectively have two
balances. But balance assertions can only test one or the other of
these. So to avoid making fragile assertions, either:

• assert the balance calculated with --auto, and always use --auto with

```
that file

```
• or assert the balance calculated without --auto, and never use --auto

```
with that file

```
• or avoid balance assertions on accounts affected by auto postings (or

```
avoid auto postings entirely).

```

## Assertions and precision

Balance assertions compare the exactly calculated amounts, which are
not always what is shown by reports. Eg a commodity directive may
limit the display precision, but this will not affect balance assertions. Balance assertion failure messages show exact amounts.

## Assertions and hledger add

Balance assertions can be included in the amounts given in add. All
types of assertions are supported, and assertions can be used as in a
normal journal file.

All transactions, not just those that have an explicit assertion, are
validated against the existing assertions in the journal. This means
it is possible for an added transaction to fail even if its assertions
are correct as of the transaction date.

If this assertion checking is not desired, then it can be disabled with
-I.

However, balance assignments are currently not supported.

## Posting comments

Text following ;, at the end of a posting line, and/or on indented
lines immediately below it, form comments for that posting. They are
reproduced by print but otherwise ignored, except they may contain
tags, which are not ignored.

```
2012-01-01
expenses   1	; a comment for posting 1
assets
; a comment for posting 2
; a second comment line for posting 2

```

## Transaction balancing

How exactly does hledger decide when a transaction is balanced ? Especially when it involves costs, which often are not exact, because of
repeating decimals, or imperfect data from financial institutions ? In
each commodity, hledger sums the transaction's posting amounts, after
converting any with costs; then it checks if that sum is zero, when
rounded to a suitable number of decimal digits - which we call the balancing precision.

Since version 1.50, hledger infers balancing precision in each transaction from the amounts in that transaction's journal entry (like
Ledger). Ie, when checking the balance of commodity A, it uses the
highest decimal precision seen for A in the journal entry (excluding
cost amounts). This makes transaction balancing robust; any imbalances
must be visibly accounted for in the journal entry, display precision
can be freely increased with -c, and compatibility with Ledger and
Beancount journals is good.

Note that hledger versions before 1.50 worked differently: they allowed
display precision to override the balancing precision. This masked
small imbalances and caused fragility (see issue #2402). As a result,
some journal entries (or CSV rules) that worked with hledger <1.50, are
now rejected with an "unbalanced transaction" error. If you hit this
problem, it's easy to fix:

• You can restore the old behaviour, by adding --txn-balancing=old to

```
the  command or to your ~/.hledger.conf file.	This lets you keep using old journals unchanged, though without the above benefits.

```
• Or you can fix the problem entries (recommended). There are three

```
ways, use whichever seems best:

1. make cost amounts more precise (add more/better decimal digits)

2. or	make non-cost amounts less precise (remove unnecessary decimal
digits that are raising the precision)

3. or add a posting to absorb the imbalance (eg  "expenses:rounding".
Remember  that  one posting may omit the amount; that's convenient
here.)

```

## Tags

Tags are a way to add extra labels or data fields to transactions,
postings, or accounts, which you can match with a tag: query in reports. (See queries below.)

Tags are a single word or hyphenated word, immediately followed by a
full colon, written within a comment. (Yes, storing data in comments
is slightly weird.) Here's a transaction with a tag:

```
2025-01-01 groceries	  ; some-tag:
assets:checking
expenses:food	      $1

```
A tag can have a value, a single line of text written after the colon.
Tag values can't contain newlines.:

```
2025-01-01 groceries	  ; tag1: this is tag1's value

```
Multiple tags can be separated by comma. Tag values can't contain commas.:

```
2025-01-01 groceries	  ; tag1:value 1, tag2:value 2, comment text

```
A tag can have multiple values:

```
2025-01-01 groceries	  ; tag1:value 1, tag1:value 2

```
You can write each tag on its own line of you prefer (but they still
can't contain commas):

```
2025-01-01 groceries
; tag1: value 1
; tag2: value 2

```
Tags can be attached to individual postings, rather than the overall
transaction:

```
2025-01-01 rent
assets:checking
expenses:rent	      $1000  ; postingtag:

```
Tags can be attached to accounts, in their account directive:

```
account assets:checking	 ; acct-number: 123-45-6789

```

## Tag propagation

In addition to what they are attached to, tags also affect related data
in a few ways, allowing more powerful queries:

1. Accounts -> postings. Postings inherit tags from their account.

2. Transactions -> postings. Postings inherit tags from their transaction.

3. Postings -> transactions. Transactions also acquire the tags of

```
their postings.

```
So when you use a tag: query to match whole transactions, individual
postings, or accounts, it's good to understand how tags behave. Here's
an example showing all three kinds of propagation:

```
account assets:checking
account expenses:food	      ; atag:

2025-01-01 groceries	      ; ttag:
assets:checking	      ; p1tag:
expenses:food		  $1  ; p2tag:

```
data part has tags explanation
─────────────────────────────────────────────────────────────────────────────
assets:check‐ no tags attached
ing account
expenses:food atag atag: in comment
account

assets:check‐ p1tag, ttag p1tag: in comment, ttag acquired from
ing posting transaction
expenses:food p2tag, atag, p2tag: in comment, atag from account, ttag
posting ttag from transaction
groceries ttag, p1tag, ttag: in comment, p1tag from first posting,
transaction p2tag, atag p2tag and atag from second posting

## Displaying tags

You can use the tags command to list tag names or values.

The print command also shows tags.

You can use --pivot to display tag values in other reports, in various
ways (eg appended to account names, like pseudo subaccounts).

## When to use tags ?

Tags provide more dimensions of categorisation, complementing accounts
and transaction descriptions. When to use each of these is somewhat a
matter of taste. Accounts have the most built-in support, and regex
queries on descriptions are also quite powerful. So you may not need
tags at all. But if you want to track multiple cross-cutting categories, they can be a good fit. For example, you could tag trip-related transactions with trip: YEAR:PLACE, without disturbing your usual
account categories.

## Tag names

What is allowed in a tag name ? Most non-whitespace characters. Eg :
is a valid tag.

For extra error checking, you can declare valid tag names with the tag
directive, and then enforce these with the check command. But note
that tags are detected quite loosely at present, sometimes where you
didn't intend them. Eg a comment like ; see https://foo.com adds a
https tag.

There are several tag names which have special significance to hledger.
They are explained elsewhere, but here's a quick reference:

```
type		      -- declares an account's type
date		      -- overrides a posting's date
date2		      -- overrides a posting's secondary date
assert		      -- appears on txns generated by close --assert
retain		      -- appears on txns generated by close --retain
start		      -- appears on txns generated by close --migrate/--close/--open/--assign
t		      -- appears on postings generated from timedot letters

generated-transaction  -- appears on txns generated by a periodic rule
modified-transaction   -- appears on txns which have had auto postings added
generated-posting      -- appears on generated postings
cost-posting	      -- appears on postings which have (or could have) a cost,
and which have equivalent conversion postings in the transaction
conversion-posting     -- appears on postings which are to a V/Conversion account
and which have an equivalent cost posting in the transaction

```
The second group above (generated-transaction, etc.) are normally hidden, with a _ prefix added. This means print doesn't show them by default; but you can still use them in queries. You can add the --verbose-tags flag to make them visible, which can be useful for troubleshooting.

## Directives

Besides transactions, there is something else you can put in a journal
file: directives. These are declarations, beginning with a keyword,
that modify hledger's behaviour. Some directives can have more specific subdirectives, indented below them. hledger's directives are
similar to Ledger's in many cases, but there are also many differences.
Directives are not required, but can be useful. Here are the main directives:

purpose directive
──────────────────────────────────────────────────────────────────────────
READING DATA:
Rewrite account names alias
Comment out sections of the file comment
Declare file's decimal mark, to help decimal-mark
parse amounts accurately
Include other data files include
GENERATING DATA:
Generate recurring transactions or bud‐ ~
get goals
Generate extra postings on existing =
transactions
CHECKING FOR ERRORS:
Define valid entities to provide more account, commodity, payee, tag
error checking
REPORTING:
Declare accounts' type and display order account
Declare commodity display styles commodity
Declare market prices P

## Directives and multiple files

Directives vary in their scope, ie which journal entries and which input files they affect. Most often, a directive will affect the following entries and included files if any, until the end of the current
file - and no further. You might find this inconvenient! For example,
alias directives do not affect parent or sibling files. But there are
usually workarounds; for example, put alias directives in your top-most
file, before including other files.

The restriction, though it may be annoying at first, is in a good
cause; it allows reports to be stable and deterministic, independent of
the order of input. Without it, reports could show different numbers
depending on the order of -f options, or the positions of include directives in your files.

## Directive effects

Here are all hledger's directives, with their effects and scope summarised - nine main directives, plus four others which we consider
non-essential:

di‐ what it does ends
rec‐ at
tive file

```
end?
```
──────────────────────────────────────────────────────────────────────────────────────
ac‐ Declares an account, for checking all entries in all files; and N
count its display order and type. Subdirectives: any text, ignored.
alias Rewrites account names, in following entries until end of cur‐ Y

```
rent file or end aliases.  Command line equivalent: --alias
```
com‐ Ignores part of the journal file, until end of current file or Y
ment end comment.
com‐ Declares up to four things: 1. a commodity symbol, for checking N,N,Y,Y
mod‐ all amounts in all files 2. the display style for all amounts
ity of this commodity 3. the decimal mark for parsing amounts of

```
this	commodity,  in	the rest of this file and its children, if
there is no decimal-mark directive 4.	 the precision to use  for
balanced-transaction	checking  in  this commodity, in this file
and its children.   Takes  precedence	 over  D.   Subdirectives:
format (ignored).  Command line equivalent: -c/--commodity-style
```
deci‐ Declares the decimal mark, for parsing amounts of all commodi‐ Y
mal-mark ties in following entries until next decimal-mark or end of current file. Included files can override. Takes precedence over

```
commodity and D.

```
include Includes entries and directives from another file, as if they N

```
were	written	 inline.   Command  line   alternative:	  multiple
-f/--file
```
payee Declares a payee name, for checking all entries in all files. N
P Declares the market price of a commodity on some date, for value N

```
reports.
```
~ Declares a periodic transaction rule that generates future N
(tilde) transactions with --forecast and budget goals with balance

```
--budget.
```
Other
syntax:
apply Prepends a common parent account to all account names, in fol‐ Y
account lowing entries until end of current file or end apply account.
D Sets a default commodity to use for no-symbol amounts;and, if Y,Y,N,N

```
there	 is no commodity directive for this commodity: its decimal
mark, balancing precision, and display style, as above.
```
Y Sets a default year to use for any yearless dates, in following Y

```
entries until end of current file.
```
= Declares an auto posting rule that generates extra postings on partly
(equals) matched transactions with --auto, in current, parent, and child

```
files (but not sibling files, see #1212).
```
Other Other directives from Ledger's file format are accepted but igLedger nored.
directives

account directive
account directives can be used to declare accounts (ie, the places that
amounts are transferred from and to). Though not required, these declarations can provide several benefits:

• They can document your intended chart of accounts, providing a reference.

• They can store additional account information as comments, or as tags

```
which can be used to filter or pivot reports.

```
• They can restrict which accounts may be posted to by transactions, eg

```
in strict mode, which helps prevent errors.

```
• They influence account display order in reports, allowing non-alphabetic sorting (eg Revenues to appear above Expenses).

• They can help hledger know your accounts' types (asset, liability,

```
equity, revenue, expense), enabling reports like balancesheet and incomestatement.

```
• They help with account name completion (in hledger add, hledger-web,

```
hledger-iadd, ledger-mode, etc.)

```
They are written as the word account followed by a hledger-style account name. Eg:

```
account assets:bank:checking

```
Ledger-style indented subdirectives are also accepted, but ignored:

```
account assets:bank:checking
format subdirective  ; currently ignored

```

## Account comments

Text following two or more spaces and ; at the end of an account directive line, and/or following ; on indented lines immediately below it,
form comments for that account. They are ignored except they may contain tags, which are not ignored.

The two-space requirement for same-line account comments is because ;
is allowed in account names.

```
account assets:bank:checking    ; same-line comment, at least 2 spaces before the semicolon
; next-line comment
; some tags - type:A, acctnum:12345

```

## Account error checking

By default, accounts need not be declared; they come into existence
when a posting references them. This is convenient, but it means
hledger can't warn you when you mis-spell an account name in the journal. Usually you'll find that error later, as an extra account in balance reports, or an incorrect balance when reconciling.

In strict mode, enabled with the -s/--strict flag, or when you run
hledger check accounts, hledger will report an error if any transaction
uses an account name that has not been declared by an account directive. Some notes:

• The declaration is case-sensitive; transactions must use the correct

```
account name capitalisation.

```
• The account directive's scope is "whole file and below" (see directives). This means it affects all of the current file, and any files

```
it includes, but not parent or sibling files.	The  position  of  account	directives  within the file does not matter, though it's usual
to put them at the top.

```
• Accounts can only be declared in journal files, but will affect included files of all types.

• It's currently not possible to declare "all possible subaccounts"

```
with a wildcard; every account posted to must be declared.

```
• If you use the --infer-equity flag, you will also need declarations

```
for the account names it generates.

```

## Account display order

Account directives also cause hledger to display accounts in a particular order, not just alphabetically. Eg, here is a conventional ordering for the top-level accounts:

```
account assets
account liabilities
account equity
account revenues
account expenses

```
Now hledger displays them in that order:

```
$ hledger accounts
assets
liabilities
equity
revenues
expenses

```
If there are undeclared accounts, those will be displayed last, in alphabetical order.

Sorting is done within each group of sibling accounts, at each level of
the account tree. Eg, a declaration like account parent:child influences child's position among its siblings.

Note, it does not affect parent's position; for that, you need an account parent declaration.

Sibling accounts are always displayed together; hledger won't display
x:y in between a:b and a:c.

An account directive both declares an account as a valid posting target, and declares its display order; you can't easily do one without
the other.

## Account types

hledger knows that in accounting there are three main account types:

Asset A things you own
Liability L things you owe
Equity E owner's investment,

```
balances	  the  two
above

```
and two more representing changes in these:

Revenue R inflows (also known

```
as Income)
```
Expense X outflows

hledger also uses a couple of subtypes:

Cash C liquid assets
Conversion V commodity conversions equity

As a convenience, hledger will detect these types automatically from
english account names. But it's better to declare them explicitly by
adding a type: tag in the account directives. The tag's value can be
any of the types or one-letter abbreviations above.

Here is a typical set of account type declarations. Subaccounts will
inherit their parent's type, or can override it:

```
account assets		 ; type: A
account liabilities	 ; type: L
account equity		 ; type: E
account revenues		 ; type: R
account expenses		 ; type: X

account assets:bank	 ; type: C
account assets:cash	 ; type: C

account equity:conversion	 ; type: V

```
This enables the easy balancesheet, balancesheetequity, cashflow and
incomestatement reports, and querying by type:.

Tips:

• You can list accounts and their types, for troubleshooting:

```
$ hledger accounts --types [ACCTPAT] [type:TYPECODES] [-DEPTH] [--locations]

```
• It's a good idea to declare at least one account for each account

```
type.	Having some types declared and some inferred can disrupt  certain reports.

```
• The rules for inferring types from account names are as follows (using Regular expressions).
If they don't work for you, just ignore them and declare your types
with type: tags.

```
If account's name contains this case insensitive regular expression | its type is
--------------------------------------------------------------------|-------------
^assets?(:.+)?:(cash|bank|che(ck|que?)(ing)?|savings?|current)(:|$) | Cash
^assets?(:|$)							    | Asset
^(debts?|liabilit(y|ies))(:|$)					    | Liability
^equity:(trad(e|ing)|conversion)s?(:|$)				    | Conversion
^equity(:|$)							    | Equity
^(income|revenue)s?(:|$)					    | Revenue
^expenses?(:|$)							    | Expense

```
• As mentioned above, subaccounts will inherit a type from their parent

```
account.  To be precise, an account's type is decided by the first of
these that exists:

1. A type: declaration for this account.

2. A  type:  declaration  in the parent accounts above it, preferring
the nearest.

3. An account type inferred from this account's name.

4. An account type inferred from a parent account's name,  preferring
the nearest parent.

5. Otherwise, it will have no type.

```
• Account aliases can disrupt account types.

alias directive
You can define account alias rules which rewrite your account names, or
parts of them, before generating reports. This can be useful for:

• expanding shorthand account names to their full form, allowing easier

```
data entry and a less verbose journal

```
• adapting old journals to your current chart of accounts

• experimenting with new account organisations, like a new hierarchy

• combining two accounts into one, eg to see their sum or difference on

```
one line

```
• customising reports

Account aliases also rewrite account names in account directives. They
do not affect account names being entered via hledger add or
hledger-web.

Account aliases are very powerful. They are generally easy to use correctly, but you can also generate invalid account names with them; more
on this below.

See also Rewrite account names.

## Basic aliases

To set an account alias, use the alias directive in your journal file.
This affects all subsequent journal entries in the current file or its
included files (but note: not sibling or parent files). The spaces
around the = are optional:

```
alias OLD = NEW

```
Or, you can use the --alias 'OLD=NEW' option on the command line. This
affects all entries. It's useful for trying out aliases interactively.

OLD and NEW are case sensitive full account names. hledger will replace any occurrence of the old account name with the new one. Subaccounts are also affected. Eg:

```
alias checking = assets:bank:wells fargo:checking
; rewrites "checking" to "assets:bank:wells fargo:checking", or "checking:a" to "assets:bank:wells fargo:checking:a"

```

## Regex aliases

There is also a more powerful variant that uses a regular expression,
indicated by wrapping the pattern in forward slashes. (This is the
only place where hledger requires forward slashes around a regular expression.)

Eg:

```
alias /REGEX/ = REPLACEMENT

```
or:

```
$ hledger --alias '/REGEX/=REPLACEMENT' ...

```
Any part of an account name matched by REGEX will be replaced by REPLACEMENT. REGEX is case-insensitive as usual.

If you need to match a forward slash, escape it with a backslash, eg
/\/=:.

If REGEX contains parenthesised match groups, these can be referenced
by the usual backslash and number in REPLACEMENT:

```
alias /^(.+):bank:([^:]+):(.*)/ = \1:\2 \3
; rewrites "assets:bank:wells fargo:checking" to	"assets:wells fargo checking"

```
REPLACEMENT continues to the end of line (or on command line, to end of
option argument), so it can contain trailing whitespace.

## Combining aliases

You can define as many aliases as you like, using journal directives
and/or command line options.

Recursive aliases - where an account name is rewritten by one alias,
then by another alias, and so on - are allowed. Each alias sees the
effect of previously applied aliases.

In such cases it can be important to understand which aliases will be
applied and in which order. For (each account name in) each journal
entry, we apply:

1. alias directives preceding the journal entry, most recently parsed

```
first (ie, reading upward from the journal entry, bottom to top)

```
2. --alias options, in the order they appeared on the command line

```
(left to right).

```
In other words, for (an account name in) a given journal entry:

• the nearest alias declaration before/above the entry is applied first

• the next alias before/above that will be be applied next, and so on

• aliases defined after/below the entry do not affect it.

This gives nearby aliases precedence over distant ones, and helps provide semantic stability - aliases will keep working the same way independent of which files are being read and in which order.

In case of trouble, adding --debug=6 to the command line will show
which aliases are being applied when.

## Aliases and multiple files

As explained at Directives and multiple files, alias directives do not
affect parent or sibling files. Eg in this command,

```
hledger -f a.aliases -f b.journal

```
account aliases defined in a.aliases will not affect b.journal. Including the aliases doesn't work either:

```
include a.aliases

2023-01-01  ; not affected by a.aliases
foo  1
bar

```
This means that account aliases should usually be declared at the start
of your top-most file, like this:

```
alias foo=Foo
alias bar=Bar

2023-01-01  ; affected by aliases above
foo  1
bar

include c.journal	 ; also affected

```
end aliases directive
You can clear (forget) all currently defined aliases (seen in the journal so far, or defined on the command line) with this directive:

```
end aliases

```

## Aliases can generate bad account names

Be aware that account aliases can produce malformed account names,
which could cause confusing reports or invalid print output. For example, you could erase all account names:

```
2021-01-01
a:aa	 1
b

$ hledger print --alias '/.*/='
2021-01-01
1

```
The above print output is not a valid journal. Or you could insert an
illegal double space, causing print output that would give a different
journal when reparsed:

```
2021-01-01
old    1
other

$ hledger print --alias old="new	USD" | hledger -f- print
2021-01-01
new		  USD 1
other

```

## Aliases and account types

If an account with a type declaration (see Declaring accounts > Account
types) is renamed by an alias, normally the account type remains in effect.

However, renaming in a way that reshapes the account tree (eg renaming
parent accounts but not their children, or vice versa) could prevent
child accounts from inheriting the account type of their parents.

Secondly, if an account's type is being inferred from its name, renaming it by an alias could prevent or alter that.

If you are using account aliases and the type: query is not matching
accounts as you expect, try troubleshooting with the accounts command,
eg something like:

```
$ hledger accounts --types -1 --alias assets=bassetts

```
commodity directive
The commodity directive performs several functions:

1. It declares which commodity symbols may be used in the journal, enabling useful error checking with strict mode or the check command.

```
See Commodity error checking below.

```
2. It declares how all amounts in this commodity should be displayed,

```
eg how many decimals to show.	 See Commodity display style above.

```
3. (If no decimal-mark directive is in effect:) It sets the decimal

```
mark to expect (period or comma) when parsing amounts in  this  commodity, in this file and files it includes, from the directive until
end of current file.	See Decimal marks above.

```
4. It declares the precision with which this commodity's amounts should

```
be  compared	when  checking	for balanced transactions, anywhere in
this file and files it includes, until end of current file.

```
Declaring commodities solves several common parsing/display problems,
so we recommend it.

Note that effects 3 and 4 above end at the end of the directive's file,
and will not affect sibling or parent files. So if you are relying on
them (especially 4) and using multiple files, placing your commodity
directives in a top-level parent file might be important. Or, keep
your decimal marks unambiguous and your entries well balanced and precise.

Omitting the commodity symbol will set the display style for just the
no-symbol commodity, not all commodities.

Commodity styles can be overridden by the -c/--commodity-style command
line option.

(Related: #793)

## Commodity directive syntax

A commodity directive is normally the word commodity followed by a sample amount (and optionally a comment). Only the amount's symbol and
the number's format is significant. Eg:

```
commodity $1000.00
commodity 1.000,00 EUR
commodity 1 000 000.0000	 ; the no-symbol commodity

```
Commodities do not have tags (tags in the comment will be ignored).

A commodity directive's sample amount must always include a period or
comma decimal mark (this rule helps disambiguate decimal marks and
digit group marks). If you don't want to show any decimal digits,
write the decimal mark at the end:

```
commodity 1000. AAAA	 ; show AAAA with no decimals

```
Commodity symbols containing spaces, numbers, or punctuation must be
enclosed in double quotes, as usual:

```
commodity 1.0000 "AAAA 2023"

```
Commodity directives normally include a sample amount, but can declare
only a symbol (ie, just function 1 above):

```
commodity $
commodity INR
commodity "AAAA 2023"
commodity ""		 ; the no-symbol commodity

```
Commodity directives may also be written with an indented format subdirective, as in Ledger. The symbol is repeated and must be the same in
both places. Other subdirectives are currently ignored:

```
; display indian rupees with currency name on the left,
; thousands, lakhs and crores comma-separated,
; period as decimal point, and two decimal places.
commodity INR
format INR 1,00,00,000.00
an unsupported subdirective  ; ignored by hledger

```

## Commodity error checking

In strict mode (-s/--strict) (or when you run hledger check commodities), hledger will report an error if an undeclared commodity symbol
is used. (With one exception: zero amounts are always allowed to have
no commodity symbol.) It works like account error checking (described
above).

decimal-mark directive
You can use a decimal-mark directive - usually one per file, at the top
of the file - to declare which character represents a decimal mark when
parsing amounts in this file. It can look like

```
decimal-mark .

```
or

```
decimal-mark ,

```
This prevents any ambiguity when parsing numbers in the file, so we
recommend it, especially if the file contains digit group marks (eg
thousands separators).

include directive
You can pull in the content of additional files by writing an include
directive, like this:

```
include SOMEFILE

```
This has the same effect as if SOMEFILE's content was inlined at this
point. (With any include directives in SOMEFILE processed similarly,
recursively.)

Only journal files can include other files. They can include journal,
timeclock or timedot files, but not CSV files.

If the file path begins with a tilde, that means your home directory:
include ~/main.journal.

If it begins with a slash, it is an absolute path: include
/home/user/main.journal. Otherwise it is relative to the including
file's folder: include ../finances/main.journal.

Also, the path may have a file type prefix to force a specific file
format, overriding the file extension(s) (as described in Data formats): include timedot:notes/2023.md.

The path may contain glob patterns to match multiple files. hledger's
globs are similar to zsh's: ? to match any character; [a-z] to match
any character in a range; * to match zero or more characters that
aren't a path separator (like /); ** to match zero or more subdirectories and/or zero or more characters at the start of a file name; etc.
For convenience, include always excludes the current file. So, you can
do

• include *.journal to include all other journal files in the current

```
directory (excluding dot files)

```
• include **.journal to include all other journal files in this directory and below (excluding dot files and top-level dot directories)

• include timelogs/2???.timedot to include all timedot files named like

```
a year number.

```
Note * and ** usually won't match dot files or dot directories, with
one exception: ** does search non-top-level dot directories. If this
causes problems, make your glob pattern more specific (eg **.journal
instead of **).

If you are using many, or deeply nested, include files, and have an error that's hard to pinpoint: a good troubleshooting command is hledger
files --debug=6 (or 7).

## P directive

The P directive declares a market price, which is a conversion rate between two commodities on a certain date. This allows value reports to
convert amounts of one commodity to their value in another, on or after
that date. These prices are often obtained from a stock exchange,
cryptocurrency exchange, the or foreign exchange market.

The format is:

```
P DATE COMMODITY1SYMBOL COMMODITY2AMOUNT

```
DATE is a simple date, COMMODITY1SYMBOL is the symbol of the commodity
being priced, and COMMODITY2AMOUNT is the amount (symbol and quantity)
of commodity 2 that one unit of commodity 1 is worth on this date. Examples:

```
# one euro was worth $1.35 from 2009-01-01 onward:
P 2009-01-01 � $1.35

# and $1.40 from 2010-01-01 onward:
P 2010-01-01 � $1.40

```
The -V, -X and --value flags use these market prices to show amount
values in another commodity. See Value reporting.

payee directive
payee PAYEE NAME

This directive can be used to declare a limited set of payees which may
appear in transaction descriptions. The "payees" check will report an
error if any transaction refers to a payee that has not been declared.
Eg:

```
payee Whole Foods	   ; a comment

```
Payees do not have tags (tags in the comment will be ignored).

To declare the empty payee name, use "".

```
payee ""

```
Ledger-style indented subdirectives, if any, are currently ignored.

tag directive
tag TAGNAME

This directive can be used to declare a limited set of tag names allowed in tags. TAGNAME should be a valid tag name (no spaces). Eg:

```
tag  item-id

```
Any indented subdirectives are currently ignored.

The "tags" check will report an error if any undeclared tag name is
used. It is quite easy to accidentally create a tag through normal use
of colons in comments; if you want to prevent this, you can declare and
check your tags .

## Periodic transactions

The ~ directive declares a "periodic rule" which generates temporary
extra transactions, usually recurring at some interval, when hledger is
run with the --forecast flag. These "forecast transactions" are useful
for forecasting future activity. They exist only for the duration of
the report, and only when --forecast is used; they are not saved in the
journal file by hledger.

Periodic rules also have a second use: with the --budget flag they set
budget goals for budgeting.

Periodic rules can be a little tricky, so before you use them, read
this whole section, or at least the following tips:

1. Two spaces accidentally added or omitted will cause you trouble -

```
read about this below.

```
2. For troubleshooting, show the generated transactions with hledger

```
print	 --forecast  tag:generated  or	hledger	 register   --forecast
tag:generated.

```
3. Forecasted transactions will begin only after the last non-forecasted transaction's date.

4. Forecasted transactions will end 6 months from today, by default.

```
See below for the exact start/end rules.

```
5. period expressions can be tricky. Their documentation needs improvement, but is worth studying.

6. Some period expressions with a repeating interval must begin on a

```
natural  boundary  of	 that  interval.  Eg in weekly from DATE, DATE
must be a monday.  ~ weekly from 2019/10/1 (a tuesday) will give  an
error.

```
7. Other period expressions with an interval are automatically expanded

```
to cover a whole number of that interval.  (This is done to  improve
reports, but it also affects periodic transactions.  Yes, it's a bit
inconsistent with the above.)	 Eg:  ~ every 10th day of  month  from
2023/01,  which  is  equivalent  to	~ every 10th day of month from
2023/01/01, will be adjusted to start on 2019/12/10.

```

## Periodic rule syntax

A periodic transaction rule looks like a normal journal entry, with the
date replaced by a tilde (~) followed by a period expression (mnemonic:
~ looks like a recurring sine wave.):

```
# every first of month
~ monthly
expenses:rent		 $2000
assets:bank:checking

# every 15th of month in 2023's first quarter:
~ monthly from 2023-04-15 to 2023-06-16
expenses:utilities	      $400
assets:bank:checking

```
The period expression is the same syntax used for specifying multi-period reports, just interpreted differently; there, it specifies report
periods; here it specifies recurrence dates (the periods' start dates).

## Periodic rules and relative dates

Partial or relative dates (like 12/31, 25, tomorrow, last week, next
quarter) are usually not recommended in periodic rules, since the results will change as time passes. If used, they will be interpreted
relative to, in order of preference:

1. the first day of the default year specified by a recent Y directive

2. or the date specified with --today

3. or the date on which you are running the report.

They will not be affected at all by report period or forecast period
dates.

## Two spaces between period expression and description!

If the period expression is followed by a transaction description,
these must be separated by two or more spaces. This helps hledger know
where the period expression ends, so that descriptions can not accidentally alter their meaning, as in this example:

```
; 2 or more spaces needed here, so the period is not understood as "every 2 months in 2023"
;		      ||
;		      vv
~ every 2 months	in 2023, we will review
assets:bank:checking	 $1500
income:acme inc

```
So,

• Do write two spaces between your period expression and your transaction description, if any.

• Don't accidentally write two spaces in the middle of your period expression.

## Auto postings

The = directive declares an "auto posting rule", which adds extra postings to existing transactions. (Remember, postings are the account
name & amount lines below a transaction's date & description.)

In the journal, an auto posting rule looks quite like a transaction,
but instead of date and description it has = (mnemonic: "match") and a
query, like this:

```
= QUERY
ACCOUNT    AMOUNT
...

```
Queries are just like command line queries; an account name substring
is most common. Query terms containing spaces should be enclosed in
single or double quotes.

Each = rule works like this: when hledger is run with the --auto flag,
wherever the QUERY matches a posting in the journal, the rule's postings are added to that transaction, immediately below the matched posting. Note these generated postings are temporary, existing only for
the duration of the report, and only when --auto is used; they are not
saved in the journal file by hledger.

The postings can contain the special string %account which will be expanded to the account name of the matched account.

Generated postings' amounts can depend on the matched posting's amount.
So auto postings can be useful for, eg, adding tax postings with a
standard percentage. AMOUNT can be:

• a number with no commodity symbol, like 2. The matched posting's

```
commodity symbol will be added to this.

```
• a normal amount with a commodity symbol, like $2. This will be used

```
as-is.

```
• an asterisk followed by a number, like *2. This will multiply the

```
matched posting's amount (and total price, if any) by the number.

```
• an asterisk followed by an amount with commodity symbol, like *$2.

```
This  multiplies and also replaces the commodity symbol with this new
one.

```
Some examples:

```
; every time I buy food, schedule a dollar donation
= expenses:food
(liabilities:charity)	  $-1

; when I buy a gift, also deduct that amount from a budget envelope subaccount
= expenses:gifts
assets:checking:gifts	 *-1
assets:checking	  *1

2017/12/1
expenses:food	 $10
assets:checking

2017/12/14
expenses:gifts	 $20
assets:checking

$ hledger print --auto
2017-12-01
expenses:food		     $10
assets:checking
(liabilities:charity)	     $-1

2017-12-14
expenses:gifts	     $20
assets:checking
assets:checking:gifts	    -$20
assets:checking	     $20

```
Note that depending fully on generated data such as this has some drawbacks - it's less portable, less future-proof, less auditable by others, and less robust (eg your balance assertions will depend on whether
you use or don't use --auto). An alternative is to use auto postings
in "one time" fashion - use them to help build a complex journal entry,
view it with hledger print --auto, and then copy that output into the
journal file to make it permanent.

## Auto postings and multiple files

An auto posting rule can affect any transaction in the current file, or
in any parent file or child file. Note, currently it will not affect
sibling files (when multiple -f/--file are used - see #1212).

## Auto postings and dates

A posting date (or secondary date) in the matched posting, or (taking
precedence) a posting date in the auto posting rule itself, will also
be used in the generated posting.

## Auto postings and transaction balancing / inferred amounts / balance assertions

Currently, auto postings are added:

• after missing amounts are inferred, and transactions are checked for

```
balancedness,

```
• but before balance assertions are checked.

Note this means that journal entries must be balanced both before and
after auto postings are added. This changed in hledger 1.12+; see #893
for background.

This also means that you cannot have more than one auto-posting with a
missing amount applied to a given transaction, as it will be unable to
infer amounts.

## Auto posting tags

Automated postings will have some extra tags:

• generated-posting:= QUERY - shows this was generated by an auto posting rule, and the query

• _generated-posting:= QUERY - a hidden tag, which does not appear in

```
hledger's output.  This can be used to match postings generated "just
now", rather than generated in the past and saved to the journal.

```
Also, any transaction that has been changed by auto posting rules will
have these tags added:

• modified: - this transaction was modified

• _modified: - a hidden tag not appearing in the comment; this transaction was modified "just now".

## Auto postings on forecast transactions only

Tip: you can can make auto postings that will apply to forecast transactions but not recorded transactions, by adding tag:_generated-transaction to their QUERY. This can be useful when generating new journal
entries to be saved in the journal.

## Other syntax

hledger journal format supports quite a few other features, mainly to
make interoperating with or converting from Ledger easier. Note some
of the features below are powerful and can be useful in special cases,
but in general, features in this section are considered less important
or even not recommended for most users. Downsides are mentioned to
help you decide if you want to use them.

## Balance assignments

Ledger-style balance assignments are also supported. These are like
balance assertions, but with no posting amount on the left side of the
equals sign; instead it is calculated automatically so as to satisfy
the assertion. This can be a convenience during data entry, eg when
setting opening balances:

```
; starting a new journal, set asset account balances
2016/1/1 opening balances
assets:checking		   = $409.32
assets:savings		   = $735.24
assets:cash		    = $42
equity:opening balances

```
or when adjusting a balance to reality:

```
; no cash left; update balance, record any untracked spending as a generic expense
2016/1/15
assets:cash    = $0
expenses:misc

```
The calculated amount depends on the account's balance in the commodity
at that point (which depends on the previously-dated postings of the
commodity to that account since the last balance assertion or assignment).

Downsides: using balance assignments makes your journal less explicit;
to know the exact amount posted, you have to run hledger or do the calculations yourself, instead of just reading it. Also balance assignments' forcing of balances can hide errors. These things make your financial data less portable, less future-proof, and less trustworthy in
an audit.

## Balance assignments and costs

A cost in a balance assignment will cause the calculated amount to have
that cost attached:

```
2019/1/1
(a)		= $1 @ �2

$ hledger print --explicit
2019-01-01
(a)	      $1 @ �2 = $1 @ �2

```

## Balance assignments and multiple files

Balance assignments handle multiple files like balance assertions.
They see balance from other files previously included from the current
file, but not from previous sibling or parent files.

## Bracketed posting dates

For setting posting dates and secondary posting dates, Ledger's bracketed date syntax is also supported: [DATE], [DATE=DATE2] or [=DATE2] in
posting comments. hledger will attempt to parse any square-bracketed
sequence of the 0123456789/-.= characters in this way. With this syntax, DATE infers its year from the transaction and DATE2 infers its
year from DATE.

Downsides: another syntax to learn, redundant with hledger's
date:/date2: tags, and confusingly similar to Ledger's lot date syntax.

## D directive

D AMOUNT

This directive sets a default commodity, to be used for any subsequent
commodityless amounts (ie, plain numbers) seen while parsing the journal. This effect lasts until the next D directive, or the end of the
current file.

For compatibility/historical reasons, D also acts like a commodity directive (setting the commodity's decimal mark for parsing and display
style for output). So its argument is not just a commodity symbol, but
a full amount demonstrating the style. The amount must include a decimal mark (either period or comma). Eg:

```
; commodity-less amounts should be treated as dollars
; (and displayed with the dollar sign on the left, thousands separators and two decimal places)
D $1,000.00

1/1
a     5	 ; <- commodity-less amount, parsed as $5 and displayed as $5.00
b

```
Interactions with other directives:

For setting a commodity's display style, a commodity directive has
highest priority, then a D directive.

For detecting a commodity's decimal mark during parsing, decimal-mark
has highest priority, then commodity, then D.

For checking commodity symbols with the check command, a commodity directive is required (hledger check commodities ignores D directives).

Downsides: omitting commodity symbols makes your financial data less
explicit, less portable, and less trustworthy in an audit. It is usually an unsustainable shortcut; sooner or later you will want to track
multiple commodities. D is overloaded with functions redundant with
commodity and decimal-mark. And it works differently from Ledger's D.

apply account directive
This directive sets a default parent account, which will be prepended
to all accounts in following entries, until an end apply account directive or end of current file. Eg:

```
apply account home

2010/1/1
food	  $10
cash

end apply account

```
is equivalent to:

```
2010/01/01
home:food	      $10
home:cash	     $-10

```
account directives are also affected, and so is any included content.

Account names entered via hledger add or hledger-web are not affected.

Account aliases, if any, are applied after the parent account is
prepended.

Downsides: this can make your financial data less explicit, less portable, and less trustworthy in an audit.

## Y directive

Y YEAR

or (deprecated backward-compatible forms):

year YEAR apply year YEAR

The space is optional. This sets a default year to be used for subsequent dates which don't specify a year. Eg:

```
Y2009  ; set default year to 2009

12/15  ; equivalent to 2009/12/15
expenses  1
assets

year 2010	 ; change default year to 2010

2009/1/30	 ; specifies the year, not affected
expenses  1
assets

1/31   ; equivalent to 2010/1/31
expenses  1
assets

```
Downsides: omitting the year (from primary transaction dates, at least)
makes your financial data less explicit, less portable, and less trustworthy in an audit. Such dates can get separated from their corresponding Y directive, eg when evaluating a region of the journal in
your editor. A missing Y directive makes reports dependent on today's
date.

## Secondary dates

A secondary date is written after the primary date, following an equals
sign: DATE1=DATE2. If the year is omitted, the primary date's year is
assumed. When running reports, the primary (left side) date is used by
default, but with the --date2 flag (--aux-date or--effective also work,
for Ledger users), the secondary (right side) date will be used instead.

The meaning of secondary dates is up to you. Eg it could be "primary
is the bank's clearing date, secondary is the date the transaction was
initiated, if different".

In practice, this feature usually adds confusion:

• You have to remember the primary and secondary dates' meaning, and

```
follow that consistently.

```
• It splits your bookkeeping into two modes, and you have to remember

```
which mode is appropriate for a given report.

```
• Usually your balance assertions will work with only one of these

```
modes.

```
• It makes your financial data more complicated, less portable, and

```
less clear in an audit.

```
• It interacts with every feature, creating an ongoing cost for implementors.

• It distracts new users and supporters.

• Posting dates are simpler and work better.

So secondary dates are officially deprecated in hledger, remaining only
as a Ledger compatibility aid; we recommend using posting dates instead.

## Star comments

Lines beginning with * (star/asterisk) are also comment lines. This
feature allows Emacs users to insert org headings in their journal, allowing them to fold/unfold/navigate it like an outline when viewed with
org mode.

Downsides: another, unconventional comment syntax to learn. Decreases
your journal's portability. And switching to Emacs org mode just for
folding/unfolding meant losing the benefits of ledger mode; nowadays
you can add outshine mode to ledger mode to get folding without losing
ledger mode's features.

## Valuation expressions

Ledger allows a valuation function or value to be written in double
parentheses after an amount. hledger ignores these.

## Virtual postings

A posting with parentheses around the account name, like (some:account)
10, is called an unbalanced virtual posting. These postings do not
participate in transaction balancing. (And if you write them without
an amount, a zero amount is always inferred.) These can occasionally
be convenient for special circumstances, but they violate double entry
bookkeeping and make your data less portable across applications, so
many people avoid using them at all.

A posting with brackets around the account name ([some:account]) is
called a balanced virtual posting. The balanced virtual postings in a
transaction must add up to zero, just like ordinary postings, but separately from them. These are not part of double entry bookkeeping either, but they are at least balanced. An example:

```
2022-01-01 buy food with cash, update budget envelope subaccounts, & something else
assets:cash		       $-10  ; <- these balance each other
expenses:food			 $7  ; <-
expenses:food			 $3  ; <-
[assets:checking:budget:food]  $-10  ;	 <- and these balance each other
[assets:checking:available]	$10  ;	 <-
(something:else)		 $5  ;	   <- this is not required to balance

```
Ordinary postings, whose account names are neither parenthesised nor
bracketed, are called real postings. You can exclude virtual postings
from reports with the -R/--real flag or a real:1 query.

## Other Ledger directives

These other Ledger directives are currently accepted but ignored. This
allows hledger to read more Ledger files, but be aware that hledger's
reports may differ from Ledger's if you use these.

```
apply fixed COMM AMT
apply tag	  TAG
assert	  EXPR
bucket / A  ACCT
capture	  ACCT REGEX
check	  EXPR
define	  VAR=EXPR
end apply fixed
end apply tag
end apply year
end tag
eval / expr EXPR
python
PYTHONCODE
tag	  NAME
value	  EXPR
--command-line-flags

```
See also https://hledger.org/ledger.html for a detailed hledger/Ledger
syntax comparison.

## Other cost/lot notations

A slight digression for Ledger and Beancount users.

Ledger has a number of cost/lot-related notations:

• @ UNITCOST and @@ TOTALCOST

```
• expresses a conversion rate, as in hledger

• when	 buying,  also	creates	 a lot that can be selected at selling
time

```
• (@) UNITCOST and (@@) TOTALCOST (virtual cost)

```
• like the above, but also means "this cost  was  exceptional,	 don't
use it when inferring market prices".

```
• {=UNITCOST} and {{=TOTALCOST}} (fixed price)

```
• when buying, means "this cost is also the fixed value, don't let it
fluctuate in value reports"

```
• {UNITCOST} and {{TOTALCOST}} (lot price)

```
• can be used identically to @ UNITCOST and @@ TOTALCOST,  also  creates a lot

• when	 selling,  combined with @ ..., selects an existing lot by its
cost basis.	Does not check if that lot is present.

```
• [YYYY/MM/DD] (lot date)

```
• when buying, attaches this acquisition date to the lot

• when selling, selects a lot by its acquisition date

```
• (SOME TEXT) (lot note)

```
• when buying, attaches this note to the lot

• when selling, selects a lot by its note

```
Currently, hledger

• accepts any or all of the above in any order after the posting amount

• supports @ and @@

• treats (@) and (@@) as synonyms for @ and @@

• and ignores the rest. (This can break transaction balancing.)

Beancount has simpler notation and different behaviour:

• @ UNITCOST and @@ TOTALCOST

```
• expresses a cost without creating a lot, as in hledger

• when buying (acquiring) or selling (disposing of) a lot,  and  combined  with	{...}: is not used except to document the cost/selling
price

```
• {UNITCOST} and {{TOTALCOST}}

```
• when buying, expresses the cost for transaction balancing, and also
creates a lot with this cost basis attached

• when selling,

• selects a lot by its cost basis

• raises an error if that lot is not present or can not be selected
unambiguously (depending on booking method configured)

• expresses the selling price for transaction balancing

```
• {}, {YYYY-MM-DD}, {"LABEL"}, {UNITCOST, "LABEL"}, {UNITCOST,

```
YYYY-MM-DD, "LABEL"}

• when	 selling,  other  combinations	of  date/cost/label,  like the
above, are accepted for selecting the lot.

```
Currently, hledger

• supports @ and @@

• accepts the {UNITCOST}/{{TOTALCOST}} notation, but ignores it

• and rejects the rest.
