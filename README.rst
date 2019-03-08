argparse: Command line optional and positional argument parser
==============================================================

.. image:: https://www.r-pkg.org/badges/version/argparse
    :target: https://cran.r-project.org/package=argparse
    :alt: CRAN Status Badge

.. image:: https://travis-ci.org/trevorld/r-argparse.svg?branch=master
    :target: https://travis-ci.org/trevorld/r-argparse
    :alt: Travis-CI Build Status

.. image:: https://ci.appveyor.com/api/projects/status/github/trevorld/r-argparse?branch=master&svg=true
    :target: https://ci.appveyor.com/project/trevorld/r-argparse/branch/master
    :alt: AppVeyor Build Status

.. image:: https://img.shields.io/codecov/c/github/trevorld/r-argparse.svg
    :target: https://codecov.io/github/trevorld/r-argparse?branch=master
    :alt: Coverage Status

.. image:: https://cranlogs.r-pkg.org/badges/argparse
    :target: https://cran.r-project.org/package=argparse
    :alt: RStudio CRAN mirror downloads


``argparse`` is an R package which provides a command line parser to
be used with Rscript to write "#!" shebang scripts that gracefully
accept positional and optional arguments and automatically generate usage.

To install the latest version released on CRAN use the following command::

    > install.packages("argparse")

To install the development version use the following command::

    > remotes::install_github("trevorld/r-argparse")

dependencies
------------

The package has a Python dependency.  
It is easily satisfied if you have Python (version 3.2 or higher) on your PATH.
Read the INSTALL file for more information if this doesn't describe you.

Additionally this package depends on the R packages ``R6``, ``findpython``, and ``jsonlite``.

To run the unit tests you will need the suggested R package ``testthat`` and in
order to build the vignette you will need the suggested R package ``knitr`` 
which in turn probably requires the system tool ``pandoc``::

    sudo apt install pandoc

examples
--------

::

  > library("argparse")
  > parser <- ArgumentParser(description='Process some integers')
  > parser$add_argument('integers', metavar='N', type="integer", nargs='+',
  +                    help='an integer for the accumulator')
  > parser$add_argument('--sum', dest='accumulate', action='store_const',
  +                    const='sum', default='max',
  +                    help='sum the integers (default: find the max)')
  > parser$print_help()
  usage: PROGRAM [-h] [--sum] N [N ...]
  
  Process some integers
  
  positional arguments:
    N           an integer for the accumulator
  
  optional arguments:
    -h, --help  show this help message and exit
    --sum       sum the integers (default: find the max)

Default args for ``ArgumentParser()$parse_args`` are ``commandArgs(TRUE)``
which is what you'd want for an Rscript but not for interactive use::

  > args <- parser$parse_args(c("--sum", "1", "2", "3")) 
  > accumulate_fn <- get(args$accumulate)
  > print(accumulate_fn(args$integers))
  [1] 6

Beginning with version 2.0 ``argparse`` also supports argument groups::

    > parser = ArgumentParser(prog='PROG', add_help=FALSE)
    > group1 = parser$add_argument_group('group1', 'group1 description')
    > group1$add_argument('foo', help='foo help')
    > group2 = parser$add_argument_group('group2', 'group2 description')
    > group2$add_argument('--bar', help='bar help')
    > parser$print_help()
    usage: PROG [-h] [--bar BAR] foo

    optional arguments:
      -h, --help  show this help message and exit

    group1:
      group1 description

      foo         foo help

    group2:
      group2 description

      --bar BAR   bar help

as well as mutually exclusive groups::

    > parser = ArgumentParser(prog='PROG')
    > group = parser$add_mutually_exclusive_group()
    > group$add_argument('--foo', action='store_true')
    > group$add_argument('--bar', action='store_false')
    > parser$parse_args('--foo')
    $bar
    [1] TRUE

    $foo
    [1] TRUE

    > parser$parse_args('--bar')
    $bar
    [1] FALSE

    $foo
    [1] FALSE
    > parser$parse_args(c('--foo', '--bar'))
    Error in .stop(output, "parse error:") : parse error:
    usage: PROG [-h] [--foo | --bar]
    PROG: error: argument --bar: not allowed with argument --foo

and even basic support for sub-commands!::

    > # create the top-level parser
    > parser = ArgumentParser(prog='PROG')
    > parser$add_argument('--foo', action='store_true', help='foo help')
    > subparsers = parser$add_subparsers(help='sub-command help')

    > # create the parser for the "a" command
    > parser_a = subparsers$add_parser('a', help='a help')
    > parser_a$add_argument('bar', type='integer', help='bar help')

    > # create the parser for the "b" command
    > parser_b = subparsers$add_parser('b', help='b help')
    > parser_b$add_argument('--baz', choices='XYZ', help='baz help')
   
    > # parse some argument lists
    > parser$parse_args(c('a', '12'))
    $bar
    [1] 12

    $foo
    [1] FALSE

    > parser$parse_args(c('--foo', 'b', '--baz', 'Z'))
    $baz
    [1] "Z"

    $foo
    [1] TRUE

    > parser$print_help()
    usage: PROG [-h] [--foo] {a,b} ...

    positional arguments:
      {a,b}       sub-command help
        a         a help
        b         b help

    optional arguments:
      -h, --help  show this help message and exit
      --foo       foo help

    > parser_a$print_help()
    usage: PROG a [-h] bar

    positional arguments:
      bar         bar help

    optional arguments:
      -h, --help  show this help message and exit

    > parser_b$print_help()
    usage: PROG b [-h] [--baz {X,Y,Z}]

    optional arguments:
      -h, --help     show this help message and exit
      --baz {X,Y,Z}  baz help
