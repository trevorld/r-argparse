# Copyright (c) 2012-2021 Trevor L Davis <trevor.l.davis@gmail.com>
#
#  This file is free software: you may copy, redistribute and/or modify it
#  under the terms of the GNU General Public License as published by the
#  Free Software Foundation, either version 2 of the License, or (at your
#  option) any later version.
#
#  This file is distributed in the hope that it will be useful, but
#  WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#  General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# This file incorporates work from the argparse module in Python 2.7.3.
#
#     Copyright (c) 1990-2012 Python Software Foundation; All Rights Reserved
#
# See (inst/)COPYRIGHTS or http://docs.python.org/2/license.html for the full
# Python (GPL-compatible) license stack.
test_that("print_help works as expected", {
    skip_if_not(detects_python())
    parser <- ArgumentParser(description = "Process some integers.")
    expect_output(parser$print_help(), "usage:")
    expect_output(parser$print_help(), "optional arguments:|options:")
    expect_output(parser$print_help(), "Process some integers.")
    expect_output(parser$print_usage(), "usage:")
    expect_true(grepl("Process some integers.", parser$format_help()))
    expect_true(grepl("usage:", parser$format_usage()))

    # Request/bug by PlasmaBinturong
    parser$add_argument("integers", metavar = "N", type = "integer", nargs = "+",
                       help = "an integer for the accumulator")
    expect_error(capture.output(parser$parse_args(), "parse error"))

    if (!interactive()) skip("interactive() == FALSE")
    expect_error(capture.output(parser$parse_args("-h")), "help requested")
})

test_that("convert_argument works as expected", {
    skip_if_not(detects_python())
    expect_equal(convert_argument("foobar"), '"""foobar"""')
    expect_equal(convert_argument(14.9), "14.9")
    expect_equal(convert_argument(c(12.1, 14.9)), "(12.1, 14.9)")
    expect_equal(convert_argument(c("a", "b")), '("""a""", """b""")')
})

test_that("convert_..._to_arguments works as expected", {
    skip_if_not(detects_python())
    # test in mode "add_argument"
    c.2a <- function(...) convert_..._to_arguments("add_argument", ...)
    waz <- "wazzup"
    expect_equal(c.2a(foo = "bar", hello = "world"), 'foo="""bar""", hello="""world"""')
    expect_equal(c.2a(foo = "bar", waz), 'foo="""bar""", """wazzup"""')
    expect_equal(c.2a(type = "character"), "type=str")
    expect_equal(c.2a(default = TRUE), "default=True")
    expect_equal(c.2a(default = 3.4), "default=3.4")
    expect_equal(c.2a(default = "foo"), 'default="""foo"""')
    # test in mode "ArgumentParser"
    c.2a <- function(...) convert_..._to_arguments("ArgumentParser", ...)
    expect_match(c.2a(argument_default = FALSE), "argument_default=False")
    expect_match(c.2a(argument_default = 30), "argument_default=30")
    expect_match(c.2a(argument_default = "foobar"), 'argument_default="""foobar"""')
    expect_match(c.2a(foo = "bar"), "^prog='PROGRAM'|^prog='test-argparse.R'")
    expect_match(c.2a(formatter_class = "argparse.ArgumentDefaultsHelpFormatter"),
                 "formatter_class=argparse.ArgumentDefaultsHelpFormatter")
})

