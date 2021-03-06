log2mail.rb(1) -- monitors (log) files for patterns and reports hits by mail
============================================================================

## SYNOPSIS

`log2mail.rb` (start|stop|status|configtest) [<var>options</var>]:

## DESCRIPTION

`log2mail.rb` helps having an eye on your systems' log files.  It efficiently monitors multiple files and reports as soon as specified (regular expression) patterns match.

On startup, `log2mail.rb` opens all files on the 'watch list' and seeks to EOF.  All new data are parsed about once a minute (see `--sleeptime`). Matched patterns are reported to the configured mail address(es) (see `mailto` configuration option).

Log files are reopened automatically when rotated.

`log2mail.rb` is a pure ruby clone of [log2mail](https://packages.debian.org/squeeze/log2mail) which supports most of the original's features and configuration syntax and adds multiline regular expression matching.  Actually it should be possible to use `log2mail.rb` with your existing configuration you may have for log2mail(8).

## OPTIONS

  * `--config`=<var>path</var>, `-c` <var>path</var>:
    Specifies the configuration file or directory path.  If <var>path</var> is a directory, all files (except such ending in `~` or `#`) are parsed in sorted order. Sorting is by character code, i.e. 0-9 before A-Z followed by a-z.
    Default value: `/etc/log2mail/conf`.
    This can also be set by environment variable `LOG2MAIL_CONF`.

  * `--sleeptime`=<var>seconds</var>:
    Specifies at which interval (in seconds) the log files are parsed.  Default value: 60.

## ENVIRONMENT

`log2mail.rb` uses the environment variable `LOG2MAIL_CONF`, if present (see option `--config`).  The value supplied by option takes precedence.

## CONFIGURATION (OLD-STYLE)

The old-style configuration syntax is directly cloned from log2mail(8)'s behavior and should be mostly compatible.  It may seem a bit awkward first, but this is how it works:  There are two possible top-level 'sections', `defaults` and `file=`<var>path-to-log-file</var> sections. The only statement allowed after a `file=...` section are one or more `pattern=`<var>pattern</var> entries.  After the `pattern=...` there may be one or more `mailto=`<var>single-mail-recipient</var> entries.  After each `mailto=...` there may be options for that recipient.  Also, these options are set from the special `defaults` section, if present (usually it is).

The basic layout looks like follows:

    # comments start with pound sign (aka hash or number sign)

    defaults
      fromaddr   = DEFAULT FROMADDR
      sendtime   = DEFAULT SENDTIME   # seconds
      resendtime = DEFAULT RESENDTIME # seconds
      maxlines   = DEFAULT MAXLINES   # number of lines
      template   = DEFAULT TEMPLATE   # filename or path
      sendmail   = DEFAULT SENDMAIL   # path to executable with arguments
      mailto     = DEFAULT RECIPIENT  # new to log2mail.rb
      # awkward, not recommended, but possible:
      pattern    = DEFAULT PATTERN    # this pattern would be applied to every file
      mailto     = DEFAULT RECIPIENT for previous DEFAULT PATTERN

    # one or more file sections follow
    file = FILENAME

      # each file can have one or more patterns
      pattern = PATTERN

        # each pattern can have one or more mailto recipients
        # each recipient gets its own mailto=... statement
        mailto = MAIL

          # every option NOT stated here is supplied from defaults
          fromaddr   = ...
          sendtime   = ...
          resendtime = ...
          maxlines   = ...
          template   = ...
          sendmail   = ...

    # "include" includes the contents of file at the exact place of the
    # include statement
    include = PATH TO FILE

Note that indentation is done for readability purposes only.  It serves no role syntactically.

Splitting the configuration into multiple files is possible, and convenient when using automation tools to distribute settings.  In opposition to classic log2mail, with `log2mail.rb` it does not matter at which place the `defaults` section is parsed.  Keep in mind though, that later definitions may override earlier ones. In that case a warning is logged.

## CONFIGURATION (NEW-STYLE)

None (yet).  More features might warrant a new configuration syntax.

## SECURITY CONSIDERATIONS

It is neither necessary nor recommended to run this software as root.

## BUGS

Configuration options `sendtime`, `resendtime`, `maxlines` not implemented yet.  Every match produces a single mail which is sent out immediately - which could produce a lot of mails.

## HISTORY

December 2014:
This software is not feature-complete and in pre-release testing.

## AUTHOR

Markus Strauss <<log2mail@dev.sieb.mx>>

## THANKS

Many thanks to Michael Krax for writing the classic **log2mail** in the first place.

## SEE ALSO

Documentation for the classic log2mail software by Michael Krax:

  * log2mail(8), log2mail.conf(5)
  * [Configuration notice from the Debian project]( https://raw.githubusercontent.com/lordlamer/log2mail/e6beb36644ce74639cbc453e664a08ed15f138b9/Configuration)


[SYNOPSIS]: #SYNOPSIS "SYNOPSIS"
[DESCRIPTION]: #DESCRIPTION "DESCRIPTION"
[OPTIONS]: #OPTIONS "OPTIONS"
[ENVIRONMENT]: #ENVIRONMENT "ENVIRONMENT"
[SECURITY CONSIDERATIONS]: #SECURITY-CONSIDERATIONS "SECURITY CONSIDERATIONS"
[BUGS]: #BUGS "BUGS"
[HISTORY]: #HISTORY "HISTORY"
[AUTHOR]: #AUTHOR "AUTHOR"
[THANKS]: #THANKS "THANKS"
[SEE ALSO]: #SEE-ALSO "SEE ALSO"


[log2mail.rb(1)]: log2mail.1.html
