# Copyright (c) 2012-2013 Trevor L Davis <trevor.l.davis@stanford.edu>
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
context("Unit tests")

options(python_cmd = find_python_cmd())
context("print_help")
test_that("print_help works as expected", {
    parser <- ArgumentParser(description="Process some integers.")
    expect_output(parser$print_help(), "usage:")
    expect_output(parser$print_help(), "optional arguments:")
    expect_output(parser$print_help(), "Process some integers.")
    expect_output(parser$print_usage(), "usage:")
    # expect_output(parser$parse_args("-h"), "usage:")
    # expect_output(parser$parse_args("--help"), "options:")
})
context("convert_..._to_arguments")
test_that("convert_..._to_arguments works as expected", {
    # test in mode "add_argument"
    c.2a <- function(...) { convert_..._to_arguments("add_argument", ...) }
    waz <- "wazzup"
    expect_equal(c.2a(foo="bar", hello="world"), "foo='bar', hello='world'")
    expect_equal(c.2a(foo="bar", waz), "foo='bar', 'wazzup'")
    expect_equal(c.2a(type="character"), "type=str")
    expect_equal(c.2a(default=TRUE), "default=True")
    expect_equal(c.2a(default=3.4), "default=3.4")
    expect_equal(c.2a(default="foo"), "default='foo'")
    # test in mode "ArgumentParser"
    c.2a <- function(...) { convert_..._to_arguments("ArgumentParser", ...) }
    expect_match(c.2a(argument_default=FALSE), "argument_default=False")
    expect_match(c.2a(argument_default=30), "argument_default=30")
    expect_match(c.2a(argument_default="foobar"), "argument_default='foobar'")
    expect_match(c.2a(foo="bar"), "^prog='PROGRAM'|^prog='test-argparse.R'")
})

context("add_argument")
test_that("add_argument works as expected", {
    parser <- ArgumentParser()
    parser$add_argument('integers', metavar='N', type="integer", nargs='+',
                       help='an integer for the accumulator')
    parser$add_argument('--sum', dest='accumulate', action='store_const',
                       const='sum', default='max',
                       help='sum the integers (default: find the max)')
    arguments <- parser$parse_args(c("--sum", "1", "2"))
    f <- get(arguments$accumulate)
    expect_output(parser$print_help(), "sum the integers")
    expect_equal(arguments$accumulate, "sum")
    expect_equal(arguments$integers, c(1,2))
    expect_equal(f(arguments$integers), 3)
    expect_error(parser$add_argument("--foo", type="boolean"))

    # Bug found by Martin Diehl
    parser$add_argument('--label',type='character',nargs=2,
        dest='label',action='store',default=c("a","b"),help='label for X and Y axis')
    parser$add_argument('--bool',type='logical',nargs=2,
        dest='bool',action='store',default=c(FALSE, TRUE))
    arguments <- parser$parse_args(c("--sum", "1", "2"))
    expect_equal(arguments$label, c("a", "b"))
    expect_equal(arguments$bool, c(FALSE, TRUE))
})

context("ArgumentParser")
test_that("ArgumentParser works as expected", {
    parser <- ArgumentParser(prog="foobar", usage="%(prog)s arg1 arg2")
    parser$add_argument('--hello', dest='saying', action='store_const',
            const='hello', default='bye', 
            help="%(prog)s's saying (default: %(default)s)")
    expect_output(parser$print_help(), "foobar arg1 arg2")
    expect_output(parser$print_help(), "foobar's saying \\(default: bye\\)")
    expect_error(ArgumentParser(python_cmd="foobar"))
})