test_that("add_argument works as expected", {
    skip_if_not(detects_python())
    parser <- ArgumentParser()
    parser$add_argument("integers", metavar = "N", type = "integer", nargs = "+",
                       help = "an integer for the accumulator")
    parser$add_argument("--sum", dest = "accumulate", action = "store_const",
                       const = "sum", default = "max",
                       help = "sum the integers (default: find the max)")
    arguments <- parser$parse_args(c("--sum", "1", "2"))
    f <- get(arguments$accumulate)
    expect_output(parser$print_help(), "sum the integers")
    expect_equal(arguments$accumulate, "sum")
    expect_equal(arguments$integers, c(1, 2))
    expect_equal(f(arguments$integers), 3)
    expect_error(parser$add_argument("--foo", type = "boolean"))

    # Bug found by Martin Diehl
    parser$add_argument("--label", type = "character", nargs = 2,
        dest = "label", action = "store", default = c("a", "b"), help = "label for X and Y axis")
    suppressWarnings(parser$add_argument("--bool", type = "logical", nargs = 2,
        dest = "bool", action = "store", default = c(FALSE, TRUE)))
    arguments <- parser$parse_args(c("--sum", "1", "2"))
    expect_equal(arguments$label, c("a", "b"))
    expect_equal(arguments$bool, c(FALSE, TRUE))

    # Bug found by Oliver Dreschel (@oliverdreschel)
    p <- ArgumentParser()
    p$add_argument('--listlab', type='character', help='This is a helpstring,"Containing Quotes"')
    expect_equal(p$parse_args()$listlab, NULL)

    # Use R casting of logicals
    p <- ArgumentParser()
    p$add_argument("--bool", type = "logical", action = "store")
    expect_false(p$parse_args("--bool=F")$bool)
    expect_true(p$parse_args("--bool=T")$bool)
    expect_error(p$parse_args("--bool=1")$bool)

    # Use R casting of logicals with type append
    p <- ArgumentParser()
    p$add_argument("--bool", type = "logical", action = "append")
    expect_equal(p$parse_args(c("--bool=F", "--bool=true", "--bool=T"))$bool,
                 c(FALSE, TRUE, TRUE))
    expect_error(p$parse_args(c("--bool=F", "--bool=1", "--bool=T"))$bool)

    # Bug/Feature request found by Hyunsoo Kim
    p <- ArgumentParser()
    p$add_argument("--test", default = NULL)
    expect_equal(p$parse_args()$test, NULL)

    # Feature request of Paul Newell
    parser <- ArgumentParser()
    parser$add_argument("extent", nargs = 4, type = "double", metavar = c("e1", "e2", "e3", "e4"))
    expect_output(parser$print_usage(), "usage: PROGRAM \\[-h\\] e1 e2 e3 e4")

    # Bug report by Claire D. McWhite
    parser <- ArgumentParser()
    parser$add_argument("-o", "--output_filename", required = FALSE, default = "outfile.txt")
    expect_equal(parser$parse_args()$output_filename, "outfile.txt")

    parser <- ArgumentParser()
    parser$add_argument("-o", "--output_filename", required = TRUE, default = "outfile.txt")
    expect_error(parser$parse_args())
})

test_that("version flags works as expected", {
    skip_if_not(detects_python())
    # Feature request of Dario Beraldi
    parser <- ArgumentParser()
    parser$add_argument("-v", "--version", action = "version", version = "1.0.1")
    if (interactive()) {
        expect_error(parser$parse_args("-v"), "version requested:\n1.0.1")
        expect_error(parser$parse_args("--version"), "version requested:\n1.0.1")
    }

    # empty list
    parser <- ArgumentParser()
    el <- parser$parse_args()
    expect_true(is.list(el))
    expect_equal(length(el), 0)
})

test_that("parse_known_args() works as expected", {
    skip_if_not(detects_python())
    parser <- ArgumentParser()
    parser$add_argument("-o", "--output_filename", default = "outfile.txt")
    a_r <- parser$parse_known_args(c("-o", "foobar.txt", "-n", "4"))
    expect_equal(a_r[[1]]$output_filename, "foobar.txt")
    expect_equal(a_r[[2]], c("-n", "4"))

})

test_that("parse_intermixed_args() works as expected", {
    skip_if_not(detects_python(minimum_version = '3.7'))
    parser <- ArgumentParser()
    parser$add_argument('--foo')
    parser$add_argument('cmd')
    parser$add_argument('rest', nargs='*', type='integer')
    args <- strsplit('doit 1 --foo bar 2 3', ' ')[[1]]
    args <- parser$parse_intermixed_args(args)
    expect_equal(args$cmd, 'doit')
    expect_equal(args$foo, 'bar')
    expect_equal(args$rest, 1:3)

    args <- strsplit('doit 1 --foo bar 2 3 -n 4', ' ')[[1]]
    a_r <- parser$parse_known_intermixed_args(args)
    expect_equal(a_r[[1]]$cmd, 'doit')
    expect_equal(a_r[[1]]$foo, 'bar')
    expect_equal(a_r[[1]]$rest, 1:3)
    expect_equal(a_r[[2]], c('-n', '4'))
})

