---
title: hledger — Concepts & Options
toc: true
---

hledger is a robust, user-friendly, cross-platform set of programs for
tracking money, time, or any other commodity, using double-entry accounting and a simple, editable file format. hledger is inspired by
and largely compatible with ledger(1), and largely interconvertible
with beancount(1).

This manual is for hledger's command line interface, version 1.51.2.
It also describes the common options, file formats and concepts used by
all hledger programs. It might accidentally teach you some bookkeeping/accounting as well! You don't need to know everything in here to
use hledger productively, but when you have a question about functionality, this doc should answer it. It is detailed, so do skip ahead or
skim when needed. You can read it on hledger.org, or as an info manual
or man page on your system. You can also open a built-in copy, at a
point of interest, by running
hledger --man [CMD], hledger --info [CMD] or hledger help [TOPIC].

(And for shorter help, try hledger --tldr [CMD].)

The main function of the hledger CLI is to read plain text files describing financial transactions, crunch the numbers, and print a useful
report on the terminal (or save it as HTML, CSV, JSON or SQL). Many
reports are available, as subcommands. hledger will also detect other
hledger-* executables as extra subcommands.

hledger usually reads from (and appends to) a journal file specified by
the LEDGER_FILE environment variable (defaulting to
$HOME/.hledger.journal); or you can specify files with -f options. It
can also read timeclock files, timedot files, or any CSV/SSV/TSV file
with a date field.

Here is a small journal file describing one transaction:

```
2015-10-16 bought food
expenses:food	       $10
assets:cash

```
Transactions are dated movements of money (etc.) between two or more
accounts: bank accounts, your wallet, revenue/expense categories, people, etc. You can choose any account names you wish, using : to indicate subaccounts. There must be at least two spaces between account
name and amount. Positive amounts are inflow to that account (debit),
negatives are outflow from it (credit). (Some reports show revenue,
liability and equity account balances as negative numbers as a result;
this is normal.)

hledger’s add command can help you add transactions, or you can install
other data entry UIs like hledger-web or hledger-iadd. For more extensive/efficient changes, use a text editor: Emacs + ledger-mode, VIM +
vim-ledger, or VS Code + hledger-vscode are some good choices (see
https://hledger.org/editors.html).

To get started, run hledger add and follow the prompts, or save some
entries like the above in $HOME/.hledger.journal, then try commands
like:

```
$ hledger print -x
$ hledger aregister assets
$ hledger balance
$ hledger balancesheet
$ hledger incomestatement

```
Run hledger to list the commands. See also the "Starting a journal
file" and "Setting opening balances" sections in PART 5: COMMON TASKS.

PART 1: USER INTERFACE
Input
hledger reads one or more data files, each time you run it. You can
specify a file with -f, like so

```
$ hledger -f FILE [-f FILE2 ...] print

```
Files are most often in hledger's journal format, with the .journal
file extension (.hledger or .j also work); these files describe transactions, like an accounting general journal.

When no file is specified, hledger looks for .hledger.journal in your
home directory.

But most people prefer to keep financial files in a dedicated folder,
perhaps with version control. Also, starting a new journal file each
year is common (it's not required, but helps keep things fast and organised). So we usually configure a different journal file, by setting
the LEDGER_FILE environment variable, to something like ~/finance/2023.journal. For more about how to do that on your system, see
Common tasks > Setting LEDGER_FILE.

## Text encoding

hledger expects non-ascii input to be decodable with the system locale's text encoding. (For CSV/SSV/TSV files, this can be overridden
by the encoding CSV rule.)

So, trying to read non-ascii files which have the wrong text encoding,
or when no system locale is configured, will fail. To fix this, configure your system locale appropriately, and/or convert the files to
your system's text encoding (using iconv on unix, or powershell or
notepad on Windows). See Install: Text encoding for more tips.

hledger's output will use the system locale's encoding.

hledger's docs and example files mostly use UTF-8 encoding.

## Data formats

Usually the data file is in hledger's journal format, but it can be in
any of the supported file formats, which currently are:

Reader: Reads: Automatically used for

```
files with extensions:
```
─────────────────────────────────────────────────────────────────────────────
journal hledger journal files and some .journal .j .hledger

```
Ledger journals, for transactions   .ledger
```
timeclock timeclock files, for precise time .timeclock

```
logging
```
timedot timedot files, for approximate .timedot

```
time logging
```
csv Comma- or other delimiter-sepa‐ .csv

```
rated values, for data import

```
ssv Semicolon separated values .ssv
tsv Tab separated values .tsv
rules CSV/SSV/TSV/other separated val‐ .rules

```
ues, alternate way

```
These formats are described in more detail below.

