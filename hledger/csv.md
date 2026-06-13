---
title: hledger — CSV/TSV Format
---

hledger can read transactions from CSV (comma-separated values) files.
More precisely, it can read DSV (delimiter-separated values), from a
file or standard input. Comma-separated, semicolon-separated and
tab-separated are the most common variants, and hledger will recognise
these three automatically based on a .csv, .ssv or .tsv file name extension or a csv:, ssv: or tsv: file path prefix.

(To learn about producing CSV or TSV output, see Output format.)

Each CSV file must be described by a corresponding rules file. This
contains rules describing the CSV data (header line, fields layout,
date format etc.), how to construct hledger transactions from it, and
how to categorise transactions based on description or other attributes.

By default, hledger expects this rules file to be named like the CSV
file, with an extra .rules extension added, in the same directory. Eg
when asked to read foo/FILE.csv, hledger looks for foo/FILE.csv.rules.
You can specify a different rules file with the --rules option.

At minimum, the rules file must identify the date and amount fields,
and often it also specifies the date format and how many header lines
there are. Here's a simple CSV file and a rules file for it:

```
Date, Description, Id, Amount
12/11/2019, Foo, 123, 10.23

# basic.csv.rules
skip	   1
fields	   date, description, , amount
date-format  %d/%m/%Y

$ hledger print -f basic.csv
2019-11-12 Foo
expenses:unknown	     10.23
income:unknown	    -10.23

```
There's an introductory Tutorial: Import CSV data on hledger.org, and
more CSV rules examples below, and a larger collection at
https://github.com/simonmichael/hledger/tree/master/examples/csv.

## CSV rules cheatsheet

