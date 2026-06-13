---
title: hledger help
---

# hledger help

help [OPTIONS] [TOPIC]
Show the hledger user manual with info, man, or a pager. With a (case
insensitive) TOPIC argument, try to open it at that section heading.

Flags:
-i show the manual with info
-m show the manual with man
-p show the manual with $PAGER or less
(less is always used if TOPIC is specified)

General help flags:
-h --help show command line help

```
     --tldr                show command examples with tldr
     --info                show the manual with info
     --man                 show the manual with man
     --version             show version information
     --debug=[1-9]         show this much debug output (default: 1)
     --pager=YN            use a pager when needed ? y/yes (default) or n/no
     --color=YNA --colour  use ANSI color ? y/yes, n/no, or auto (default)
```

This command shows the hledger manual built in to your hledger
executable. It can be useful when offline, or when you prefer the
terminal to a web browser, or when the appropriate hledger manual or
viewers are not installed properly on your system.

By default it chooses the best viewer found in $PATH, trying in this
order: info, man, $PAGER, less, more, stdout. (If a TOPIC is specified,
$PAGER and more are not tried.) You can force the use of info, man, or a
pager with the -i, -m, or -p flags. If no viewer can be found, or if
running non-interactively, it just prints the manual to stdout.

When using info, TOPIC can match either the full heading or a prefix. If
your info --version is < 6, you'll need to upgrade it, eg with
'brew install texinfo' on mac.

When using man or less, TOPIC must match the full heading. For a prefix
match, you can write 'TOPIC.*'.

Examples

$ hledger help -h # show the help command's usage
$ hledger help # show the manual with info, man or $PAGER
$ hledger help 'time periods' # show the manual's "Time periods" topic
$ hledger help 'time periods' -m # use man, even if info is installed
