---
title: "Effortless Exception Logging in R: loggit!"
author: "Ryan Price <ryapric@gmail.com>"
date: "2018-02-21"
output:
  html_document:
    keep_md: TRUE
---



This package is designed for anyone who has written their own package or
analysis functions that already use basic exception handling by way of base R's
`message()`, `warning()`, and `stop()`. The loggit package *masks* base R's
versions of these functions, but slots in a logging function (`loggit()`) just
before the exception handler executes. Since these functions maintain identical
functionality to their base equivalents, there is no need for any change in
your existing code, if you have already written handlers. Just install &
load/import `loggit`, tell R where to store your log file on startup, and
instantly have your exceptions recorded.

The included `loggit()` function is also very flexible on its own, and allows
for any number of custom fields to be added to your logs, in addition to
maintaining the aforementioned functionality.

This package was inspired by a colleague's suggestion of how we could log our
ETL workflow results in R, as well as the
[rlogging](https://github.com/mjkallen/rlogging) package. When we looked at how
`rlogging` was doing this, we felt that we could expand upon it and make it
more flexible, system-portable, and with even less user effort. As opposed to
other packages like [log4r](http://cran.r-project.org/package=log4r),
[futile.logger](http://cran.r-project.org/package=futile.logger) and
[logging](http://cran.r-project.org/package=logging), which may allow for more
powerful logs in some cases, we wanted to make great logging "out of sight, out
of mind"; at least until your boss asks for those ETL logs!

<br>

### Features

R has a selection of built-in functions for handling different *exceptions*, or
special cases where diagnostic messages are provided, and/or function execution
is halted because of an error. However, R itself provides nothing to record
this diagnostic post-hoc; useRs are left with what is printed to the console as
their only means of analyzing the what-went-wrong of their code. There are some
slightly hacky ways of capturing this console output, such as `sink`ing to a
text file, repetitively `cat`ing identical exception messages that are passed
to existing handler calls, etc. But there are two main issues with these
approaches:

1. The console output is not at all easy to parse, so that a user can quickly
identify the causes of failure without manually scanning through it

2. Even if the user tries to structure a text file output, they would likely
have to ensure consistency in that output across all their work, and there is
still the issue of parsing that text file into a familiar, usable format

Enter: [JSON](https://www.json.org/)

JSON is a lightweight, portable (standardized) data format that is easy to read
and write by both humans and machines. An excerpt from the introduction of the
JSON link above:

"JSON (JavaScript Object Notation) is a lightweight data-interchange format. It
is easy for humans to read and write. It is easy for machines to parse and
generate. It is based on a subset of the JavaScript Programming Language,
Standard ECMA-262 3rd Edition - December 1999. JSON is a text format that is
completely language independent but uses conventions that are familiar to
programmers of the C-family of languages, including C, C++, C#, Java,
JavaScript, Perl, Python, and many others. These properties make JSON an ideal
data-interchange language."

Basically, you can think of JSON objects like you would think of `list`s in R:
a set of key-value pairs, with the option to nest lists within other lists.
This makes JSON not only as powerful as R's lists, but it allows this
nested-list functionality to be translated to other software, and let them
handle them just as easily! As such, JSON is the default log file output type
in the `loggit` package. You can manipulate & review JSON objects in R by way
of the [jsonlite](https://cran.r-project.org/package=jsonlite) package.

<br>

### How to Use

Chances are that if you've read this far, you're familiar with R's exception
handlers. If so, then there are only two other things that you need to know in
order to use `loggit`:

1. As per CRAN policies, _**a package cannot write**_ to a user's "home
filespace" without approval. Therefore, you need to set the log file before any
logs are written to disk, using `setLogFile(logfile)` (I recommend in your
working directory, and naming it "loggit.json"). If you are using loggit in
your own package, you can wrap this in a call to `.onLoad()`, so that logging
is set on package load. If not, then make the set call as soon as possible
(e.g. at the top of your script(s), right after your calls to `library()`);
otherwise, no logs will be written to persistent storage!

1. The logs are output to your log file each time an exception is raised, or
when `loggit()` is called, and you can review it there. The fields supplied by
default are:

- `timestamp`: when the exception was raised
- `log_lvl`: the "level" of the exception (INFO, WARN, ERROR, or custom)
- `log_msg`: the diagnostic message generated by R
- `log_detail`: additional exception details you can pass to the exception
handlers, though not necessary to supply (will be filled with "" if not
supplied).

#### _**That's it!**_

<br>

However, if you want more control, or care a bit more about the details:

While this package automatically masks the base handlers, the `loggit` function
that they call is also exported for use, if so desired. This allows you to log
arbitrary things as much or as little as you see fit. The `loggit` function is
called as: `loggit(log_lvl, log_msg, log_detail, ...)`. The argument you may
not recognize is `...`, which is supplied as *named* vectors (each of length
one) providing any additional field names you would like to log:

    loggit("INFO", "This is a message", but_maybe = "you want more fields?", sure = "why not?", like = 2, or = 10, what = "ever")

Since `loggit()` calls
[dplyr::bind_rows()](http://dplyr.tidyverse.org/reference/bind.html) behind the
scenes, you can add as many fields of any type as you want without any append
issues or errors. Note, however, that this means that any future calls to
`loggit()` for the same custom fields, require that those fields are spelled
the same as originally provided. If not, then the misspelling will cause
*another* field to be created, and (the `data frame` version of) your log file
will look like this:

    > loggit("INFO", "Result 1", scientist = "Ryan")
    > loggit("INFO", "Result 2", scietist = "Thomas")

                timestamp log_lvl  log_msg  log_detail scientist scietist
    1 2018-02-13 18:01:32    INFO Result 1          ""      Ryan     <NA>
    2 2018-02-13 18:02:32    INFO Result 2          ""      <NA>   Thomas

Also note that *you __do not always__ have to supply a custom field* once it is
created; thanks, JSON and `dplyr`!

    > loggit("INFO", "Result 1", scientist = "Ryan")
    > loggit("INFO", "Result 2", scientist = "Thomas")
    > loggit("INFO", "Result 3")

                timestamp log_lvl  log_msg  log_detail     scientist
    1 2018-02-13 18:01:32    INFO Result 1          ""          Ryan
    2 2018-02-13 18:02:32    INFO Result 2          ""        Thomas
    3 2018-02-13 18:03:32    INFO Result 3          ""          <NA>

As of v1.0.1, you can also supply a `data.frame` or `tbl_df` as the *sole*
argument to `loggit()`, and the whole data frame will be logged. To do this,
you must specify at least "log_lvl" and "log_msg" as column names in the data
frame; you can then supply as many additional columns as you wish, just like is
using `...`. Note that the timestamp is still handled by `loggit()`.

<br>

Also, other control options:

- You can control the output name & location of the log file using
    `setLogFile(logfile)`. `loggit` *will not* write to disk unless an
    exception is raised, or unless `loggit()` is called, but you should specify
    this change early, if desired. You can see the current log file path at
    package attachment, or by calling `getLogFile()`.
- If for any reason you do not want to log the output to a log file, you can
    set each handler's `.loggit` argument to `FALSE`. This will eventually be a
    global option that the user can set, and leave the handlers without the
    argument. If using `loggit` in your own package, you can just
    `importFrom(loggit, function)` the handlers that you _do_ want.
- You can control the format of the timestamp in the logs; it defaults to ISO
    format `"%Y-%m-%d %H:%M:%S"`, but you may set it yourself using
    `setTimestampFormat()`. Note that this format is passed to `format.Date()`,
    so the supplied format needs to be valid.

<br>

### Note on *What* Gets Logged

Note that this package does not mask the handler functions included in *other*
packages, _**including in base R**_; for example, running the following will
throw an error as usual, but *will not* write to the log file:

    > 2 + "a"
    Error in 2 + "a" : non-numeric argument to binary operator
    > dplyr::left_join(data.frame(a = 1), data.frame(b = 2))
    Error: `by` required, because the data sources have no common variables
    > # Did loggit write these exception messages to the logfile?
    > file.exists(getLogFile())
    [1] FALSE

This is integral to how R works with packages, and is by design; it has to do
with [namespaces](http://r-pkgs.had.co.nz/namespace.html), which is how R looks
for *what* to do when you ask it to do something. Basically, if a package you
use doesn't have `loggit` in its `NAMESPACE` file, then its internal exception
handlers won't be masked by `loggit`.

If you really wish to have *all* exception messages logged by `loggit`, please
be patient, as this feature is in the works.

<br>

### Installation

You can install the latest CRAN release of `loggit` via
`install.packages("loggit")`.

Or, to get the latest development version from GitHub --

Via [devtools](https://github.com/hadley/devtools):

    devtools::install_github("ryapric/loggit")

Or, clone & build from source:

    cd /path/to/your/repos
    git clone https://github.com/ryapric/loggit.git loggit
    R CMD INSTALL loggit

To use the most recent development version of `loggit` in your own package, you
can include it in your `Remotes:` field in your DESCRIPTION file:

    Remotes: github::ryapric/loggit

Note that packages being submitted to CRAN *cannot* have a `Remotes` field.
Refer
[here](https://cran.r-project.org/web/packages/devtools/vignettes/dependencies.html)
for more info.

<br>

### License

MIT