hledger detects the format automatically based on the file extensions
shown above. If it can't recognise the file extension, it assumes
journal format. So for non-journal files, it's important to use a
recognised file extension, so as to either read successfully or to show
relevant error messages.

You can also force a specific reader/format by prefixing the file path
with the format and a colon. Eg, to read a .dat file containing tab
separated values:

```
$ hledger -f tsv:/some/file.dat stats

```

## Standard input

The file name - means standard input:

```
$ cat FILE | hledger -f- print

```
If reading non-journal data in this way, you'll need to write the format as a prefix, like timeclock: here:

```
$ echo 'i 2009/13/1 08:00:00' | hledger print -f timeclock:-

```

## Multiple files

You can specify multiple -f options, to read multiple files as one big
journal. When doing this, note that certain features (described below)
will be affected:

• Balance assertions will not see the effect of transactions in previous files. (Usually this doesn't matter as each file will set the

```
corresponding opening balances.)

```
• Some directives will not affect previous or subsequent files.

If needed, you can work around these by using a single parent file
which includes the others, or concatenating the files into one, eg: cat
a.journal b.journal | hledger -f- CMD.

## Strict mode

hledger checks input files for valid data. By default, the most important errors are detected, while still accepting easy journal files
without a lot of declarations:

• Are the input files parseable, with valid syntax ?

• Are all transactions balanced ?

• Do all balance assertions pass ?

With the -s/--strict flag, additional checks are performed:

• Are all accounts posted to, declared with an account directive ?

```
(Account error checking)

```
• Are all commodities declared with a commodity directive ? (Commodity

```
error checking)

```
• Are all commodity conversions declared explicitly ?

You can use the check command to run individual checks - the ones
listed above and some more.

Commands
hledger provides various subcommands for getting things done. Most of
these commands do not change the journal file; they just read it and
output a report. A few commands assist with adding data and file management. Some often-used commands are add, print, register, balancesheet and incomestatement.

To show a summary of commands, run hledger with no arguments. You can
see the same commands summary at the start of PART 4: COMMANDS below.

To use a particular command, run hledger CMD [CMDOPTS] [CMDARGS],

• CMD is the full command name, or its standard abbreviation shown in

```
the commands list, or any unambiguous prefix of the name.

```
• CMDOPTS are command-specific options, if any. Command-specific options must be written after the command name. Eg: hledger print -x.

• CMDARGS are additional arguments to the command, if any. Most

```
hledger commands accept arguments representing a query, to limit  the
data in some way.  Eg: hledger reg assets:checking.

```
To list a command's options, arguments, and documentation in the terminal, run hledger CMD -h. Eg: hledger bal -h.

## Add-on commands

In addition to the built-in commands, you can install add-on commands,
which will also appear in hledger's commands list. Some of these can
be installed as separate packages; others can be found in hledger's
bin/ directory, documented at https://hledger.org/scripts.html.

Add-on commands are programs or scripts in your shell's PATH, whose
name starts with "hledger-" and ends with no extension or a recognised
extension (".bat", ".com", ".exe", ".hs", ".js", ".lhs", ".lua",
".php", ".pl", ".py", ".rb", ".rkt", or ".sh"), and (on unix and mac)
which has executable permission for the current user.

You can run add-on commands directly: hledger-ui --watch.

Or you can run them with hledger, like built-in commands: hledger ui
--watch. In this case hledger's config file will be used, so you can
set custom options for the addon there. (Before hledger 1.50, an --
argument was needed before addon options, but not any more.)

Options
Run hledger -h to see general command line help. Options can be written either before or after the command name. These options are specific to the hledger CLI:

```
Flags:
--conf=CONFFILE	  Use extra options defined in this config file. If
not specified, searches upward and in XDG config
dir for hledger.conf (or .hledger.conf in $HOME).
-n --no-conf		  ignore any config file

```
And the following general options are common to most hledger commands:

```
General input/data transformation flags:
-f --file=[FMT:]FILE	  Read data from FILE, or from stdin if FILE is -,
inferring format from extension or a FMT: prefix.
Can be specified more than once. If not specified,
reads from $LEDGER_FILE or $HOME/.hledger.journal.
--rules=RULESFILE	  Use rules defined in this rules file for
converting subsequent CSV/SSV/TSV files. If not
specified, uses FILE.csv.rules for each FILE.csv.
--alias=A=B|/RGX/=RPL  transform account names from A to B, or by
replacing regular expression matches
--auto		  generate extra postings by applying auto posting
rules ("=") to all transactions
--forecast[=PERIOD]	  Generate extra transactions from periodic rules
("~"), from after the latest ordinary transaction
until 6 months from now. Or, during the specified
PERIOD (the equals is required). Auto posting rules
will also be applied to these transactions. In
hledger-ui, also make future-dated transactions
visible at startup.
-I --ignore-assertions	  don't check balance assertions by default
--txn-balancing=...	  how to check that transactions are balanced:
'old':   use global display precision
'exact': use transaction precision (default)
--infer-costs	  infer conversion equity postings from costs
--infer-equity	  infer costs from conversion equity postings
--infer-market-prices  infer market prices from costs
--pivot=TAGNAME	  use a different field or tag as account names
-s --strict		  do extra error checks (and override -I)
--verbose-tags	  add tags indicating generated/modified data

General output/reporting flags (supported by some commands):
-b --begin=DATE		  include postings/transactions on/after this date
-e --end=DATE		  include postings/transactions before this date
(with a report interval, will be adjusted to
following subperiod end)
-D --daily		  multiperiod report with 1 day interval
-W --weekly		  multiperiod report with 1 week interval
-M --monthly		  multiperiod report with 1 month interval
-Q --quarterly		  multiperiod report with 1 quarter interval
-Y --yearly		  multiperiod report with 1 year interval
-p --period=PERIODEXP	  set begin date, end date, and/or report interval,
with more flexibility
--today=DATE		  override today's date (affects relative dates)
--date2		  match/use secondary dates instead (deprecated)
-U --unmarked		  include only unmarked postings/transactions
-P --pending		  include only pending postings/transactions
-C --cleared		  include only cleared postings/transactions
(-U/-P/-C can be combined)
-R --real		  include only non-virtual postings
-E --empty		  Show zero items, which are normally hidden.
In hledger-ui & hledger-web, do the opposite.
--depth=DEPTHEXP	  if a number (or -NUM): show only top NUM levels
of accounts. If REGEXP=NUM, only apply limiting to
accounts matching the regular expression.
-B --cost		  show amounts converted to their cost/sale amount
-V --market		  Show amounts converted to their value at period
end(s) in their default valuation commodity.
Equivalent to --value=end.
-X --exchange=COMM	  Show amounts converted to their value at period
end(s) in the specified commodity.
Equivalent to --value=end,COMM.
--value=WHEN[,COMM]	  show amounts converted to their value on the
specified date(s) in their default valuation
commodity or a specified commodity. WHEN can be:
'then':     value on transaction dates
'end':      value at period end(s)
'now':      value today
YYYY-MM-DD: value on given date
-c --commodity-style=S	  Override a commodity's display style.
Eg: -c '.' or -c '1.000,00 EUR'
--pretty[=YN]	  Use box-drawing characters in text output? Can be
'y'/'yes' or 'n'/'no'.
If YN is specified, the equals is required.

General help flags:
-h --help		  show command line help
--tldr		  show command examples with tldr
--info		  show the manual with info
--man		  show the manual with man
--version		  show version information
--debug=[1-9]	  show this much debug output (default: 1)
--pager=YN		  use a pager when needed ? y/yes (default) or n/no
--color=YNA --colour	  use ANSI color ? y/yes, n/no, or auto (default)

```
Usually hledger accepts any unambiguous flag prefix, eg you can write
--tl instead of --tldr or --dry instead of --dry-run.

You can combine short flags which don't take arguments, eg you can
write -MAST instead of -M -A -S -T. Flags requiring an argument can't
be combined in this way (-If FILE won't work).

If the same option appears more than once in a command line, usually
the last (right-most) wins. Similarly, if mutually exclusive flags are
used together, the right-most wins. (When flags are mutually exclusive, they'll usually have a group prefix in --help.)

With most commands, arguments are interpreted as a hledger query which
filter the data. Some queries can be expressed either with options or
with arguments.

Below are more tips for using the command line interface - feel free to
skip these until you need them.

## Special characters

In commands you type at the command line, certain characters have special meaning and sometimes need to be "escaped" or "quoted", by prefixing backslashes or enclosing in quotes.

If you are able to minimise the use of special characters in your data,
you won't have to deal with this as much. For example, you could use
hyphen - or underscore _ instead of spaces in account names, and you
could use the USD currency code instead of the $ currency symbol in
amounts.

But if you prefer to use spaced account names and $, it's fine. Just
be aware of this topic so you can check this doc when needed. (These
examples are mostly tested on unix; some details might need to be
adapted if you're on Windows.)

## Escaping shell special characters

These are some characters which may have special meaning to your shell
(the program which interprets command lines):

• SPACE, <, >, (, ), |, \, %

• $ if followed by a word character

So for example, to match an account name containing spaces, like
"credit card", don't write:

```
$ hledger register credit card

```
Instead, enclose the name in single quotes:

```
$ hledger register 'credit card'

```
On unix or in Windows powershell, if you use double quotes your shell
will silently treat $ as variable interpolation. So you should probably avoid double quotes, unless you want that behaviour, eg in a
script:

```
$ hledger register "assets:$SOMEACCT"

```
But in an older Windows CMD.EXE window, you must use double quotes:

```
C:\Users\Me> hledger register "credit card"

```
On unix or in Windows powershell, as an alternative to quotes you can
write a backslash before each special character:

```
$ hledger register credit\ card

```
Finally, since hledger's query arguments are regular expressions (described below), you could also fill that gap with . which matches any
character:

```
$ hledger register credit.card

```

## Escaping regular expression special characters

Some characters also have special meaning in regular expressions, which
hledger's arguments often are. Those include:

• ., ^, $, [, ], (, ), |, \

To escape one of these, write \ before it. But note this is in addition to the shell escaping above. So for characters which are special
to both shell and regular expressions, like \ and $, you will sometimes
need two levels of escaping.

For example, a balance report that uses a cur: query restricting it to
just the $ currency, should be written like this:

```
$ hledger balance cur:\\$

```
Explanation:

1. Add a backslash \ before the dollar sign $ to protect it from regular expressions (so it will be matched literally with no special

```
meaning).

```
2. Add another backslash before that backslash, to protect it from the

```
shell (so the shell won't consume it).

```
3. $ doesn't need to be protected from the shell in this case, because

```
it's	not  followed by a word character; but it would be harmless to
do so.

```
But here's another way to write that, which tends to be easier: add
backslashes to escape from regular expressions, then enclose with
quotes to escape from the shell:

```
$ hledger balance cur:'\$'

```

## Escaping in other situations

hledger options and arguments are sometimes used in places other than
the command line, where the escaping/quoting rules are different. For
example, backslash-quoting may not be available. Here's a quick reference:

In unix shell Use single quotes and/or backslash (or double quotes

```
for variable interpolation)
```
In Windows power‐ Use single quotes (or double quotes for variable inshell terpolation)
In Windows cmd Use double quotes

In hledger-ui's Use single or double quotes
filter prompt
In hledger-web's Use single or double quotes
search form
In an argument Don't use spaces, don't shell-escape, do regex-esfile cape, write one argument/option per line
In a config file Use single or double quotes, and enclose the whole

```
argument ('desc:a b' not desc:'a b')
```
In ghci (the Use double quotes, and enclose the whole argument
Haskell REPL)

## Unicode characters

hledger is expected to handle non-ascii characters correctly:

• they should be parsed correctly in input files and on the command

```
line,	by all hledger tools (add, iadd, hledger-web's search/add/edit
forms, etc.)

```
• they should be displayed correctly by all hledger tools, and

```
on-screen alignment should be preserved.

```
This requires a well-configured environment. Here are some tips:

• A system locale must be configured, which can decode the characters

```
being used.  This is essential - see Text encoding and Install:  Text
encoding.

```
• Your terminal software (eg Terminal.app, iTerm, CMD.exe, xterm..)

```
must support unicode.	On Windows, you may need to use Windows Terminal.

```
• The terminal must be using a font which includes the required unicode

```
glyphs.

```
• The terminal should be configured to display wide characters as double width (for report alignment).

• On Windows, for best results you should run hledger in the same kind

```
of environment in which it was built.	Eg hledger built in the	 standard  CMD.EXE	environment  (like  the binaries on our download page)
might show display problems when run in a cygwin  or  msys  terminal,
and vice versa.  (See eg #961).

```

## Regular expressions

A regular expression (regexp) is a small piece of text where certain
characters (like ., ^, $, +, *, (), |, [], \) have special meanings,
forming a tiny language for matching text precisely - very useful in
hledger and elsewhere. To learn all about them, visit regular-expressions.info.

hledger supports regexps whenever you are entering a pattern to match
something, eg in query arguments, account aliases, CSV if rules,
hledger-web's search form, hledger-ui's / search, etc. You may need to
wrap them in quotes, especially at the command line (see Special characters above). Here are some examples:

Account name queries (quoted for command line use):

```
Regular expression:  Matches:
-------------------  ------------------------------------------------------------
bank		   assets:bank, assets:bank:savings, expenses:art:banksy, ...
:bank		   assets:bank:savings, expenses:art:banksy
:bank:		   assets:bank:savings
'^bank'		   none of those ( ^ matches beginning of text )
'bank$'		   assets:bank	 ( $ matches end of text )
'big \$ bank'	   big $ bank	 ( \ disables following character's special meaning )
'\bbank\b'	   assets:bank, assets:bank:savings  ( \b matches word boundaries )
'(sav|check)ing'	   saving or checking  ( (|) matches either alternative )
'saving|checking'	   saving or checking  ( outer parentheses are not needed )
'savings?'	   saving or savings   ( ? matches 0 or 1 of the preceding thing )
'my +bank'	   my bank, my	bank, ... ( + matches 1 or more of the preceding thing )
'my *bank'	   mybank, my bank, my	bank, ... ( * matches 0 or more of the preceding thing )
'b.nk'		   bank, bonk, b nk, ... ( . matches any character )

```
Some other queries:

```
desc:'amazon|amzn|audible'  Amazon transactions
cur:EUR		   amounts with commodity symbol containing EUR
cur:'\$'		   amounts with commodity symbol containing $
cur:'^\$$'	   only $ amounts, not eg AU$ or CA$
cur:....?		   amounts with 4-or-more-character symbols
tag:.=202[1-3]	   things with any tag whose value contains 2021, 2022 or 2023

```
Account name aliases: accept . instead of : as account separator:

```
alias /\./=:	   replaces all periods in account names with colons

```
Show multiple top-level accounts combined as one:

```
--alias='/^[^:]+/=combined'  ( [^:] matches any character other than : )

```
Show accounts with the second-level part removed:

```
--alias '/^([^:]+):[^:]+/ = \1'
match a top-level account and a second-level account
and replace those with just the top-level account
( \1 in the replacement text means "whatever was matched
by the first parenthesised part of the regexp"

```
CSV rules: match CSV records containing dining-related MCC codes:

```
if \?MCC581[124]

```
Match CSV records with a specific amount around the end/start of month:

```
if %amount \b3\.99
&	 %date	 (29|30|31|01|02|03)$

```
hledger's regular expressions
hledger's regular expressions come from the regex-tdfa library. If
they're not doing what you expect, it's important to know exactly what
they support:

1. they are case insensitive

2. they are infix matching (they do not need to match the entire thing

```
being matched)

```
3. they are POSIX ERE (extended regular expressions)

4. they also support GNU word boundaries (\b, \B, \<, \>)

5. backreferences are supported when doing text replacement in account

```
aliases  or  CSV  rules, where backreferences can be used in the replacement string to reference capturing groups in the search regexp.
Otherwise, if you write \1, it will match the digit 1.

```
6. they do not support mode modifiers ((?s)), character classes (\w,

```
\d), or anything else not mentioned above.

```
7. they may not (I'm guessing not) properly support right-to-left or

```
bidirectional text.

```
Some things to note:

• In the alias directive and --alias option, regular expressions must

```
be enclosed in forward	 slashes  (/REGEX/).   Elsewhere  in  hledger,
these are not required.

```
• In queries, to match a regular expression metacharacter like $ as a

```
literal character, prepend a backslash.  Eg  to  search  for  amounts
with the dollar sign in hledger-web, write cur:\$.

```
• On the command line, some metacharacters like $ have a special meaning to the shell and so must be escaped at least once more. See Special characters.

## Argument files

You can save a set of command line options and arguments in a file, and
then use them by writing @FILE.args as a hledger command argument. The
.args file extension is conventional, but not required. In an argument
file,

• Each line can contain one argument, flag, or option.

• Blank lines or lines beginning with # are ignored.

• An option's flag and value should be joined by =.

• An option value or an argument may contain spaces. Don't use single

```
or double quotes.

```
• And generally, use one less level of quoting/escaping than at the

```
command line.	Eg cur:\$, not cur:\\$ as on the command line.

```
For example:

```
# cash.args

assets:cash
assets:charles schwab:sweep
cur:\$
-c=$1.

$ hledger bal @cash.args

```

## Config files

With hledger 1.40+, you can save extra command line options and arguments in a more featureful hledger config file. Here's a small example:

```
# General options are listed first, and used with hledger commands that support them.
--pretty

# Options following a `[COMMAND]` heading are used with that hledger command only.
[print]
--explicit --infer-costs

```
To use a config file, specify it with the --conf option. Its options
will be inserted near the start of your command line, so you can override them with command line options if needed.

Or, you can set up an automatic config file that is used whenever you
run hledger, by creating hledger.conf in the current directory or
above, or .hledger.conf in your home directory (~/.hledger.conf), or
hledger.conf in your XDG config directory (~/.config/hledger/hledger.conf).

Here is another example config you could start with:
https://github.com/simonmichael/hledger/blob/master/hledger.conf.sample

You can put not only options, but also arguments in a config file. If
the first word in a config file's top (general) section does not begin
with a dash (eg: print), it is treated as the command argument (overriding any argument on the command line).

On unix machines, you can add a shebang line at the top of a config
file, set executable permission on the file, and use it like a script.
Eg (the -S is needed on some operating systems):

```
#!/usr/bin/env -S hledger --conf

```
You can ignore config files by adding the -n/--no-conf flag to the command line. This is useful when using hledger in scripts, or when troubleshooting. When both --conf and --no-conf options are used, the
right-most wins.

To inspect the processing of config files, use --debug or --debug=8.
Or, run the setup command, which will display any active config files.
(setup is not affected by config files itself, unlike other commands.)

Warning!

There aren't many hledger features that need a warning, but this is
one!

Automatic config files, while convenient, also make hledger less predictable and dependable. It's easy to make a config file that changes
a report's behaviour, or breaks your hledger-using scripts/applications, in ways that will surprise you later.

If you don't want this,

1. Just don't create a hledger.conf file on your machine.

2. Also be alert to downloaded directories which may contain a

```
hledger.conf file.

```
3. Also if you are sharing scripts or examples or support, consider

```
that others may have a hledger.conf file.

```
Conversely, once you decide to use this feature, try to remember:

1. Whenever a hledger command does not work as expected, try it again

```
with -n (--no-conf) to see if a config file was to blame.

```
2. Whenever you call hledger from a script, consider whether that call

```
should use -n or not.

```
3. Be conservative about what you put in your config file; try to consider the effect on all your reports.

4. To troubleshoot the effect of config files, run with --debug or

```
--debug 8.

```
The config file feature was added in hledger 1.40.

## Shell completions

If you use the bash or zsh shells, you can optionally set up context-sensitive autocompletion for hledger command lines. Try pressing
hledger<SPACE><TAB><TAB> (should list all hledger commands) or hledger
reg acct:<TAB><TAB> (should list your top-level account names). If
completions aren't working, or for more details, see Install > Shell
completions.

Output

## Output destination

hledger commands send their output to the terminal by default. You can
of course redirect this, eg into a file, using standard shell syntax:

```
$ hledger print > foo.txt

```
Some commands (print, register, stats, the balance commands) also provide the -o/--output-file option, which does the same thing without
needing the shell. Eg:

```
$ hledger print -o foo.txt
$ hledger print -o -	  # write to stdout (the default)

```

## Output format

Some commands offer other kinds of output, not just text on the terminal. Here are those commands and the formats currently supported:

command txt html csv/tsv fods beancount sql json
────────────────────────────────────────────────────────────────────────────────────────────
aregister Y Y Y Y Y
balance Y Y Y Y Y
balancesheet Y Y Y Y Y
balancesheetequity Y Y Y Y Y
cashflow Y Y Y Y Y
incomestatement Y Y Y Y Y
print Y Y Y Y Y Y Y
register Y Y Y Y Y

You can also see which output formats a command supports by running
hledger CMD -h and looking for the -O/--output-format=FMT option,

You can select the output format by using that option:

```
$ hledger print -O csv	# print CSV to standard output

```
or by choosing a suitable filename extension with the -o/--output-file=FILE.FMT option:

```
$ hledger balancesheet -o foo.csv	   # write CSV to foo.csv

```
The -O option can be combined with -o to override the file extension if
needed:

```
$ hledger balancesheet -o foo.txt -O csv	  # write CSV to foo.txt

```
Here are some notes about the various output formats.

## Text output

This is the default: human readable, plain text report output, suitable
for viewing with a monospace font in a terminal. If your data contains
unicode or wide characters, you'll need a terminal and font that render
those correctly. (This can be challenging on MS Windows.)

Some reports (register, aregister) will normally use the full window
width. If this isn't working or you want to override it, you can use
the -w/--width option.

Balance reports (balance, balancesheet, incomestatement...) use whatever width they need. Multi-period multi-currency reports can often be
wider than the window. Besides using a pager, helpful techniques for
this situation include --layout=bare, -X COMM, cur:, --transpose,
--tree, --depth, --drop, switching to html output, etc.

## Box-drawing characters

hledger draws simple table borders by default, to minimise the risk of
display problems caused by a terminal/font not supporting box-drawing
characters.

But your terminal and font probably do support them, so we recommend
using the --pretty flag to show prettier tables in the terminal. This
is a good flag to add to your hledger config file.

## Colour

hledger tries to automatically detect ANSI colour and text styling support and use it when appropriate. (Currently, it is used rather minimally: some reports show negative numbers in red, and help output uses
bold text for emphasis.)

You can override this by setting the NO_COLOR environment variable to
disable it, or by using the --color/--colour option, perhaps in your
config file, with a y/yes or n/no value to force it on or off.

## Paging

In unix-like environments, when displaying large output (in any output
format) in the terminal, hledger tries to use a pager when appropriate.
(You can disable this with the --pager=no option, perhaps in your config file.)

The pager shows one page of text at a time, and lets you scroll around
to see more. While it is active, usually SPACE shows the next page, h
shows help, and q quits. The home/end/page up/page down/cursor keys,
and mouse scrolling, may also work.

hledger will use the pager specified by the PAGER environment variable,
otherwise less if available, otherwise more if available. (With one
exception: hledger help -p TOPIC will always use less, so that it can
scroll to the topic.)

The pager is expected to display hledger's ANSI colour and text
styling. If you see junk characters, you might need to configure your
pager to handle ANSI codes. Or you could disable colour as described
above.

If you are using the less pager, hledger automatically appends a number
of options to the LESS variable to enable ANSI colour and a number of
other conveniences. (At the time of writing: --chop-long-lines
--hilite-unread --ignore-case --no-init --quit-at-eof
--quit-if-one-screen --RAW-CONTROL-CHARS --shift=8
--squeeze-blank-lines --use-backslash ). If these don't work well, you
can set your preferred options in the HLEDGER_LESS variable, which will
be used instead.

## HTML output

HTML output can be styled by an optional hledger.css file in the same
directory.

HTML output will be a HTML fragment, not a complete HTML document.
Like other hledger output, for non-ascii characters it will use the
system locale's text encoding (see Text encoding).

## CSV / TSV output

In CSV or TSV output, digit group marks (such as thousands separators)
are disabled automatically.

## FODS output

FODS is the OpenDocument Spreadsheet format as plain XML, as accepted
by LibreOffice and OpenOffice. If you use their spreadsheet applications, this is better than CSV because it works across locales (decimal
point vs. decimal comma, character encoding stored in XML header, thus
no problems with umlauts), it supports fixed header rows and columns,
cell types (string vs. number vs. date), separation of number and
currency (currency is displayed but the cell type is still a number accessible for computation), styles (bold), borders. Btw. you can still
extract CSV from FODS/ODS using various utilities like libreoffice
--headless or ods2csv.

## Beancount output

This is Beancount's journal format. You can use this to export your
hledger data to Beancount, eg to use the Fava web app.

hledger will try to adjust your data to suit Beancount, automatically.
Be cautious and check the conversion until you are confident it is
good. If you plan to export to Beancount often, you may want to follow
its conventions, for a cleaner conversion:

• use Beancount-friendly account names

• use currency codes instead of currency symbols

• use cost notation instead of equity conversion postings

• avoid virtual postings, balance assignments, and secondary dates.

There is one big adjustment you must handle yourself: for Beancount,
the top level account names must be Assets, Liabilities, Equity, Income, and/or Expenses. You can use account aliases to rewrite your account names temporarily, if needed, as in this hledger2beancount.conf
config file.

2024-12-20: Some more things not yet handled for you:

• P directives are not converted automatically - convert those yourself.

• Balance assignments are not converted (Beancount doesn't support

```
them) - replace those with explicit amounts.

```

## Beancount account names

Aside from the top-level names, hledger will adjust your account names
to make valid Beancount account names, by capitalising each part, replacing spaces with -, replacing other unsupported characters with
C<HEXBYTES>, prepending A to account name parts which don't begin with
a letter or digit, and appending :A to account names which have only
one part.

## Beancount commodity names

hledger will adjust your commodity names to make valid Beancount commodity/currency names, which must be 2-24 uppercase letters, digits, or
', ., _, -, beginning with a letter and ending with a letter or digit.
hledger will convert known currency symbols to ISO 4217 currency codes,
capitalise letters, replace spaces with -, replace other unsupported
characters with C<HEXBYTES>, and prepend or append C if needed.

## Beancount virtual postings

Beancount doesn't allow virtual postings; if you have any, they will be
omitted from beancount output.

## Beancount metadata

hledger tags will be converted to Beancount metadata (except for tags
whose name begins with _). Metadata names will be adjusted to be Beancount-compatible: beginning with a lowercase letter, at least two characters long, and with unsupported characters encoded. Metadata values
will use Beancount's string type.

In hledger, objects can have the same tag repeated with multiple values. Eg an assets:cash account might have both type:Asset and
type:Cash tags. For Beancount these will be combined into one, with
the values combined, comma separated. Eg: type: "Asset, Cash".

## Beancount costs

Beancount doesn't allow redundant costs and conversion postings as
hledger does. If you have any of these, the conversion postings will
be omitted. Currently we support at most one cost + conversion postings group per transaction.

## Beancount operating currency

Declaring an operating currency (or several) improves Beancount and
Fava reports. Currently hledger will declare each currency used in
cost amounts as an operating currency. If needed, replace these with
your own declaration, like

```
option "operating_currency" "USD"

```

## SQL output

SQL output is expected to work at least with SQLite, MySQL and Postgres.

The SQL statements are expected to be executed in the empty database.
If you already have tables created via SQL output of hledger, you would
probably want to either clear data from these (via delete or truncate
SQL statements) or drop the tables completely before import; otherwise
your postings would be duplicated.

For SQLite, it is more useful if you modify the generated id field to
be a PRIMARY KEY. Eg:

```
$ hledger print -O sql | sed 's/id serial/id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL/g' | ...

```
This is not yet much used; feedback is welcome.

## JSON output

Our JSON is rather large and verbose, since it is a faithful representation of hledger's internal data types. To understand its structure,
read the Haskell type definitions, which are mostly in
https://github.com/simonmichael/hledger/blob/master/hledger-lib/Hledger/Data/Types.hs. hledger-web's OpenAPI specification may also be relevant.

hledger stores numbers with sometimes up to 255 significant digits.
This is too many digits for most JSON consumers, so in JSON output we
round numbers to at most 10 decimal places. (We don't limit the number
of integer digits.) If you find this causing problems, please let us
know. Related: #1195

This is not yet much used; feedback is welcome.

## Commodity styles

When displaying amounts, hledger infers a standard display style for
each commodity/currency, as described below in Commodity display style.

If needed, this can be overridden by a -c/--commodity-style option (except for cost amounts and amounts displayed by the print command, which
are always displayed with all decimal digits). For example, the following will force dollar amounts to be displayed as shown:

```
$ hledger print -c '$1.000,0'

```
This option can be repeated to set the display style for multiple commodities/currencies. Its argument is as described in the commodity directive. Note that omitting the commodity symbol will set the display
style for just the no-symbol commodity, not all commodities.

In some cases hledger will adjust number formatting to improve their
parseability (such as adding trailing decimal marks when needed).

## Debug output

We intend hledger to be relatively easy to troubleshoot, introspect and
develop. You can add --debug[=N] to any hledger command line to see
additional debug output. N ranges from 1 (least output, the default)
to 9 (maximum output). Typically you would start with 1 and increase
until you are seeing enough. Debug output goes to stderr, and is not
affected by -o/--output-file (unless you redirect stderr to stdout, eg:
2>&1). It will be interleaved with normal output, which can help reveal when parts of the code are evaluated. To capture debug output in
a log file instead, you can usually redirect stderr, eg:

```
hledger bal --debug=3 2>hledger.log

```
(This option doesn't work in a config file yet.)

Environment
These environment variables affect hledger:

HLEDGER_LESS If less is your pager, this variable specifies the less
options hledger should use. (Otherwise, LESS + custom options are
used.)

LEDGER_FILE The default journal file, to be used when no -f/--file option is provided. For example, it could be ~/finance/main.journal.
This can also be a glob pattern, eg ./2???.journal. (If the glob
matches multiple files, only the alphanumerically first one is used.)
If LEDGER_FILE points to a non-existent file, an error will be raised.
If the value is the empty string, it is ignored.

If LEDGER_FILE is not set and -f is not provided, the default journal
file is $HOME/.hledger.journal (or if a home directory can't be detected, ./.hledger.journal).

See also Common tasks > Setting LEDGER_FILE.

NO_COLOR If this environment variable exists (with any value, including
empty), hledger will not use ANSI color codes in terminal output, unless overridden by an explicit --color=y or --colour=y option.

PART 2: DATA FORMATS
Journal
hledger's usual data source is a plain text file containing journal entries in hledger journal format. If you're looking for a quick reference, jump ahead to the journal cheatsheet (or use the table of contents at https://hledger.org/hledger.html).

This file represents an accounting General Journal. The .journal file
extension is most often used, though not strictly required. The journal file contains a number of transaction entries, each describing a
transfer of money (or any commodity) between two or more named accounts, in a simple format readable by both hledger and humans.

hledger's journal format is compatible with most of Ledger's journal
format, but not all of it. The differences and interoperation tips are
described at hledger and Ledger. With some care, and by avoiding incompatible features, you can keep your hledger journal readable by
Ledger and vice versa. This can useful eg for comparing the behaviour
of one app against the other.

You can use hledger without learning any more about this file; just use
the add or web or import commands to create and update it.

Many users, though, edit the journal file with a text editor, and track
changes with a version control system such as git. Editor add-ons such
as ledger-mode or hledger-mode for Emacs, vim-ledger for Vim, and
hledger-vscode for Visual Studio Code, make this easier, adding colour,
formatting, tab completion, and useful commands. See Editors at
hledger.org for the full list.

A hledger journal file can contain three kinds of thing: comment lines,
transactions, and/or directives (including periodic transaction rules
and auto posting rules). Understanding the journal file format will
also give you a good understanding of hledger's data model. Here's a
quick cheatsheet/overview, followed by detailed descriptions of each
part.