test_that("set_defaults() works as expected", {
    skip_if_not(detects_python())
    parser <- ArgumentParser()
    parser$set_defaults(bar=42)
    args <- parser$parse_args(c())
    expect_equal(args$bar, 42)

    # expect_equal(parser$get_default("bar"), 42)
})

test_that("ArgumentParser works as expected", {
    skip_if_not(detects_python())
    parser <- ArgumentParser(prog = "foobar", usage = "%(prog)s arg1 arg2")
    parser$add_argument("--hello", dest = "saying", action = "store_const",
            const = "hello", default = "bye",
            help = "%(prog)s's saying (default: %(default)s)")
    expect_output(parser$print_help(), "foobar arg1 arg2")
    expect_output(parser$print_help(), "foobar's saying \\(default: bye\\)")
    expect_error(ArgumentParser(python_cmd = "foobar"))
    skip_if_not(interactive(), "Skip passing -h if not interactive()")
    # Bug report by George Chlipala
    expect_error(ArgumentParser()$parse_args("-h"), "help requested")
    expect_error(ArgumentParser(add_help = TRUE)$parse_args("-h"), "help requested")
    expect_error(ArgumentParser(add_help = FALSE)$parse_args("-h"), "unrecognized arguments")
})

test_that("parse_args() works as expected", {
    skip_if_not(detects_python())
    parser <- ArgumentParser("foobar", usage = "%(prog)s arg1 arg2")
    parser$add_argument("--hello", dest = "saying", action = "store", default = "foo",
            choices = c("foo", "bar"),
            help = "%(prog)s's saying (default: %(default)s)")
    expect_equal(parser$parse_args("--hello=bar"), list(saying = "bar"))
    expect_error(parser$parse_args("--hello=what"))

    # Unhelpful error message found by Martí Duran Ferrer
    parser <- ArgumentParser()
    parser$add_argument("M", required = TRUE, help = "Test")
    expect_error(parser$parse_args(), "python error")


    # bug reported by Dominik Mueller
    p <- argparse::ArgumentParser()
    p$add_argument("--int", type = "integer")
    p$add_argument("--double", type = "double")
    p$add_argument("--character", type = "character")
    p$add_argument("--numeric", type = "numeric")

    input <- "1"
    args <- p$parse_args(c("--int", input,
                           "--double", input,
                           "--character", input,
                           "--numeric", input))
    expect_equal(class(args$int), "integer")
    expect_equal(class(args$double), "numeric")
    expect_equal(class(args$character), "character")
    expect_equal(class(args$numeric), "numeric")
    expect_equal(args$int, as.integer(1.0))
    expect_equal(args$double, 1.0)
    expect_equal(args$character, "1")
    expect_equal(args$numeric, 1.0)

    # bug reported by Arthur Gilly
    parser <- ArgumentParser(description="Description of tool.\nAuthor information.")
    expect_true(is.list(parser$parse_args()))

    # Bug found by Taylor Pospisil
    skip_on_os("windows") # Didn't work on Github Actions Windows
    skip_on_cran() # Once gave an error on win-builder
    parser <- ArgumentParser()
    parser$add_argument("--lotsofstuff", type = "character", nargs = "+")
    args <- parser$parse_args(c("--lotsofstuff", rep("stuff", 1000)))
    expect_equal(args$lotsofstuff, rep("stuff", 1000))

    # Bug found by @miker985
    test_that("we can action = 'append' with a default list", {
        parser <- argparse::ArgumentParser()
        parser$add_argument("--test-dim", dest = "dims", action = "append",
                            default = c("year", "sex", "age"))
        args <- parser$parse_args(c("--test-dim", "race"))

        expect_equal(args$dims, c("year", "sex", "age", "race"))
    })
})

# Bug found by Erick Rocha Fonseca
test_that("Unicode support works if Python and OS sufficient", {
    skip_if_not(detects_python())
    skip_on_os("windows") # Didn't work on win-builder
    skip_on_cran() # Didn't work on Debian Clang
    did_find_python3 <- findpython::can_find_python_cmd(minimum_version = "3.0",
                                    required_modules = c("argparse", "json|simplejson"),
                                    silent = TRUE)
    if (!did_find_python3) skip("Need at least Python 3.0 for Unicode support")
    p <- ArgumentParser(python_cmd = attr(did_find_python3, "python_cmd"))
    p$add_argument("name")
    expect_equal(p$parse_args("\u8292\u679C"), list(name = "\u8292\u679C")) # 芒果
})

