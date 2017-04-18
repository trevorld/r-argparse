argparse: Command line optional and positional argument parser.
===============================================================

.. image:: http://www.r-pkg.org/badges/version/argparse
    :target: http://cran.r-project.org/package=argparse
    :alt: CRAN Status Badge

.. image:: https://travis-ci.org/trevorld/argparse.png?branch=master
    :target: http://travis-ci.org/trevorld/argparse
    :alt: Build Status

.. image:: https://img.shields.io/codecov/c/github/trevorld/argparse.svg
    :target: https://codecov.io/github/trevorld/argparse?branch=master
    :alt: Coverage Status

A command line parser to
be used with Rscript to write "#!" shebang scripts that gracefully
accept positional and optional arguments and automatically generate usage.

To install the development version use the following command::

    devtools::install_github("argparse", "trevorld")

dependencies
============

The package has a Python dependency.  Read the INSTALL file for more
information.  Essentially the Python binary must have both the ``argparse`` and
``json`` modules which is are automatically included for Python 2.7 and Python
3.2+ and can be manually installed for Python 2.6 and Python 2.5.

Additionally this package depends on the R packages ``proto``, ``findpython``,
``getopt``, and ``rjson``.

To run the unit tests you will need the suggested R package ``testthat`` and in
order to build the vignette you will need the suggested R package ``knitr`` 
which in turn probably requires the system tool ``pandoc``::

    sudo pip install pandoc

example
=======

::

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