The following kinds of rule can appear in the rules file, in any order.
(Blank lines and lines beginning with # or ; or * are ignored.)

source optionally declare which file to read data

```
from
```
archive optionally enable an archive of imported files
encoding optionally declare which text encoding the

```
data has

```
separator declare the field separator, instead of relying on file extension
decimal-mark declare the decimal mark used in CSV amounts,

```
when ambiguous
```
date-format declare how to parse CSV dates/date-times
timezone declare the time zone of ambiguous CSV

```
date-times
```
newest-first improve txn order when: there are multiple

```
records, newest first, all with the same date
```
intra-day-reversed improve txn order when: same-day txns are in

```
opposite order to the overall file
```
skip (at top level) skip header line(s) at start of

```
file
```
fields list name CSV fields for easy reference, and optionally assign their values to hledger fields
Field assignment assign a CSV value or interpolated text value

```
to a hledger field
```
if block conditionally assign values to hledger fields,

```
or skip a record or end (skip rest of file)
```
if table conditionally assign values to hledger fields,

```
using compact syntax
```
skip (inside an if rule) skip current record(s)
end (inside an if rule) skip all remaining records
balance-type select which type of balance assertions/assignments to generate
include inline another CSV rules file

Working with CSV tips can be found below, including How CSV rules are
evaluated.

source
If you tell hledger to read a csv file with -f foo.csv, it will look
for rules in foo.csv.rules. Or, you can tell it to read the rules
file, with -f foo.csv.rules, and it will look for data in foo.csv
(since 1.30). These are mostly equivalent, but the second method provides some extra features. For one, the data file can be missing,
without causing an error; it is just considered empty.

For more flexibility, add a source rule, which lets you specify a different data file:

```
source ./Checking1.csv

```
If the file does not exist, it is just considered empty, without raising an error.

If you specify just a file name with no path, hledger will look for it
in the ~/Downloads folder:

```
source Checking1.csv

```
You can use a glob pattern, to avoid specifying the file name exactly:

```
source Checking1*.csv

```
This has another benefit: if the pattern matches multiple files,
hledger will read the newest (most recently modified) one. This avoids
problems if you have downloaded a file multiple times without cleaning
up.

All this enables a convenient workflow where can you just download CSV
files, then run hledger import rules/*.

See also "Working with CSV > Reading files specified by rule".

## Data cleaning / data generating commands

After source's file pattern, you can write | (pipe) and a data cleaning
command (or command pipeline). If hledger's CSV rules aren't enough,
you can pre-process the downloaded data here with a shell command or
script, to make it more suitable for conversion. The command will be
executed by your default shell, in the directory of the rules file,
will receive the data file's content as standard input, and should output zero or more lines of character-separated-values, suitable for conversion by the CSV rules.

Examples:

```
source ./paypal.json | paypalcsv
source data/simplefin.json | simplefincsv - 'chase.*card'
source OfxDownload*.csv | grep -vE '^(([^,]*,){6}[^,]*|)$' | sort -t, -n +2
source History_for_Account_Z20144832*.csv	  # | grep -E '^([^,]*,){12}[^,]*$' | sed -E -e 's/^ //' -e 's/\.([0-9]),/.\10,/g' -e 's/,([0-9]+),/,\1.00,/g'

```
Or, after source you can write | and a data generating command (with no
file pattern before the |). This command receives no input, and should
output zero or more lines of character-separated values, suitable for
conversion by the CSV rules.

Examples:

```
source | paypaljson | paypalcsv
source | paypalcsv data/paypal.json
source | simplefinjson >data/simplefin.json && simplefincsv data/simplefin.json 'chase.*card'
source | simplefincsv data/simplefin.json 'unify.*checking'

```
(paypal* and simplefin* scripts are in bin/)

Whenever hledger runs one of these commands, it will echo the command
on stderr. If the command produces error output, but exits successfully, hledger will show the error output as a warning. If the command
fails, hledger will fail and show the error output in the error message.

Added in 1.50; experimental.

archive
With archive added to a rules file, the import command will archive
each successfully processed data file or data command output in a
nearby data/ directory. The archive file name will be based on the
rules file and the data file's modification date and extension (or for
a data-generating command, the current date and the ".csv" extension).
The original data file, if any, will be removed.

Also, in this mode import will prefer the oldest file matched by the
source rule's glob pattern, not the newest. (So if there are multiple
downloads, they will be imported and archived oldest first.)

Archiving is optional, but it can be useful for troubleshooting your
CSV rules, regenerating entries with improved rules, checking for variations in your bank's CSV, etc.

Added in 1.50; experimental.

encoding

```
encoding ENCODING

```
hledger normally expects non-ascii text to be using the system locale's
text encoding. If you need to read CSV files which have some other encoding, you can do it by adding encoding ENCODING to your CSV rules.
Eg: encoding iso-8859-1.

The following encodings are supported:

ascii, utf-8, utf-16, utf-32, iso-8859-1, iso-8859-2, iso-8859-3,
iso-8859-4, iso-8859-5, iso-8859-6, iso-8859-7, iso-8859-8, iso-8859-9,
iso-8859-10, iso-8859-11, iso-8859-13, iso-8859-14, iso-8859-15,
iso-8859-16, cp1250, cp1251, cp1252, cp1253, cp1254, cp1255, cp1256,
cp1257, cp1258, koi8-r, koi8-u, gb18030, macintosh, jis-x-0201,
jis-x-0208, iso-2022-jp, shift-jis, cp437, cp737, cp775, cp850, cp852,
cp855, cp857, cp860, cp861, cp862, cp863, cp864, cp865, cp866, cp869,
cp874, cp932.

Added in 1.42.

separator
You can use the separator rule to read other kinds of character-separated data. The argument is any single separator character, or the
words tab or space (case insensitive). Eg, for comma-separated values
(CSV):

```
separator ,

```
or for semicolon-separated values (SSV):

```
separator ;

```
or for tab-separated values (TSV):

```
separator TAB

```
If the input file has a .csv, .ssv or .tsv file extension (or a csv:,
ssv:, tsv: prefix), the appropriate separator will be inferred automatically, and you won't need this rule.

skip

```
skip N

```
The word skip followed by a number (or no number, meaning 1) tells
hledger to ignore this many non-empty lines at the start of the input
data. You'll need this whenever your CSV data contains header lines.
Note, empty and blank lines are skipped automatically, so you don't
need to count those.

skip has a second meaning: it can be used inside if blocks (described
below), to skip one or more records whenever the condition is true.
Records skipped in this way are ignored, except they are still required
to be valid CSV.

date-format

```
date-format DATEFMT

```
This is a helper for the date (and date2) fields. If your CSV dates
are not formatted like YYYY-MM-DD, YYYY/MM/DD or YYYY.MM.DD, you'll
need to add a date-format rule describing them with a strptime-style
date parsing pattern - see https://hackage.haskell.org/package/time/docs/Data-Time-Format.html#v:formatTime. The pattern must
parse the CSV date value completely. Some examples:

```
# MM/DD/YY
date-format %m/%d/%y

# D/M/YYYY
# The - makes leading zeros optional.
date-format %-d/%-m/%Y

# YYYY-Mmm-DD
date-format %Y-%h-%d

# M/D/YYYY HH:MM AM some other junk
# Note the time and junk must be fully parsed, though only the date is used.
date-format %-m/%-d/%Y %l:%M %p some other junk

```
Note currently there is no locale awareness for things like %b, and
setting LC_TIME won't help.

timezone

```
timezone TIMEZONE

```
When CSV contains date-times that are implicitly in some time zone
other than yours, but containing no explicit time zone information, you
can use this rule to declare the CSV's native time zone, which helps
prevent off-by-one dates.

When the CSV date-times do contain time zone information, you don't
need this rule; instead, use %Z in date-format (or %z, %EZ, %Ez; see
the formatTime link above).

In either of these cases, hledger will do a time-zone-aware conversion,
localising the CSV date-times to your current system time zone. If you
prefer to localise to some other time zone, eg for reproducibility, you
can (on unix at least) set the output timezone with the TZ environment
variable, eg:

```
$ TZ=-1000 hledger print -f foo.csv  # or TZ=-1000 hledger import foo.csv

```
timezone currently does not understand timezone names, except "UTC",
"GMT", "EST", "EDT", "CST", "CDT", "MST", "MDT", "PST", or "PDT". For
others, use numeric format: +HHMM or -HHMM.

newest-first
hledger tries to ensure that the generated transactions will be ordered
chronologically, including same-day transactions. Usually it can
auto-detect how the CSV records are ordered. But if it encounters CSV
where all records are on the same date, it assumes that the records are
oldest first. If in fact the CSV's records are normally newest first,
like:

```
2022-10-01, txn 3...
2022-10-01, txn 2...
2022-10-01, txn 1...

```
you can add the newest-first rule to help hledger generate the transactions in correct order.

```
# same-day CSV records are newest first
newest-first

```
intra-day-reversed
If CSV records within a single day are ordered opposite to the overall
record order, you can add the intra-day-reversed rule to improve the
order of journal entries. Eg, here the overall record order is newest
first, but same-day records are oldest first:

```
2022-10-02, txn 3...
2022-10-02, txn 4...
2022-10-01, txn 1...
2022-10-01, txn 2...

# transactions within each day are reversed with respect to the overall date order
intra-day-reversed

```
decimal-mark

```
decimal-mark .

```
or:

```
decimal-mark ,

```
hledger automatically accepts either period or comma as a decimal mark
when parsing numbers (cf Amounts). However if any numbers in the CSV
contain digit group marks, such as thousand-separating commas, you
should declare the decimal mark explicitly with this rule, to avoid
misparsed numbers.

## CSV fields and hledger fields

This can be confusing, so let's start with an overview:

• CSV fields are provided by your data file. They are named by their

```
position  in the CSV record, starting with 1.	You can also give them
a readable name.

```
• hledger fields are predefined; date, description, account1, amount1,

```
account2  are	some  of them.	They correspond to parts of a transaction's journal entry, mostly.

```
• The CSV fields and hledger fields are the only fields you'll be working with; you can't define new fields, or variables as in a programming language. (But you could add extra CSV fields to the data in

```
preprocessing, before running the rules.)

```
• For each CSV record, you'll assign values to one or more of the

```
hledger fields to build up a transaction (journal entry).  Values can
be static text, CSV field values from the current record, or a combination of these.

```
• For simple cases, you can give a CSV field the same name as one of

```
the  hledger fields, then its value will be automatically assigned to
that hledger field.

```
• CSV fields can only be read, not written to. They'll be on the right

```
hand side, with a % prefix.  Eg

• testing a CSV field's value: if %CSVFIELD ...

• interpolating its value: HLEDGERFIELD %CSVFIELD

```
• hledger fields can only be written to, not read. They'll be on the

```
left hand side (or in a fields list), with no prefix.	Eg

• setting the transaction's description to a value: description VALUE

• setting the transaction's description to  the  second  CSV  field's
value:
fields date, description, amount

```
fields list

```
fields FIELDNAME1, FIELDNAME2, ...

```
A fields list (the word fields followed by comma-separated field names)
is optional, but convenient. It does two things:

1. It names the CSV field in each column. This can be convenient if

```
you  are  referencing them in other rules, so you can say %SomeField
instead of remembering %13.

```
2. Whenever you use one of the special hledger field names (described

```
below),  it  assigns	the CSV value in this position to that hledger
field.  This is the quickest way to populate	hledger's  fields  and
build a transaction.

```
Here's an example that says "use the 1st, 2nd and 4th fields as the
transaction's date, description and amount; name the last two fields
for later reference; and ignore the others":

```
fields date, description, , amount, , , somefield, anotherfield

```
In a fields list, the separator is always comma; it is unrelated to the
CSV file's separator. Also:

• There must be least two items in the list (at least one comma).

• Field names may not contain spaces. Spaces before/after field names

```
are optional.

```
• Field names may contain _ (underscore) or - (hyphen).

• Fields you don't care about can be given a dummy name or an empty

```
name.

```
If the CSV contains column headings, it's convenient to use these for
your field names, suitably modified (eg lower-cased with spaces replaced by underscores).

Sometimes you may want to alter a CSV field name to avoid assigning to
a hledger field with the same name. Eg you could call the CSV's "balance" field balance_ to avoid directly setting hledger's balance field
(and generating a balance assertion).

## Field assignment

```
HLEDGERFIELD FIELDVALUE

```
Field assignments are the more flexible way to assign CSV values to
hledger fields. They can be used instead of or in addition to a fields
list (see above).

To assign a value to a hledger field, write the field name (any of the
standard hledger field/pseudo-field names, defined below), a space,
followed by a text value on the same line. This text value may interpolate CSV fields, referenced either by their 1-based position in the
CSV record (%N) or by the name they were given in the fields list
(%CSVFIELD), and regular expression match groups (\N).

Some examples:

```
# set the amount to the 4th CSV field, with " USD" appended
amount %4 USD

# combine three fields to make a comment, containing note: and date: tags
comment note: %somefield - %anotherfield, date: %1

```
Tips:

• Interpolation strips outer whitespace (so a CSV value like " 1 " becomes 1 when interpolated) (#1051).

• Interpolations always refer to a CSV field - you can't interpolate a

```
hledger field.	 (See Referencing other fields below).

```

## Field names

Note the two kinds of field names mentioned here, and used only in
hledger CSV rules files:

1. CSV field names (CSVFIELD in these docs): you can optionally name

```
the CSV columns for easy reference (since hledger doesn't yet	 automatically recognise column headings in a CSV file), by writing arbitrary names in a fields list, eg:

fields When, What, Some_Id, Net, Total, Foo, Bar

```
2. Special hledger field names (HLEDGERFIELD in these docs): you must

```
set  at least some of these to generate the hledger transaction from
a CSV record, by writing them as the left hand side of a  field  assignment, eg:

date	      %When
code	      %Some_Id
description %What
comment     %Foo %Bar
amount1     $ %Total

or directly in a fields list:

fields date, description, code, , amount1, Foo, Bar
currency $
comment  %Foo %Bar

```
Here are all the special hledger field names available, and what happens when you assign values to them:

date field
Assigning to date sets the transaction date.

date2 field
date2 sets the transaction's secondary date, if any.

status field
status sets the transaction's status, if any.

code field
code sets the transaction's code, if any.

description field
description sets the transaction's description, if any.

comment field
comment sets the transaction's comment, if any.

commentN, where N is a number, sets the Nth posting's comment.

You can assign multi-line comments by writing literal \n in the code.
A comment starting with \n will begin on a new line.

Comments can contain tags, as usual.

Posting comments can also contain a posting date. A secondary date, or
a year-less date, will be ignored.

account field
Assigning to accountN, where N is 1 to 99, sets the account name of the
Nth posting, and causes that posting to be generated.

Most often there are two postings, so you'll want to set account1 and
account2. Typically account1 is associated with the CSV file, and is
set once with a top-level assignment, while account2 is set based on
each transaction's description, in conditional rules.

If a posting's account name is left unset but its amount is set (see
below), a default account name will be chosen (like "expenses:unknown"
or "income:unknown").

amount field
There are several ways to set posting amounts from CSV, useful in different situations.

1. amount is the oldest and simplest. Assigning to this sets the

```
amount of the first and second postings.  In the second posting, the
amount  will be negated; also, if it has a cost attached, it will be
converted to cost.

```
2. amount-in and amount-out work exactly like the above, but should be

```
used	when  the  CSV	has  two  amount  fields  (such as "Debit" and
"Credit",  or	 "Inflow"  and	"Outflow").   Whichever	 field	has  a
non-zero  value  will	 be used as the amount of the first and second
postings.  Here are some tips to avoid confusion:

• It's not "amount-in for posting 1 and amount-out for posting  2",
it	 is  "extract a single amount from the amount-in or amount-out
field, and use that for posting 1 and (negated) for posting 2".

• Don't use both amount and amount-in/amount-out in the same	 rules
file; choose based on whether the amount is in a single CSV field
or spread across two fields.

• In each record, at most one of the two CSV fields should  contain
a	non-zero  amount; the other field must contain a zero or nothing.

• hledger assumes both CSV fields contain unsigned numbers, and  it
automatically negates the amount-out values.

• If	 the data doesn't fit these requirements, you'll probably need
an if rule (see below).

```
3. amountN (where N is a number from 1 to 99) sets the amount of only a

```
single  posting: the Nth posting in the transaction.	You'll usually
need at least two such assignments to make a	balanced  transaction.
You can also generate more than two postings, to represent more complex transactions.  The posting numbers don't have  to  be  consecutive;	 with if rules, higher posting numbers can be useful to ensure
a certain order of postings.

```
4. amountN-in and amountN-out work exactly like the above, but should

```
be  used  when  the CSV has two amount fields.  This is analogous to
amount-in and amount-out, and those tips also apply here.

```
5. Remember that a fields list can also do assignments. So in a fields

```
list	if  you name a CSV field "amount", that counts as assigning to
amount.  (If you don't want that, call  it  something	 else  in  the
fields list, like "amount_".)

```
6. The above don't handle every situation; if you need more flexibility, use an if rule to set amounts conditionally. See "Working with

```
CSV  > Setting amounts" below for more on this and on amount-setting
generally.

```
currency field
currency sets a currency symbol, to be prepended to all postings'
amounts. You can use this if the CSV amounts do not have a currency
symbol, eg if it is in a separate column.

currencyN prepends a currency symbol to just the Nth posting's amount.

balance field
balanceN sets a balance assertion amount (or if the posting amount is
left empty, a balance assignment) on posting N.

balance is a compatibility spelling for hledger <1.17; it is equivalent
to balance1.

You can adjust the type of assertion/assignment with the balance-type
rule (see below).

See the Working with CSV tips below for more about setting amounts and
currency.

if block
Rules can be applied conditionally, depending on patterns in the CSV
data. This allows flexibility; in particular, it is how you can categorise transactions, selecting an appropriate account name based on
their description (for example). There are two ways to write conditional rules: "if blocks", described here, and "if tables", described
below.

An if block is the word if and one or more "matcher" expressions (can
be a word or phrase), one per line, starting either on the same or next
line; followed by one or more indented rules. Eg,

```
if MATCHER
RULE

```
or

```
if
MATCHER
MATCHER
MATCHER
RULE
RULE

```
If any of the matchers succeeds, all of the indented rules will be applied. They are usually field assignments, but the following special
rules may also be used within an if block:

• skip - skips the matched CSV record (generating no transaction from

```
it)

```
• end - skips the rest of the current CSV file.

Some examples:

```
# if the record contains "groceries", set account2 to "expenses:groceries"
if groceries
account2 expenses:groceries

# if the record contains any of these phrases, set account2 and a transaction comment as shown
if
monthly service fee
atm transaction fee
banking thru software
account2 expenses:business:banking
comment	XXX deductible ? check it

# if an empty record is seen (assuming five fields), ignore the rest of the CSV file
if ,,,,
end

```

## Matchers

There are two kinds of matcher:

1. A whole record matcher is simplest: it is just a word, single-line

```
text	fragment,  or other regular expression, which hledger will try
to match case-insensitively anywhere within the CSV record.
```
Eg: whole foods.

2. A field matcher has a percent-prefixed CSV field number or name before the pattern.
Eg: %3 whole foods or %description whole foods.
hledger will try to match the pattern just within the named CSV field.

When using these, there's two things to be aware of:

1. Whole record matchers don't see the exact original record; they see

```
a reconstruction of it, in which  values  are	 comma-separated,  and
quotes  enclosing values and whitespace outside those quotes are removed.
```
Eg when reading an SSV record like: 2023-01-01 ; "Acme, Inc. " ; 1,000
the whole record matcher sees instead: 2023-01-01,Acme, Inc. ,1,000

2. Field matchers expect either a CSV field number, or a CSV field name

```
declared  with fields.  (Don't use a hledger field name here, unless
it is also a CSV field name.)	 A non-CSV field name will  cause  the
matcher  to  match against "" (the empty string), and does not raise
an error, allowing easier reuse of common rules with	different  CSV
files.

```
You can also prefix a matcher with ! (and optional space) to negate it.
Eg ! whole foods, ! %3 whole foods, !%description whole foods will
match if "whole foods" is NOT present. Added in 1.32.

The pattern is, as usual in hledger, a POSIX extended regular expression that also supports GNU word boundaries (\b, \B, \<, \>) and nothing else. For more details and tips, see Regular expressions in CSV
rules below.

## Multiple matchers

When an if block has multiple matchers, each on its own line,

• By default they are OR'd (any of them can match).

• Matcher lines beginning with & (or &&, since 1.42) are AND'ed with

```
the matcher above (all in the AND'ed group must match).

```
• Matcher lines beginning with & ! (since 1.41, or && !, since 1.42)

```
are first negated and then AND'ed with the matcher above.

```
You can also combine multiple matchers one the same line separated by
&& (AND) or && ! (AND NOT). Eg %description amazon && %date 2025-01-01
will match only when the description field contains "amazon" and the
date field contains "2025-01-01". Added in 1.42.

## Match groups

Added in 1.32

Matchers can define match groups: parenthesised portions of the regular
expression which are available for reference in field assignments.
Groups are enclosed in regular parentheses (( and )) and can be nested.
Each group is available in field assignments using the token \N, where
N is an index into the match groups for this conditional block (e.g.
\1, \2, etc.).

Example: Warp credit card payment postings to the beginning of the
billing period (Month start), to match how they are presented in statements, using posting dates:

```
if %date (....-..)-..
comment2 date:\1-01

```
Another example: Read the expense account from the CSV field, but throw
away a prefix:

```
if %account1 liabilities:family:(expenses:.*)
account1 \1

```
if table
"if tables" are an alternative to if blocks; they can express many
matchers and field assignments in a more compact tabular format, like
this:

```
if,HLEDGERFIELD1,HLEDGERFIELD2,...
MATCHERA,VALUE1,VALUE2,...
MATCHERB && MATCHERC,VALUE1,VALUE2,...  (*since 1.42*)
; Comment line that explains MATCHERD
MATCHERD,VALUE1,VALUE2,...
<empty line>

```
The first character after if is taken to be this if table's field separator. It is unrelated to the separator used in the CSV file. It
should be a non-alphanumeric character like , or | that does not appear
anywhere else in the table (it should not be used in field names or
matchers or values, and it cannot be escaped with a backslash).

Each line must contain the same number of separators; empty values are
allowed. Whitespace can be used in the matcher lines for readability
(but not in the if line, currently). You can use the comment lines in
the table body. The table must be terminated by an empty line (or end
of file).

An if table like the above is interpreted as follows: try all of the
lines with matchers; whenever a line with matchers succeeds, assign all
of the values on that line to the corresponding hledger fields; If multiple lines match, later lines will override fields assigned by the
earlier ones - just like the sequence of if blocks would behave.

If table presented above is equivalent to this sequence of if blocks:

```
if MATCHERA
HLEDGERFIELD1 VALUE1
HLEDGERFIELD2 VALUE2
...

if MATCHERB && MATCHERC
HLEDGERFIELD1 VALUE1
HLEDGERFIELD2 VALUE2
...

; Comment line which explains MATCHERD
if MATCHERD
HLEDGERFIELD1 VALUE1
HLEDGERFIELD2 VALUE2
...

```
Example:

```
if,account2,comment
atm transaction fee,expenses:business:banking,deductible? check it
%description groceries,expenses:groceries,
;; Comment line that desribes why this particular date is special
2023/01/12.*Plumbing LLC,expenses:house:upkeep,emergency plumbing call-out

```
balance-type
Balance assertions generated by assigning to balanceN are of the simple
= type by default, which is a single-commodity, subaccount-excluding
assertion. You may find the subaccount-including variants more useful,
eg if you have created some virtual subaccounts of checking to help
with budgeting. You can select a different type of assertion with the
balance-type rule:

```
# balance assertions will consider all commodities and all subaccounts
balance-type ==*

```
Here are the balance assertion types for quick reference:

```
=	   single commodity, exclude subaccounts
=*   single commodity, include subaccounts
==   multi commodity,  exclude subaccounts
==*  multi commodity,  include subaccounts

```
include

```
include RULESFILE

```
This includes the contents of another CSV rules file at this point.
RULESFILE is an absolute file path or a path relative to the current
file's directory. This can be useful for sharing common rules between
several rules files, eg:

```
# someaccount.csv.rules

## someaccount-specific rules
fields   date,description,amount
account1 assets:someaccount
account2 expenses:misc

## common rules
include categorisation.rules

```

## Working with CSV

Some tips:

## Rapid feedback

It's a good idea to get rapid feedback while creating/troubleshooting
CSV rules. Here's a good way, using entr from eradman.com/entrproject:

```
$ ls foo.csv* | entr bash -c 'echo ----; hledger -f foo.csv print desc:SOMEDESC'

```
A desc: query (eg) is used to select just one, or a few, transactions
of interest. "bash -c" is used to run multiple commands, so we can
echo a separator each time the command re-runs, making it easier to
read the output.

## Valid CSV

Note that hledger will only accept valid CSV conforming to RFC 4180,
and equivalent SSV and TSV formats (like RFC 4180 but with semicolon or
tab as separators). This means, eg:

• Values may be enclosed in double quotes, or not. Enclosing in single

```
quotes is not allowed.	 (Eg 'A','B' is rejected.)

```
• When values are enclosed in double quotes, spaces outside the quotes

```
are not allowed.  (Eg "A", "B" is rejected.)

```
• When values are not enclosed in quotes, they may not contain double

```
quotes.  (Eg A"A, B is rejected.)

```
If your CSV/SSV/TSV is not valid in this sense, you'll need to transform it before reading with hledger. Try using sed, or a more permissive CSV parser like python's csv lib.

## File Extension

To help hledger choose the CSV file reader and show the right error
messages (and choose the right field separator character by default),
it's best if CSV/SSV/TSV files are named with a .csv, .ssv or .tsv
filename extension. (More about this at Data formats.)

When reading files with the "wrong" extension, you can ensure the CSV
reader (and the default field separator) by prefixing the file path
with csv:, ssv: or tsv:: Eg:

```
$ hledger -f ssv:foo.dat print

```
You can also override the default field separator with a separator rule
if needed.

## Reading CSV from standard input

You'll need the file format prefix when reading CSV from stdin also,
since hledger assumes journal format by default. Eg:

```
$ cat foo.dat | hledger -f ssv:- print

```

## Reading multiple CSV files

If you use multiple -f options to read multiple CSV files at once,
hledger will look for a correspondingly-named rules file for each CSV
file. But if you specify a rules file with --rules, that rules file
will be used for all the CSV files.

## Reading files specified by rule

Instead of specifying a CSV file in the command line, you can specify a
rules file, as in hledger -f foo.csv.rules CMD. By default this will
read data from foo.csv in the same directory, but you can add a source
rule to specify a different data file, perhaps located in your web
browser's download directory.

This feature was added in hledger 1.30, so you won't see it in most CSV
rules examples. But it helps remove some of the busywork of managing
CSV downloads. Most of your financial institutions's default CSV filenames are different and can be recognised by a glob pattern. So you
can put a rule like source Checking1*.csv in foo-checking.csv.rules,
and then periodically follow a workflow like:

1. Download CSV from Foo's website, using your browser's defaults

2. Run hledger import foo-checking.csv.rules to import any new transactions

After import, you can: discard the CSV, or leave it where it is for a
while, or move it into your archives, as you prefer. If you do nothing, next time your browser will save something like Checking1-2.csv,
and hledger will use that because of the * wild card and because it is
the most recent.

## Valid transactions

After reading a CSV file, hledger post-processes and validates the generated journal entries as it would for a journal file - balancing them,
applying balance assignments, and canonicalising amount styles. Any
errors at this stage will be reported in the usual way, displaying the
problem entry.

There is one exception: balance assertions, if you have generated them,
will not be checked, since normally these will work only when the CSV
data is part of the main journal. If you do need to check balance assertions generated from CSV right away, pipe into another hledger:

```
$ hledger -f file.csv print | hledger -f- print

```

## Deduplicating, importing

When you download a CSV file periodically, eg to get your latest bank
transactions, the new file may overlap with the old one, containing
some of the same records.

The import command will (a) detect the new transactions, and (b) append
just those transactions to your main journal. It is idempotent, so you
don't have to remember how many times you ran it or with which version
of the CSV. (It keeps state in a hidden .latest.FILE.csv file.) This
is the easiest way to import CSV data. Eg:

```
# download the latest CSV files, then run this command.
# Note, no -f flags needed here.
$ hledger import *.csv [--dry]

```
This method works for most CSV files. (Where records have a stable
chronological order, and new records appear only at the new end.)

A number of other tools and workflows, hledger-specific and otherwise,
exist for converting, deduplicating, classifying and managing CSV data.
See:

• https://hledger.org/cookbook.html#setups-and-workflows

• https://plaintextaccounting.org -> data import/conversion

## Regular expressions in CSV rules

Regular expressions in if conditions (AKA matchers) are POSIX extended
regular expressions, that also support GNU word boundaries (\b, \B, \<,
\>), and nothing else. (For more detail, see Regular expressions.)

Here are some examples that might be useful in CSV rules:

• Is field "foo" truly empty ? if %foo ^$

• Is it empty or containing only whitespace ? if %foo ^ *$

• Is it non-empty ? if %foo .

• Does it contain non-whitespace ? if %foo [^ ]

Testing the value of numeric fields is a little harder. You can't use
hledger queries like amt:0 or amt:>10 in CSV rules. But you can often
achieve the same thing with a regular expression.

Note the content and layout of number fields in CSV varies, and can
change over time (eg if you switch data providers). So numeric regexps
are always somewhat specific to your particular CSV data; and it's a
good idea to make them defensive and robust if you can.

Here are some examples:

• Does foo contain a non-zero number ? if %foo [1-9]

• Is it negative ? if %foo -

• Is it non-negative ? if ! %foo -

• Is it >= 10 ? if %foo [1-9][0-9]+\. (assuming a decimal period and

```
no leading zeros)

```
• Is it >= 10 and < 20 ? if %foo \b1[0-9]\.

## Setting amounts

Continuing from amount field above, here are more tips for amount-setting:

1. If the amount is in a single CSV field:

```
a. If its sign indicates direction of flow:
Assign  it  to amountN, to set the Nth posting's amount.  N is usually 1 or 2 but can go up to 99.

b. If another field indicates direction of flow:
Use one or more conditional rules to	 set  the  appropriate	amount
sign.  Eg:

# assume a withdrawal unless Type contains "deposit":
amount1  -%Amount
if %Type deposit
amount1  %Amount

```
2. If the amount is in two CSV fields (such as Debit and Credit, or In

```
and Out):
a. If both fields are unsigned:
Assign one field  to	 amountN-in  and  the  other  to  amountN-out.
hledger  will  automatically	 negate	 the "out" field, and will use
whichever field value is non-zero as posting N's amount.

b. If either field is signed:
You will probably need to override hledger's sign for  one  or  the
other field, as in the following example:

# Negate the -out value, but only if it is not empty:
fields date, description, amount1-in, amount1-out
if %amount1-out [1-9]
amount1-out -%amount1-out

c. If  both	fields	can  contain  a non-zero value (or both can be
empty):
The	-in/-out  rules	  normally   choose   the   value   which   is
non-zero/non-empty.	 Some  value pairs can be ambiguous, such as 1
and none.  For such cases, use conditional rules to help select the
amount.   Eg,  to  handle the above you could select the value containing non-zero digits:

fields date, description, in, out
if %in [1-9]
amount1 %in
if %out [1-9]
amount1 %out

```
3. If you want posting 2's amount converted to cost:
Use the unnumbered amount (or amount-in and amount-out) syntax.

4. If the CSV has only balance amounts, not transaction amounts:
Assign to balanceN, to set a balance assignment on the Nth posting,
causing the posting's amount to be calculated automatically. balance
with no number is equivalent to balance1. In this situation hledger is
more likely to guess the wrong default account name, so you may need to
set that explicitly.

## Amount signs

There is some special handling making it easier to parse and to reverse
amount signs. (This only works for whole amounts, not for cost amounts
such as COST in amount1 AMT @ COST):

• If an amount value begins with a plus sign:
that will be removed: +AMT becomes AMT

• If an amount value is parenthesised:
it will be de-parenthesised and sign-flipped: (AMT) becomes -AMT

• If an amount value has two minus signs (or two sets of parentheses,

```
or a minus sign and parentheses):
```
they cancel out and will be removed: --AMT or -(AMT) becomes AMT

• If an amount value contains just a sign (or just a set of parentheses):
that is removed, making it an empty value. "+" or "-" or "()" becomes
"".

It's not possible (without preprocessing the CSV) to set an amount to
its absolute value, ie discard its sign.

## Setting currency/commodity

If the currency/commodity symbol is included in the CSV's amount
field(s):

```
2023-01-01,foo,$123.00

```
you don't have to do anything special for the commodity symbol, it will
be assigned as part of the amount. Eg:

```
fields date,description,amount

2023-01-01 foo
expenses:unknown	   $123.00
income:unknown	  $-123.00

```
If the currency is provided as a separate CSV field:

```
2023-01-01,foo,USD,123.00

```
You can assign that to the currency pseudo-field, which has the special
effect of prepending itself to every amount in the transaction (on the
left, with no separating space):

```
fields date,description,currency,amount

2023-01-01 foo
expenses:unknown	 USD123.00
income:unknown	USD-123.00

```
Or, you can use a field assignment to construct the amount yourself,
with more control. Eg to put the symbol on the right, and separated by
a space:

```
fields date,description,cur,amt
amount %amt %cur

2023-01-01 foo
expenses:unknown	  123.00 USD
income:unknown	 -123.00 USD

```
Note we used a temporary field name (cur) that is not currency - that
would trigger the prepending effect, which we don't want here.

## Amount decimal places

When you are reading CSV data, eg with a command like hledger -f
foo.csv print, hledger will infer each commodity's decimal precision
(and other commodity display styles) from the amounts - much as when
reading a journal file without commodity directives (see the link).

Note, the commodity styles are not inferred from the numbers in the
original CSV data; rather, they are inferred from the amounts generated
by the CSV rules.

When you are importing CSV data with the import command, eg hledger import foo.csv, there's another step: import tries to make the new entries conform to the journal's existing styles. So for each commodity
- let's say it's EUR - import will choose:

1. the style declared for EUR by a commodity directive in the journal

2. otherwise, the style inferred from EUR amounts in the journal

3. otherwise, the style inferred from EUR amounts generated by the CSV

```
rules.

```
TLDR: if import is not generating the precisions or styles you want,
add a commodity directive to specify them.

## Referencing other fields

In field assignments, you can interpolate only CSV fields, not hledger
fields. In the example below, there's both a CSV field and a hledger
field named amount1, but %amount1 always means the CSV field, not the
hledger field:

```
# Name the third CSV field "amount1"
fields date,description,amount1

# Set hledger's amount1 to the CSV amount1 field followed by USD
amount1 %amount1 USD

# Set comment to the CSV amount1 (not the amount1 assigned above)
comment %amount1

```
Here, since there's no CSV amount1 field, %amount1 will produce a literal "amount1":

```
fields date,description,csvamount
amount1 %csvamount USD
# Can't interpolate amount1 here
comment %amount1

```
When there are multiple field assignments to the same hledger field,
only the last one takes effect. Here, comment's value will be be B, or
C if "something" is matched, but never A:

```
comment A
comment B
if something
comment C

```

## How CSV rules are evaluated

Here's how to think of CSV rules being evaluated. If you get a confusing error while reading a CSV file, it may help to try to understand
which of these steps is failing:

1. Any included rules files are inlined, from top to bottom, depth

```
first (scanning each included	 file  for  further  includes,	recursively, before proceeding).

```
2. Top level rules (date-format, fields, newest-first, skip etc) are

```
read, top to bottom.	"Top level rules" means non-conditional rules.
If  a	 rule  occurs  more  than  once, the last one wins; except for
skip/end rules, where the first one wins.

```
3. The CSV file is read as text. Any non-ascii characters will be decoded using the text encoding specified by the encoding rule, otherwise the system locale's text encoding.

4. Any top-level skip or end rule is applied. skip [N] immediately

```
skips	 the  current or next N CSV records; end immediately skips all
remaining CSV records (not normally used at top level).

```
5. Now any remaining CSV records are processed. For each CSV record,

```
in file order:

• Is there a conditional skip/end rule that applies for this record
?	Search the if blocks, from top to bottom, for a succeeding one
containing a skip or end rule.  If found, skip the specified number of CSV records, then continue at 5.
Otherwise...

• Do some basic validation on this CSV record (eg,  check  that  it
has at least two fields).

• For each hledger field (date, description, account1, etc.):

1. Get  the field's assigned value, first searching top level assignments, made directly or by the fields rule,	 then  assignments  made  inside  succeeding	 if blocks.  If there are more
than one, the last one wins.

2. Compute the field's actual value (as text),  by	 interpolating
any  %CSVFIELD	references  within  the	 assigned value; or by
choosing a default value if there was no assignment.

• Generate a hledger transaction from  the  hledger	field  values,
parsing them if needed (eg from text to an amount).

```
This is all done by the CSV reader, one of several readers hledger can
use to read transactions from an input file. When all input files have
been read successfully, their transactions are passed to whichever
hledger command the user specified.

## Well factored rules

Some things than can help reduce duplication and complexity in rules
files:

• Extracting common rules usable with multiple CSV files into a common.rules, and adding include common.rules to each CSV's rules file.

• Splitting if blocks into smaller if blocks, extracting the frequently

```
used parts.

```

## CSV rules examples

## Bank of Ireland

Here's a CSV with two amount fields (Debit and Credit), and a balance
field, which we can use to add balance assertions, which is not necessary but provides extra error checking:

```
Date,Details,Debit,Credit,Balance
07/12/2012,LODGMENT	529898,,10.0,131.21
07/12/2012,PAYMENT,5,,126

# bankofireland-checking.csv.rules

# skip the header line
skip

# name the csv fields, and assign some of them as journal entry fields
fields  date, description, amount-out, amount-in, balance

# We generate balance assertions by assigning to "balance"
# above, but you may sometimes need to remove these because:
#
# - the CSV balance differs from the true balance,
#	  by up to 0.0000000000005 in my experience
#
# - it is sometimes calculated based on non-chronological ordering,
#	  eg when multiple transactions clear on the same day

# date is in UK/Ireland format
date-format  %d/%m/%Y

# set the currency
currency	EUR

# set the base account for all txns
account1	assets:bank:boi:checking

$ hledger -f bankofireland-checking.csv print
2012-12-07 LODGMENT	529898
assets:bank:boi:checking	   EUR10.0 = EUR131.2
income:unknown		  EUR-10.0

2012-12-07 PAYMENT
assets:bank:boi:checking	   EUR-5.0 = EUR126.0
expenses:unknown		    EUR5.0

```
The balance assertions don't raise an error above, because we're reading directly from CSV, but they will be checked if these entries are
imported into a journal file.

## Coinbase

A simple example with some CSV from Coinbase. The spot price is
recorded using cost notation. The legacy amount field name conveniently sets amount 2 (posting 2's amount) to the total cost.

```
# Timestamp,Transaction Type,Asset,Quantity Transacted,Spot Price Currency,Spot Price at Transaction,Subtotal,Total (inclusive of fees and/or spread),Fees and/or Spread,Notes
# 2021-12-30T06:57:59Z,Receive,USDC,100,GBP,0.740000,"","","","Received 100.00 USDC from an external account"

# coinbase.csv.rules
skip	   1
fields	   Timestamp,Transaction_Type,Asset,Quantity_Transacted,Spot_Price_Currency,Spot_Price_at_Transaction,Subtotal,Total,Fees_Spread,Notes
date	   %Timestamp
date-format  %Y-%m-%dT%T%Z
description  %Notes
account1	   assets:coinbase:cc
amount	   %Quantity_Transacted %Asset @ %Spot_Price_at_Transaction %Spot_Price_Currency

$ hledger print -f coinbase.csv
2021-12-30 Received 100.00 USDC from an external account
assets:coinbase:cc	100 USDC @ 0.740000 GBP
income:unknown		 -74.000000 GBP

```

## Amazon

Here we convert amazon.com order history, and use an if block to generate a third posting if there's a fee. (In practice you'd probably get
this data from your bank instead, but it's an example.)

```
"Date","Type","To/From","Name","Status","Amount","Fees","Transaction ID"
"Jul 29, 2012","Payment","To","Foo.","Completed","$20.00","$0.00","16000000000000DGLNJPI1P9B8DKPVHL"
"Jul 30, 2012","Payment","To","Adapteva, Inc.","Completed","$25.00","$1.00","17LA58JSKRD4HDGLNJPI1P9B8DKPVHL"

# amazon-orders.csv.rules

# skip one header line
skip 1

# name the csv fields, and assign the transaction's date, amount and code.
# Avoided the "status" and "amount" hledger field names to prevent confusion.
fields date, _, toorfrom, name, amzstatus, amzamount, fees, code

# how to parse the date
date-format %b %-d, %Y

# combine two fields to make the description
description %toorfrom %name

# save the status as a tag
comment	  status:%amzstatus

# set the base account for all transactions
account1	  assets:amazon
# leave amount1 blank so it can balance the other(s).
# I'm assuming amzamount excludes the fees, don't remember

# set a generic account2
account2	  expenses:misc
amount2	  %amzamount
# and maybe refine it further:
#include categorisation.rules

# add a third posting for fees, but only if they are non-zero.
if %fees [1-9]
account3	   expenses:fees
amount3	   %fees

$ hledger -f amazon-orders.csv print
2012-07-29 (16000000000000DGLNJPI1P9B8DKPVHL) To Foo.  ; status:Completed
assets:amazon
expenses:misc		 $20.00

2012-07-30 (17LA58JSKRD4HDGLNJPI1P9B8DKPVHL) To Adapteva, Inc.  ; status:Completed
assets:amazon
expenses:misc		 $25.00
expenses:fees		  $1.00

```

## Paypal

Here's a real-world rules file for (customised) Paypal CSV, with some
Paypal-specific rules, and a second rules file included:

```
"Date","Time","TimeZone","Name","Type","Status","Currency","Gross","Fee","Net","From Email Address","To Email Address","Transaction ID","Item Title","Item ID","Reference Txn ID","Receipt ID","Balance","Note"
"10/01/2019","03:46:20","PDT","Calm Radio","Subscription Payment","Completed","USD","-6.99","0.00","-6.99","simon@joyful.com","memberships@calmradio.com","60P57143A8206782E","MONTHLY - $1 for the first 2 Months: Me - Order 99309. Item total: $1.00 USD first 2 months, then $6.99 / Month","","I-R8YLY094FJYR","","-6.99",""
"10/01/2019","03:46:20","PDT","","Bank Deposit to PP Account ","Pending","USD","6.99","0.00","6.99","","simon@joyful.com","0TU1544T080463733","","","60P57143A8206782E","","0.00",""
"10/01/2019","08:57:01","PDT","Patreon","PreApproved Payment Bill User Payment","Completed","USD","-7.00","0.00","-7.00","simon@joyful.com","support@patreon.com","2722394R5F586712G","Patreon* Membership","","B-0PG93074E7M86381M","","-7.00",""
"10/01/2019","08:57:01","PDT","","Bank Deposit to PP Account ","Pending","USD","7.00","0.00","7.00","","simon@joyful.com","71854087RG994194F","Patreon* Membership","","2722394R5F586712G","","0.00",""
"10/19/2019","03:02:12","PDT","Wikimedia Foundation, Inc.","Subscription Payment","Completed","USD","-2.00","0.00","-2.00","simon@joyful.com","tle@wikimedia.org","K9U43044RY432050M","Monthly donation to the Wikimedia Foundation","","I-R5C3YUS3285L","","-2.00",""
"10/19/2019","03:02:12","PDT","","Bank Deposit to PP Account ","Pending","USD","2.00","0.00","2.00","","simon@joyful.com","3XJ107139A851061F","","","K9U43044RY432050M","","0.00",""
"10/22/2019","05:07:06","PDT","Noble Benefactor","Subscription Payment","Completed","USD","10.00","-0.59","9.41","noble@bene.fac.tor","simon@joyful.com","6L8L1662YP1334033","Joyful Systems","","I-KC9VBGY2GWDB","","9.41",""

# paypal-custom.csv.rules

# Tips:
# Export from Activity -> Statements -> Custom -> Activity download
# Suggested transaction type: "Balance affecting"
# Paypal's default fields in 2018 were:
# "Date","Time","TimeZone","Name","Type","Status","Currency","Gross","Fee","Net","From Email Address","To Email Address","Transaction ID","Shipping Address","Address Status","Item Title","Item ID","Shipping and Handling Amount","Insurance Amount","Sales Tax","Option 1 Name","Option 1 Value","Option 2 Name","Option 2 Value","Reference Txn ID","Invoice Number","Custom Number","Quantity","Receipt ID","Balance","Address Line 1","Address Line 2/District/Neighborhood","Town/City","State/Province/Region/County/Territory/Prefecture/Republic","Zip/Postal Code","Country","Contact Phone Number","Subject","Note","Country Code","Balance Impact"
# This rules file assumes the following more detailed fields, configured in "Customize report fields":
# "Date","Time","TimeZone","Name","Type","Status","Currency","Gross","Fee","Net","From Email Address","To Email Address","Transaction ID","Item Title","Item ID","Reference Txn ID","Receipt ID","Balance","Note"

fields date, time, timezone, description_, type, status_, currency, grossamount, feeamount, netamount, fromemail, toemail, code, itemtitle, itemid, referencetxnid, receiptid, balance, note

skip  1

date-format  %-m/%-d/%Y

# ignore some paypal events
if
In Progress
Temporary Hold
Update to
skip

# add more fields to the description
description %description_ %itemtitle

# save some other fields as tags
comment  itemid:%itemid, fromemail:%fromemail, toemail:%toemail, time:%time, type:%type, status:%status_

# convert to short currency symbols
if %currency USD
currency $
if %currency EUR
currency E
if %currency GBP
currency P

# generate postings

# the first posting will be the money leaving/entering my paypal account
# (negative means leaving my account, in all amount fields)
account1 assets:online:paypal
amount1  %netamount

# the second posting will be money sent to/received from other party
# (account2 is set below)
amount2  -%grossamount

# if there's a fee, add a third posting for the money taken by paypal.
if %feeamount [1-9]
account3 expenses:banking:paypal
amount3	-%feeamount
comment3 business:

# choose an account for the second posting

# override the default account names:
# if the amount is positive, it's income (a debit)
if %grossamount ^[^-]
account2 income:unknown
# if negative, it's an expense (a credit)
if %grossamount ^-
account2 expenses:unknown

# apply common rules for setting account2 & other tweaks
include common.rules

# apply some overrides specific to this csv

# Transfers from/to bank. These are usually marked Pending,
# which can be disregarded in this case.
if
Bank Account
Bank Deposit to PP Account
description %type for %referencetxnid %itemtitle
account2 assets:bank:wf:pchecking
account1 assets:online:paypal

# Currency conversions
if Currency Conversion
account2 equity:currency conversion

# common.rules

if
darcs
noble benefactor
account2 revenues:foss donations:darcshub
comment2 business:

if
Calm Radio
account2 expenses:online:apps

if
electronic frontier foundation
Patreon
wikimedia
Advent of Code
account2 expenses:dues

if Google
account2 expenses:online:apps
description google | music

$ hledger -f paypal-custom.csv  print
2019-10-01 (60P57143A8206782E) Calm Radio MONTHLY - $1 for the first 2 Months: Me - Order 99309. Item total: $1.00 USD first 2 months, then $6.99 / Month	 ; itemid:, fromemail:simon@joyful.com, toemail:memberships@calmradio.com, time:03:46:20, type:Subscription Payment, status:Completed
assets:online:paypal		$-6.99 = $-6.99
expenses:online:apps		 $6.99

2019-10-01 (0TU1544T080463733) Bank Deposit to PP Account for 60P57143A8206782E  ; itemid:, fromemail:, toemail:simon@joyful.com, time:03:46:20, type:Bank Deposit to PP Account, status:Pending
assets:online:paypal		     $6.99 = $0.00
assets:bank:wf:pchecking	    $-6.99

2019-10-01 (2722394R5F586712G) Patreon Patreon* Membership  ; itemid:, fromemail:simon@joyful.com, toemail:support@patreon.com, time:08:57:01, type:PreApproved Payment Bill User Payment, status:Completed
assets:online:paypal		$-7.00 = $-7.00
expenses:dues			 $7.00

2019-10-01 (71854087RG994194F) Bank Deposit to PP Account for 2722394R5F586712G Patreon* Membership  ; itemid:, fromemail:, toemail:simon@joyful.com, time:08:57:01, type:Bank Deposit to PP Account, status:Pending
assets:online:paypal		     $7.00 = $0.00
assets:bank:wf:pchecking	    $-7.00

2019-10-19 (K9U43044RY432050M) Wikimedia Foundation, Inc. Monthly donation to the Wikimedia Foundation  ; itemid:, fromemail:simon@joyful.com, toemail:tle@wikimedia.org, time:03:02:12, type:Subscription Payment, status:Completed
assets:online:paypal		   $-2.00 = $-2.00
expenses:dues			    $2.00
expenses:banking:paypal      ; business:

2019-10-19 (3XJ107139A851061F) Bank Deposit to PP Account for K9U43044RY432050M  ; itemid:, fromemail:, toemail:simon@joyful.com, time:03:02:12, type:Bank Deposit to PP Account, status:Pending
assets:online:paypal		     $2.00 = $0.00
assets:bank:wf:pchecking	    $-2.00

2019-10-22 (6L8L1662YP1334033) Noble Benefactor Joyful Systems  ; itemid:, fromemail:noble@bene.fac.tor, toemail:simon@joyful.com, time:05:07:06, type:Subscription Payment, status:Completed
assets:online:paypal			     $9.41 = $9.41
revenues:foss donations:darcshub	   $-10.00  ; business:
expenses:banking:paypal		     $0.59  ; business:

```
Timeclock
hledger can read time logs in the timeclock time logging format of
timeclock.el. As with Ledger, hledger's timeclock format is a subset/variant of timeclock.el's.

hledger's timeclock format was updated in hledger 1.43 and 1.50. If
your old time logs are rejected, you should adapt them to modern
hledger; for now, you can restore the pre-1.43 behaviour with the
--old-timeclock flag.

Here the timeclock format in hledger 1.50+:

```
# Comment lines like these, and blank lines, are ignored:
# comment line
; comment line
* comment line

# Lines beginning with b, h, or capital O are also ignored, for compatibility:
b SIMPLEDATE HH:MM[:SS][+-ZZZZ][ TEXT]
h SIMPLEDATE HH:MM[:SS][+-ZZZZ][ TEXT]
O SIMPLEDATE HH:MM[:SS][+-ZZZZ][ TEXT]

# Lines beginning with i or o are are clock-in / clock-out entries:
i SIMPLEDATE HH:MM[:SS][+-ZZZZ] ACCOUNT[	DESCRIPTION][;COMMENT]]
o SIMPLEDATE HH:MM[:SS][+-ZZZZ][ ACCOUNT][;COMMENT]

```
The date is a hledger simple date (YYYY-MM-DD or similar). The time
parts must use two digits. The seconds are optional. A + or -
four-digit time zone is accepted for compatibility, but currently ignored; times are always interpreted as a local time.

In clock-in entries (i), the account name is required. A transaction
description, separated from the account name by 2+ spaces, is optional.
A transaction comment, beginning with ;, is also optional. (Indented
following comment lines are also allowed, as in journal format.)

In clock-out entries (o) have no description, but can have a comment if
you wish. A clock-in and clock-out pair form a "transaction" posting
some number of hours to an account - also known as a session. Eg:

```
i 2015/03/30 09:00:00 session1
o 2015/03/30 10:00:00

$ hledger -f a.timeclock print
2015-03-30 * 09:00-10:00
(session1)	       1.00h

```
Clock-ins and clock-outs are matched by their account/session name. If
a clock-out does not specify a name, the most recent unclosed clock-in
is closed. You can have multiple sessions active simultaneously. Entries are processed in the order they are parsed. Sessions spanning
more than one day are automatically split at day boundaries.

Eg, the following time log:

```
i 2015/03/30 09:00:00 some account  optional description after 2 spaces ; optional comment, tags:
o 2015/03/30 09:20:00
i 2015/03/31 22:21:45 another:account
o 2015/04/01 02:00:34
i 2015/04/02 12:00:00 another:account  ; this demonstrates multple sessions being clocked in
i 2015/04/02 13:00:00 some account
o 2015/04/02 14:00:00
o 2015/04/02 15:00:00 another:account

```
generates these transactions:

```
$ hledger -f t.timeclock print
2015-03-30 * optional description after 2 spaces	 ; optional comment, tags:
(some account)	   0.33h

2015-03-31 * 22:21-23:59
(another:account)	      1.64h

2015-04-01 * 00:00-02:00
(another:account)	      2.01h

2015-04-02 * 12:00-15:00	; this demonstrates multiple sessions being clocked in
(another:account)	      3.00h

2015-04-02 * 13:00-14:00
(some account)	   1.00h

```
Here is a sample.timeclock to download and some queries to try:

```
$ hledger -f sample.timeclock balance				  # current time balances
$ hledger -f sample.timeclock register -p 2009/3			  # sessions in march 2009
$ hledger -f sample.timeclock register -p weekly --depth 1 --empty  # time summary by week

```
To generate time logs, ie to clock in and clock out, you could:

• use these shell aliases at the command line:

```
alias ti='echo i `date "+%Y-%m-%d %H:%M:%S"` $* >>$TIMELOG'
alias to='echo o `date "+%Y-%m-%d %H:%M:%S"` >>$TIMELOG'

```
• or Emacs's built-in timeclock.el, or the extended timeclock-x.el, and

```
perhaps the extras in ledgerutils.el

```
• or use the old ti and to scripts in the ledger 2.x repository. These

```
rely  on  a "timeclock" executable which I think is just the ledger 2
executable renamed.

```
Timedot
timedot format is hledger's human-friendly time logging format. Compared to timeclock format, it is more convenient for quick, approximate, and retroactive time logging, and more human-readable (you can
see at a glance where time was spent). A quick example:

```
2023-05-01
hom:errands	   .... ....  ; two hours; the space is ignored
fos:hledger:timedot  ..	      ; half an hour
per:admin:finance		      ; no time spent yet

```
hledger reads this as a transaction on this day with three (unbalanced)
postings, where each dot represents "0.25". No commodity symbol is assumed, but we typically interpret it as hours.

```
$ hledger -f a.timedot print   # .timedot file extension (or timedot: prefix) is required
2023-05-01 *
(hom:errands)			   2.00	 ; two hours
(fos:hledger:timedot)		   0.50	 ; half an hour
(per:admin:finance)		      0

```
A timedot file contains a series of transactions (usually one per day).
Each begins with a simple date (Y-M-D, Y/M/D, or Y.M.D), optionally be
followed on the same line by a transaction description, and/or a transaction comment following a semicolon.

After the date line are zero or more time postings, consisting of:

• An account name - any hledger-style account name, optionally indented.

• Two or more spaces - required if there is an amount (as in journal

```
format).

```
• A timedot amount, which can be

```
• empty (representing zero)

• a number, optionally followed by a unit s, m, h, d, w,  mo,	or  y,
representing	 a  precise  number  of	 seconds, minutes, hours, days
weeks, months or years (hours is assumed by default), which will be
converted  to hours according to 60s = 1m, 60m = 1h, 24h = 1d, 7d =
1w, 30d = 1mo, 365d = 1y.

• one or more	dots  (period  characters),  each  representing	 0.25.
These  are  the  dots  in "timedot".	 Spaces are ignored and can be
used for grouping/alignment.

• Added in 1.32 one or more letters.  These are like  dots  but  they
also	 generate  a  tag t: (short for "type") with the letter as its
value, and a separate posting for each of the  values.   This  provides  a  second  dimension	of categorisation, viewable in reports
with --pivot t.

```
• An optional comment following a semicolon (a hledger-style posting

```
comment).

```
There is some flexibility to help with keeping time log data and notes
in the same file:

• Blank lines and lines beginning with # or ; are ignored.

• After the first date line, lines which do not contain a double space

```
are parsed as postings with zero amount.  (hledger's register reports
will show these if you add -E).

```
• Before the first date line, lines beginning with * (eg org headings)

```
are  ignored.	 And  from  the first date line onward, Emacs org mode
heading prefixes at the start of lines (one or more *'s followed by a
space)	 will  be  ignored.  This means the time log can also be a org
outline.

```
Timedot files don't support directives like journal files. So a common
pattern is to have a main journal file (eg time.journal) that contains
any needed directives, and then includes the timedot file (include
time.timedot).

## Timedot examples

Numbers:

```
2016/2/3
inc:client1   4
fos:hledger   3h
biz:research  60m

```
Dots:

```
# on this day, 6h was spent on client work, 1.5h on haskell FOSS work, etc.
2016/2/1
inc:client1   .... .... .... .... .... ....
fos:haskell   .... ..
biz:research  .

2016/2/2
inc:client1   .... ....
biz:research  .

$ hledger -f a.timedot print date:2016/2/2
2016-02-02 *
(inc:client1)		 2.00

2016-02-02 *
(biz:research)	  0.25

$ hledger -f a.timedot bal --daily --tree
Balance changes in 2016-02-01-2016-02-03:

||  2016-02-01d  2016-02-02d	2016-02-03d
============++========================================
biz	  ||	     0.25	  0.25	       1.00
research ||	     0.25	  0.25	       1.00
fos	  ||	     1.50	     0	       3.00
haskell  ||	     1.50	     0		  0
hledger  ||		0	     0	       3.00
inc	  ||	     6.00	  2.00	       4.00
client1  ||	     6.00	  2.00	       4.00
------------++----------------------------------------
||	     7.75	  2.25	       8.00

```
Letters:

```
# Activity types:
#	 c cleanup/catchup/repair
#	 e enhancement
#	 s support
#	 l learning/research

2023-11-01
work:adm	ccecces

$ hledger -f a.timedot print
2023-11-01
(work:adm)  1	    ; t:c
(work:adm)  0.5   ; t:e
(work:adm)  0.25  ; t:s

$ hledger -f a.timedot bal
1.75  work:adm
--------------------
1.75

$ hledger -f a.timedot bal --pivot t
1.00  c
0.50  e
0.25  s
--------------------
1.75

```
Org:

```
* 2023 Work Diary
** Q1
*** 2023-02-29
**** DONE
0700 yoga
**** UNPLANNED
**** BEGUN
hom:chores
cleaning	 ...
water plants
outdoor - one full watering can
indoor - light watering
**** TODO
adm:planning: trip
*** LATER

```
Using . as account name separator:

```
2016/2/4
fos.hledger.timedot  4h
fos.ledger	   ..

$ hledger -f a.timedot --alias '/\./=:' bal -t
4.50  fos
4.00    hledger:timedot
0.50    ledger
--------------------
4.50

```
PART 3: REPORTING CONCEPTS
Time periods

## Report start & end date

Most hledger reports will by default show the full time period represented by the journal. The report start date will be the earliest
transaction or posting date, and the report end date will be the latest
transaction, posting, or market price date.

Often you will want to see a shorter period, such as the current month.
You can specify a start and/or end date with the -b/--begin, -e/--end,
or -p/--period options, or a date: query argument, described below.
All of these accept the smart date syntax, also described below.

End dates are exclusive; specify the day after the last day you want to
see in the report.

When dates are specified by multiple options, the last (right-most) option wins. And when date: queries and date options are combined, the
report period will be their intersection.

Examples:

-b 2016/3/17

```
beginning on St.	Patrick’s day 2016

```
-e 12/1

```
ending at the start of December 1st in the current year

```
-p 'this month'

```
during the current month

```
-p thismonth

```
same as above, spaces are optional

```
-b 2023

```
beginning on the first day of 2023

```
date:2023.. or date:2023-

```
same as above

```
-b 2024 -e 2025 -p '2000 to 2030' date:2020-01 date:2020 :
during January 2020 (the smallest common period, with the -p overriding
-b and -e)

## Smart dates

In hledger's user interfaces (though not in the journal file), you can
optionally use "smart date" syntax. Smart dates can be written with
english words, can be relative, and can have parts omitted. Missing
parts are inferred as 1, when needed. Smart dates can be interpreted
as dates or periods depending on the context.

Examples:

2004-01-01, 2004/10/1, 2004.9.1, 20240504, 2024Q1 :
Exact dates. The year must have at least four digits, the month must
be 1-12, the day must be 1-31, the separator can be - or / or . or
nothing. The q can be upper or lower case and the quarter number must
be 1-4.

2004-10

```
start of month

```
2004q3 start of third quarter of 2004

q3 start of third quarter of current year

2004 start of year

10/1 or oct or october

```
October 1st in current year

```
21 21st day in current month

yesterday, today, tomorrow

```
-1, 0, 1 days from today

```
last/this/next day/week/month/quarter/year

```
-1, 0, 1 periods from the current period

```
in n days/weeks/months/quarters/years

```
n periods from the current period

```
n days/weeks/months/quarters/years ahead

```
n periods from the current period

```
n days/weeks/months/quarters/years ago

```
-n periods from the current period

```
20181201

```
8 digit YYYYMMDD with valid year month and day

```
201812 6 digit YYYYMM with valid year and month

Dates with no separators are allowed but might give surprising results
if mistyped:

• 20181301 (YYYYMMDD with an invalid month) is parsed as an eight-digit

```
year

```
• 20181232 (YYYYMMDD with an invalid day) gives a parse error

• 201801012 (a valid YYYYMMDD followed by additional digits) gives a

```
parse error

```
The meaning of relative dates depends on today's date. If you need to
test or reproduce old reports, you can use the --today option to override that. (Except for periodic transaction rules, which are not affected by --today.)

## Report intervals

A report interval can be specified so that reports like register, balance or activity become multi-period, showing each subperiod as a separate row or column.

The following standard intervals can be enabled with command-line
flags:

• -D/--daily

• -W/--weekly

• -M/--monthly

• -Q/--quarterly

• -Y/--yearly

More complex intervals can be specified using -p/--period, described
below.

## Date adjustments

## Start date adjustment

If you let hledger infer a report's start date, it will adjust the date
to the previous natural boundary of the report interval, for convenient
periodic reports. (If you don't want that, specify a start date.)

For example, if the journal's first transaction is on january 10th,

• hledger register (no report interval) will start the report on january 10th.

• hledger register --monthly will start the report on the previous

```
month boundary, january 1st.

```
• hledger register --monthly --begin 1/5 will start the report on january 5th [1].

Also if you are generating transactions or budget goals with periodic
transaction rules, their start date may be adjusted in a similar way
(in certain situations).

## End date adjustment

A report's end date is always adjusted to include a whole number of intervals, so that the last subperiod has the same length as the others.

For example, if the journal's last transaction is on february 20th,

• hledger register will end the report on february 20th.

• hledger register --monthly will end the report at the end of february.

• hledger register --monthly --end 2/14 also will end the report at the

```
end of february (overriding the requested end date).

```
• hledger register --monthly --begin 1/5 --end 2/14 will end the report

```
on march 4th [1].

```
[1] Since hledger 1.29.

## Period headings

With non-standard subperiods, hledger will show "STARTDATE..ENDDATE"
headings. With standard subperiods (ie, starting on a natural interval
boundary), you'll see more compact headings, which are usually preferable. (Though month names will be in english, currently.)

So if you are specifying a start date and you want compact headings:
choose a start of year for yearly reports, a start of quarter for quarterly reports, a start of month for monthly reports, etc. (Remember,
you can write eg -b 2024 or 1/1 as a shortcut for a start of year, or
2024-04 or 202404 or Apr for a start of month or quarter.)

For weekly reports, choose a date that's a Monday. (You can try different dates until you see the short headings, or write eg -b '3 weeks
ago'.)

## Period expressions

The -p/--period option specifies a period expression, which is a compact way of expressing a start date, end date, and/or report interval.

Here's a period expression with a start and end date (specifying the
first quarter of 2009):

-p "from 2009/1/1 to 2009/4/1"

Several keywords like "from" and "to" are supported for readability;
these are optional. "to" can also be written as ".." or "-". The spaces are also optional, as long as you don't run two dates together. So
the following are equivalent to the above:

-p "2009/1/1 2009/4/1"
-p2009/1/1to2009/4/1
-p2009/1/1..2009/4/1

Dates are smart dates, so if the current year is 2009, these are also
equivalent to the above:

-p "1/1 4/1"
-p "jan-apr"
-p "this year to 4/1"

If you specify only one date, the missing start or end date will be the
earliest or latest transaction date in the journal:

-p "from 2009/1/1" everything after january

```
1, 2009
```
-p "since 2009/1" the same, since is a synonym
-p "from 2009" the same
-p "to 2009" everything before january

```
1, 2009

```
You can also specify a period by writing a single partial or full date:

-p "2009" the year 2009; equivalent to “2009/1/1 to 2010/1/1”
-p "2009/1" the month of january 2009; equivalent to “2009/1/1 to

```
2009/2/1”
```
-p "2009/1/1" the first day of 2009; equivalent to “2009/1/1 to

```
2009/1/2”

```
or by using the "Q" quarter-year syntax (case insensitive):

-p "2009Q1" first quarter of 2009, equivalent to “2009/1/1 to

```
2009/4/1”
```
-p "q4" fourth quarter of the current year

## Period expressions with a report interval

A period expression can also begin with a report interval, separated
from the start/end dates (if any) by a space or the word in:

-p "weekly from 2009/1/1 to 2009/4/1"
-p "monthly in 2008"
-p "quarterly"

## More complex report intervals

Some more complex intervals can be specified within period expressions,
such as:

• biweekly (every two weeks)

• fortnightly

• bimonthly (every two months)

• every day|week|month|quarter|year

• every N days|weeks|months|quarters|years

Weekly on a custom day:

• every Nth day of week (th, nd, rd, or st are all accepted after the

```
number)

```
• every WEEKDAYNAME (full or three-letter english weekday name, case

```
insensitive)

```
Monthly on a custom day:

• every Nth day [of month] (31st day will be adjusted to each month's

```
last day)

```
• every Nth WEEKDAYNAME [of month]

Yearly on a custom month and day:

• every MM/DD [of year] (month number and day of month number)

• every MONTHNAME DDth [of year] (full or three-letter english month

```
name, case insensitive, and day of month number)

```
• every DDth MONTHNAME [of year] (equivalent to the above)

Examples:

-p "bimonthly from 2008"
-p "every 2 weeks"
-p "every 5 months from
2009/03"
-p "every 2nd day of week" periods will go from Tue to Tue
-p "every Tue" same
-p "every 15th day" period boundaries will be on 15th of each

```
month
```
-p "every 2nd Monday" period boundaries will be on second Monday

```
of each month
```
-p "every 11/05" yearly periods with boundaries on 5th of

```
November
```
-p "every 5th November" same
-p "every Nov 5th" same

Show historical balances at end of the 15th day of each month (N is an
end date, exclusive as always):

```
$ hledger balance -H -p "every 16th day"

```
Group postings from the start of wednesday to end of the following
tuesday (N is both (inclusive) start date and (exclusive) end date):

```
$ hledger register checking -p "every 3rd day of week"

```

## Multiple weekday intervals

This special form is also supported:

• every WEEKDAYNAME,WEEKDAYNAME,... (full or three-letter english weekday names, case insensitive)

Also, weekday and weekendday are shorthand for mon,tue,wed,thu,fri and
sat,sun.

This is mainly intended for use with --forecast, to generate periodic
transactions on arbitrary days of the week. It may be less useful with
-p, since it divides each week into subperiods of unequal length, which
is unusual. (Related: #1632)

Examples:

-p "every dates will be Mon, Wed, Fri; periods will be
mon,wed,fri" Mon-Tue, Wed-Thu, Fri-Sun
-p "every weekday" dates will be Mon, Tue, Wed, Thu, Fri; periods will

```
be Mon, Tue, Wed, Thu, Fri-Sun
```
-p "every weekend‐ dates will be Sat, Sun; periods will be Sat, Sun-Fri
day"

Depth
With the --depth NUM option (short form, usually preferred: -NUM), reports will show accounts only to the specified depth, hiding deeper
subaccounts. Use this when you want a summary with less detail. This
flag has the same effect as a depth: query argument. So all of these
are equivalent: depth:2, --depth=2, -2.

You can also provide custom depths for specific accounts, by providing
a REGEX=NUM argument instead of just NUM (since 1.41). For example,
--depth assets=2 (or depth:assets=2) will collapse accounts matching
the regular expression "assets" to depth 2. So assets:bank:savings
would be collapsed to assets:bank, but liabilities:bank:credit card
would not be affected.

If REGEX contains spaces or other special characters, enclose it in
quotes in the usual way. Eg: --depth 'credit card=2'

## Combining depth options

If a command line contains multiple general depth options, the last one
wins. (Useful for overriding a depth specified by scripts.)

Or a command may contain a combination of general and custom depth options. In this case, the most specifically (deepest) matching option
wins. Some examples:

• --depth assets=3 --depth expenses=2 --depth 1 would collapse accounts

```
containing "assets" to depth 3,  accounts  containing	"expenses"  to
depth 2, and all other accounts to depth 1.

```
• --depth assets=1 --depth savings=2 would collapse assets:bank:savings

```
to depth 2 (not depth 1; because "savings" matches a deeper  part  of
the account name than "assets").

```
Note currently, to override a custom depth option --depth REGEX=NUM
with a later option, the later option must use the same REGEX.

Queries
Many hledger commands accept query arguments, which restrict their
scope and let you report on a precise subset of your data. Here's a
quick overview of hledger's queries:

• By default, a query argument is treated as a case-insensitive substring pattern for matching account names. Eg:

```
dining groceries
car:fuel
```
• Patterns containing spaces or other special characters must be enclosed in single or double quotes:

```
'personal care'
```
• Patterns are actually regular expressions, so you can add regexp

```
metacharacters	 for  more precision (or you may need to backslash-escape certain characters; see "Regular expressions" above):

'^expenses\b'
'food$'
'fuel|repair'
'accounts (payable|receivable)'
```
• To match something other than the account name, you can add a query

```
type prefix, such as:

date:202312-
status:
desc:amazon
cur:USD
cur:\\$
amt:'>0'
acct:groceries	 (but acct: is the default, so we usually don't bother
writing it)
```
• To negate a query, add a not: prefix:

```
not:status:'*'
not:desc:'opening|closing'
not:cur:USD
```
• Multiple query terms can be combined, as space-separated queries Eg:

```
hledger  print	 date:2022  desc:amazon	 desc:amzn  (show transactions
dated in 2022 whose description contains "amazon" or "amzn").
```
• Or more flexibly as boolean queries. Eg: hledger print

```
expr:'date:2022 and (desc:amazon or desc:amzn) and not date:202210'
```
All hledger commands use the same query language, but different commands may interpret the query in different ways. We haven't described
the commands yet (that's coming in PART 4: COMMANDS below) but here's
the gist of it:

• Transaction-oriented commands (print, aregister, close, import, descriptions..) try to match transactions (including the transaction's

```
postings).

```
• Posting-oriented commands (register, balance, balancesheet, incomestatement, accounts..) try to match postings. Postings inherit their

```
transaction's attributes for querying purposes, so transaction fields
like date or description can still be referenced in a posting query.

```
• A few commands match in more specific ways. (Eg aregister, which has

```
a special first argument.)

```

## Query types

Here are the query types available:

acct: query
acct:REGEX, or just REGEX
Match account names containing this case insensitive regular expression.
This is the default query type, so we usually don't bother writing the
"acct:" prefix.

amt: query
amt:N, amt:'<N', amt:'<=N', amt:'>N', amt:'>=N'
Match postings with a single-commodity amount equal to, less than, or
greater than N. (Postings with multi-commodity amounts are not tested
and will always match.) amt: needs quotes to hide the less
than/greater than sign from the command line shell.

The comparison has two modes: if N is preceded by a + or - sign (or is
0), the two signed numbers are compared. Otherwise, the absolute magnitudes are compared, ignoring sign.

Keep in mind that amt: matches posting amounts, not account balances.

code: query
code:REGEX
Match by transaction code (eg check number).

cur: query
cur:REGEX
Match postings or transactions including any amounts whose currency/commodity symbol is fully matched by REGEX. (Contrary to
hledger's usual infix matching. To do infix matching, write
.*REGEX.*.) Note, to match special characters which are regex-significant, you need to escape them with \. And for characters which are
significant to your shell you will usually need one more level of escaping. Eg to match the dollar sign: cur:\\$ or cur:'\$'

desc: query
desc:REGEX
Match transaction descriptions.

date: query
date:PERIODEXPR
Match dates (or with the --date2 flag, secondary dates) within the
specified period. PERIODEXPR is a period expression with no report interval. Examples:
date:2016, date:thismonth, date:2/1-2/15, date:2021-07-27..nextquarter.

date2: query
date2:PERIODEXPR
If you use secondary dates: this matches secondary dates within the
specified period. It is not affected by the --date2 flag.

depth: query
depth:[REGEXP=]N
Match (or display, depending on command) accounts at or above this
depth, optionally only for accounts matching a provided regular expression. See Depth for detailed rules.

note: query
note:REGEX
Match transaction notes (the part of the description right of |, or the
whole description if there's no |).

payee: query
payee:REGEX
Match transaction payee/payer names (the part of the description left
of |, or the whole description if there's no |).

real: query
real:, real:0
Match real or virtual postings respectively.

status: query
status:, status:!, status:*
Match unmarked, pending, or cleared transactions respectively.

type: query
type:TYPECODES
Match by account type (see Declaring accounts > Account types). TYPECODES is one or more of the single-letter account type codes ALERXCV,
case insensitive. Note type:A and type:E will also match their respective subtypes C (Cash) and V (Conversion). Certain kinds of account
alias can disrupt account types, see Rewriting accounts > Aliases and
account types.

tag: query
tag:NAMEREGEX[=VALREGEX]
Match by tag name, and optionally also by tag value. Note:

• Both regular expressions do infix matching. If you need a complete

```
match, use ^ and $.
```
Eg: tag:'^fullname$', tag:'^fullname$=^fullvalue$

• To match values, ignoring names, do tag:.=VALREGEX

• Accounts also inherit the tags of their parent accounts.

• Postings also inherit the tags of their account and their transaction

```
.

```
• Transactions also acquire the tags of their postings.

## Negative queries

not: query
not:QUERY
You can prepend not: to a query to negate the match.
Eg: not:equity, not:desc:apple
(Also, a trick: not:not:... can sometimes solve query problems conveniently.)

## Space-separated queries

When given multiple space-separated query terms, most commands select
things which match:

• any of the description terms AND

• any of the account terms AND

• any of the status terms AND

• all the other terms.

The print command is a little different, showing transactions which:

• match any of the description terms AND

• have any postings matching any of the positive account terms AND

• have no postings matching any of the negative account terms AND

• match all the other terms.

## Boolean queries

You can write more complicated "boolean" query expressions, enclosed in
quotes and prefixed with expr:. These can combine subqueries with NOT,
AND, OR operators (case insensitive), and parentheses for grouping.
Eg, to show transactions involving both cash and expense accounts:

```
hledger print expr:'cash AND expenses'

```
The prefix and enclosing quotes are required, so don't write hledger
print cash AND expenses. That would be a space-separated query showing
transactions involving accounts with any of "cash", "and", "expenses"
in their names.

You can write space-separated queries inside a boolean query, and they
will combine as described above, but it might be confusing and best
avoided. Eg these are equivalent, showing transactions involving cash
or expenses accounts:

```
hledger print expr:'cash expenses'
hledger print cash expenses

```
There is a restriction with date: queries: they may not be used inside
OR expressions.

Actually, there are three types of boolean query: expr: for general
use, and any: and all: variants which can be useful with print.

expr: query
expr:'QUERYEXPR'
For example, expr:'date:lastmonth AND NOT (food OR rent)' means "match
things which are dated in the last month and do not have food or rent
in the account name".

When using expr: with transaction-oriented commands like print, posting-oriented query terms like acct: and amt: are considered to match
the transaction if they match any of its postings.
So, hledger print expr:'cash and amt:>0' means "show transactions with
(at least one posting involving a cash account) and (at least one posting with a positive amount)".

any: query
any:'QUERYEXPR'
Like expr:, but when used with transaction-oriented commands like
print, it matches the transaction only if a posting can be matched by
all of QUERYEXPR.
So, hledger print any:'cash and amt:>0' means "show transactions where
at least one posting posts a positive amount to a cash account".

all: query
all:'QUERYEXPR'
Like expr:, but when used with transaction-oriented commands like
print, it matches the transaction only if all postings are matched by
all of QUERYEXPR (and there is at least one posting).
So, hledger print all:'cash and amt:0' means "show transactions where
all postings involve a cash account and have a zero amount".
Or, hledger print all:'cash or checking' means "show transactions which
touch only cash and/or checking accounts".

## Queries and command options

Some queries can also be expressed as command-line options: depth:2 is
equivalent to --depth 2, date:2023 is equivalent to -p 2023, etc. When
you mix command options and query arguments, generally the resulting
query is their intersection.

## Queries and account aliases

When account names are rewritten with --alias or alias, acct: will
match either the old or the new account name.

## Queries and valuation

When amounts are converted to other commodities in cost or value reports, cur: and amt: match the old commodity symbol and the old amount
quantity, not the new ones. (Except in hledger 1.22, #1625.)

Pivoting
Normally, hledger groups amounts and displays their totals by account
(name). With --pivot PIVOTEXPR, some other field's (or multiple
fields') value is used as a synthetic account name, causing different
grouping and display. PIVOTEXPR can be

• any of these standard transaction or posting fields (their value is

```
substituted):	status,	 code, desc, payee, note, acct, comm/cur, amt,
cost

```
• or a tag name

• or any combination of these, colon-separated.

Some special cases:

• Colons appearing in PIVOTEXPR or in a pivoted tag value will generate

```
account hierarchy.

```
• When pivoting a posting that has multiple values for a tag, the tag's

```
first value will be used as the pivoted value.

```
• When a posting has multiple commodities, the pivoted value of

```
"comm"/"cur" will be "".  Also when an unrecognised tag name or field
is provided, its pivoted value will be "".  (If this causes confusing
output, consider excluding those postings from the report.)

```
Examples:

```
2016/02/16 Yearly Dues Payment
assets:bank account		      2 EUR
income:dues			     -2 EUR  ; member: John Doe, kind: Lifetime

```
Normal balance report showing account names:

```
$ hledger balance
2 EUR  assets:bank account
-2 EUR  income:dues
--------------------
0

```
Pivoted balance report, using member: tag values instead:

```
$ hledger balance --pivot member
2 EUR
-2 EUR  John Doe
--------------------
0

```
One way to show only amounts with a member: value (using a query):

```
$ hledger balance --pivot member tag:member=.
-2 EUR  John Doe
--------------------
-2 EUR

```
Another way (the acct: query matches against the pivoted "account
name"):

```
$ hledger balance --pivot member acct:.
-2 EUR  John Doe
--------------------
-2 EUR

```
Hierarchical reports can be generated with multiple pivot values:

```
$ hledger balance Income:Dues --pivot kind:member
-2 EUR  Lifetime:John Doe
--------------------
-2 EUR

```
Generating data
hledger can enrich the data provided to it, or generate new data, in a
number of ways. Mostly, this is done only if you request it:

• Missing amounts or missing costs in transactions are inferred automatically when possible.

• The --infer-equity flag infers missing conversion equity postings

```
from @/@@ costs.

```
• The --infer-costs flag infers missing costs from conversion equity

```
postings.

```
• The --infer-market-prices flag infers P price directives from costs.

• The --auto flag adds extra postings to transactions matched by auto

```
posting rules.

```
• The --forecast option generates transactions from periodic transaction rules.

• The balance --budget report infers budget goals from periodic transaction rules.

• Commands like close, rewrite, and hledger-interest generate transactions or postings.

• CSV data is converted to transactions by applying CSV conversion

```
rules..  etc.

```
Such generated data is temporary, existing only at report time. You
can convert it to permanent recorded data by, eg, capturing the output
of hledger print and saving it in your journal file. This can sometimes be useful as a data entry aid.

If you are curious what data is being generated and why, run hledger
print -x --verbose-tags. -x/--explicit shows inferred amounts and
--verbose-tags adds tags like generated-transaction (from periodic
rules) and generated-posting, modified (from auto posting rules). Similar hidden tags (with an underscore prefix) are always present, also,
so you can always match such data with queries like tag:generated or
tag:modified.

Forecasting
Forecasting, or speculative future reporting, can be useful for estimating future balances, or for exploring different future scenarios.

The simplest and most flexible way to do it with hledger is to manually
record a bunch of future-dated transactions. You could keep these in a
separate future.journal and include that with -f only when you want to
see them.

--forecast
There is another way: with the --forecast option, hledger can generate
temporary "forecast transactions" for reporting purposes, according to
periodic transaction rules defined in the journal. Each rule can generate multiple recurring transactions, so by changing one rule you can
change many forecasted transactions.

Forecast transactions usually start after ordinary transactions end.
By default, they begin after your latest-dated ordinary transaction, or
today, whichever is later, and they end six months from today. (The
exact rules are a little more complicated, and are given below.)

This is the "forecast period", which need not be the same as the report
period. You can override it - eg to forecast farther into the future,
or to force forecast transactions to overlap your ordinary transactions
- by giving the --forecast option a period expression argument, like
--forecast=..2099 or --forecast=2023-02-15... Note that the = is required.

## Inspecting forecast transactions

print is the best command for inspecting and troubleshooting forecast
transactions. Eg:

```
~ monthly from 2022-12-20	   rent
assets:bank:checking
expenses:rent		  $1000

$ hledger print --forecast --today=2023/4/21
2023-05-20 rent
; generated-transaction: ~ monthly from 2022-12-20
assets:bank:checking
expenses:rent			 $1000

2023-06-20 rent
; generated-transaction: ~ monthly from 2022-12-20
assets:bank:checking
expenses:rent			 $1000

2023-07-20 rent
; generated-transaction: ~ monthly from 2022-12-20
assets:bank:checking
expenses:rent			 $1000

2023-08-20 rent
; generated-transaction: ~ monthly from 2022-12-20
assets:bank:checking
expenses:rent			 $1000

2023-09-20 rent
; generated-transaction: ~ monthly from 2022-12-20
assets:bank:checking
expenses:rent			 $1000

```
Here there are no ordinary transactions, so the forecasted transactions
begin on the first occurrence after today's date. (You won't normally
use --today; it's just to make these examples reproducible.)

## Forecast reports

Forecast transactions affect all reports, as you would expect. Eg:

```
$ hledger areg rent --forecast --today=2023/4/21
Transactions in expenses:rent and subaccounts:
2023-05-20 rent		      as:ba:checking		   $1000	 $1000
2023-06-20 rent		      as:ba:checking		   $1000	 $2000
2023-07-20 rent		      as:ba:checking		   $1000	 $3000
2023-08-20 rent		      as:ba:checking		   $1000	 $4000
2023-09-20 rent		      as:ba:checking		   $1000	 $5000

$ hledger bal -M expenses --forecast --today=2023/4/21
Balance changes in 2023-05-01..2023-09-30:

||	  May	 Jun	Jul    Aug    Sep
===============++===================================
expenses:rent || $1000  $1000  $1000  $1000  $1000
---------------++-----------------------------------
|| $1000  $1000  $1000  $1000  $1000

```

## Forecast tags

Forecast transactions generated by --forecast have a hidden tag, _generated-transaction. So if you ever need to match forecast transactions, you could use tag:_generated-transaction (or just tag:generated)
in a query.

For troubleshooting, you can add the --verbose-tags flag. Then, visible generated-transaction tags will be added also, so you can view them
with the print command. Their value indicates which periodic rule was
responsible.

## Forecast period, in detail

Forecast start/end dates are chosen so as to do something useful by default in almost all situations, while also being flexible. Here are
(with luck) the exact rules, to help with troubleshooting:

The forecast period starts on:

• the later of

```
• the start date in the periodic transaction rule

• the start date in --forecast's argument

```
• otherwise (if those are not available): the later of

```
• the report start date specified with -b/-p/date:

• the day after the latest ordinary transaction in the journal

```
• otherwise (if none of these are available): today.

The forecast period ends on:

• the earlier of

```
• the end date in the periodic transaction rule

• the end date in --forecast's argument

```
• otherwise: the report end date specified with -e/-p/date:

• otherwise: 180 days (~6 months) from today.

## Forecast troubleshooting

When --forecast is not doing what you expect, one of these tips should
help:

• Remember to use the --forecast option.

• Remember to have at least one periodic transaction rule in your journal.

• Test with print --forecast.

• Check for typos or too-restrictive start/end dates in your periodic

```
transaction rule.

```
• Leave at least 2 spaces between the rule's period expression and description fields.

• Check for future-dated ordinary transactions suppressing forecasted

```
transactions.

```
• Try setting explicit report start and/or end dates with -b, -e, -p or

```
date:

```
• Try adding the -E flag to encourage display of empty periods/zero

```
transactions.

```
• Try setting explicit forecast start and/or end dates with --forecast=START..END

• Consult Forecast period, in detail, above.

• Check inside the engine: add --debug=2 (eg).

Budgeting
With the balance command's --budget report, each periodic transaction
rule generates recurring budget goals in specified accounts, and goals
and actual performance can be compared. See the balance command's doc
below.

You can generate budget goals and forecast transactions at the same
time, from the same or different periodic transaction rules: hledger
bal -M --budget --forecast ...

See also: Budgeting and Forecasting.

Amount formatting

## Commodity display style

For the amounts in each commodity, hledger chooses a consistent display
style (symbol placement, decimal mark and digit group marks, number of
decimal digits) to use in most reports. This is inferred as follows:

First, if there's a D directive declaring a default commodity, that
commodity symbol and amount format is applied to all no-symbol amounts
in the journal.

Then each commodity's display style is determined from its commodity
directive. We recommend always declaring commodities with commodity
directives, since they help ensure consistent display styles and precisions, and bring other benefits such as error checking for commodity
symbols. Here's an example:

```
# Set display styles (and decimal marks, for parsing, if there is no decimal-mark directive)
# for the $, EUR, INR and no-symbol commodities:
commodity $1,000.00
commodity EUR 1.000,00
commodity INR 9,99,99,999.00
commodity 1 000 000.9455

```
But for convenience, if a commodity directive is not present, hledger
infers a commodity's display styles from its amounts as they are written in the journal (excluding cost amounts and amounts in periodic
transaction rules or auto posting rules). It uses

• the symbol placement and decimal mark of the first amount seen

• the digit group marks of the first amount with digit group marks

• and the maximum number of decimal digits seen across all amounts.

And as fallback if no applicable amounts are found, it would use a default style, like $1000.00 (symbol on the left with no space, period as
decimal mark, and two decimal digits).

Finally, commodity styles can be overridden by the -c/--commodity-style
command line option.

## Rounding

Amounts are stored internally as decimal numbers with up to 255 decimal
places. They are displayed with their original journal precisions by
print and print-like reports, and rounded to their display precision
(the number of decimal digits specified by the commodity display style)
by other reports. When rounding, hledger uses banker's rounding (it
rounds to the nearest even digit). So eg 0.5 displayed with zero decimal digits appears as "0".

## Trailing decimal marks

If you're wondering why your print report sometimes shows trailing decimal marks, with no decimal digits; it does this when showing amounts
that have digit group marks but no decimal digits, to disambiguate them
and allow them to be re-parsed reliably (see Decimal marks). Eg:

```
commodity $1,000.00

2023-01-02
(a)	   $1000

$ hledger print
2023-01-02
(a)	     $1,000.

```
If this is a problem (eg when exporting to Ledger), you can avoid it by
disabling digit group marks, eg with -c/--commodity (for each affected
commodity):

```
$ hledger print -c '$1000.00'
2023-01-02
(a)	       $1000

```
or by forcing print to always show decimal digits, with --round:

```
$ hledger print -c '$1,000.00' --round=soft
2023-01-02
(a)	   $1,000.00

```

## Amount parseability

More generally, hledger output falls into three rough categories, which
format amounts a little bit differently to suit different consumers:

1. "hledger-readable output" - should be readable by hledger (and by
humans)

• This is produced by reports that show full journal entries: print,

```
import, close, rewrite etc.

```
• It shows amounts with their original journal precisions, which may

```
not be consistent from one amount to the next.

```
• It adds a trailing decimal mark when needed to avoid showing ambiguous amounts.

• It can be parsed reliably (by hledger and ledger2beancount at least,

```
but perhaps not by Ledger..)

```
2. "human-readable output" - usually for humans

• This is produced by all other reports.

• It shows amounts with standard display precisions, which will be consistent within each commodity.

• It shows ambiguous amounts unmodified.

• It can be parsed reliably in the context of a known report (when you

```
know decimals are consistently not being shown, you can assume a single mark is a digit group mark).

```
3. "machine-readable output" - usually for other software

• This is produced by all reports when an output format like csv, tsv,

```
json, or sql is selected.

```
• It shows amounts as 1 or 2 do, but without digit group marks.

• It can be parsed reliably (if needed, the decimal mark can be changed

```
with -c/--commodity-style).

```
Cost reporting
In some transactions - for example a currency conversion, or a purchase
or sale of stock - one commodity is exchanged for another. In these
transactions there is a conversion rate, also called the cost (when
buying) or selling price (when selling). (In hledger docs we just say
"cost" generically for convenience.) With the -B/--cost flag, hledger
can show amounts "at cost", converted to the cost's commodity.

## Recording costs

We'll explore several ways of recording transactions involving costs.
These are also summarised at hledger Cookbook > Cost notation.

Costs can be recorded explicitly in the journal, using the @ UNITCOST
or @@ TOTALCOST notation described in Journal > Costs:

Variant 1

```
2022-01-01
assets:dollars	  $-135
assets:euros	   �100 @ $1.35	  ; $1.35 per euro (unit cost)

```
Variant 2

```
2022-01-01
assets:dollars	  $-135
assets:euros	   �100 @@ $135	  ; $135 total cost

```
Typically, writing the unit cost (variant 1) is preferable; it can be
more effort, requiring more attention to decimal digits; but it reveals
the per-unit cost basis, and makes stock sales easier.

Costs can also be left implicit, and hledger will infer the cost that
is consistent with a balanced transaction:

Variant 3

```
2022-01-01
assets:dollars	  $-135
assets:euros	   �100

```
Here, hledger will attach a @@ �100 cost to the first amount (you can
see it with hledger print -x). This form looks convenient, but there
are downsides:

• It sacrifices some error checking. For example, if you accidentally

```
wrote	�10  instead  of �100, hledger would not be able to detect the
mistake.

```
• It is sensitive to the order of postings - if they were reversed, a

```
different entry would be inferred and reports would be different.

```
• The per-unit cost basis is not easy to read.

So generally this kind of entry is not recommended. You can make sure
you have none of these by using -s (strict mode), or by running hledger
check balanced.

## Reporting at cost

Now when you add the -B/--cost flag to reports ("B" is from Ledger's
-B/--basis/--cost flag), any amounts which have been annotated with
costs will be converted to their cost's commodity (in the report output). Ie they will be displayed "at cost" or "at sale price".

Some things to note:

• Costs are attached to specific posting amounts in specific transactions, and once recorded they do not change. This contrasts with

```
market prices, which are ambient and fluctuating.

```
• Conversion to cost is performed before conversion to market value

```
(described below).

```

## Equity conversion postings

There is a problem with the entries above - they are not conventional
Double Entry Bookkeeping (DEB) notation, and because of the "magical"
transformation of one commodity into another, they cause an imbalance
in the Accounting Equation. This shows up as a non-zero grand total in
balance reports like hledger bse.

For most hledger users, this doesn't matter in practice and can safely
be ignored ! But if you'd like to learn more, keep reading.

Conventional DEB uses an extra pair of equity postings to balance the
transaction. Of course you can do this in hledger as well:

Variant 4

```
2022-01-01
assets:dollars      $-135
assets:euros	       �100
equity:conversion    $135
equity:conversion   �-100

```
Now the transaction is perfectly balanced according to standard DEB,
and hledger bse's total will not be disrupted.

And, hledger can still infer the cost for cost reporting, but it's not
done by default - you must add the --infer-costs flag like so:

```
$ hledger print --infer-costs
2022-01-01 one hundred euros purchased at $1.35 each
assets:dollars       $-135 @@ �100
assets:euros			�100
equity:conversion		$135
equity:conversion	       �-100

$ hledger bal --infer-costs -B
�-100  assets:dollars
�100  assets:euros
--------------------
0

```
Here are some downsides of this kind of entry:

• The per-unit cost basis is not easy to read.

• Instead of -B you must remember to type -B --infer-costs.

• --infer-costs works only where hledger can identify the two equity:conversion postings and match them up with the two non-equity

```
postings.   So	 writing  the journal entry in a particular format becomes more important.	More on this below.

```

## Inferring equity conversion postings

Can we go in the other direction ? Yes, if you have transactions written with the @/@@ cost notation, hledger can infer the missing equity
postings, if you add the --infer-equity flag. Eg:

```
2022-01-01
assets:dollars	-$135
assets:euros	 �100 @ $1.35

$ hledger print --infer-equity
2022-01-01
assets:dollars		    $-135
assets:euros		     �100 @ $1.35
equity:conversion:$-�:�	    �-100
equity:conversion:$-�:$	  $135.00

```
The equity account names will be "equity:conversion:A-B:A" and "equity:conversion:A-B:B" where A is the alphabetically first commodity
symbol. You can customise the "equity:conversion" part by declaring an
account with the V/Conversion account type.

Note you will need to add account declarations for these to your journal, if you use check accounts or check --strict.

## Combining costs and equity conversion postings

Finally, you can use both the @/@@ cost notation and equity postings at
the same time. This in theory gives the best of all worlds - preserving the accounting equation, revealing the per-unit cost basis, and
providing more flexibility in how you write the entry:

Variant 5

```
2022-01-01 one hundred euros purchased at $1.35 each
assets:dollars      $-135
equity:conversion    $135
equity:conversion   �-100
assets:euros	       �100 @ $1.35

```
All the other variants above can (usually) be rewritten to this final
form with:

```
$ hledger print -x --infer-costs --infer-equity

```
Downsides:

• The precise format of the journal entry becomes more important. If

```
hledger  can't	 detect	 and match up the cost and equity postings, it
will give a transaction balancing error.

```
• The add command does not yet accept this kind of entry (#2056).

• This is the most verbose form.

## Requirements for detecting equity conversion postings

--infer-costs has certain requirements (unlike --infer-equity, which
always works). It will infer costs only in transactions with:

• Two non-equity postings, in different commodities. Their order is

```
significant: the cost will be added to the first of them.

```
• Two postings to equity conversion accounts, next to one another,

```
which balance the two non-equity postings.  This balancing is checked
to the same precision (number of decimal places) used in the  conversion posting's amount.	 Equity conversion accounts are:

• any accounts declared with account type V/Conversion, or their subaccounts

• otherwise, accounts named equity:conversion, equity:trade,  or  equity:trading, or their subaccounts.

```
And multiple such four-posting groups can coexist within a single
transaction. When --infer-costs fails, it does not infer a cost in
that transaction, and does not raise an error (ie, it infers costs
where it can).

Reading variant 5 journal entries, combining cost notation and equity
postings, has all the same requirements. When reading such an entry
fails, hledger raises an "unbalanced transaction" error.

## Infer cost and equity by default ?

Should --infer-costs and --infer-equity be enabled by default ? Try
using them always, eg with a shell alias:

```
alias h="hledger --infer-equity --infer-costs"

```
and let us know what problems you find.

Value reporting
hledger can also show amounts "at market value", converted to some
other commodity using the market price or conversion rate on a certain
date.

This is controlled by the --value=TYPE[,COMMODITY] option. We also
provide simpler -V and -X COMMODITY aliases for this, which are often
sufficient. The market prices are declared with a special P directive,
and/or they can be inferred from the costs recorded in transactions, by
using the --infer-market-prices flag.

-X: Value in specified commodity
The -X COMM (or --exchange=COMM) option converts amounts to their market value in the specified commodity, using the market prices in effect
on the valuation date(s), if any. (More on these in a minute.)

Use this when you want to (eg) show everything in your base currency as
far as possible. (Commodities for which no conversion rate can be
found, will not be converted.)

COMM should be the full commodity symbol or name. Remember to quote
special shell characters, if needed. Some examples:

• -X�

• -X$ (nothing after $, no quoting needed)

• -X CNY (the space after -X is optional)

• -X 'red apples'

• -X 'r&r'

-V: Value in default commodity(s)
The -V/--market flag is a variant of -X where you don't have to specify
COMM. Instead it tries to guess a default valuation commodity for each
original commodity, based on the market prices in effect on the valuation date(s).

-V can often be a convenient shortcut for -X MYCURRENCY, but not always; depending on your data it could guess multiple valuation commodities. Usually you want to convert to a single commodity, so it's better to use -X, unless you're sure -V is doing what you want.

## Valuation date

Market prices can change from day to day. hledger will use the prices
on a particular valuation date (or on more than one date). By default
hledger uses "end" dates for valuation. More specifically:

• For single period reports (including normal print and register reports):

```
• If an explicit report end date is specified, that is used.

• Otherwise  the  latest  transaction	date or non-future P directive
date is used.

```
• For multiperiod reports, each period is valued on its last day.

This can be customised with the --value option described below, which
can select either "then", "end", "now", or "custom" dates.

## Finding market price

To convert a commodity A to its market value in another commodity B,
hledger looks for a suitable market price (exchange rate) as follows,
in this order of preference:

1. A declared market price or inferred market price: A's latest market

```
price in B on or before the valuation date as declared by a P directive, or (with the --infer-market-prices flag) inferred from costs.

```
2. A reverse market price: the inverse of a declared or inferred market

```
price from B to A.

```
3. A forward chain of market prices: a synthetic price formed by combining the shortest chain of "forward" (only 1 above) market prices,

```
leading from A to B.

```
4. Any chain of market prices: a chain of any market prices, including

```
both	forward	 and reverse prices (1 and 2 above), leading from A to
B.

```
There is a limit to the length of these price chains; if hledger
reaches that length without finding a complete chain or exhausting all
possibilities, it will give up (with a "gave up" message visible in
--debug=2 output). That limit is currently 1000.

Amounts for which no suitable market price can be found, are not converted.

--infer-market-prices: market prices from transactions
Normally, market value in hledger is fully controlled by, and requires,
P directives in your journal. Since adding and updating those can be a
chore, and since transactions usually take place at close to market
value, why not use the recorded costs as additional market prices (as
Ledger does) ? Adding the --infer-market-prices flag to -V, -X or
--value enables this.

So for example, hledger bs -V --infer-market-prices will get market
prices both from P directives and from transactions. If both occur on
the same day, the P directive takes precedence.

There is a downside: value reports can sometimes be affected in confusing/undesired ways by your journal entries. If this happens to you,
read all of this Value reporting section carefully, and try adding
--debug or --debug=2 to troubleshoot.

--infer-market-prices can infer market prices from:

• multicommodity transactions with explicit prices (@/@@)

• multicommodity transactions with implicit prices (no @, two commodities, unbalanced). (With these, the order of postings matters.

```
hledger print -x can be useful for troubleshooting.)

```
• multicommodity transactions with equity postings, if cost is inferred

```
with --infer-costs.

```
There is a limitation (bug) currently: when a valuation commodity is
not specified, prices inferred with --infer-market-prices do not help
select a default valuation commodity, as P prices would. So conversion
might not happen because no valuation commodity was detected (--debug=2
will show this). To be safe, specify the valuation commmodity, eg:

• -X EUR --infer-market-prices, not -V --infer-market-prices

• --value=then,EUR --infer-market-prices, not --value=then --infer-market-prices

Signed costs and market prices can be confusing. For reference, here
is the current behaviour, since hledger 1.25. (If you think it should
work differently, see #1870.)

```
2022-01-01 Positive Unit prices
a	   A 1
b	   B -1 @ A 1

2022-01-01 Positive Total prices
a	   A 1
b	   B -1 @@ A 1

2022-01-02 Negative unit prices
a	   A 1
b	   B 1 @ A -1

2022-01-02 Negative total prices
a	   A 1
b	   B 1 @@ A -1

2022-01-03 Double Negative unit prices
a	   A -1
b	   B -1 @ A -1

2022-01-03 Double Negative total prices
a	   A -1
b	   B -1 @@ A -1

```
All of the transactions above are considered balanced (and on each day,
the two transactions are considered equivalent). Here are the market
prices inferred for B:

```
$ hledger -f- --infer-market-prices prices
P 2022-01-01 B A 1
P 2022-01-01 B A 1.0
P 2022-01-02 B A -1
P 2022-01-02 B A -1.0
P 2022-01-03 B A -1
P 2022-01-03 B A -1.0

```

## Valuation commodity

When you specify a valuation commodity (-X COMM or --value TYPE,COMM):
hledger will convert all amounts to COMM, wherever it can find a suitable market price (including by reversing or chaining prices).

When you leave the valuation commodity unspecified (-V or --value
TYPE):
For each commodity A, hledger picks a default valuation commodity as
follows, in this order of preference:

1. The price commodity from the latest P-declared market price for A on

```
or before valuation date.

```
2. The price commodity from the latest P-declared market price for A on

```
any  date.   (Allows	conversion  to proceed when there are inferred
prices before the valuation date.)

```
3. If there are no P directives at all (any commodity or date) and the

```
--infer-market-prices	 flag  is  used:  the price commodity from the
latest transaction-inferred price for A on or before valuation date.

```
This means:

• If you have P directives, they determine which commodities -V will

```
convert, and to what.

```
• If you have no P directives, and use the --infer-market-prices flag,

```
costs determine it.

```
Amounts for which no valuation commodity can be found are not converted.

--value: Flexible valuation
-V and -X are special cases of the more general --value option:

```
--value=TYPE[,COMM]  TYPE is then, end, now or YYYY-MM-DD.
COMM is an optional commodity symbol.
Shows amounts converted to:
- default valuation commodity (or COMM) using market prices at posting dates
- default valuation commodity (or COMM) using market prices at period end(s)
- default valuation commodity (or COMM) using current market prices
- default valuation commodity (or COMM) using market prices at some date

```
The TYPE part selects cost or value and valuation date:

--value=then

```
Convert  amounts to their value in the default valuation commodity, using market prices on each posting's date.

```
--value=end

```
Convert amounts to their value in the default valuation  commodity,  using  market  prices on the last day of the report period
(or if unspecified, the journal's end date); or  in  multiperiod
reports, market prices on the last day of each subperiod.

```
--value=now

```
Convert  amounts to their value in the default valuation commodity using current market prices (as of  when  report  is	generated).

```
--value=YYYY-MM-DD

```
Convert  amounts to their value in the default valuation commodity using market prices on this date.

```
To select a different valuation commodity, add the optional ,COMM part:
a comma, then the target commodity's symbol. Eg: --value=now,EUR.
hledger will do its best to convert amounts to this commodity, deducing
market prices as described above.

## Valuation examples

Here are some quick examples of -V:

```
; one euro is worth this many dollars from nov 1
P 2016/11/01 � $1.10

; purchase some euros on nov 3
2016/11/3
assets:euros	      �100
assets:checking

; the euro is worth fewer dollars by dec 21
P 2016/12/21 � $1.03

```
How many euros do I have ?

```
$ hledger -f t.j bal -N euros
�100  assets:euros

```
What are they worth at end of nov 3 ?

```
$ hledger -f t.j bal -N euros -V -e 2016/11/4
$110.00  assets:euros

```
What are they worth after 2016/12/21 ? (no report end date specified,
defaults to today)

```
$ hledger -f t.j bal -N euros -V
$103.00  assets:euros

```
Here are some examples showing the effect of --value, as seen with
print:

```
P 2000-01-01 A  1 B
P 2000-02-01 A  2 B
P 2000-03-01 A  3 B
P 2000-04-01 A  4 B

2000-01-01
(a)	 1 A @ 5 B

2000-02-01
(a)	 1 A @ 6 B

2000-03-01
(a)	 1 A @ 7 B

```
Show the cost of each posting:

```
$ hledger -f- print --cost
2000-01-01
(a)		  5 B

2000-02-01
(a)		  6 B

2000-03-01
(a)		  7 B

```
Show the value as of the last day of the report period (2000-02-29):

```
$ hledger -f- print --value=end date:2000/01-2000/03
2000-01-01
(a)		  2 B

2000-02-01
(a)		  2 B

```
With no report period specified, the latest transaction date or price
date is used as valuation date (2000-04-01):

```
$ hledger -f- print --value=end
2000-01-01
(a)		  3 B

2000-02-01
(a)		  3 B

2000-03-01
(a)		  3 B

```
The value today is the same (the 2000-04-01 price is still in effect):

```
$ hledger -f- print --value=now
2000-01-01
(a)		  4 B

2000-02-01
(a)		  4 B

2000-03-01
(a)		  4 B

```
Show the value on 2000/01/15:

```
$ hledger -f- print --value=2000-01-15
2000-01-01
(a)		  1 B

2000-02-01
(a)		  1 B

2000-03-01
(a)		  1 B

```

## Interaction of valuation and queries

When matching postings based on queries in the presence of valuation,
the following happens:

1. The query is separated into two parts:

```
1. the currency (cur:) or amount (amt:).

2. all other parts.

```
2. The postings are matched to the currency and amount queries based on

```
pre-valued amounts.

```
3. Valuation is applied to the postings.

4. The postings are matched to the other parts of the query based on

```
post-valued amounts.

```
Related: #1625

## Effect of valuation on reports

Here is a reference for how valuation is supposed to affect each part
of hledger's reports. It may be useful when troubleshooting. If you
find problems, please report them, ideally with a reproducible example.
Related: #329, #1083.

First, a quick glossary:

cost calculated using price(s) recorded in the transaction(s).

value market value using available market price declarations, or the

```
unchanged amount if no conversion rate can be found.

```
report start

```
the  first  day  of the report period specified with -b or -p or
date:, otherwise today.

```
report or journal start

```
the first day of the report period specified with -b  or	-p  or
date:,  otherwise	 the earliest transaction date in the journal,
otherwise today.

```
report end

```
the last day of the report period specified with	-e  or	-p  or
date:, otherwise today.

```
report or journal end

```
the  last	 day  of  the report period specified with -e or -p or
date:, otherwise the latest transaction  date  in	 the  journal,
otherwise today.

```
report interval

```
a	 flag (-D/-W/-M/-Q/-Y) or period expression that activates the
report's multi-period mode (whether showing one or many subperiods).

```
Report -B, --cost -V, -X --value=then --value=end --value=DATE,
type --value=now
────────────────────────────────────────────────────────────────────────────────────────────
print
posting cost value at re‐ value at posting value at re‐ value at
amounts port end or date port or DATE/today

```
today				      journal end
```
balance unchanged unchanged unchanged unchanged unchanged
assertions/assignments

register
starting cost value at re‐ valued at day value at re‐ value at
balance port or each historical port or DATE/today
(-H) journal end posting was made journal end
starting cost value at day valued at day value at day value at
balance before re‐ each historical before re‐ DATE/today
(-H) with port or posting was made port or
report journal journal
interval start start
posting cost value at re‐ value at posting value at re‐ value at
amounts port or date port or DATE/today

```
journal end			      journal end
```
summary summarised value at pe‐ sum of postings value at pe‐ value at
posting cost riod ends in interval, val‐ riod ends DATE/today
amounts ued at interval
with re‐ start
port interval

running sum/average sum/average sum/average of sum/average sum/average
total/av‐ of displayed of displayed displayed values of displayed of displayed
erage values values values values

balance
(bs, bse,
cf, is)
balance sums of value at re‐ value at posting value at re‐ value at
changes costs port end or date port or DATE/today of

```
today	    of			      journal  end   sums of postsums	    of			      of  sums	of   ings
postings			      postings
```
budget like balance like balance like balance like bal‐ like balance
amounts changes changes changes ances changes
(--budget)
grand to‐ sum of dis‐ sum of dis‐ sum of displayed sum of dis‐ sum of distal played val‐ played val‐ valued played val‐ played values

```
ues		  ues				      ues

```
balance
(bs, bse,
cf, is)
with report interval
starting sums of value at re‐ sums of values of value at re‐ sums of postbalances costs of port start postings before port start ings before
(-H) postings be‐ of sums of report start at of sums of report start

```
fore	 report	  all postings	 respective  post‐    all postings
start	  before   re‐	 ing dates	      before   report start			      port start
```
balance sums of same as sums of values of balance value at
changes costs of --value=end postings in pe‐ change in DATE/today of
(bal, is, postings in riod at respec‐ each period, sums of postbs period tive posting valued at ings
--change, dates period ends
cf
--change)
end bal‐ sums of same as sums of values of period end value at
ances costs of --value=end postings from be‐ balances, DATE/today of
(bal -H, postings fore period start valued at sums of postis --H, from before to period end at period ends ings
bs, cf) report start respective postto period ing dates

```
end
```
budget like balance like balance like balance like bal‐ like balance
amounts changes/end changes/end changes/end bal‐ ances changes/end
(--bud‐ balances balances ances balances
get)
row to‐ sums, aver‐ sums, aver‐ sums, averages of sums, aver‐ sums, avertals, row ages of dis‐ ages of dis‐ displayed values ages of dis‐ ages of disaverages played val‐ played val‐ played val‐ played values
(-T, -A) ues ues ues
column sums of dis‐ sums of dis‐ sums of displayed sums of dis‐ sums of distotals played val‐ played val‐ values played val‐ played values

```
ues		  ues				      ues
```
grand to‐ sum, average sum, average sum, average of sum, average sum, average
tal, of column of column column totals of column of column togrand av‐ totals totals totals tals
erage

--cumulative is omitted to save space, it works like -H but with a zero
starting balance.

PART 4: COMMANDS
Here are hledger's standard subcommands. You can list these by running
hledger. If you have installed more add-on commands, they also will be
listed.

In the following command docs, each command's specific options are
shown. Most commands also support the general options described above,
though some of them might have no effect. (Usually if there's a sensible way for a general option to affect a command, it will.) You can
list all of a command's options by running hledger CMD -h.

Help commands

• commands - show the hledger commands list (default)

• demo - show small hledger demos in the terminal

• help - show the hledger manual with info, man, or pager

User interface commands

• repl - run commands from an interactive prompt

• run - run commands from a script

• ui - (if installed) run hledger's terminal UI

• web - (if installed) run hledger's web UI

Data entry commands

• add - add transactions using terminal prompts

• import - add new transactions from other files, eg CSV files

Basic report commands

• accounts - show account names

• codes - show transaction codes

• commodities - show commodity/currency symbols

• descriptions - show transaction descriptions

• files - show input file paths

• notes - show note parts of transaction descriptions

• payees - show payee parts of transaction descriptions

• prices - show market prices

• stats - show journal statistics

• tags - show tag names

Standard report commands

• print - show transactions or export journal data

• aregister (areg) - show transactions in a particular account

• register (reg) - show postings in one or more accounts & running total

• balancesheet (bs) - show assets, liabilities and net worth

• balancesheetequity (bse) - show assets, liabilities and equity

• cashflow (cf) - show changes in liquid assets

• incomestatement (is) - show revenues and expenses

Advanced report commands

• balance (bal) - show balance changes, end balances, budgets, gains..

• roi - show return on investments

Chart commands

• activity - show bar charts of posting counts per period

Data generation commands

• close - generate balance-zeroing/restoring transactions

• rewrite - generate auto postings, like print --auto

Maintenance commands

• check - check for various kinds of error in the data

• diff - compare account transactions in two journal files

• setup - check and show the status of the hledger installation

• test - run self tests

Next, these commands are described in detail.

Help commands
commands
Show the hledger commands list.

```
Flags:
--builtin		 show only builtin commands, not addons

```
demo
Play demos of hledger usage in the terminal, if asciinema is installed.

```
Flags:
-s --speed=SPEED	 playback speed (1 is original speed, .5 is half, 2
is double, etc (default: 2))

```
Run this command with no argument to list the demos. To play a demo,
write its number or a prefix or substring of its title. Tips:

Make your terminal window large enough to see the demo clearly.

Use the -s/--speed SPEED option to set your preferred playback speed,
eg -s4 to play at 4x original speed or -s.5 to play at half speed. The
default speed is 2x.

During playback, several keys are available: SPACE to pause/unpause, .
to step forward (while paused), CTRL-c quit.

Examples:

```
$ hledger demo		   # list available demos
$ hledger demo 1		   # play the first demo at default speed (2x)
$ hledger demo install -s4   # play the "install" demo at 4x speed

```
This command is experimental: there aren't many useful demos yet.

help
Show the hledger user manual with info, man, or a pager. With a (case
insensitive) TOPIC argument, try to open it at that section heading.

```
Flags:
-i			 show the manual with info
-m			 show the manual with man
-p			 show the manual with $PAGER or less
(less is always used if TOPIC is specified)

```
This command shows the hledger manual built in to your hledger executable. It can be useful when offline, or when you prefer the terminal to a web browser, or when the appropriate hledger manual or viewers
are not installed properly on your system.

By default it chooses the best viewer found in $PATH, trying in this
order: info, man, $PAGER, less, more, stdout. (If a TOPIC is specified, $PAGER and more are not tried.) You can force the use of info,
man, or a pager with the -i, -m, or -p flags. If no viewer can be
found, or if running non-interactively, it just prints the manual to
stdout.

When using info, TOPIC can match either the full heading or a prefix.
If your info --version is < 6, you'll need to upgrade it, eg with 'brew
install texinfo' on mac.

When using man or less, TOPIC must match the full heading. For a prefix match, you can write 'TOPIC.*'.

Examples

```
$ hledger help -h			# show the help command's usage
$ hledger help			# show the manual with info, man or $PAGER
$ hledger help 'time periods'	# show the manual's "Time periods" topic
$ hledger help 'time periods' -m	# use man, even if info is installed

```
User interface commands
repl
Start an interactive prompt, where you can run any of hledger's commands. Data files are parsed just once, so the commands run faster.

```
Flags:
no command-specific flags

```
This command is experimental and could change in the future.

hledger repl starts a read-eval-print loop (REPL) where you can enter
commands interactively. As with the run command, each input file (or
each input file/input options combination) is parsed just once, so commands will run more quickly than if you ran them individually at the
command line.

Also like run, the input file(s) specified for the repl command will be
the default input for all interactive commands. You can override this
temporarily by specifying an -f option in particular commands. But
note that commands will not see any changes made to input files (eg by
add) until you exit and restart the REPL.

The command syntax is the same as with run:

• enter one hledger command at a time, without the usual hledger first

```
word

```
• empty lines and comment text from # to end of line are ignored

• use single or double quotes to quote arguments when needed

• type exit or quit or control-D to exit the REPL.

While it is running, the REPL remembers your command history, and you
can navigate in the usual ways:

• Keypad or Emacs navigation keys to edit the current command line

• UP/DOWN or control-P/control-N to step back/forward through history

• control-R to search for a past command

• TAB to complete file paths.

Generally repl command lines should feel much like the normal hledger
CLI, but you may find differences. repl is a little stricter; eg it
requires full command names or official abbreviations (as seen in the
commands list).

The commands and help commands, and the command help flags (CMD --tldr,
CMD -h/--help, CMD --info, CMD --man), can be useful.

You can type control-C to cancel a long-running command (but only once;
typing it a second time will exit the REPL).

And in most shells you can type control-Z to temporarily exit to the
shell (and then fg to return to the REPL).

## Examples

Start the REPL and enter some commands:

```
$ hledger repl
Enter hledger commands. To exit, enter 'quit' or 'exit', or send EOF.
% stats
Main file		  : .../2025.journal
...
% stats -f 2024/2024.journal
Main file		  : .../2024.journal
...
% stats
Main file		  : .../2025.journal
...

```
or:

```
$ hledger repl -f some.journal
Enter hledger commands. To exit, enter 'quit' or 'exit', or send EOF.
% bs
...
% print -b 'last week'
...
% bs -f other.journal
...

```
run
Run a sequence of hledger commands, provided as files or command line
arguments. Data files are parsed just once, so the commands run
faster.

```
Flags:
no command-specific flags

```
This command is experimental and could change in the future.

You can use run in three ways:

• hledger run -- CMD1 -- CMD2 -- CMD3 - read commands from the command

```
line, separated by --

```
• hledger run SCRIPTFILE1 SCRIPTFILE2 - read commands from one or more

```
files

```
• cat SCRIPTFILE1 | hledger run - read commands from standard input.

run first loads the input file(s) specified by LEDGER_FILE or by -f options, in the usual way. Then it runs each command in turn, each using
the same input data. But if you want a particular command to use different input, you can specify an -f option within that command. This
will override (not add to) the default input, just for that command.

Each input file (more precisely, each combination of input file and input options) is parsed only once. This means that commands will not
see any changes made to these files, until the next run. But the commands will run more quickly than if run individually (typically about
twice as fast).

Command scripts, whether in a file or written on the command line, have
a simple syntax:

• each line may contain a single hledger command and its arguments,

```
without the usual hledger first word

```
• empty lines are ignored

• text from # to end of line is a comment, and ignored

• you can use single or double quotes to quote arguments when needed,

```
as on the command line

```
• these extra commands are available: echo TEXT prints some text, and

```
exit or quit ends the run.

```
On unix systems you can use #!/usr/bin/env hledger run in the first
line of a command file to make it a runnable script. If that gives an
error, use #!/usr/bin/env -S hledger run.

It's ok to use the run command recursively within a command script.

You may find some differences in behaviour between run command lines
and normal hledger command lines. run is a little stricter; eg it requires full command names or official abbreviations (as seen in the
commands list), and command options must be written after the command
name.

## Examples

Run commands from the command line:

```
hledger -f some.journal run -- balance assets --depth 2 -- balance liabilities -f /some/other.journal --depth 3 --transpose -- stats

```
This would load some.journal, run balance assets --depth 2 on it, then
run balance liabilities --depth 3 --transpose on /some/other.journal,
and finally run stats on some.journal

Run commands from standard input:

```
(echo "files"; echo "stats") | hledger -f some.journal run

```
Run commands as a script:

```
$ cat report
#!/usr/bin/env -S hledger run -f some.journal

echo "List of accounts in some.journal"
accounts

echo "Assets of some.journal"
balance assets --depth 2

echo "Liabilities from /some/other.journal"
balance liabilities -f /some/other.journal --depth 3 --transpose

echo "Commands from another.script, applied to another.journal"
run -f another.journal another.script

$ chmod +x report
$ ./report
List of accounts in some.journal
...

```
ui
Runs hledger-ui (if installed).

web
Runs hledger-web (if installed).

Data entry commands
add
Add new transactions to a journal file, with interactive prompting.

```
Flags:
--no-new-accounts	  don't allow creating new accounts

```
Many hledger users edit their journals directly with a text editor, or
generate them from CSV. For more interactive data entry, there is the
add command, which prompts interactively on the console for new transactions, and appends them to the main journal file (which should be in
journal format). Existing transactions are not changed. This is one
of the few hledger commands that writes to the journal file (see also
import).

To use it, just run hledger add and follow the prompts. You can add as
many transactions as you like; when you are finished, enter . or press
control-d or control-c to exit.

Features:

• add tries to provide useful defaults, using the most similar (by description) recent transaction (filtered by the query, if any) as a

```
template.

```
• You can also set the initial defaults with command line arguments.

• Readline-style edit keys can be used during data entry.

• The tab key will auto-complete whenever possible - accounts, payees/descriptions, dates (yesterday, today, tomorrow). If the input

```
area is empty, it will insert the default value.

```
• A parenthesised transaction code may be entered following a date.

• Comments and tags may be entered following a description or amount.

• If you make a mistake, enter < at any prompt to go one step backward.

• Input prompts are displayed in a different colour when the terminal

```
supports it.

```
Notes:

• If you enter a number with no commodity symbol, and you have declared

```
a default commodity with a D directive, you might expect add  to  add
this  symbol for you.	It does not do this; we assume that if you are
using a D directive you prefer not to see the	commodity  symbol  repeated on amounts in the journal.

```
• add creates entries in journal format; it won't work with timeclock

```
or timedot files.

```
Examples:

• Record new transactions, saving to the default journal file:

```
hledger add

```
• Add transactions to 2024.journal, but also load 2023.journal for completions:

```
hledger add --file 2024.journal --file 2023.journal

```
• Provide answers for the first four prompts:

```
hledger add today 'best buy' expenses:supplies '$20'

```
There is a detailed tutorial at https://hledger.org/add.html.

add and balance assertions
Since hledger 1.43, you can add a balance assertion by writing AMOUNT =
BALANCE when asked for an amount. Eg 100 = 500.

Also, each time you enter a new amount, hledger re-checks all balance
assertions in the journal and rejects the new amount if it would make
any of them fail. You can run add with -I/--ignore-assertions to disable balance assertion checking.

add and balance assignments
Since hledger 1.51, you can add a balance assignment by writing = BALANCE (or ==, =* etc) when asked for an amount. The missing amount will
be calculated automatically.

add normally won't let you add a new posting which is dated earlier
than an existing balance assignment. (Because when add runs, existing
balance assignments have already been calculated and converted to
amounts and balance assertions.) You can allow it by disabling balance
assertion checking with -I.

import
Import new transactions from one or more data files to the main journal.

```
Flags:
--catchup		  just mark all transactions as already imported
--dry-run		  just show the transactions to be imported

```
This command detects new transactions in one or more data files specified as arguments, and appends them to the main journal.

You can import from any input file format hledger supports, but
CSV/SSV/TSV files, downloaded from financial institutions, are the most
common import source.

The import destination is the default journal file, or another specified in the usual way with $LEDGER_FILE or -f/--file. It should be in
journal format.

Examples:

```
$ hledger import bank1-checking.csv bank1-savings.csv

$ hledger import *.csv

```

## Import dry run

It's useful to preview the import by running first with --dry-run, to
sanity check the range of dates being imported, and to check the effect
of your conversion rules if converting from CSV. Eg:

```
$ hledger import bank.csv --dry-run

```
The dry run output is valid journal format, so hledger can re-parse it.
If the output is large, you could show just the uncategorised transactions like so:

```
$ hledger import --dry-run bank.csv | hledger -f- -I print unknown

```
You could also run this repeatedly to see the effect of edits to your
conversion rules:

```
$ watchexec -- "hledger import --dry-run bank.csv | hledger -f- -I print unknown"

```
Once the conversion and dates look good enough to import to your journal, perhaps with some manual fixups to follow, you would do the actual
import:

```
$ hledger import bank.csv

```

## Overlap detection

Reading CSV files is built in to hledger, and not specific to import;
so you could also import by doing hledger -f bank.csv print
>>$LEDGER_FILE.

But import is easier and provides some advantages. The main one is
that it avoids re-importing transactions it has seen on previous runs.
This means you don't have to worry about overlapping data in successive
downloads of your bank CSV; just download and import as often as you
like, and only the new transactions will be imported each time.

We don't call this "deduplication", as it's generally not possible to
reliably detect duplicates in bank CSV. Instead, import remembers the
latest date processed previously in each CSV file (saving it in a hidden file), and skips any records prior to that date. This works well
for most real-world CSV, where:

1. the data file name is stable (does not change) across imports

2. the item dates are stable across imports

3. the order of same-date items is stable across imports

4. the newest items have the newest dates

(Occasional violations of 2-4 are often harmless; you can reduce the
chance of disruption by downloading and importing more often.)

Overlap detection is automatic, and shouldn't require much attention
from you, except perhaps at first import (see below). But here's how
it works:

• For each FILE being imported from:

```
1. hledger  reads  a  file named .latest.FILE file in the same directory, if any.  This file contains the latest  record  date	previously  imported  from  FILE,  in  YYYY-MM-DD  format.  If multiple
records with that date were imported, the date is  repeated	 on  N
lines.

2. hledger  reads  records  from FILE.	 If a latest date was found in
step 1, any records before that date, and the first N  records  on
that date, are skipped.

```
• After a successful import from all FILEs, without error and without

```
--dry-run, hledger updates each FILE's .latest.FILE for next time.

```
If this goes wrong, it's relatively easy to repair:

• You'll notice it before import when you preview with import

```
--dry-run.

```
• Or after import when you try to reconcile your hledger account balances with your bank.

• hledger print -f FILE.csv will show all recently downloaded transactions. Compare these with your journal. Copy/paste if needed.

• Update your conversion rules and print again, if needed.

• You can manually update or remove the .latest file, or use import

```
--catchup FILE.

```
• Download and import more often, eg twice a week, at least while you

```
are  learning.	 It's easier to review and troubleshoot when there are
fewer transactions.

```

## First import

The first time you import from a file, when no corresponding .latest
file has been created yet, all of the records will be imported.

But perhaps you have been entering the data manually, so you know that
all of these transactions are already recorded in the journal. In this
case you can run hledger import --catchup once. This will create a
.latest file containing the latest CSV record date, so that none of
those records will be re-imported.

Or, if you know that some but not all of the transactions are in the
journal, you can create the .latest file yourself. Eg, let's say you
previously recorded foobank transactions up to 2024-10-31 in the journal. Then in the directory where you'll be saving foobank.csv, you
would create a .latest.foobank.csv file containing

```
2024-10-31

```
Or if you had three foobank transactions recorded with that date, you
would repeat the date that many times:

```
2024-10-31
2024-10-31
2024-10-31

```
Then hledger import foobank.csv [--dry-run] will import only the newer
records.

## Importing balance assignments

Journal entries added by import will have all posting amounts made explicit (like print -x).

This means that any balance assignments in the imported entries would
need to be evaluated. But this generally isn't possible, as the main
file's account balances are not visible during import. So try to avoid
generating balance assignments with your CSV rules, or importing from a
journal that contains balance assignments. (Balance assignments are
best avoided anyway.)

But if you must use them, eg because your CSV includes only balances:
you can import with print, which leaves implicit amounts implicit.
(print can also do overlap detection like import, with the --new flag):

```
$ hledger print --new -f bank.csv >> $LEDGER_FILE

```
(If you think import should preserve implicit balances, please test
that and send a pull request.)

## Import and commodity styles

Amounts in entries added by import will be formatted according to the
journal's canonical commodity styles, as declared by commodity directives or inferred from the journal's amounts.

Related: CSV > Amount decimal places.

## Import archiving

When importing from a CSV rules file (hledger import bank.rules), you
can use the archive rule to enable automatic archiving of the data
file. After a successful import, the data file (specified by source)
will be moved to an archive folder (data/, next to the rules file,
auto-created), and renamed similar to the rules file, with a date.
This can be useful for troubleshooting, detecting variations in your
banks' CSV data, regenerating entries with improved rules, etc.

The archive rule also causes import to handle source glob patterns differently: when there are multiple matched files, it will pick the oldest, not the newest.

## Import special cases

## Deduplication

Here are two kinds of "deduplication" which import does not handle (and
should not, because these can happen legitimately in financial data):

• Two or more of the new CSV records are identical, and generate identical new journal entries.

• A new CSV record generates a journal entry identical to one(s) already in the journal.

## Varying file name

If you have a download whose file name varies, you could rename it to a
fixed name after each download. Or you could use a CSV source rule
with a suitable glob pattern, and import from the .rules file.

## Multiple versions

Say you download bank.csv, import it, but forget to delete it from your
downloads folder. The next time you download it, your web browser will
save it as (eg) bank (2).csv. The source rule's glob patterns are for
just this situation: instead of specifying source bank.csv, specify
source bank*.csv. Then hledger -f bank.rules CMD or hledger import
bank.rules will automatically pick the newest matched file (bank
(2).csv).

Alternately, what if you download, but forget to import or delete, then
download again ? Now each of bank.csv and bank (2).csv might contain
data that's not in the other, and not in your journal. In this case,
it's best to import each of them in turn, oldest first (otherwise,
overlap detection could cause new records to be skipped). Enabling import archiving ensures this. Then hledger import bank.rules; hledger
import bank.rules will import and archive first bank.csv, then bank
(2).csv.

Basic report commands
accounts
List the account names used or declared in the journal.

```
Flags:
-u --used		  list accounts used
-d --declared		  list accounts declared
--undeclared		  list accounts used but not declared
--unused		  list accounts declared but not used
--find		  list the first account matched by the first
argument (a case-insensitive infix regexp)
--directives		  show as account directives, for use in journals
--locations		  also show where accounts were declared
--types		  also show account types when known
-l --flat		  list/tree mode: show accounts as a flat list
(default)
-t --tree		  list/tree mode: show accounts as a tree
--drop=N		  flat mode: omit N leading account name parts

```
This command lists account names - all of them by default, or just the
ones which have been used in transactions (-u/--used), or declared with
account directives (-d/--declared), or used but not declared (--undeclared), or declared but not used (--unused), or just the first one
matched by a pattern (--find, returning a non-zero exit code if it
fails).

You can add query arguments to select a subset of transactions or accounts.

With --directives, it shows valid account directives which could be
pasted into a journal file. This is useful together with --undeclared
when updating your account declarations to satisfy hledger check accounts.

With --locations, it also shows the file and line number of each account's declaration, if any, and the account's overall declaration order; these may be useful when troubleshooting account display order.

With --types, it also shows each account's type, if it's known. (See
Declaring accounts > Account types.)

It shows a flat list by default. With --tree, it uses indentation to
show the account hierarchy. In flat mode you can add --drop N to omit
the first few account name components. Account names can be
depth-clipped with depth:N or --depth N or -N.

Examples:

```
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

```
codes
List the codes seen in transactions, in the order parsed.

```
Flags:
no command-specific flags

```
This command prints the value of each transaction's code field, in the
order transactions were parsed. The transaction code is an optional
value written in parentheses between the date and description, often
used to store a cheque number, order number or similar.

Transactions aren't required to have a code, and missing or empty codes
will not be shown by default. With the -E/--empty flag, they will be
printed as blank lines.

You can add a query to select a subset of transactions.

Examples:

```
2022/1/1 (123) Supermarket
Food	  $5.00
Checking

2022/1/2 (124) Post Office
Postage	  $8.32
Checking

2022/1/3 Supermarket
Food	 $11.23
Checking

2022/1/4 (126) Post Office
Postage	  $3.21
Checking

$ hledger codes
123
124
126

$ hledger codes -E
123
124

126

```
commodities
List the commodity symbols used or declared in the journal.

```
Flags:
--used		  list commodities used
--declared		  list commodities declared
--undeclared		  list commodities used but not declared
--unused		  list commodities declared but not used
--find		  list the first commodity matched by the first
argument (a case-insensitive infix regexp)

```
This command lists commodity symbols/names - all of them by default, or
just the ones which have been used in transactions or P directives, or
declared with commodity directives, or used but not declared, or declared but not used, or just the first one matched by a pattern (with
--find, returning a non-zero exit code if it fails).

You can add cur: query arguments to further limit the commodities.

descriptions
List the unique descriptions used in transactions.

```
Flags:
no command-specific flags

```
This command lists the unique descriptions that appear in transactions,
in alphabetic order. You can add a query to select a subset of transactions.

Example:

```
$ hledger descriptions
Store Name
Gas Station | Petrol
Person A

```
files
List all files included in the journal. With a REGEX argument, only
file names matching the regular expression (case sensitive) are shown.

```
Flags:
no command-specific flags

```
notes
List the unique notes that appear in transactions.

```
Flags:
no command-specific flags

```
This command lists the unique notes that appear in transactions, in alphabetic order. You can add a query to select a subset of transactions. The note is the part of the transaction description after a |
character (or if there is no |, the whole description).

Example:

```
$ hledger notes
Petrol
Snacks

```
payees
List the payee/payer names used or declared in the journal.

```
Flags:
--used		  list payees used
--declared		  list payees declared
--undeclared		  list payees used but not declared
--unused		  list payees declared but not used
--find		  list the first payee matched by the first
argument (a case-insensitive infix regexp)

```
This command lists unique payee/payer names - all of them by default,
or just the ones which have been used in transaction descriptions, or
declared with payee directives, or used but not declared, or declared
but not used, or just the first one matched by a pattern (with --find,
returning a non-zero exit code if it fails).

The payee/payer name is the part of the transaction description before
a | character (or if there is no |, the whole description).

You can add query arguments to select a subset of transactions or payees.

Example:

```
$ hledger payees
Store Name
Gas Station
Person A

```
prices
Print the market prices declared with P directives. With --infer-market-prices, also show any additional prices inferred from costs. With
--show-reverse, also show additional prices inferred by reversing known
prices.

```
Flags:
--show-reverse	  also show the prices inferred by reversing known
prices

```
Price amounts are always displayed with their full precision, except
for reverse prices which are limited to 8 decimal digits.

Prices can be filtered by a date:, cur: or amt: query.

Generally if you run this command with --infer-market-prices --show-reverse, it will show the same prices used internally to calculate value
reports. But if in doubt, you can inspect those directly by running
the value report with --debug=2.

stats
Show journal and performance statistics.

```
Flags:
-1			  show a single line of output
-v --verbose		  show more detailed output
-o --output-file=FILE	  write output to FILE.

```
The stats command shows summary information for the whole journal, or a
matched part of it. With a reporting interval, it shows a report for
each report period.

It also shows some performance statistics:

• how long the program ran for

• the number of transactions processed per second

• the peak live memory in use by the program to do its work

• the peak allocated memory as seen by the program

By default, the output is reasonably discreet; it reveals the main file
name, your activity level, and the speed of your machine.

With -v/--verbose, more details are shown: the full paths of all files,
and the names of the commodities you work with.

With -1, only one line of output is shown, in a machine-friendly
tab-separated format: the program version, the main journal file name,
and the performance stats,

The run time of stats is similar to that of a balance report.

Example:

```
$ hledger stats -f examples/1ktxns-1kaccts.journal
Main file		  : .../1ktxns-1kaccts.journal
Included files	  : 0
Txns span		  : 2000-01-01 to 2002-09-27 (1000 days)
Last txn		  : 2002-09-26 (7827 days ago)
Txns		  : 1000 (1.0 per day)
Txns last 30 days	  : 0 (0.0 per day)
Txns last 7 days	  : 0 (0.0 per day)
Payees/descriptions : 1000
Accounts		  : 1000 (depth 10)
Commodities	  : 26
Market prices	  : 1000
Runtime stats	  : 0.12 s elapsed, 8266 txns/s, 4 MB live, 16 MB alloc

$ hledger stats -1 -f examples/10ktxns-1kaccts.journal
1.50.99-g0835a2485-20251119, mac-aarch64	  10ktxns-1kaccts.journal 0.66 s elapsed  15244 txns/s	  28 MB live  86 MB alloc

```
This command supports the -o/--output-file option (but not -O/--output-format).

tags
List the tag names used or declared in the journal, or their values.

```
Flags:
--used		  list tags used
--declared		  list tags declared
--undeclared		  list tags used but not declared
--unused		  list tags declared but not used
--find		  list the first tag whose name is matched by the
first argument (a case-insensitive infix regexp)
--values		  list tag values instead of tag names
--parsed		  show them in the order they were parsed (mostly),
including duplicates

```
This command lists tag names - all of them by default, or just the ones
which have been used on transactions/postings/accounts, or declared
with tag directives, or used but not declared, or declared but not
used, or just the first one matched by a pattern (with --find, returning a non-zero exit code if it fails).

Note this command's non-standard first argument: it is a case-insensitive infix regular expression for matching tag names, which limits the
tags shown. Any additional arguments are standard query arguments,
which limit the transactions, postings, or accounts providing tags.

With --values, the tags' unique non-empty values are listed instead.

With -E/--empty, blank/empty values are also shown.

With --parsed, tags or values are shown in the order they were parsed,
with duplicates included. (Except, tags from account declarations are
always shown first.)

Remember that accounts also acquire tags from their parents; postings
also acquire tags from their account and transaction; and transactions
also acquire tags from their postings.

Standard report commands
print
Show full journal entries, representing transactions.

```
Flags:
-x --explicit		  show all amounts explicitly
--invert		  display all amounts with reversed sign
--locations		  add tags showing file paths and line numbers
-m --match=DESC		  fuzzy search for one recent transaction with
description closest to DESC
--new		  show only newer-dated transactions added in each
file since last run
--round=TYPE		  how much rounding or padding should be done when
displaying amounts ?
none - show original decimal digits,
as in journal (default)
soft - just add or remove decimal zeros
to match precision
hard - round posting amounts to precision
(can unbalance transactions)
all  - also round cost amounts to precision
(can unbalance transactions)
--base-url=URLPREFIX	  in html output, generate links to hledger-web,
with this prefix. (Usually the base url shown by
hledger-web; can also be relative.)
-O --output-format=FMT	  select the output format. Supported formats:
txt, beancount, csv, tsv, html, fods, json, sql.
-o --output-file=FILE	  write output to FILE. A file extension matching
one of the above formats selects that format.

```
The print command displays full journal entries (transactions) from the
journal file, sorted by date (or with --date2, by secondary date).

Directives and inter-transaction comments are not shown, currently.
This means the print command is somewhat lossy, and if you are using it
to reformat/regenerate your journal you should take care to also copy
over the directives and inter-transaction comments.

Eg:

```
$ hledger print -f examples/sample.journal date:200806
2008/06/01 gift
assets:bank:checking		  $1
income:gifts			 $-1

2008/06/02 save
assets:bank:saving		  $1
assets:bank:checking		 $-1

2008/06/03 * eat & shop
expenses:food		       $1
expenses:supplies	       $1
assets:cash		      $-2

```
print amount explicitness
Normally, whether posting amounts are implicit or explicit is preserved. For example, when an amount is omitted in the journal, it will
not appear in the output. Similarly, if a conversion cost is implied
but not written, it will not appear in the output.

You can use the -x/--explicit flag to force explicit display of all
amounts and costs. This can be useful for troubleshooting or for making your journal more readable and robust against data entry errors.
-x is also implied by using any of -B,-V,-X,--value.

The -x/--explicit flag will cause any postings with a multi-commodity
amount (which can arise when a multi-commodity transaction has an implicit amount) to be split into multiple single-commodity postings,
keeping the output parseable.

print alignment
Amounts are shown right-aligned within each transaction (but not
aligned across all transactions; you can achieve that with ledger-mode
in Emacs).

print amount style
Amounts will be displayed mostly in their commodity's display style,
with standardised symbol placement, decimal mark, and digit group
marks. This does not apply to their decimal digits; print normally
shows the same decimal digits that are recorded in each journal entry.

You can override the decimal precisions with print's special --round
option (since 1.32). --round tries to show amounts with their commodities' standard decimal precisions, increasingly strongly:

• --round=none show amounts with original precisions (default)

• --round=soft add/remove decimal zeros in amounts (except costs)

• --round=hard round amounts (except costs), possibly hiding significant digits

• --round=all round all amounts and costs

soft is good for non-lossy cleanup, displaying more consistent decimals
where possible, without making entries unbalanced.

hard or all can be good for stronger cleanup, when decimal rounding is
wanted. Note rounding can produce unbalanced journal entries, perhaps
requiring manual fixup.

print parseability
Normally, print's output is a valid hledger journal, which you can
"pipe" to a second hledger command for further processing. This is
sometimes convenient for achieving certain kinds of query (though less
needed now that queries have become more powerful):

```
# Show running total of food expenses paid from cash.
# -f- reads from stdin. -I/--ignore-assertions is sometimes needed.
$ hledger print assets:cash | hledger -f- -I reg expenses:food

```
But here are some things which can cause print's output to become unparseable:

• --round (see above) can disrupt transaction balancing.

• Account aliases or pivoting can disrupt account names, balance assertions, or balance assignments.

• Value reporting also can disrupt balance assertions or balance assignments.

• Auto postings can generate too many amountless postings.

• --infer-costs or --infer-equity can generate too-complex redundant

```
costs.

```
• Because print always shows transactions in date order, balance assertions involving non-date-ordered transactions (and same-day postings)

```
could be disrupted.

```
print, other features
With -B/--cost, amounts with costs are shown converted to cost.

With --invert, posting amounts are shown with their sign flipped. It
could be useful if you have accidentally recorded some transactions
with the wrong signs.

With --new, print shows only transactions it has not seen on a previous
run. This uses the same deduplication system as the import command.
(See import's docs for details.)

With -m DESC/--match=DESC, print shows one recent transaction whose description is most similar to DESC. DESC should contain at least two
characters. If there is no similar-enough match, no transaction will
be shown and the program exit code will be non-zero.

With --locations, print adds the source file and line number to every
transaction, as a tag.

print output format
This command also supports the output destination and output format options The output formats supported are txt, beancount (Added in 1.32),
csv, tsv (Added in 1.32), json and sql.

The beancount format tries to produce Beancount-compatible output, as
follows:

• Transaction and postings with unmarked status are converted to

```
cleared (*) status.

```
• Transactions' payee and note are backslash-escaped and double-quote-escaped and wrapped in double quotes.

• Transaction tags are copied to Beancount #tag format.

• Commodity symbols are converted to upper case, and a small number of

```
currency symbols like $ are converted to the  corresponding  currency
names.

```
• Account name parts are capitalised and unsupported characters are replaced with -. If an account name part does not begin with a letter,

```
or  if	 the first part is not Assets, Liabilities, Equity, Income, or
Expenses, an error is raised.	(Use --alias options to bring your accounts into compliance.)

```
• An open directive is generated for each account used, on the earliest

```
transaction date.

```
Some limitations:

• Balance assertions are removed.

• Balance assignments become missing amounts.

• Virtual and balanced virtual postings become regular postings.

• Directives are not converted.

Here's an example of print's CSV output:

```
$ hledger print -Ocsv
"txnidx","date","date2","status","code","description","comment","account","amount","commodity","credit","debit","posting-status","posting-comment"
"1","2008/01/01","","","","income","","assets:bank:checking","1","$","","1","",""
"1","2008/01/01","","","","income","","income:salary","-1","$","1","","",""
"2","2008/06/01","","","","gift","","assets:bank:checking","1","$","","1","",""
"2","2008/06/01","","","","gift","","income:gifts","-1","$","1","","",""
"3","2008/06/02","","","","save","","assets:bank:saving","1","$","","1","",""
"3","2008/06/02","","","","save","","assets:bank:checking","-1","$","1","","",""
"4","2008/06/03","","*","","eat & shop","","expenses:food","1","$","","1","",""
"4","2008/06/03","","*","","eat & shop","","expenses:supplies","1","$","","1","",""
"4","2008/06/03","","*","","eat & shop","","assets:cash","-2","$","2","","",""
"5","2008/12/31","","*","","pay off","","liabilities:debts","1","$","","1","",""
"5","2008/12/31","","*","","pay off","","assets:bank:checking","-1","$","1","","",""

```
• There is one CSV record per posting, with the parent transaction's

```
fields repeated.

```
• The "txnidx" (transaction index) field shows which postings belong to

```
the same transaction.	(This number might change if transactions  are
reordered  within  the file, files are parsed/included in a different
order, etc.)

```
• The amount is separated into "commodity" (the symbol) and "amount"

```
(numeric quantity) fields.

```
• The numeric amount is repeated in either the "credit" or "debit" column, for convenience. (Those names are not accurate in the accounting sense; it just puts negative amounts under credit and zero or

```
greater amounts under debit.)

```
aregister
(areg)

Show the transactions and running balances in one account, with each
transaction on one line.

```
Flags:
--txn-dates		  filter strictly by transaction date, not posting
date. Warning: this can show a wrong running
balance.
--no-elide		  don't show only 2 commodities per amount
--cumulative		  accumulation mode: show running total from report
start date
-H --historical		  accumulation mode: show historical running
total/balance (includes postings before report
start date) (default)
--invert		  display all amounts with reversed sign
--heading=YN		  show heading row above table: yes (default) or no
-w --width=N		  set output width (default: terminal width). -wN,M
sets description width as well.
--align-all		  guarantee alignment across all lines (slower)
-O --output-format=FMT	  select the output format. Supported formats:
txt, html, csv, tsv, json.
-o --output-file=FILE	  write output to FILE. A file extension matching
one of the above formats selects that format.

```
aregister shows the overall transactions affecting a particular account
(and any subaccounts). Each report line represents one transaction in
this account. Transactions before the report start date are included
in the running balance (--historical mode is the default). You can
suppress this behaviour using the --cumulative option.

This is a more "real world", bank-like view than the register command
(which shows individual postings, possibly from multiple accounts, not
necessarily in historical mode). As a quick rule of thumb:

• aregister is best when reconciling real-world asset/liability accounts

• register is best when reviewing individual revenues/expenses.

Note this command's non-standard, and required, first argument; it
specifies the account whose register will be shown. You can write the
account's name, or (to save typing) a case-insensitive infix regular
expression matching the name, which selects the alphabetically first
matched account. (For example, if you have assets:personal checking
and assets:business checking, hledger areg checking would select assets:business checking.)

Transactions involving subaccounts of this account will also be shown.
aregister ignores depth limits, so its final total will always match a
historical balance report with similar arguments.

Any additional arguments are standard query arguments, which will limit
the transactions shown. Note some queries will disturb the running
balance, causing it to be different from the account's real-world running balance.

An example: this shows the transactions and historical running balance
during july, in the first account whose name contains "checking":

```
$ hledger areg checking date:jul

```
Each aregister line item shows:

• the transaction's date (or the relevant posting's date if different,

```
see below)

```
• the names of all the other account(s) involved in this transaction

```
(probably abbreviated)

```
• the total change to this account's balance from this transaction

• the account's historical running balance after this transaction.

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

This command also supports the output destination and output format options. The output formats supported are txt, csv, tsv (Added in 1.32),
html, fods (Added in 1.41) and json.

aregister and posting dates
aregister always shows one line (and date and amount) per transaction.
But sometimes transactions have postings with different dates. Also,
not all of a transaction's postings may be within the report period.
To resolve this, aregister shows the earliest of the transaction's date
and posting dates that is in-period, and the sum of the in-period postings. In other words it will show a combined line item with just the
earliest date, and the running balance will (temporarily, until the
transaction's last posting) be inaccurate. Use register -H if you need
to see the individual postings.

There is also a --txn-dates flag, which filters strictly by transaction
date, ignoring posting dates. This too can cause an inaccurate running
balance.

register
(reg)

Show postings and their running total.

```
Flags:
--cumulative		  accumulation mode: show running total from report
start date (default)
-H --historical		  accumulation mode: show historical running
total/balance (includes postings before report
start date)
-A --average		  show running average of posting amounts instead
of total (implies --empty)
-m --match=DESC		  fuzzy search for one recent posting with
description closest to DESC
-r --related		  show postings' siblings instead
--invert		  display all amounts with reversed sign
--sort=FIELDS	  sort by: date, desc, account, amount, absamount,
or a comma-separated combination of these. For a
descending sort, prefix with -. (Default: date)
-w --width=N		  set output width (default: terminal width). -wN,M
sets description width as well.
--align-all		  guarantee alignment across all lines (slower)
--base-url=URLPREFIX	  in html output, generate links to hledger-web,
with this prefix. (Usually the base url shown by
hledger-web; can also be relative.)
-O --output-format=FMT	  select the output format. Supported formats:
txt, csv, tsv, html, fods, json.
-o --output-file=FILE	  write output to FILE. A file extension matching
one of the above formats selects that format.

```
The register command displays matched postings, across all accounts, in
date order, with their running total or running historical balance.
(See also the aregister command, which shows matched transactions in a
specific account.)

register normally shows line per posting, but note that multi-commodity
amounts will occupy multiple lines (one line per commodity).

It is typically used with a query selecting a particular account, to
see that account's activity:

```
$ hledger register checking
2008/01/01 income		      assets:bank:checking	      $1	   $1
2008/06/01 gift		      assets:bank:checking	      $1	   $2
2008/06/02 save		      assets:bank:checking	     $-1	   $1
2008/12/31 pay off	      assets:bank:checking	     $-1	    0

```
With --date2, it shows and sorts by secondary date instead.

For performance reasons, column widths are chosen based on the first
1000 lines; this means unusually wide values in later lines can cause
visual discontinuities as column widths are adjusted. If you want to
ensure perfect alignment, at the cost of more time and memory, use the
--align-all flag.

The --historical/-H flag adds the balance from any undisplayed prior
postings to the running total. This is useful when you want to see
only recent activity, with a historically accurate running balance:

```
$ hledger register checking -b 2008/6 --historical
2008/06/01 gift		      assets:bank:checking	      $1	   $2
2008/06/02 save		      assets:bank:checking	     $-1	   $1
2008/12/31 pay off	      assets:bank:checking	     $-1	    0

```
The --depth option limits the amount of sub-account detail displayed.

The --average/-A flag shows the running average posting amount instead
of the running total (so, the final number displayed is the average for
the whole report period). This flag implies --empty (see below). It
is affected by --historical. It works best when showing just one account and one commodity.

The --related/-r flag shows the other postings in the transactions of
the postings which would normally be shown.

The --invert flag negates all amounts. For example, it can be used on
an income account where amounts are normally displayed as negative numbers. It's also useful to show postings on the checking account together with the related account:

The --sort=FIELDS flag sorts by the fields given, which can be any of
account, amount, absamount, date, or desc/description, optionally separated by commas. For example, --sort account,amount will group all
transactions in each account, sorted by transaction amount. Each field
can be negated by a preceding -, so --sort -amount will show transactions ordered from smallest amount to largest amount.

```
$ hledger register --related --invert assets:checking

```
With a reporting interval, register shows summary postings, one per interval, aggregating the postings to each account:

```
$ hledger register --monthly income
2008/01		      income:salary			     $-1	  $-1
2008/06		      income:gifts			     $-1	  $-2

```
Periods with no activity, and summary postings with a zero amount, are
not shown by default; use the --empty/-E flag to see them:

```
$ hledger register --monthly income -E
2008/01		      income:salary			     $-1	  $-1
2008/02							       0	  $-1
2008/03							       0	  $-1
2008/04							       0	  $-1
2008/05							       0	  $-1
2008/06		      income:gifts			     $-1	  $-2
2008/07							       0	  $-2
2008/08							       0	  $-2
2008/09							       0	  $-2
2008/10							       0	  $-2
2008/11							       0	  $-2
2008/12							       0	  $-2

```
Often, you'll want to see just one line per interval. The --depth option helps with this, causing subaccounts to be aggregated:

```
$ hledger register --monthly assets --depth 1
2008/01		      assets				      $1	   $1
2008/06		      assets				     $-1	    0
2008/12		      assets				     $-1	  $-1

```
Note when using report intervals, if you specify start/end dates these
will be adjusted outward if necessary to contain a whole number of intervals. This ensures that the first and last intervals are full
length and comparable to the others in the report.

With -m DESC/--match=DESC, register does a fuzzy search for one recent
posting whose description is most similar to DESC. DESC should contain
at least two characters. If there is no similar-enough match, no posting will be shown and the program exit code will be non-zero.

## Custom register output

register normally uses the full terminal width (or 80 columns if it
can't detect that). You can override this with the --width/-w option.

The description and account columns normally share the space equally
(about half of (width - 40) each). You can adjust this by adding a description width as part of --width's argument, comma-separated: --width
W,D . Here's a diagram (won't display correctly in --help):

```
<--------------------------------- width (W) ---------------------------------->
date (10)	 description (D)       account (W-41-D)	    amount (12)	  balance (12)
DDDDDDDDDD dddddddddddddddddddd  aaaaaaaaaaaaaaaaaaa  AAAAAAAAAAAA  AAAAAAAAAAAA

```
and some examples:

```
$ hledger reg			# use terminal width (or 80 on windows)
$ hledger reg -w 100		# use width 100
$ hledger reg -w 100,40		# set overall width 100, description width 40

```
This command also supports the output destination and output format options The output formats supported are txt, csv, tsv (Added in 1.32),
and json.

balancesheet
(bs)

Show the end balances in asset and liability accounts. Amounts are
shown with normal positive sign, as in conventional financial statements.

```
Flags:
--sum		  calculation mode: show sum of posting amounts
(default)
--valuechange	  calculation mode: show total change of value of
period-end historical balances (caused by deposits,
withdrawals, market price fluctuations)
--gain		  calculation mode: show unrealised capital
gain/loss (historical balance value minus cost
basis)
--count		  calculation mode: show the count of postings
--change		  accumulation mode: accumulate amounts from column
start to column end (in multicolumn reports)
--cumulative		  accumulation mode: accumulate amounts from report
start (specified by e.g. -b/--begin) to column end
-H --historical		  accumulation mode: accumulate amounts from
journal start to column end (includes postings
before report start date) (default)
-l --flat		  list/tree mode: show accounts as a flat list
(default). Amounts exclude subaccount amounts,
except where the account is depth-clipped.
-t --tree		  list/tree mode: show accounts as a tree. Amounts
include subaccount amounts.
--drop=N		  in list mode, omit N leading account name parts
--declared		  include non-parent declared accounts (best used
with -E)
-A --average		  show a row average column (in multicolumn
reports)
-T --row-total		  show a row total column (in multicolumn reports)
--summary-only	  display only row summaries (e.g. row total,
average) (in multicolumn reports)
-N --no-total		  omit the final total row
--no-elide		  in tree mode, don't squash boring parent accounts
--format=FORMATSTR	  use this custom line format (in simple reports)
-S --sort-amount	  sort by amount instead of account code/name
-% --percent		  express values in percentage of each column's
total
--layout=ARG		  how to show multi-commodity amounts:
'wide[,WIDTH]': all commodities on one line
'tall'	: each commodity on a new line
'bare'	: bare numbers, symbols in a column
--base-url=URLPREFIX	  in html output, generate hyperlinks to
hledger-web, with this prefix. (Usually the base
url shown by hledger-web; can also be relative.)
-O --output-format=FMT	  select the output format. Supported formats:
txt, html, csv, tsv, json.
-o --output-file=FILE	  write output to FILE. A file extension matching
one of the above formats selects that format.

```
This command displays a balance sheet, showing historical ending balances of asset and liability accounts. (To see equity as well, use the
balancesheetequity command.)

Accounts declared with the Asset, Cash or Liability type are shown (see
account types). Or if no such accounts are declared, it shows
top-level accounts named asset or liability (case insensitive, plurals
allowed) and their subaccounts.

Example:

```
$ hledger balancesheet
Balance Sheet 2008-12-31

|| 2008-12-31
====================++============
Assets		  ||
--------------------++------------
assets:bank:saving ||	     $1
assets:cash	  ||	    $-2
--------------------++------------
||	    $-1
====================++============
Liabilities	  ||
--------------------++------------
liabilities:debts  ||	    $-1
--------------------++------------
||	    $-1
====================++============
Net:		  ||	      0

```
This command is a higher-level variant of the balance command, and supports many of that command's features, such as multi-period reports.
It is similar to hledger balance -H assets liabilities, but with
smarter account detection, and liabilities displayed with their sign
flipped.

This command also supports the output destination and output format options The output formats supported are txt, csv, tsv (Added in 1.32),
html, and json.

balancesheetequity
(bse)

This command displays a balance sheet, showing historical ending balances of asset, liability and equity accounts. Amounts are shown with
normal positive sign, as in conventional financial statements.

```
Flags:
--sum		  calculation mode: show sum of posting amounts
(default)
--valuechange	  calculation mode: show total change of value of
period-end historical balances (caused by deposits,
withdrawals, market price fluctuations)
--gain		  calculation mode: show unrealised capital
gain/loss (historical balance value minus cost
basis)
--count		  calculation mode: show the count of postings
--change		  accumulation mode: accumulate amounts from column
start to column end (in multicolumn reports)
--cumulative		  accumulation mode: accumulate amounts from report
start (specified by e.g. -b/--begin) to column end
-H --historical		  accumulation mode: accumulate amounts from
journal start to column end (includes postings
before report start date) (default)
-l --flat		  list/tree mode: show accounts as a flat list
(default). Amounts exclude subaccount amounts,
except where the account is depth-clipped.
-t --tree		  list/tree mode: show accounts as a tree. Amounts
include subaccount amounts.
--drop=N		  in list mode, omit N leading account name parts
--declared		  include non-parent declared accounts (best used
with -E)
-A --average		  show a row average column (in multicolumn
reports)
-T --row-total		  show a row total column (in multicolumn reports)
--summary-only	  display only row summaries (e.g. row total,
average) (in multicolumn reports)
-N --no-total		  omit the final total row
--no-elide		  in tree mode, don't squash boring parent accounts
--format=FORMATSTR	  use this custom line format (in simple reports)
-S --sort-amount	  sort by amount instead of account code/name
-% --percent		  express values in percentage of each column's
total
--layout=ARG		  how to show multi-commodity amounts:
'wide[,WIDTH]': all commodities on one line
'tall'	: each commodity on a new line
'bare'	: bare numbers, symbols in a column
--base-url=URLPREFIX	  in html output, generate hyperlinks to
hledger-web, with this prefix. (Usually the base
url shown by hledger-web; can also be relative.)
-O --output-format=FMT	  select the output format. Supported formats:
txt, html, csv, tsv, json.
-o --output-file=FILE	  write output to FILE. A file extension matching
one of the above formats selects that format.

```
This report shows accounts declared with the Asset, Cash, Liability or
Equity type (see account types). Or if no such accounts are declared,
it shows top-level accounts named asset, liability or equity (case insensitive, plurals allowed) and their subaccounts.

Example:

```
$ hledger balancesheetequity
Balance Sheet With Equity 2008-12-31

|| 2008-12-31
====================++============
Assets		  ||
--------------------++------------
assets:bank:saving ||	     $1
assets:cash	  ||	    $-2
--------------------++------------
||	    $-1
====================++============
Liabilities	  ||
--------------------++------------
liabilities:debts  ||	    $-1
--------------------++------------
||	    $-1
====================++============
Equity		  ||
--------------------++------------
--------------------++------------
||	      0
====================++============
Net:		  ||	      0

```
This command is a higher-level variant of the balance command, and supports many of that command's features, such as multi-period reports.
It is similar to hledger balance -H assets liabilities equity, but with
smarter account detection, and liabilities/equity displayed with their
sign flipped.

This report is the easiest way to see if the accounting equation (A+L+E
= 0) is satisfied (after you have done a close --retain to merge revenues and expenses with equity, and perhaps added --infer-equity to
balance your commodity conversions).

This command also supports the output destination and output format options The output formats supported are txt, csv, tsv, html, and json.

cashflow
(cf)

This command displays a (simple) cashflow statement, showing the inflows and outflows affecting "cash" (ie, liquid, easily convertible)
assets. Amounts are shown with normal positive sign, as in conventional financial statements.

```
Flags:
--sum		  calculation mode: show sum of posting amounts
(default)
--valuechange	  calculation mode: show total change of value of
period-end historical balances (caused by deposits,
withdrawals, market price fluctuations)
--gain		  calculation mode: show unrealised capital
gain/loss (historical balance value minus cost
basis)
--count		  calculation mode: show the count of postings
--change		  accumulation mode: accumulate amounts from column
start to column end (in multicolumn reports)
(default)
--cumulative		  accumulation mode: accumulate amounts from report
start (specified by e.g. -b/--begin) to column end
-H --historical		  accumulation mode: accumulate amounts from
journal start to column end (includes postings
before report start date)
-l --flat		  list/tree mode: show accounts as a flat list
(default). Amounts exclude subaccount amounts,
except where the account is depth-clipped.
-t --tree		  list/tree mode: show accounts as a tree. Amounts
include subaccount amounts.
--drop=N		  in list mode, omit N leading account name parts
--declared		  include non-parent declared accounts (best used
with -E)
-A --average		  show a row average column (in multicolumn
reports)
-T --row-total		  show a row total column (in multicolumn reports)
--summary-only	  display only row summaries (e.g. row total,
average) (in multicolumn reports)
-N --no-total		  omit the final total row
--no-elide		  in tree mode, don't squash boring parent accounts
--format=FORMATSTR	  use this custom line format (in simple reports)
-S --sort-amount	  sort by amount instead of account code/name
-% --percent		  express values in percentage of each column's
total
--layout=ARG		  how to show multi-commodity amounts:
'wide[,WIDTH]': all commodities on one line
'tall'	: each commodity on a new line
'bare'	: bare numbers, symbols in a column
--base-url=URLPREFIX	  in html output, generate hyperlinks to
hledger-web, with this prefix. (Usually the base
url shown by hledger-web; can also be relative.)
-O --output-format=FMT	  select the output format. Supported formats:
txt, html, csv, tsv, json.
-o --output-file=FILE	  write output to FILE. A file extension matching
one of the above formats selects that format.

```
This report shows accounts declared with the Cash type (see account
types). Or if no such accounts are declared, it shows accounts

• under a top-level account named asset (case insensitive, plural allowed)

• whose name contains some variation of cash, bank, checking or saving.

More precisely: all accounts matching this case insensitive regular expression:

^assets?(:.+)?:(cash|bank|che(ck|que?)(ing)?|savings?|currentcash)(:|$)

and their subaccounts.

An example cashflow report:

```
$ hledger cashflow
Cashflow Statement 2008

|| 2008
====================++======
Cash flows	  ||
--------------------++------
assets:bank:saving ||   $1
assets:cash	  ||  $-2
--------------------++------
||  $-1

```
This command is a higher-level variant of the balance command, and supports many of that command's features, such as multi-period reports.
It is similar to hledger balance assets not:fixed not:investment
not:receivable, but with smarter account detection.

This command also supports the output destination and output format options The output formats supported are txt, csv, tsv (Added in 1.32),
html, and json.

incomestatement
(is)

Show revenue inflows and expense outflows during the report period.
Amounts are shown with normal positive sign, as in conventional financial statements.

```
Flags:
--sum		  calculation mode: show sum of posting amounts
(default)
--valuechange	  calculation mode: show total change of value of
period-end historical balances (caused by deposits,
withdrawals, market price fluctuations)
--gain		  calculation mode: show unrealised capital
gain/loss (historical balance value minus cost
basis)
--count		  calculation mode: show the count of postings
--change		  accumulation mode: accumulate amounts from column
start to column end (in multicolumn reports)
(default)
--cumulative		  accumulation mode: accumulate amounts from report
start (specified by e.g. -b/--begin) to column end
-H --historical		  accumulation mode: accumulate amounts from
journal start to column end (includes postings
before report start date)
-l --flat		  list/tree mode: show accounts as a flat list
(default). Amounts exclude subaccount amounts,
except where the account is depth-clipped.
-t --tree		  list/tree mode: show accounts as a tree. Amounts
include subaccount amounts.
--drop=N		  in list mode, omit N leading account name parts
--declared		  include non-parent declared accounts (best used
with -E)
-A --average		  show a row average column (in multicolumn
reports)
-T --row-total		  show a row total column (in multicolumn reports)
--summary-only	  display only row summaries (e.g. row total,
average) (in multicolumn reports)
-N --no-total		  omit the final total row
--no-elide		  in tree mode, don't squash boring parent accounts
--format=FORMATSTR	  use this custom line format (in simple reports)
-S --sort-amount	  sort by amount instead of account code/name
-% --percent		  express values in percentage of each column's
total
--layout=ARG		  how to show multi-commodity amounts:
'wide[,WIDTH]': all commodities on one line
'tall'	: each commodity on a new line
'bare'	: bare numbers, symbols in a column
--base-url=URLPREFIX	  in html output, generate hyperlinks to
hledger-web, with this prefix. (Usually the base
url shown by hledger-web; can also be relative.)
-O --output-format=FMT	  select the output format. Supported formats:
txt, html, csv, tsv, json.
-o --output-file=FILE	  write output to FILE. A file extension matching
one of the above formats selects that format.

```
This command displays an income statement, showing revenues and expenses during one or more periods.

It shows accounts declared with the Revenue or Expense type (see account types). Or if no such accounts are declared, it shows top-level
accounts named revenue or income or expense (case insensitive, plurals
allowed) and their subaccounts.

Example:

```
$ hledger incomestatement
Income Statement 2008

|| 2008
===================++======
Revenues		 ||
-------------------++------
income:gifts	 ||   $1
income:salary	 ||   $1
-------------------++------
||   $2
===================++======
Expenses		 ||
-------------------++------
expenses:food	 ||   $1
expenses:supplies ||   $1
-------------------++------
||   $2
===================++======
Net:		 ||    0

```
This command is a higher-level variant of the balance command, and supports many of that command's features, such as multi-period reports.
It is similar to hledger balance '(revenues|income)' expenses, but with
smarter account detection, and revenues/income displayed with their
sign flipped.

This command also supports the output destination and output format options The output formats supported are txt, csv, tsv (Added in 1.32),
html, and json.

Advanced report commands
balance
(bal)

A flexible, general purpose "summing" report that shows accounts with
some kind of numeric data. This can be balance changes per period, end
balances, budget performance, unrealised capital gains, etc.

```
Flags:
--sum		  calculation mode: show sum of posting amounts
(default)
--valuechange	  calculation mode: show total change of value of
period-end historical balances (caused by deposits,
withdrawals, market price fluctuations)
--gain		  calculation mode: show unrealised capital
gain/loss (historical balance value minus cost
basis)
--budget[=DESCPAT]	  calculation mode: show sum of posting amounts
together with budget goals defined by periodic
transactions. With a DESCPAT argument (must be
separated by = not space),
use only periodic transactions with matching
description
(case insensitive substring match).
--count		  calculation mode: show the count of postings
--change		  accumulation mode: accumulate amounts from column
start to column end (in multicolumn reports,
default)
--cumulative		  accumulation mode: accumulate amounts from report
start (specified by e.g. -b/--begin) to column end
-H --historical		  accumulation mode: accumulate amounts from
journal start to column end (includes postings
before report start date)
-l --flat		  list/tree mode: show accounts as a flat list
(default). Amounts exclude subaccount amounts,
except where the account is depth-clipped.
-t --tree		  list/tree mode: show accounts as a tree. Amounts
include subaccount amounts.
--drop=N		  in list mode, omit N leading account name parts
--declared		  include non-parent declared accounts (best used
with -E)
-A --average		  show a row average column (in multicolumn
reports)
-T --row-total		  show a row total column (in multicolumn reports)
--summary-only	  display only row summaries (e.g. row total,
average) (in multicolumn reports)
-N --no-total		  omit the final total row
--no-elide		  in tree mode, don't squash boring parent accounts
--format=FORMATSTR	  use this custom line format (in simple reports)
-S --sort-amount	  sort by amount instead of account code/name (in
flat mode). With multiple columns, sorts by the row
total, or by row average if that is displayed.
-% --percent		  express values in percentage of each column's
total
-r --related		  show the other accounts transacted with, instead
--invert		  display all amounts with reversed sign
--transpose		  switch rows and columns (use vertical time axis)
--layout=ARG		  how to lay out multi-commodity amounts and the
overall table:
'wide[,W]': commodities on same line, up to W wide
'tall'    : commodities on separate lines
'bare'    : commodity symbols in a separate column
'tidy'    : each data field in its own column
--base-url=URLPREFIX	  in html output, generate links to hledger-web,
with this prefix. (Usually the base url shown by
hledger-web; can also be relative.)
-O --output-format=FMT	  select the output format. Supported formats:
txt, html, csv, tsv, json, fods.
-o --output-file=FILE	  write output to FILE. A file extension matching
one of the above formats selects that format.

```
balance is one of hledger's oldest and most versatile commands, for
listing account balances, balance changes, values, value changes and
more, during one time period or many. Generally it shows a table, with
rows representing accounts, and columns representing periods.

Note there are some variants of the balance command with convenient defaults, which are simpler to use: balancesheet, balancesheetequity,
cashflow and incomestatement. When you need more control, then use
balance.

balance features
Here's a quick overview of the balance command's features, followed by
more detailed descriptions and examples. Many of these work with the
other balance-like commands as well (bs, cf, is..).

balance can show..

• accounts as a list (-l) or a tree (-t)

• optionally depth-limited (-[1-9])

• sorted by declaration order and name, or by amount

..and their..

• balance changes (the default)

• or actual and planned balance changes (--budget)

• or value of balance changes (-V)

• or change of balance values (--valuechange)

• or unrealised capital gain/loss (--gain)

• or balance changes from sibling postings (--related/-r)

• or postings count (--count)

..in..

• one time period (the whole journal period by default)

• or multiple periods (-D, -W, -M, -Q, -Y, -p INTERVAL)

..either..

• per period (the default)

• or accumulated since report start date (--cumulative)

• or accumulated since account creation (--historical/-H)

..possibly converted to..

• cost (--value=cost[,COMM]/--cost/-B)

• or market value, as of transaction dates (--value=then[,COMM])

• or at period ends (--value=end[,COMM])

• or now (--value=now)

• or at some other date (--value=YYYY-MM-DD)

..with..

• totals (-T), averages (-A), percentages (-%), inverted sign (--invert)

• rows and columns swapped (--transpose)

• another field used as account name (--pivot)

• custom-formatted line items (single-period reports only) (--format)

• commodities displayed on the same line or multiple lines (--layout)

This command supports the output destination and output format options,
with output formats txt, csv, tsv (Added in 1.32), json, and (multi-period reports only:) html, fods (Added in 1.40). In txt output in a
colour-supporting terminal, negative amounts are shown in red.

## Simple balance report

With no arguments, balance shows a list of all accounts and their
change of balance - ie, the sum of posting amounts, both inflows and
outflows - during the entire period of the journal. ("Simple" here
means just one column of numbers, covering a single period. You can
also have multi-period reports, described later.)

For real-world accounts, these numbers will normally be their end balance at the end of the journal period; more on this below.

Accounts are sorted by declaration order if any, and then alphabetically by account name. For instance (using examples/sample.journal):

```
$ hledger -f examples/sample.journal bal
$1  assets:bank:saving
$-2  assets:cash
$1  expenses:food
$1  expenses:supplies
$-1  income:gifts
$-1  income:salary
$1  liabilities:debts
--------------------
0

```
Accounts with a zero balance (and no non-zero subaccounts, in tree mode
- see below) are hidden by default. Use -E/--empty to show them (revealing assets:bank:checking here):

```
$ hledger -f examples/sample.journal bal	-E
0  assets:bank:checking
$1  assets:bank:saving
$-2  assets:cash
$1  expenses:food
$1  expenses:supplies
$-1  income:gifts
$-1  income:salary
$1  liabilities:debts
--------------------
0

```
The total of the amounts displayed is shown as the last line, unless
-N/--no-total is used.

## Balance report line format

For single-period balance reports displayed in the terminal (only), you
can use --format FMT to customise the format and content of each line.
Eg:

```
$ hledger -f examples/sample.journal balance --format "%20(account) %12(total)"
assets	    $-1
bank:saving	     $1
cash	    $-2
expenses	     $2
food	     $1
supplies	     $1
income	    $-2
gifts	    $-1
salary	    $-1
liabilities:debts	     $1
---------------------------------
0

```
The FMT format string specifies the formatting applied to each account/balance pair. It may contain any suitable text, with data fields
interpolated like so:

%[MIN][.MAX](FIELDNAME)

• MIN pads with spaces to at least this width (optional)

• MAX truncates at this width (optional)

• FIELDNAME must be enclosed in parentheses, and can be one of:

```
• depth_spacer	 - a number of spaces equal to the account's depth, or
if MIN is specified, MIN * depth spaces.

• account - the account's name

• total - the account's balance/posted total, right justified

```
Also, FMT can begin with an optional prefix to control how multi-commodity amounts are rendered:

• %_ - render on multiple lines, bottom-aligned (the default)

• %^ - render on multiple lines, top-aligned

• %, - render on one line, comma-separated

There are some quirks. Eg in one-line mode, %(depth_spacer) has no effect, instead %(account) has indentation built in. Experimentation
may be needed to get pleasing results.

Some example formats:

• %(total) - the account's total

• %-20.20(account) - the account's name, left justified, padded to 20

```
characters and clipped at 20 characters

```
• %,%-50(account) %25(total) - account name padded to 50 characters,

```
total	padded to 20 characters, with multiple commodities rendered on
one line

```
• %20(total) %2(depth_spacer)%-(account) - the default format for the

```
single-column balance report

```

## Filtered balance report

You can show fewer accounts, a different time period, totals from
cleared transactions only, etc. by using query arguments or options to
limit the postings being matched. Eg:

```
$ hledger -f examples/sample.journal bal --cleared assets date:200806
$-2  assets:cash
--------------------
$-2

```

## List or tree mode

By default, or with -l/--flat, accounts are shown as a flat list with
their full names visible, as in the examples above.

With -t/--tree, the account hierarchy is shown, with subaccounts'
"leaf" names indented below their parent:

```
$ hledger -f examples/sample.journal balance
$-1  assets
$1    bank:saving
$-2    cash
$2  expenses
$1    food
$1    supplies
$-2  income
$-1    gifts
$-1    salary
$1  liabilities:debts
--------------------
0

```
Notes:

• "Boring" accounts are combined with their subaccount for more compact

```
output, unless --no-elide is used.  Boring accounts have  no  balance
of  their own and just one subaccount (eg assets:bank and liabilities
above).

```
• All balances shown are "inclusive", ie including the balances from

```
all  subaccounts.   Note  this	 means	some repetition in the output,
which requires explanation when sharing reports with non-plaintextaccounting-users.   A  tree mode report's final total is the sum of the
top-level balances shown, not of all the balances shown.

```
• Each group of sibling accounts (ie, under a common parent) is sorted

```
separately.

```

## Depth limiting

With a depth:NUM query, or --depth NUM option, or just -NUM (eg: -3)
balance reports will show accounts only to the specified depth, hiding
the deeper subaccounts. This can be useful for getting an overview
without too much detail.

Account balances at the depth limit always include the balances from
any deeper subaccounts (even in list mode). Eg, limiting to depth 1:

```
$ hledger -f examples/sample.journal balance -1
$-1  assets
$2  expenses
$-2  income
$1  liabilities
--------------------
0

```

## Dropping top-level accounts

You can also hide one or more top-level account name parts, using
--drop NUM. This can be useful for hiding repetitive top-level account
names:

```
$ hledger -f examples/sample.journal bal expenses --drop 1
$1  food
$1  supplies
--------------------
$2

```

## Showing declared accounts

With --declared, accounts which have been declared with an account directive will be included in the balance report, even if they have no
transactions. (Since they will have a zero balance, you will also need
-E/--empty to see them.)

More precisely, leaf declared accounts (with no subaccounts) will be
included, since those are usually the more useful in reports.

The idea of this is to be able to see a useful "complete" balance report, even when you don't have transactions in all of your declared accounts yet.

## Sorting by amount

With -S/--sort-amount, accounts with the largest (most positive) balances are shown first. Eg: hledger bal expenses -MAS shows your biggest averaged monthly expenses first. When more than one commodity is
present, they will be sorted by the alphabetically earliest commodity
first, and then by subsequent commodities (if an amount is missing a
commodity, it is treated as 0).

Revenues and liability balances are typically negative, however, so -S
shows these in reverse order. To work around this, you can add --invert to flip the signs. Or you could use one of the higher-level balance reports (bs, is..), which flip the sign automatically (eg: hledger
is -MAS).

## Percentages

With -%/--percent, balance reports show each account's value expressed
as a percentage of the (column) total.

Note it is not useful to calculate percentages if the amounts in a column have mixed signs. In this case, make a separate report for each
sign, eg:

```
$ hledger bal -% amt:`>0`
$ hledger bal -% amt:`<0`

```
Similarly, if the amounts in a column have mixed commodities, convert
them to one commodity with -B, -V, -X or --value, or make a separate
report for each commodity:

```
$ hledger bal -% cur:\\$
$ hledger bal -% cur:�

```

## Multi-period balance report

With a report interval (set by the -D/--daily, -W/--weekly,
-M/--monthly, -Q/--quarterly, -Y/--yearly, or -p/--period flag), balance shows a tabular report, with columns representing successive time
periods (and a title):

```
$ hledger -f examples/sample.journal bal --quarterly income expenses -E
Balance changes in 2008:

||  2008q1  2008q2  2008q3  2008q4
===================++=================================
expenses:food	 ||	  0	 $1	  0	  0
expenses:supplies ||	  0	 $1	  0	  0
income:gifts	 ||	  0	$-1	  0	  0
income:salary	 ||	$-1	  0	  0	  0
-------------------++---------------------------------
||	$-1	 $1	  0	  0

```
Notes:

• The report's start/end dates will be expanded, if necessary, to fully

```
encompass the displayed subperiods (so that the first and last subperiods have the same duration as the others).

```
• Leading and trailing periods (columns) containing all zeroes are not

```
shown, unless -E/--empty is used.

```
• Accounts (rows) containing all zeroes are not shown, unless

```
-E/--empty is used.

```
• Amounts with many commodities are shown in abbreviated form, unless

```
--no-elide is used.

```
• Average and/or total columns can be added with the -A/--average and

```
-T/--row-total flags.

```
• The --transpose flag can be used to exchange rows and columns.

• The --pivot FIELD option causes a different transaction field to be

```
used as "account name".  See PIVOTING.

```
• The --summary-only flag (--summary also works) hides all but the Total and Average columns (those should be enabled with --row-total and

```
-A/--average).

```
Multi-period reports with many periods can be too wide for easy viewing
in the terminal. Here are some ways to handle that:

• Hide the totals row with -N/--no-total

• Filter to a single currency with cur:

• Convert to a single currency with -V [--infer-market-price]

• Use a more compact layout like --layout=bare

• Maximize the terminal window

• Reduce the terminal's font size

• View with a pager like less, eg: hledger bal -D --color=yes | less

```
-RS

```
• Output as CSV and use a CSV viewer like visidata (hledger bal -D -O

```
csv | vd -f csv), Emacs' csv-mode  (M-x  csv-mode,  C-c  C-a),	 or  a
spreadsheet (hledger bal -D -o a.csv && open a.csv)

```
• Output as HTML and view with a browser: hledger bal -D -o a.html &&

```
open a.html

```

## Balance change, end balance

It's important to be clear on the meaning of the numbers shown in balance reports. Here is some terminology we use:

A balance change is the net amount added to, or removed from, an account during some period.

An end balance is the amount accumulated in an account as of some date
(and some time, but hledger doesn't store that; assume end of day in
your timezone). It is the sum of previous balance changes.

We call it a historical end balance if it includes all balance changes
since the account was created. For a real world account, this means it
will match the "historical record", eg the balances reported in your
bank statements or bank web UI. (If they are correct!)

In general, balance changes are what you want to see when reviewing
revenues and expenses, and historical end balances are what you want to
see when reviewing or reconciling asset, liability and equity accounts.

balance shows balance changes by default. To see accurate historical
end balances:

1. Initialise account starting balances with an "opening balances"

```
transaction  (a  transfer  from  equity  to the account), unless the
journal covers the account's full lifetime.

```
2. Include all of of the account's prior postings in the report, by not

```
specifying  a	 report	 start	date,  or by using the -H/--historical
flag.	 (-H causes report start date to be ignored when summing postings.)

```

## Balance report modes

The balance command is quite flexible; here is the full detail on how
to control what it reports. If the following seems complicated, don't
worry - this is for advanced reporting, and it does take time and experimentation to get familiar with all the report modes.

There are three important option groups:

hledger balance [CALCULATIONMODE] [ACCUMULATIONMODE] [VALUATIONMODE]
...

## Calculation mode

The basic calculation to perform for each table cell. It is one of:

• --sum : sum the posting amounts (default)

• --budget : sum the amounts, but also show the budget goal amount (for

```
each account/period)

```
• --valuechange : show the change in period-end historical balance values (caused by deposits, withdrawals, and/or market price fluctuations)

• --gain : show the unrealised capital gain/loss, (the current valued

```
balance minus each amount's original cost)

```
• --count : show the count of postings

## Accumulation mode

How amounts should accumulate across a report's subperiods/columns.
Another way to say it: which time period's postings should contribute
to each cell's calculation. It is one of:

• --change : calculate with postings from column start to column end,

```
ie "just this column".	  Typically  used  to  see  revenues/expenses.
(default for balance, cashflow, incomestatement)

```
• --cumulative : calculate with postings from report start to column

```
end, ie "previous columns plus this column".  Typically used to  show
changes accumulated since the report's start date.  Not often used.

```
• --historical/-H : calculate with postings from journal start to column end, ie "all postings from before report start date until this

```
column's  end".  Typically used to see historical end balances of assets/liabilities/equity.  (default for	 balancesheet,	balancesheetequity)

```

## Valuation mode

Which kind of value or cost conversion should be applied, if any, before displaying the report. See Cost reporting and Value reporting for
more about conversions.

A valuation (or cost) mode can be selected with the --value option:

• no conversion : don't convert to cost or value (default)

• --value=cost[,COMM] : convert amounts to cost (then optionally to

```
some other commodity)

```
• --value=then[,COMM] : convert amounts to market value on transaction

```
dates

```
• --value=end[,COMM] : convert amounts to market value on period end

```
date(s)
```
(default with --valuechange, --gain)

• --value=now[,COMM] : convert amounts to market value on today's date

• --value=YYYY-MM-DD[,COMM] : convert amounts to market value on another date

or with the legacy -B/-V/-X options, which are equivalent and easier to
type:

• -B/--cost : like --value=cost

• -V/--market : like --value=end

• -X COMM/--exchange COMM : like --value=end,COMM

Note that --value can also convert to cost, as a convenience; but actually --cost and --value are independent options, and could be used together.

## Combining balance report modes

Most combinations of these modes should produce reasonable reports, but
if you find any that seem wrong or misleading, let us know. The following restrictions are applied:

• --valuechange implies --value=end

• --valuechange makes --change the default when used with the balancesheet/balancesheetequity commands

• --cumulative or --historical disables --row-total/-T

For reference, here is what the combinations of accumulation and valuation show:

Valua‐ no valuation --value= then --value= end --value=
tion:> YYYY-MM-DD
Accumu‐ /now
lation:v
───────────────────────────────────────────────────────────────────────────────────
--change change in period sum of post‐ period-end DATE-value of

```
ing-date	market	 value of change   change in  pevalues in period	 in period	   riod
```
--cumu‐ change from re‐ sum of post‐ period-end DATE-value of
lative port start to ing-date market value of change change from

```
period end	     values  from  re‐	 from	  report   report   start
port start to pe‐	 start to period   to period end
riod end		 end
```
--his‐ change from sum of post‐ period-end DATE-value of
torical journal start to ing-date market value of change change from
/-H period end (his‐ values from jour‐ from journal journal start

```
torical end bal‐   nal start to  pe‐	 start to period   to period end
ance)		     riod end		 end

```

## Budget report

The --budget report is like a regular balance report, but with two main
differences:

• Budget goals and performance percentages are also shown, in brackets

• Accounts which don't have budget goals are hidden by default.

This is useful for comparing planned and actual income, expenses, time
usage, etc.

Periodic transaction rules are used to define budget goals. For example, here's a periodic rule defining monthly goals for bus travel and
food expenses:

```
;; Budget
~ monthly
(expenses:bus)		    $30
(expenses:food)		   $400

```
After recording some actual expenses,

```
;; Two months worth of expenses
2017-11-01
income			 $-1950
expenses:bus		    $35
expenses:food:groceries	   $310
expenses:food:dining	    $42
expenses:movies		    $38
assets:bank:checking

2017-12-01
income			 $-2100
expenses:bus		    $53
expenses:food:groceries	   $380
expenses:food:dining	    $32
expenses:gifts		   $100
assets:bank:checking

```
we can see a budget report like this:

```
$ hledger bal -M --budget
Budget performance in 2017-11-01..2017-12-31:

||			 Nov		       Dec
===============++============================================
<unbudgeted>  || $-425		      $-565
expenses	     ||	 $425 [ 99% of $430]   $565 [131% of $430]
expenses:bus  ||	  $35 [117% of	$30]	$53 [177% of  $30]
expenses:food ||	 $352 [ 88% of $400]   $412 [103% of $400]
---------------++--------------------------------------------
||	    0 [	 0% of $430]	  0 [  0% of $430]

```
This is "goal-based budgeting"; you define goals for accounts and periods, often recurring, and hledger shows performance relative to the
goals. This contrasts with "envelope budgeting", which is more detailed and strict - useful when cash is tight, but also quite a bit
more work. https://plaintextaccounting.org/Budgeting has more on this
topic.

## Using the budget report

Historically this report has been confusing and fragile. hledger's
version should be relatively robust and intuitive, but you may still
find surprises. Here are more notes to help with learning and troubleshooting.

• In the above example, expenses:bus and expenses:food are shown because they have budget goals during the report period.

• Their parent expenses is also shown, with budget goals aggregated

```
from the children.

```
• The subaccounts expenses:food:groceries and expenses:food:dining are

```
not  shown since they have no budget goal of their own, but they contribute to expenses:food's actual amount.

```
• Unbudgeted accounts expenses:movies and expenses:gifts are also not

```
shown, but they contribute to expenses's actual amount.

```
• The other unbudgeted accounts income and assets:bank:checking are

```
grouped as <unbudgeted>.

```
• --depth or depth: can be used to limit report depth in the usual way

```
(but will not reveal unbudgeted subaccounts).

```
• Amounts are always inclusive of subaccounts (even in -l/--list mode).

• Numbers displayed in a --budget report will not always agree with the

```
totals, because  of  hidden  unbudgeted  accounts;  this  is  normal.
-E/--empty can be used to reveal the hidden accounts.

```
• In the periodic rules used for setting budget goals, unbalanced postings are convenient.

• You can filter budget reports with the usual queries, eg to focus on

```
particular  accounts.	It's common to restrict them to just expenses.
(The <unbudgeted> account is occasionally hard to  exclude;  this  is
because of date surprises, discussed below.)

```
• When you have multiple currencies, you may want to convert them to

```
one (-X COMM --infer-market-prices) and/or show just one  at  a  time
(cur:COMM).   If  you	do  need  to show multiple currencies at once,
--layout bare can be helpful.

```
• You can "roll over" amounts (actual and budgeted) to the next period

```
with --cumulative.

```
See also: https://hledger.org/budgeting.html.

## Budget date surprises

With small data, or when starting out, some of the generated budget
goal transaction dates might fall outside the report periods. Eg with
the following journal and report, the first period appears to have no
expenses:food budget. (Also the <unbudgeted> account should be excluded by the expenses query, but isn't.):

```
~ monthly in 2020
(expenses:food)	 $500

2020-01-15
expenses:food	 $400
assets:checking

$ hledger bal --budget expenses
Budget performance in 2020-01-15:

||		2020-01-15
===============++====================
<unbudgeted>  || $400
expenses:food ||	   0 [ 0% of $500]
---------------++--------------------
|| $400 [80% of $500]

```
In this case, the budget goal transactions are generated on first days
of of month (this can be seen with hledger print --forecast tag:generated expenses). Whereas the report period defaults to just the 15th
day of january (this can be seen from the report table's column headings).

To fix this kind of thing, be more explicit about the report period
(and/or the periodic rules' dates). In this case, adding -b 2020 does
the trick.

## Selecting budget goals

By default, the budget report uses all available periodic transaction
rules to generate goals. This includes rules with a different report
interval from your report. Eg if you have daily, weekly and monthly
periodic rules, all of these will contribute to the goals in a monthly
budget report.

You can select a subset of periodic rules by providing an argument to
the --budget flag. --budget=DESCPAT will match all periodic rules
whose description contains DESCPAT, a case-insensitive substring (not a
regular expression or query). This means you can give your periodic
rules descriptions (remember that two spaces are needed between period
expression and description), and then select from multiple budgets defined in your journal.

## Budgeting vs forecasting

--forecast and --budget both use the periodic transaction rules in the
journal to generate temporary transactions for reporting purposes.
However they are separate features - though you can use both at the
same time if you want. Here are some differences between them:

--forecast --budget
──────────────────────────────────────────────────────────────────────────
is a general option; it enables fore‐ is a balance command option; it
casting with all reports selects the balance report's

```
budget mode
```
generates visible transactions which generates invisible transactions
appear in reports which produce goal amounts
generates forecast transactions from generates budget goal transacafter the last regular transaction, to tions throughout the report pethe end of the report period; or with riod, optionally restricted by
an argument --forecast=PERIODEXPR gen‐ periods specified in the perierates them throughout the specified odic transaction rules
period, both optionally restricted by
periods specified in the periodic
transaction rules
uses all periodic rules uses all periodic rules; or with

```
an   argument	--budget=DESCPAT
uses just the rules  matched  by
DESCPAT

```

## Balance report layout

The --layout option affects how balance and the other balance-like commands show multi-commodity amounts and commodity symbols. It can improve readability, for humans and/or machines (other software). It has
four possible values:

• --layout=wide[,WIDTH]: commodities are shown on a single line, optionally elided to WIDTH

• --layout=tall: each commodity is shown on a separate line

• --layout=bare: commodity symbols are in their own column, amounts are

```
bare numbers

```
• --layout=tidy: data is normalised to easily-consumed "tidy" form,

```
with  one  row per data value.	 (This one is currently supported only
by the balance command.)

```
Here are the --layout modes supported by each output format Only CSV
output supports all of them:

- txt csv html json sql
─────────────────────────────────────
wide Y Y Y
tall Y Y Y
bare Y Y Y
tidy Y

Examples:

## Wide layout

With many commodities, reports can be very wide:

```
$ hledger -f examples/bcexample.hledger bal assets:us:etrade -3 -T -Y --layout=wide
Balance changes in 2012-01-01..2014-12-31:

||					    2012						     2013					      2014							Total
==================++====================================================================================================================================================================================================================
Assets:US:ETrade || 10.00 ITOT, 337.18 USD, 12.00 VEA, 106.00 VHT  70.00 GLD, 18.00 ITOT, -98.12 USD, 10.00 VEA, 18.00 VHT  -11.00 ITOT, 4881.44 USD, 14.00 VEA, 170.00 VHT  70.00 GLD, 17.00 ITOT, 5120.50 USD, 36.00 VEA, 294.00 VHT
------------------++--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
|| 10.00 ITOT, 337.18 USD, 12.00 VEA, 106.00 VHT  70.00 GLD, 18.00 ITOT, -98.12 USD, 10.00 VEA, 18.00 VHT  -11.00 ITOT, 4881.44 USD, 14.00 VEA, 170.00 VHT  70.00 GLD, 17.00 ITOT, 5120.50 USD, 36.00 VEA, 294.00 VHT

```
A width limit reduces the width, but some commodities will be hidden:

```
$ hledger -f examples/bcexample.hledger bal assets:us:etrade -3 -T -Y --layout=wide,32
Balance changes in 2012-01-01..2014-12-31:

||			       2012				2013		       2014			       Total
==================++===========================================================================================================================
Assets:US:ETrade || 10.00 ITOT, 337.18 USD, 2 more..  70.00 GLD, 18.00 ITOT, 3 more..  -11.00 ITOT, 3 more..  70.00 GLD, 17.00 ITOT, 3 more..
------------------++---------------------------------------------------------------------------------------------------------------------------
|| 10.00 ITOT, 337.18 USD, 2 more..  70.00 GLD, 18.00 ITOT, 3 more..  -11.00 ITOT, 3 more..  70.00 GLD, 17.00 ITOT, 3 more..

```

## Tall layout

Each commodity gets a new line (may be different in each column), and
account names are repeated:

```
$ hledger -f examples/bcexample.hledger bal assets:us:etrade -3 -T -Y --layout=tall
Balance changes in 2012-01-01..2014-12-31:

||	 2012	     2013	  2014	      Total
==================++==================================================
Assets:US:ETrade || 10.00 ITOT	70.00 GLD  -11.00 ITOT	  70.00 GLD
Assets:US:ETrade || 337.18 USD  18.00 ITOT  4881.44 USD	 17.00 ITOT
Assets:US:ETrade ||  12.00 VEA  -98.12 USD    14.00 VEA	5120.50 USD
Assets:US:ETrade || 106.00 VHT	10.00 VEA   170.00 VHT	  36.00 VEA
Assets:US:ETrade ||		18.00 VHT		 294.00 VHT
------------------++--------------------------------------------------
|| 10.00 ITOT	70.00 GLD  -11.00 ITOT	  70.00 GLD
|| 337.18 USD  18.00 ITOT  4881.44 USD	 17.00 ITOT
||  12.00 VEA  -98.12 USD    14.00 VEA	5120.50 USD
|| 106.00 VHT	10.00 VEA   170.00 VHT	  36.00 VEA
||		18.00 VHT		 294.00 VHT

```

## Bare layout

Commodity symbols are kept in one column, each commodity has its own
row, amounts are bare numbers, account names are repeated:

```
$ hledger -f examples/bcexample.hledger bal assets:us:etrade -3 -T -Y --layout=bare
Balance changes in 2012-01-01..2014-12-31:

|| Commodity	2012	2013	 2014	 Total
==================++=============================================
Assets:US:ETrade || GLD		   0   70.00	    0	 70.00
Assets:US:ETrade || ITOT	       10.00   18.00   -11.00	 17.00
Assets:US:ETrade || USD	      337.18  -98.12  4881.44  5120.50
Assets:US:ETrade || VEA	       12.00   10.00	14.00	 36.00
Assets:US:ETrade || VHT	      106.00   18.00   170.00	294.00
------------------++---------------------------------------------
|| GLD		   0   70.00	    0	 70.00
|| ITOT	       10.00   18.00   -11.00	 17.00
|| USD	      337.18  -98.12  4881.44  5120.50
|| VEA	       12.00   10.00	14.00	 36.00
|| VHT	      106.00   18.00   170.00	294.00

```
Bare layout also affects CSV output, which is useful for producing data
that is easier to consume, eg for making charts:

```
$ hledger -f examples/bcexample.hledger bal assets:us:etrade -3 -O csv --layout=bare
"account","commodity","balance"
"Assets:US:ETrade","GLD","70.00"
"Assets:US:ETrade","ITOT","17.00"
"Assets:US:ETrade","USD","5120.50"
"Assets:US:ETrade","VEA","36.00"
"Assets:US:ETrade","VHT","294.00"
"Total:","GLD","70.00"
"Total:","ITOT","17.00"
"Total:","USD","5120.50"
"Total:","VEA","36.00"
"Total:","VHT","294.00"

```
Bare layout will sometimes display an extra row for the no-symbol commodity, because of zero amounts (hledger treats zeroes as commodity-less, usually). This can break hledger-bar confusingly (workaround: add a cur: query to exclude the no-symbol row).

## Tidy layout

This produces normalised "tidy data" (see
https://cran.r-project.org/web/packages/tidyr/vignettes/tidy-data.html)
where every variable has its own column and each row represents a single data point. This is the easiest kind of data for other software to
consume:

```
$ hledger -f examples/bcexample.hledger bal assets:us:etrade -3 -Y -O csv --layout=tidy
"account","period","start_date","end_date","commodity","value"
"Assets:US:ETrade","2012","2012-01-01","2012-12-31","GLD","0"
"Assets:US:ETrade","2012","2012-01-01","2012-12-31","ITOT","10.00"
"Assets:US:ETrade","2012","2012-01-01","2012-12-31","USD","337.18"
"Assets:US:ETrade","2012","2012-01-01","2012-12-31","VEA","12.00"
"Assets:US:ETrade","2012","2012-01-01","2012-12-31","VHT","106.00"
"Assets:US:ETrade","2013","2013-01-01","2013-12-31","GLD","70.00"
"Assets:US:ETrade","2013","2013-01-01","2013-12-31","ITOT","18.00"
"Assets:US:ETrade","2013","2013-01-01","2013-12-31","USD","-98.12"
"Assets:US:ETrade","2013","2013-01-01","2013-12-31","VEA","10.00"
"Assets:US:ETrade","2013","2013-01-01","2013-12-31","VHT","18.00"
"Assets:US:ETrade","2014","2014-01-01","2014-12-31","GLD","0"
"Assets:US:ETrade","2014","2014-01-01","2014-12-31","ITOT","-11.00"
"Assets:US:ETrade","2014","2014-01-01","2014-12-31","USD","4881.44"
"Assets:US:ETrade","2014","2014-01-01","2014-12-31","VEA","14.00"
"Assets:US:ETrade","2014","2014-01-01","2014-12-31","VHT","170.00"

```

## Balance report output

As noted in Output format, if you choose HTML output (by using -O html
or -o somefile.html), you can create a hledger.css file in the same directory to customise the report's appearance.

The HTML and FODS output formats can generate hyperlinks to a
hledger-web register view for each account and period. E.g. if your
hledger-web server is reachable at http://localhost:5000 then you might
run the balance command with the extra option --base-url=http://localhost:5000. You can also produce relative links, like
--base-url="some/path" or --base-url="".)

## Some useful balance reports

Some frequently used balance options/reports are:

• bal -M revenues expenses
Show revenues/expenses in each month. Also available as the incomestatement command.

• bal -M -H assets liabilities
Show historical asset/liability balances at each month end. Also
available as the balancesheet command.

• bal -M -H assets liabilities equity
Show historical asset/liability/equity balances at each month end.
Also available as the balancesheetequity command.

• bal -M assets not:receivable
Show changes to liquid assets in each month. Also available as the
cashflow command.

Also:

• bal -M expenses -2 -SA
Show monthly expenses summarised to depth 2 and sorted by average
amount.

• bal -M --budget expenses
Show monthly expenses and budget goals.

• bal -M --valuechange investments
Show monthly change in market value of investment assets.

• bal investments --valuechange -D date:lastweek amt:'>1000' -STA

```
[--invert]
```
Show top gainers [or losers] last week

roi
Shows the time-weighted (TWR) and money-weighted (IRR) rate of return
on your investments.

```
Flags:
--cashflow		      show all amounts that were used to compute
returns
--investment=QUERY	      query to select your investment transactions
--profit-loss=QUERY --pnl  query to select profit-and-loss or
appreciation/valuation transactions

```
At a minimum, you need to supply a query (which could be just an account name) to select your investment(s) with --inv, and another query
to identify your profit and loss transactions with --pnl.

If you do not record changes in the value of your investment manually,
or do not require computation of time-weighted return (TWR), --pnl
could be an empty query (--pnl "" or --pnl STR where STR does not match
any of your accounts).

This command will compute and display the internalized rate of return
(IRR, also known as money-weighted rate of return) and time-weighted
rate of return (TWR) for your investments for the time period requested. IRR is always annualized due to the way it is computed, but
TWR is reported both as a rate over the chosen reporting period and as
an annual rate.

Price directives will be taken into account if you supply appropriate
--cost or --value flags (see VALUATION).

Note, in some cases this report can fail, for these reasons:

• Error (NotBracketed): No solution for Internal Rate of Return (IRR).

```
Possible  causes:  IRR is huge (>1000000%), balance of investment becomes negative at some point in time.

```
• Error (SearchFailed): Failed to find solution for Internal Rate of

```
Return (IRR).	Either search does not converge to a solution, or converges too slowly.

```
Examples:

• Using roi to compute total return of investment in stocks:

```
https://github.com/simonmichael/hledger/blob/master/examples/investing/roi-unrealised.ledger

```
• Cookbook > Return on Investment: https://hledger.org/roi.html

## Spaces and special characters in --inv and --pnl

Note that --inv and --pnl's argument is a query, and queries could have
several space-separated terms (see QUERIES).

To indicate that all search terms form single command-line argument,
you will need to put them in quotes (see Special characters):

```
$ hledger roi --inv 'term1 term2 term3 ...'

```
If any query terms contain spaces themselves, you will need an extra
level of nested quoting, eg:

```
$ hledger roi --inv="'Assets:Test 1'" --pnl="'Equity:Unrealized Profit and Loss'"

```

## Semantics of --inv and --pnl

Query supplied to --inv has to match all transactions that are related
to your investment. Transactions not matching --inv will be ignored.

In these transactions, ROI will conside postings that match --inv to be
"investment postings" and other postings (not matching --inv) will be
sorted into two categories: "cash flow" and "profit and loss", as ROI
needs to know which part of the investment value is your contributions
and which is due to the return on investment.

• "Cash flow" is depositing or withdrawing money, buying or selling assets, or otherwise converting between your investment commodity and

```
any other commodity.  Example:

2019-01-01 Investing in Snake Oil
assets:cash	       -$100
investment:snake oil

2020-01-01 Selling my Snake Oil
assets:cash		$10
investment:snake oil	= 0

```
• "Profit and loss" is change in the value of your investment:

```
2019-06-01 Snake Oil falls in value
investment:snake oil	= $57
equity:unrealized profit or loss

```
All non-investment postings are assumed to be "cash flow", unless they
match --pnl query. Changes in value of your investment due to "profit
and loss" postings will be considered as part of your investment return.

Example: if you use --inv snake --pnl equity:unrealized, then postings
in the example below would be classifed as:

```
2019-01-01 Snake Oil #1
assets:cash	     -$100   ; cash flow posting
investment:snake oil	     ; investment posting

2019-03-01 Snake Oil #2
equity:unrealized pnl  -$100 ; profit and loss posting
snake oil		     ; investment posting

2019-07-01 Snake Oil #3
equity:unrealized pnl	     ; profit and loss posting
cash	      -$100	     ; cash flow posting
snake oil     $50	     ; investment posting

```

## IRR and TWR explained

"ROI" stands for "return on investment". Traditionally this was computed as a difference between current value of investment and its initial value, expressed in percentage of the initial value.

However, this approach is only practical in simple cases, where investments receives no in-flows or out-flows of money, and where rate of
growth is fixed over time. For more complex scenarios you need different ways to compute rate of return, and this command implements two of
them: IRR and TWR.

Internal rate of return, or "IRR" (also called "money-weighted rate of
return") takes into account effects of in-flows and out-flows, and the
time between them. Investment at a particular fixed interest rate is
going to give you more interest than the same amount invested at the
same interest rate, but made later in time. If you are withdrawing
from your investment, your future gains would be smaller (in absolute
numbers), and will be a smaller percentage of your initial investment,
so your IRR will be smaller. And if you are adding to your investment,
you will receive bigger absolute gains, which will be a bigger percentage of your initial investment, so your IRR will be larger.

As mentioned before, in-flows and out-flows would be any cash that you
personally put in or withdraw, and for the "roi" command, these are the
postings that match the query in the--inv argument and NOT match the
query in the--pnl argument.

If you manually record changes in the value of your investment as
transactions that balance them against "profit and loss" (or "unrealized gains") account or use price directives, then in order for IRR to
compute the precise effect of your in-flows and out-flows on the rate
of return, you will need to record the value of your investement on or
close to the days when in- or out-flows occur.

In technical terms, IRR uses the same approach as computation of net
present value, and tries to find a discount rate that makes net present
value of all the cash flows of your investment to add up to zero. This
could be hard to wrap your head around, especially if you haven't done
discounted cash flow analysis before. Implementation of IRR in hledger
should produce results that match the =XIRR formula in Excel.

Second way to compute rate of return that roi command implements is
called "time-weighted rate of return" or "TWR". Like IRR, it will account for the effect of your in-flows and out-flows, but unlike IRR it
will try to compute the true rate of return of the underlying asset,
compensating for the effect that deposits and withdrawas have on the
apparent rate of growth of your investment.

TWR represents your investment as an imaginary "unit fund" where
in-flows/ out-flows lead to buying or selling "units" of your investment and changes in its value change the value of "investment unit".
Change in "unit price" over the reporting period gives you rate of return of your investment, and make TWR less sensitive than IRR to the
effects of cash in-flows and out-flows.

References:

• Explanation of rate of return

• Explanation of IRR

• Explanation of TWR

• IRR vs TWR

• Examples of computing IRR and TWR and discussion of the limitations

```
of both metrics

```
Chart commands
activity
Show an ascii barchart of posting counts per interval.

```
Flags:
no command-specific flags

```
The activity command displays an ascii histogram showing transaction
counts by day, week, month or other reporting interval (by day is the
default). With query arguments, it counts only matched transactions.

Examples:

```
$ hledger activity --quarterly
2008-01-01 **
2008-04-01 *******
2008-07-01
2008-10-01 **

```
Data generation commands
close
(equity)

close prints several kinds of "closing" and/or "opening" transactions,
useful in various situations: migrating balances to a new journal file,
retaining earnings into equity, consolidating balances, viewing lot
costs.. Like print, it prints valid journal entries. You can copy
these into your journal file(s) when you are happy with how they look.

```
Flags:
--clopen[=TAGVAL]	  show closing and opening balances transactions,
for AL accounts by default
--close[=TAGVAL]	  show just a closing balances transaction
--open[=TAGVAL]	  show just an opening balances transaction
--assert[=TAGVAL]	  show a balance assertions transaction
--assign[=TAGVAL]	  show a balance assignments transaction
--retain[=TAGVAL]	  show a retain earnings transaction, for RX
accounts by default
-x --explicit		  show all amounts explicitly
--show-costs		  show amounts with different costs separately
--interleaved	  show source and destination postings together
--assertion-type=TYPE  =, ==, =* or ==*
--close-desc=DESC	  set closing transaction's description
--close-acct=ACCT	  set closing transaction's destination account
--open-desc=DESC	  set opening transaction's description
--open-acct=ACCT	  set opening transaction's source account
--round=TYPE		  how much rounding or padding should be done when
displaying amounts ?
none - show original decimal digits,
as in journal (default)
soft - just add or remove decimal zeros
to match precision
hard - round posting amounts to precision
(can unbalance transactions)
all  - also round cost amounts to precision
(can unbalance transactions)

```
close has six modes, selected by choosing one of the mode flags:
--clopen, --close (default), --open, --assert, --assign, or --retain.
They are all doing the same kind of operation, but with different defaults for different situations.

The journal entries generated by close will have a clopen: tag, which
is helpful when you want to exclude them from reports. If the main
journal file name contains a number, the tag's value will be that base
file name with the number incremented. Eg if the journal file is
2025.journal, the tag will be clopen:2026. Or you can set the tag
value by providing an argument to the mode flag. Eg --close=foo or
--clopen=2025-main.

close --clopen
This is useful if migrating balances to a new journal file at the start
of a new year. It prints a "closing balances" transaction that zeroes
out account balances (Asset and Liability accounts, by default), and an
opposite "opening balances" transaction that restores them again. Typically, you would run

```
hledger close --clopen -e NEWYEAR >> $LEDGER_FILE

```
and then move the opening transaction from the old file to the new file
(and probably also update your LEDGER_FILE environment variable).

Why might you do this ? If your reports are fast, you may not need it.
But at some point you will probably want to partition your data by
time, for performance or data integrity or regulatory reasons. A new
file or set of files per year is common. Then, having each file/fileset "bookended" with opening and closing balance transactions will allow you to freely pick and choose which files to read - just the current year, any past year, any sequence of years, or all of them - while
showing correct account balances in each case. The earliest opening
balances transaction sets correct starting balances, and any later
closing/opening pairs will harmlessly cancel each other out.

The balances will be transferred to and from equity:opening/closing
balances by default. You can override this by using --close-acct
and/or --open-acct.

You can select a different set of accounts to close/open by providing
an account query. Eg to add Equity accounts, provide arguments like
assets liabilities equity or type:ALE. When migrating to a new file,
you'll usually want to bring along the AL or ALE accounts, but not the
RX accounts (Revenue, Expense).

Assertions will be added indicating and checking the new balances of
the closed/opened accounts.

close --close
This prints just the closing balances transaction of --clopen. It is
the default if you don't specify a mode.

More customisation options are described below. Among other things,
you can use close --close to generate a transaction moving the balances
from any set of accounts, to a different account. (If you need to move
just a portion of the balance, see hledger-move.)

close --open
This prints just the opening balances transaction of --clopen. (It is
similar to Ledger's equity command.)

close --assert
This prints a transaction that asserts the account balances as they are
on the end date (and adds an assert: tag). It could be useful as documention and to guard against changes.

close --assign
This prints a transaction that assigns the account balances as they are
on the end date (and adds an "assign:" tag). Unlike balance assertions, assignments will post changes to balances as needed to reach the
specified amounts.

This is another way to set starting balances when migrating to a new
file, and it will set them correctly even in the presence of earlier
files which do not have a closing balances transaction. However, it
can hide errors, and disturb the accounting equation, so --clopen is
usually recommended.

close --retain
This is like --close, but it closes Revenue and Expense account balances by default. They will be transferred to equity:retained earnings, or another account specified with --close-acct.

Revenues and expenses correspond to changes in equity. They are categorised separately for reporting purposes, but traditionally at the end
of each accounting period, businesses consolidate them into equity,
This is called "retaining earnings", or "closing the books".

In personal accounting, there's not much reason to do this, and most
people don't. (One reason to do it is to help the balancesheetequity
report show a zero total, demonstrating that the accounting equation
(A-L=E) is satisfied.)

close customisation
In all modes, the following things can be overridden:

• the accounts to be closed/opened, with account query arguments

• the closing/opening dates, with -e OPENDATE

• the balancing account, with --close-acct=ACCT and/or --open-acct=ACCT

• the transaction descriptions, with --close-desc=DESC and

```
--open-desc=DESC

```
• the transactions' clopen tag value, with a TAGVAL argument for the

```
mode flag (see above).

```
By default, the closing date is yesterday, or the journal's end date,
whichever is later; and the opening date is always one day after the
closing date. You can change these by specifying a report end date;
the closing date will be the last day of the report period. Eg -e 2024
means "close on 2023-12-31, open on 2024-01-01".

With --x/--explicit, the balancing amount will be shown explicitly, and
if it involves multiple commodities, a separate posting will be generated for each of them (similar to print -x).

With --interleaved, each individual transfer is shown with source and
destination postings next to each other (perhaps useful for troubleshooting).

With --show-costs, balances' costs are also shown, with different costs
kept separate. This may generate very large journal entries, if you
have many currency conversions or investment transactions. close
--show-costs is currently the best way to view investment lots with
hledger. (To move or dispose of lots, see the more capable
hledger-move script.)

close and balance assertions
close adds balance assertions verifying that the accounts have been reset to zero in a closing transaction or restored to their previous balances in an opening transaction. These provide useful error checking,
but you can ignore them temporarily with -I, or remove them if you prefer.

Single-commodity, subaccount-exclusive balance assertions (=) are generated by default. This can be changed with --assertion-type='==*'
(eg).

When running close you should probably avoid using -C, -R, status:
(filtering by status or realness) or --auto (generating postings),
since the generated balance assertions would then require these.

Transactions with multiple dates (eg posting dates) spanning the file
boundary also can disrupt the balance assertions:

```
2023-12-30 a purchase made in december, cleared in january
expenses:food		 5
assets:bank:checking	-5  ; date: 2023-01-02

```
To solve this you can transfer the money to and from a temporary account, splitting the multi-day transaction into two single-day transactions:

```
; in 2022.journal:
2022-12-30 a purchase made in december, cleared in january
expenses:food		 5
equity:pending	-5

; in 2023.journal:
2023-01-02 last year's transaction cleared
equity:pending	 5 = 0
assets:bank:checking	-5

```
close examples

## Retain earnings

Record 2022's revenues/expenses as retained earnings on 2022-12-31, appending the generated transaction to the journal:

```
$ hledger close --retain -f 2022.journal -p 2022 >> 2022.journal

```
After this, to see 2022's revenues and expenses you must exclude the
retain earnings transaction:

```
$ hledger -f 2022.journal is not:desc:'retain earnings'

```

## Migrate balances to a new file

Close assets/liabilities on 2022-12-31 and re-open them on 2023-01-01:

```
$ hledger close --clopen -f 2022.journal -p 2022
# copy/paste the closing transaction to the end of 2022.journal
# copy/paste the opening transaction to the start of 2023.journal

```
After this, to see 2022's end-of-year balances you must exclude the
closing balances transaction:

```
$ hledger -f 2022.journal bs not:desc:'closing balances'

```
For more flexibility, it helps to tag closing and opening transactions
with eg clopen:NEWYEAR, then you can ensure correct balances by excluding all opening/closing transactions except the first, like so:

```
$ hledger bs -Y -f 2021.j -f 2022.j -f 2023.j expr:'tag:clopen=2021 or not tag:clopen'
$ hledger bs -Y -f 2021.j -f 2022.j	    expr:'tag:clopen=2021 or not tag:clopen'
$ hledger bs -Y -f 2022.j -f 2023.j	    expr:'tag:clopen=2022 or not tag:clopen'
$ hledger bs -Y -f 2021.j			    expr:'tag:clopen=2021 or not tag:clopen'
$ hledger bs -Y -f 2022.j			    expr:'tag:clopen=2022 or not tag:clopen'
$ hledger bs -Y -f 2023.j			    # unclosed file, no query needed

```

## More detailed close examples

See examples/multi-year.

rewrite
Print all transactions, rewriting the postings of matched transactions.
For now the only rewrite available is adding new postings, like print
--auto.

```
Flags:
--add-posting='ACCT	AMTEXPR'  add a posting to ACCT, which may be
parenthesised. AMTEXPR is either a literal
amount, or *N which means the transaction's
first matched amount multiplied by N (a
decimal number). Two spaces separate ACCT
and AMTEXPR.
--diff			  generate diff suitable as an input for
patch tool

```
This is a start at a generic rewriter of transaction entries. It reads
the default journal and prints the transactions, like print, but adds
one or more specified postings to any transactions matching QUERY. The
posting amounts can be fixed, or a multiplier of the existing transaction's first posting amount.

Examples:

```
$ hledger-rewrite.hs ^income --add-posting '(liabilities:tax)  *.33  ; income tax' --add-posting '(reserve:gifts)	 $100'
$ hledger-rewrite.hs expenses:gifts --add-posting '(reserve:gifts)  *-1"'
$ hledger-rewrite.hs -f rewrites.hledger

```
rewrites.hledger may consist of entries like:

```
= ^income amt:<0 date:2017
(liabilities:tax)  *0.33  ; tax on income
(reserve:grocery)  *0.25  ; reserve 25% for grocery
(reserve:)  *0.25  ; reserve 25% for grocery

```
Note the single quotes to protect the dollar sign from bash, and the
two spaces between account and amount.

More:

```
$ hledger rewrite [QUERY]	       --add-posting "ACCT  AMTEXPR" ...
$ hledger rewrite ^income	       --add-posting '(liabilities:tax)	 *.33'
$ hledger rewrite expenses:gifts --add-posting '(budget:gifts)  *-1"'
$ hledger rewrite ^income	       --add-posting '(budget:foreign currency)	 *0.25 JPY; diversify'

```
Argument for --add-posting option is a usual posting of transaction
with an exception for amount specification. More precisely, you can
use '*' (star symbol) before the amount to indicate that that this is a
factor for an amount of original matched posting. If the amount includes a commodity name, the new posting amount will be in the new commodity; otherwise, it will be in the matched posting amount's commodity.

## Re-write rules in a file

During the run this tool will execute so called "Automated Transactions" found in any journal it process. I.e instead of specifying this
operations in command line you can put them in a journal file.

```
$ rewrite-rules.journal

```
Make contents look like this:

```
= ^income
(liabilities:tax)  *.33

= expenses:gifts
budget:gifts	*-1
assets:budget	 *1

```
Note that '=' (equality symbol) that is used instead of date in transactions you usually write. It indicates the query by which you want to
match the posting to add new ones.

```
$ hledger rewrite -f input.journal -f rewrite-rules.journal > rewritten-tidy-output.journal

```
This is something similar to the commands pipeline:

```
$ hledger rewrite -f input.journal '^income' --add-posting '(liabilities:tax)  *.33' \
| hledger rewrite -f - expenses:gifts	   --add-posting 'budget:gifts	*-1'	   \
--add-posting 'assets:budget  *1'	      \
> rewritten-tidy-output.journal

```
It is important to understand that relative order of such entries in
journal is important. You can re-use result of previously added postings.

## Diff output format

To use this tool for batch modification of your journal files you may
find useful output in form of unified diff.

```
$ hledger rewrite --diff -f examples/sample.journal '^income' --add-posting '(liabilities:tax)  *.33'

```
Output might look like:

```
--- /tmp/examples/sample.journal
+++ /tmp/examples/sample.journal
@@ -18,3 +18,4 @@
2008/01/01 income
-	   assets:bank:checking	 $1
+	   assets:bank:checking		   $1
income:salary
+	   (liabilities:tax)		    0
@@ -22,3 +23,4 @@
2008/06/01 gift
-	   assets:bank:checking	 $1
+	   assets:bank:checking		   $1
income:gifts
+	   (liabilities:tax)		    0

```
If you'll pass this through patch tool you'll get transactions containing the posting that matches your query be updated. Note that multiple
files might be update according to list of input files specified via
--file options and include directives inside of these files.

Be careful. Whole transaction being re-formatted in a style of output
from hledger print.

See also:

https://github.com/simonmichael/hledger/issues/99

rewrite vs. print --auto
This command predates print --auto, and currently does much the same
thing, but with these differences:

• with multiple files, rewrite lets rules in any file affect all other

```
files.	 print --auto uses standard directive  scoping;	 rules	affect
only child files.

```
• rewrite's query limits which transactions can be rewritten; all are

```
printed.  print --auto's query limits which transactions are printed.

```
• rewrite applies rules specified on command line or in the journal.

```
print --auto applies rules specified in the journal.

```
Maintenance commands
check
Check for various kinds of errors in your data.

```
Flags:
no command-specific flags

```
hledger provides a number of built-in correctness checks to help validate your data and prevent errors. Some are run automatically, some
when you enable --strict mode; or you can run any of them on demand by
providing them as arguments to the check command. check produces no
output and a zero exit code if all is well. Eg:

```
hledger check			 # run basic checks
hledger check -s			 # run basic and strict checks
hledger check ordereddates payees	 # run basic checks and two others

```
If you are an Emacs user, you can also configure flycheck-hledger to
run these checks, providing instant feedback as you edit the journal.

Here are the checks currently available. They are generally checked in
the order they are shown here, and only the first failure will be reported.

## Basic checks

These important checks are performed by default, by almost all hledger
commands:

• parseable - data files are in a supported format, with no syntax errors and no invalid include directives. This ensures that all files

```
exist and are readable.

```
• autobalanced - all transactions are balanced, after automatically inferring missing amounts and conversion rates and then converting

```
amounts  to cost.  This ensures that each transaction's journal entry
is well formed.

```
• assertions - all balance assertions in the journal are passing. Balance assertions are a strong defense against errors, catching many

```
problems.  This check is on by default, but if it gets in  your  way,
you  can  disable it temporarily with -I/--ignore-assertions, or as a
default  by  adding  that  flag  to  your  config  file.   (Then  use
-s/--strict or hledger check assertions when you want to enable it).

```

## Strict checks

When the -s/--strict flag is used (AKA strict mode), all commands will
perform the following additional checks (and assertions, above). These
provide extra error-catching power to help you keep your data clean and
correct:

• balanced - like autobalanced, but implicit conversions between commodities are not allowed; all conversion transactions must use cost

```
notation or equity postings.  This prevents wrong conversions	caused
by typos.

```
• commodities - all commodity symbols used must be declared. This

```
guards against mistyping or omitting commodity symbols.

```
• accounts - all account names used must be declared. This prevents

```
the use of mis-spelled or outdated account names.

```

## Other checks

These are not wanted by everyone, but can be run using the check command:

• tags - all tags used must be declared. This prevents mis-spelled tag

```
names.	 Note hledger fairly often finds unintended tags in comments.

```
• payees - all payees used in transactions must be declared. This will

```
force you to declare any new payee name before using it.  Most people
will probably find this a bit too strict.

```
• ordereddates - within each file, transactions must be ordered by

```
date.	This is a simple and effective error catcher.	It's  not  included in strict mode, but you can add it by running hledger check -s
ordereddates.	If enabled, this check is performed before balance assertions.

```
• recentassertions - all accounts with balance assertions must have one

```
that's within the 7 days before their latest posting.	This will  encourage adding balance assertions for your active asset/liability accounts, which in turn should encourage	 you  to  reconcile  regularly
with  those  real world balances - another strong defense against errors.	(hledger close --assert >>$LEDGER_FILE is a convenient way  to
add  new balance assertions.  Later these become quite redundant, and
you might choose to remove them to reduce clutter.)

```
• uniqueleafnames - no two accounts may have the same last account name

```
part  (eg  the	 checking in assets:bank:checking).  This ensures each
account can be matched by a unique short name, easier to remember and
to type.

```

## Custom checks

You can build your own custom checks with add-on command scripts. See
also Cookbook > Scripting. Here are some examples from hledger/bin/:

• hledger-check-tagfiles - all tag values containing / exist as file

```
paths

```
• hledger-check-fancyassertions - more complex balance assertions are

```
passing

```
diff
Compares a particular account's transactions in two input files. It
shows any transactions to this account which are in one file but not in
the other.

```
Flags:
no command-specific flags

```
More precisely: for each posting affecting this account in either file,
this command looks for a corresponding posting in the other file which
posts the same amount to the same account (ignoring date, description,
etc).

Since it compares postings, not transactions, this also works when multiple bank transactions have been combined into a single journal entry.

This command is useful eg if you have downloaded an account's transactions from your bank (eg as CSV data): when hledger and your bank disagree about the account balance, you can compare the bank data with
your journal to find out the cause.

Examples:

```
$ hledger diff -f $LEDGER_FILE -f bank.csv assets:bank:giro
These transactions are in the first file only:

2014/01/01 Opening Balances
assets:bank:giro		EUR ...
...
equity:opening balances	EUR -...

These transactions are in the second file only:

```
setup
Check the status of the hledger installation.

```
Flags:
no command-specific flags

```
setup tests your hledger installation and prints a list of results,
sometimes with helpful hints. This is a good first command to run after installing hledger. Also after upgrading, or when something's not
working, or just when you want a reminder of where things are.

It makes one network request to detect the latest hledger release version. It's ok if this fails or times out. It will use ANSI color by
default, unless disabled by NO_COLOR or --color=n. It does not use a
pager or a config file.

It expects that the hledger version you are running is installed in
your PATH. If not, it will stop until you have done that (to keep
things simple).

Example:

```
$ hledger setup
Checking your hledger setup..
Legend: good, neutral, unknown, warning

hledger
* is a released version ?			  no  hledger 1.42.99-gbca4b39c5-20250425, mac-aarch64
* is up to date ?				 yes  1.42.99 installed, latest is 1.42.1
* is a native binary for this machine ?	 yes  aarch64
* is installed in PATH ?			 yes  /Users/simon/.local/bin/hledger
* has a system text encoding configured ?	 yes  UTF-8, data files should use this encoding
* has a user config file ? (optional)	  no
* current directory has a local config ?	 yes  /Users/simon/src/hledger/hledger.conf
* the config file is readable ?		 yes  /Users/simon/src/hledger/hledger.conf

terminal
* the NO_COLOR variable is defined ?	  no
* --color is configured by config file ?	  no
* hledger will use color by default ?	 yes
* the PAGER variable is defined ?		 yes  less
* --pager is configured by config file ?	  no
* hledger will use a pager when needed ?	 yes  /opt/homebrew/bin/less
* the LESS variable is defined ?		 yes
* the HLEDGER_LESS variable is defined ?	  no
* adjusting LESS variable for color etc. ? yes
* --pretty is enabled by config file ?	  no  tables will use ASCII characters
* bash shell completions are installed ?	   ?
* zsh shell completions are installed ?	   ?

journal
* the LEDGER_FILE variable is defined ?	 yes  /Users/simon/finance/2025/2025.journal
* a default journal file is readable ?	 yes  /Users/simon/finance/2025/2025.journal
* it includes additional files ?		 yes  15
* all commodities are declared ?		 yes  10
* all accounts are declared ?		 yes  160
* all accounts have types ?		  no  14 untyped
* accounts of each type were detected ?	 yes  ALERXCV
* commodities/accounts are checked ?	  no  use -s to check commodities/accounts
* balance assertions are checked ?	 yes  use -I to ignore assertions

```
test
Run built-in unit tests.

```
Flags:
no command-specific flags

```
This command runs the unit tests built in to hledger and hledger-lib,
printing the results on stdout. If any test fails, the exit code will
be non-zero.

This is mainly used by hledger developers, but you can also use it to
sanity-check the installed hledger executable on your platform. All
tests are expected to pass - if you ever see a failure, please report
as a bug!

Any arguments before a -- argument will be passed to the tasty test
runner as test-selecting -p patterns, and any arguments after -- will
be passed to tasty unchanged.

Examples:

```
$ hledger test		   # run all unit tests
$ hledger test balance	   # run tests with "balance" in their name
$ hledger test -- -h	   # show tasty's options

```
PART 5: COMMON TASKS
Here are some quick examples of how to do some basic tasks with
hledger.

## Getting help

Here's how to list commands and view options and command docs:

```
$ hledger		       # show available commands
$ hledger --help	       # show common options
$ hledger CMD --help     # show CMD's options, common options and CMD's documentation

```
You can also view your hledger version's manual in several formats by
using the help command. Eg:

```
$ hledger help	       # show the hledger manual with info, man or $PAGER (best available)
$ hledger help journal   # show the journal topic in the hledger manual
$ hledger help --help    # find out more about the help command

```
To view manuals and introductory docs on the web, visit
https://hledger.org. Chat and mail list support and discussion archives can be found at https://hledger.org/support.

## Constructing command lines

hledger has a flexible command line interface. We strive to keep it
simple and ergonomic, but if you run into one of the sharp edges described in OPTIONS, here are some tips that might help:

• command-specific options must go after the command (it's fine to put

```
common options there too: hledger CMD OPTS ARGS)

```
• you can run addon commands via hledger (hledger ui [ARGS]) or directly (hledger-ui [ARGS])

• enclose "problematic" arguments in single quotes

• if needed, also add a backslash to hide regular expression metacharacters from the shell

• to see how a misbehaving command line is being parsed, add --debug=2.

## Starting a journal file

hledger looks for your accounting data in a journal file,
$HOME/.hledger.journal by default:

```
$ hledger stats
The hledger journal file "/Users/simon/.hledger.journal" was not found.
Please create it first, eg with "hledger add" or a text editor.
Or, specify an existing journal file with -f or LEDGER_FILE.

```
You can override this by setting the LEDGER_FILE environment variable
(see below). It's a good practice to keep this important file under
version control, and to start a new file each year. So you could do
something like this:

```
$ mkdir ~/finance
$ cd ~/finance
$ git init
Initialized empty Git repository in /Users/simon/finance/.git/
$ touch 2023.journal
$ echo "export LEDGER_FILE=$HOME/finance/2023.journal" >> ~/.profile
$ source ~/.profile
$ hledger stats
Main file		       : /Users/simon/finance/2023.journal
Included files	       :
Transactions span	       :  to  (0 days)
Last transaction	       : none
Transactions	       : 0 (0.0 per day)
Transactions last 30 days: 0 (0.0 per day)
Transactions last 7 days : 0 (0.0 per day)
Payees/descriptions      : 0
Accounts		       : 0 (depth 0)
Commodities	       : 0 ()
Market prices	       : 0 ()

```

## Setting LEDGER_FILE

## Set LEDGER_FILE on unix

It depends on your shell, but running these commands in the terminal
will work for many people; adapt if needed:

```
$ echo 'export LEDGER_FILE=~/finance/my.journal' >> ~/.profile
$ source ~/.profile

```
When correctly configured:

• env | grep LEDGER_FILE will show your new setting

• and so should hledger setup and hledger files.

## Set LEDGER_FILE on mac

In a terminal window, follow the unix procedure above.

Also, this optional step may be helpful for GUI applications:

1. Add an entry to ~/.MacOSX/environment.plist like

```
{
"LEDGER_FILE" : "~/finance/my.journal"
}

```
2. Run killall Dock in a terminal window (or restart the machine), to

```
complete the change.

```
When correctly configured for GUI applications:

• apps started from the dock or a spotlight search, such as a GUI

```
Emacs, will be aware of the new LEDGER_FILE setting.

```

## Set LEDGER_FILE on Windows

Using the gui is easiest:

1. In task bar, search for environment variables, and choose "Edit environment variables for your account".

2. Create or change a LEDGER_FILE setting in the User variables pane.

```
A typical value would be C:\Users\USERNAME\finance\my.journal.

```
3. Click OK to complete the change.

4. And open a new powershell window. (Existing windows won't see the

```
change.)

```
Or at the command line, you can do it this way:

1. In a powershell window, run [Environment]::SetEnvironmentVariable("LEDGER_FILE", "C:\User\USERNAME\finance\my.journal", [System.EnvironmentVariableTarget]::User)

2. And open a new powershell window. (Existing windows won't see the

```
change.)

```
Warning, doing this from the Windows command line can be tricky; other
methods you may find online:

• may not affect the current window

• may not be persistent

• may not work unless you are an administrator

• may limit values to 1024 characters

• may break dynamic references to other variables

• may require a new-enough version of powershell

• or may be intended for the older command window.

• If you still have trouble, see eg Setting Windows PowerShell environment variables or Adding path permanently to windows using powershell

```
doesn't appear to work.

```
When correctly configured:

• in a new powershell window, $env:LEDGER_FILE will show your new setting

• and so should hledger setup and (once the file exists) hledger files.

## Setting opening balances

Pick a starting date for which you can look up the balances of some
real-world assets (bank accounts, wallet..) and liabilities (credit
cards..).

To avoid a lot of data entry, you may want to start with just one or
two accounts, like your checking account or cash wallet; and pick a recent starting date, like today or the start of the week. You can always come back later and add more accounts and older transactions, eg
going back to january 1st.

Add an opening balances transaction to the journal, declaring the balances on this date. Here are two ways to do it:

• The first way: open the journal in any text editor and save an entry

```
like this:

2023-01-01 * opening balances
assets:bank:checking		$1000	= $1000
assets:bank:savings			$2000	= $2000
assets:cash				 $100	= $100
liabilities:creditcard		 $-50	= $-50
equity:opening/closing balances

These are start-of-day balances, ie whatever was in  the  account  at
the end of the previous day.

The  *	 after	the  date  is  an optional status flag.	 Here it means
"cleared & confirmed".

The currency symbols are optional, but usually a good idea as	you'll
be dealing with multiple currencies sooner or later.

The  = amounts are optional balance assertions, providing extra error
checking.

```
• The second way: run hledger add and follow the prompts to record a

```
similar transaction:

$ hledger add
Adding transactions to journal file /Users/simon/finance/2023.journal
Any command line arguments will be used as defaults.
Use tab key to complete, readline keys to edit, enter to accept defaults.
An optional (CODE) may follow transaction dates.
An optional ; COMMENT may follow descriptions or amounts.
If you make a mistake, enter < at any prompt to go one step backward.
To end a transaction, enter . when prompted.
To quit, enter . at a date prompt or press control-d or control-c.
Date [2023-02-07]: 2023-01-01
Description: * opening balances
Account 1: assets:bank:checking
Amount	1: $1000
Account 2: assets:bank:savings
Amount	2 [$-1000]: $2000
Account 3: assets:cash
Amount	3 [$-3000]: $100
Account 4: liabilities:creditcard
Amount	4 [$-3100]: $-50
Account 5: equity:opening/closing balances
Amount	5 [$-3050]:
Account 6 (or . or enter to finish this transaction): .
2023-01-01 * opening balances
assets:bank:checking		      $1000
assets:bank:savings			      $2000
assets:cash				       $100
liabilities:creditcard		       $-50
equity:opening/closing balances	     $-3050

Save this transaction to the journal ? [y]:
Saved.
Starting the next transaction (. or ctrl-D/ctrl-C to quit)
Date [2023-01-01]: .

```
If you're using version control, this could be a good time to commit
the journal. Eg:

```
$ git commit -m 'initial balances' 2023.journal

```

## Recording transactions

As you spend or receive money, you can record these transactions using
one of the methods above (text editor, hledger add) or by using the
hledger-iadd or hledger-web add-ons, or by using the import command to
convert CSV data downloaded from your bank.

Here are some simple transactions, see the hledger_journal(5) manual
and hledger.org for more ideas:

```
2023/1/10 * gift received
assets:cash   $20
income:gifts

2023.1.12 * farmers market
expenses:food	 $13
assets:cash

2023-01-15 paycheck
income:salary
assets:bank:checking	$1000

```

## Reconciling

Periodically you should reconcile - compare your hledger-reported balances against external sources of truth, like bank statements or your
bank's website - to be sure that your ledger accurately represents the
real-world balances (and, that the real-world institutions have not
made a mistake!). This gets easy and fast with (1) practice and (2)
frequency. If you do it daily, it can take 2-10 minutes. If you let
it pile up, expect it to take longer as you hunt down errors and discrepancies.

A typical workflow:

1. Reconcile cash. Count what's in your wallet. Compare with what

```
hledger reports (hledger bal cash).  If they are different,  try  to
remember  the	 missing transaction, or look for the error in the already-recorded transactions.	 A  register  report  can  be  helpful
(hledger  reg cash).	If you can't find the error, add an adjustment
transaction.	Eg if you have $105 after the above, and can't explain
the missing $2, it could be:

2023-01-16 * adjust cash
assets:cash    $-2 = $105
expenses:misc

```
2. Reconcile checking. Log in to your bank's website. Compare today's

```
(cleared) balance with hledger's cleared balance (hledger bal checking  -C).  If they are different, track down the error or record the
missing transaction(s) or add an adjustment transaction, similar  to
the above.  Unlike the cash case, you can usually compare the transaction history and running balance from your bank with the  one  reported  by hledger reg checking -C.  This will be easier if you generally record transaction dates quite similar to your bank's	clearing dates.

```
3. Repeat for other asset/liability accounts.

Tip: instead of the register command, use hledger-ui to see a live-updating register while you edit the journal: hledger-ui --watch --register checking -C

After reconciling, it could be a good time to mark the reconciled
transactions' status as "cleared and confirmed", if you want to track
that, by adding the * marker. Eg in the paycheck transaction above,
insert * between 2023-01-15 and paycheck

If you're using version control, this can be another good time to commit:

```
$ git commit -m 'txns' 2023.journal

```

## Reporting

Here are some basic reports.

Show all transactions:

```
$ hledger print
2023-01-01 * opening balances
assets:bank:checking			    $1000
assets:bank:savings			    $2000
assets:cash				     $100
liabilities:creditcard		     $-50
equity:opening/closing balances	   $-3050

2023-01-10 * gift received
assets:cash		   $20
income:gifts

2023-01-12 * farmers market
expenses:food		    $13
assets:cash

2023-01-15 * paycheck
income:salary
assets:bank:checking		 $1000

2023-01-16 * adjust cash
assets:cash		    $-2 = $105
expenses:misc

```
Show account names, and their hierarchy:

```
$ hledger accounts --tree
assets
bank
checking
savings
cash
equity
opening/closing balances
expenses
food
misc
income
gifts
salary
liabilities
creditcard

```
Show all account totals:

```
$ hledger balance
$4105  assets
$4000    bank
$2000	checking
$2000	savings
$105    cash
$-3050  equity:opening/closing balances
$15  expenses
$13    food
$2    misc
$-1020  income
$-20    gifts
$-1000    salary
$-50  liabilities:creditcard
--------------------
0

```
Show only asset and liability balances, as a flat list, limited to
depth 2:

```
$ hledger bal assets liabilities -2
$4000  assets:bank
$105  assets:cash
$-50  liabilities:creditcard
--------------------
$4055

```
Show the same thing without negative numbers, formatted as a simple
balance sheet:

```
$ hledger bs -2
Balance Sheet 2023-01-16

|| 2023-01-16
========================++============
Assets		      ||
------------------------++------------
assets:bank	      ||      $4000
assets:cash	      ||       $105
------------------------++------------
||      $4105
========================++============
Liabilities	      ||
------------------------++------------
liabilities:creditcard ||	$50
------------------------++------------
||	$50
========================++============
Net:		      ||      $4055

```
The final total is your "net worth" on the end date. (Or use bse for a
full balance sheet with equity.)

Show income and expense totals, formatted as an income statement:

```
hledger is
Income Statement 2023-01-01-2023-01-16

|| 2023-01-01-2023-01-16
===============++=======================
Revenues	     ||
---------------++-----------------------
income:gifts  ||			  $20
income:salary ||			$1000
---------------++-----------------------
||			$1020
===============++=======================
Expenses	     ||
---------------++-----------------------
expenses:food ||			  $13
expenses:misc ||			   $2
---------------++-----------------------
||			  $15
===============++=======================
Net:	     ||			$1005

```
The final total is your net income during this period.

Show transactions affecting your wallet, with running total:

```
$ hledger register cash
2023-01-01 opening balances     assets:cash		    $100	  $100
2023-01-10 gift received	      assets:cash		     $20	  $120
2023-01-12 farmers market	      assets:cash		    $-13	  $107
2023-01-16 adjust cash	      assets:cash		     $-2	  $105

```
Show weekly posting counts as a bar chart:

```
$ hledger activity -W
2019-12-30 *****
2023-01-06 ****
2023-01-13 ****

```

## Migrating to a new file

At the end of the year, you may want to continue your journal in a new
file, so that old transactions don't slow down or clutter your reports,
and to help ensure the integrity of your accounting history. See the
close command.

If using version control, don't forget to git add the new file.