test_that("Unicode attempt throws error if Python or OS not sufficient", {
    skip_if_not(detects_python())
    skip_on_os("windows") # Didn't work on AppVeyor
    skip_on_cran() # Didn't work on Debian Clang
    did_find_python2 <- findpython::can_find_python_cmd(maximum_version = "2.7",
                                    required_modules = c("argparse", "json|simplejson"),
                                    silent = TRUE)
    if (!did_find_python2) skip("Need Python 2 to guarantee throws Unicode error")
    p <- ArgumentParser(python_cmd = attr(did_find_python2, "python_cmd"))
    p$add_argument("name")
    expect_error(p$parse_args("\u8292\u679C"), "Non-ASCII character detected.") # 芒果

})

# Mutually exclusive groups is a feature request by Vince Reuter
test_that("mutually exclusive groups works as expected", {
    skip_if_not(detects_python())
    parser <- ArgumentParser(prog = "PROG")
    group <- parser$add_mutually_exclusive_group()
    group$add_argument("--foo", action = "store_true")
    group$add_argument("--bar", action = "store_false")
    arguments <- parser$parse_args("--foo")
    expect_true(arguments$bar)
    expect_true(arguments$foo)
    arguments <- parser$parse_args("--bar")
    expect_false(arguments$bar)
    expect_false(arguments$foo)
    expect_error(parser$parse_args(c("--foo", "--bar")), "argument --bar: not allowed with argument --foo")

    parser <- ArgumentParser(prog = "PROG")
    group <- parser$add_mutually_exclusive_group(required = TRUE)
    group$add_argument("--foo", action = "store_true")
    group$add_argument("--bar", action = "store_false")
    expect_error(parser$parse_args(character()), " one of the arguments --foo --bar is required")
})

# argument groups is a feature request by Dario Beraldi
test_that("add argument group works as expected", {
    skip_if_not(detects_python())
    parser <- ArgumentParser(prog = "PROG", add_help = FALSE)
    group1 <- parser$add_argument_group("group1", "group1 description")
    group1$add_argument("foo", help = "foo help")
    group2 <- parser$add_argument_group("group2", "group2 description")
    group2$add_argument("--bar", help = "bar help")
    expect_output(parser$print_help(), "group1 description")
    expect_output(parser$print_help(), "group2 description")
})

# subparser support is a feature request by Zebulun Arendsee
test_that("sub parsers work as expected", {
    skip_if_not(detects_python())
    # create the top-level parser
    parser <- ArgumentParser(prog = "PROG")
    parser$add_argument("--foo", action = "store_true", help = "foo help")
    subparsers <- parser$add_subparsers(help = "sub-command help")

    # create the parser for the "a" command
    parser_a <- subparsers$add_parser("a", help = "a help")
    parser_a$add_argument("bar", type = "integer", help = "bar help")

    # create the parser for the "b" command
    parser_b <- subparsers$add_parser("b", help = "b help")
    parser_b$add_argument("--baz", choices = "XYZ", help = "baz help")

    # parse some argument lists
    arguments <- parser$parse_args(c("a", "12"))
    expect_equal(arguments$bar, 12)
    expect_equal(arguments$foo, FALSE)
    arguments <- parser$parse_args(c("--foo", "b", "--baz", "Z"))
    expect_equal(arguments$baz, "Z")
    expect_equal(arguments$foo, TRUE)
    expect_output(parser$print_help(), "sub-command help")
    expect_output(parser_a$print_help(), "usage: PROG a")
    expect_output(parser_b$print_help(), "usage: PROG b")
})

test_that("Paths that quit()", {
    skip_if_not(detects_python())
    skip_on_os("windows")
    cmd <- file.path(R.home(), "bin/Rscript")
    skip_if(Sys.which(cmd) == "")

    expect_equal(system2(cmd, c("scripts/test_version.R", "--version"), stdout = TRUE),
                 "1.0.1")

    help <- system2(cmd, c("scripts/test_help.R", "--help"),
                    stdout = TRUE, stderr = TRUE)
    expect_equal("usage: scripts/test_help.R [-h]", help[1])
    expect_equal("  -h, --help  show this help message and exit", help[4])
})
