# Copyright (c) 2012-2018 Trevor L. Davis <trevor.l.davis@gmail.com>  
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
#     Copyright (c) 2001-2012 Python Software Foundation; All Rights Reserved
#
# See (inst/)COPYRIGHTS or http://docs.python.org/2/license.html for the full
# Python (GPL-compatible) license stack.

#' Create a command line parser 
#'
#' \code{ArgumentParser} creates a parser object that acts as 
#' a wrapper to Python's argparse module
#' 
#' @param ... Arguments cleaned and passed to Pythons argparse.ArgumentParser()
#' @param python_cmd Python executable for \code{argparse} to use.
#'      Must have argparse and json modules (automatically included Python 2.7 and 3.2+).
#'      If you need Unicode argument support then you must use Python 3.0+.
#'      Default will be to use \code{findpython} package to find suitable Python binary.
#' @return  \code{ArgumentParser} returns a parser object which contains
#'    an \code{add_argument} function to add arguments to the parser,
#'    a \code{parse_args} function to parse command line arguments into
#'    a list, a \code{print_help} and \code{print_usage} function to print
#'    usage information.  See code examples, package vignette, 
#'    and corresponding python module for more information on how to use it.
#'    
#' @references Python's \code{argparse} library, which this package is based on,
#'  is described here: \url{http://docs.python.org/library/argparse.html}
#' @section Acknowledgement: 
#'     A big thanks to Martin Diehl for a bug report.
#'      
#' @import jsonlite
#' @import R6
#' @import findpython
#' @export
#' @examples
#'
#' parser <- ArgumentParser(description='Process some integers')
#' parser$add_argument('integers', metavar='N', type="integer", nargs='+',
#'                    help='an integer for the accumulator')
#' parser$add_argument('--sum', dest='accumulate', action='store_const',
#'                    const='sum', default='max',
#'                    help='sum the integers (default: find the max)')
#' parser$print_help()
#' # default args for ArgumentParser()$parse_args are commandArgs(TRUE)
#' # which is what you'd want for an Rscript but not for interactive use
#' args <- parser$parse_args(c("--sum", "1", "2", "3")) 
#' accumulate_fn <- get(args$accumulate)
#' print(accumulate_fn(args$integers))
## ifelse(.Platform$OS.type == "windows", "python.exe", "python")
ArgumentParser <- function(..., python_cmd=NULL) {
    python_cmd <- .find_python_cmd(python_cmd)
    .assert_python_cmd(python_cmd) 
    initial_python_code <- c("import argparse",
        "try:",
        "    import json",
        "except ImportError:",
        "    import simplejson as json", 
        "",
        sprintf("parser = argparse.ArgumentParser(%s)", 
                convert_..._to_arguments("ArgumentParser", ...)),
        "")
    Parser$new(Code$new(python_cmd, initial_python_code), "parser")
}

Code <- R6Class("Code",
    public = list(
        append = function(new_code) { 
            private$code <- c(private$code, new_code)
        },
        run = function(new_code) {
            code <- c(private$code, new_code)
            suppressWarnings(system2(private$cmd, input=code, 
                                    stdout=TRUE, stderr=TRUE))
        },
        initialize = function(cmd, code=character(0)) {
            private$cmd <- cmd
            private$code <- code
        }
    ),
    private = list(code = NULL, cmd = NULL)
)

Group <- R6Class("Group",
    public = list(
        initialize = function(python_code, name) {
            private$python_code <- python_code
            private$name <- name
        },
        add_argument = function(...) {
            private$python_code$append(sprintf("%s.add_argument(%s)", 
                private$name, convert_..._to_arguments("add_argument", ...)))
            return(invisible(NULL))
        }
    ),
    private = list(python_code = NULL, name = NULL)
)

Subparsers <- R6Class("Subparsers",
    public = list(
        initialize = function(python_code, name) {
            private$python_code <- python_code
            private$name <- name
        },
        add_parser = function(...) {
            parser_name <- paste0(private$name, "_subparser", private$n_subparsers)
            private$n_subparsers <- private$n_subparsers + 1
            private$python_code$append(sprintf("%s = %s.add_parser(%s)",
                            parser_name, private$name,
                            convert_..._to_arguments("add_argument", ...)))
            Parser$new(private$python_code, parser_name)
        }
    ),
    private = list(python_code = NULL, name = NULL, n_subparsers = 0)
)

Parser <- R6Class("Parser",
    public = list(
        parse_args = function(args=commandArgs(TRUE)) {
            new_code <- c(sprintf("args = %s.parse_args([%s])", private$name,
                            paste(sprintf("'%s'", args), collapse=", ")),
                    "print(json.dumps(args.__dict__, sort_keys=True))")
            output <- private$python_code$run(new_code)
            if(grepl("^usage:", output[1])) {
                has_positional_arguments <- any(grepl("^positional arguments:", output))
                has_optional_arguments <- any(grepl("^optional arguments:", output))
                if (has_positional_arguments || has_optional_arguments) {
                    .print_message_and_exit(output, "help requested:")
                } else {
                    .stop(output, "parse error:")
                }
            } else if(grepl("^Traceback", output[1])) {
                .stop(output, "Error: python error")
            } else if (grepl("^SyntaxError: Non-ASCII character", output[2])) {
                message <- paste("Non-ASCII character detected.",
                               "If you wish to use Unicode arguments/options",
                               "please upgrade to Python 3.2+",
                               "Please see file INSTALL for more details.")
                .stop(message, "non-ascii character error:")
            } else if (grepl("^SyntaxError: positional argument follows keyword argument", output[2]) || 
                       grepl("^SyntaxError: non-keyword arg after keyword arg", output[2])) {
                message <- paste("Positional argument following keyword argument.",
                                 "Please note ``ArgumentParser`` only accepts keyword arguments.")
                .stop(message, "syntax error:")
            } else if (grepl("^\\{", output)) {
                args <- jsonlite::fromJSON(paste(output, collapse=""))
                return (args)
            } else { # presumably version number request
                .print_message_and_exit(output, "version requested:")
            }
        },
        print_help = function() {
            cat(private$python_code$run(sprintf("%s.print_help()", private$name)), sep="\n")   
            invisible(NULL)
        },
        print_usage = function() {
            cat(private$python_code$run(sprintf("%s.print_usage()", private$name)), sep="\n")   
            invisible(NULL)
        },
        add_argument = function(...) {
            private$python_code$append(sprintf("%s.add_argument(%s)", private$name,
                            convert_..._to_arguments("add_argument", ...)))
            invisible(NULL)
        },
        add_argument_group = function(...) {
            group_name <- paste0(private$name, "_group", private$n_groups)
            private$n_groups <- private$n_groups + 1
            private$python_code$append(sprintf("%s = %s.add_argument_group(%s)", 
                           group_name, private$name, 
                            convert_..._to_arguments("add_argument", ...)))
            Group$new(private$python_code, group_name)
        },
        add_mutually_exclusive_group = function(required=FALSE) {
            group_name <- paste0(private$name, "_mutually_exclusive_group", 
                                 private$n_mutually_exclusive_groups)
            private$n_mutually_exclusive_groups <- private$n_mutually_exclusive_groups + 1
            private$python_code$append(sprintf("%s = %s.add_mutually_exclusive_group(%s)", 
                           group_name, private$name,
                           ifelse(required, "required=True", "")))
            Group$new(private$python_code, group_name)
        },
        add_subparsers = function(...) {
            subparsers_name <- paste0(private$name, "_subparsers")
            private$python_code$append(sprintf("%s = %s.add_subparsers(%s)",
                            subparsers_name, private$name,
                            convert_..._to_arguments("add_argument", ...)))
            Subparsers$new(private$python_code, subparsers_name)
        },
        initialize = function(python_code, name) {
            private$python_code <- python_code
            private$name <- name
        }
    ),
    private = list(python_code = NULL, name = NULL,
                   n_mutually_exclusive_groups = 0, n_groups = 0)
)


# @param argument argument to be converted from R to Python
convert_argument <- function(argument) {
    if(is.character(argument)) argument <- shQuote(argument, type="sh") 
    if(is.numeric(argument)) argument <- as.character(argument)
    if(is.logical(argument)) argument <- ifelse(argument, 'True', 'False') 
    if(is.null(argument)) argument <- 'None'
    if(length(argument) > 1) {
        argument <- sprintf("(%s)", paste(argument, collapse=", "))
    }
    argument
}

# @param mode Either "add_argument" or "ArgumentParser"
convert_..._to_arguments <- function(mode, ...) {

    argument_list <- list(...)
    argument_names <- names(argument_list)
    if(is.null(argument_names))
        argument_names <- rep("", length(argument_list))
    equals <- ifelse(argument_names == "", "", "=")
    proposed_arguments <- c()
    for(ii in seq_along(argument_list)) {
        name <- argument_names[ii]
        equal <- equals[ii]
        argument <- convert_argument(argument_list[[ii]])
        proposed_arguments <- append(proposed_arguments, 
                                     paste0(name, equal, argument))
    }
    # Make sure types are what Python wants
    if(mode == "add_argument" && any(grepl("type=", proposed_arguments))) {
        ii <- grep("type=", proposed_arguments)
        type <- argument_list[[ii]]
        python_type <- switch(type,
                character = "str",
                double = "float",
                integer = "int",
                logical = "bool",
                stop(paste(sprintf("type %s not supported,", type),
                        "supported types:",
                        "'logical', 'integer', 'double' or 'character'")))
        proposed_arguments[ii] <- sprintf("type=%s", python_type)
        # warn if type set to "logical" and action set to "store" 
        if (python_type == "bool" && any(grepl("action='store'", proposed_arguments)))
            warning("You almost certainly want to use action='store_true' or action='store_false' instead")
                                 
    }
    # Don't put quotes around formatter_class argument
    if(mode == "ArgumentParser" && any(grepl("formatter_class=", proposed_arguments))) {
        ii <- grep("formatter_class=", proposed_arguments)
        formatter_class <- argument_list[[ii]]
        proposed_arguments[ii] <- sprintf("formatter_class=%s", formatter_class)
    }
    # Set right default prog name if not specified, if possible
    # Do last to not screw up other fixes with prog insertion
    if(mode == "ArgumentParser" && all(!grepl("prog=", proposed_arguments))) {
        prog <- get_Rscript_filename()
        if(is.na(prog)) prog <- "PROGRAM"
        proposed_arguments <- c(sprintf("prog='%s'", prog), proposed_arguments)
    }
    return(paste(proposed_arguments, collapse=", "))
}

# Manually copied over from getopt to eliminate it as a dependency
get_Rscript_filename <- function() {
    prog <- sub("--file=", "", grep("--file=", commandArgs(), value=TRUE)[1])
    if( .Platform$OS.type == "windows") { 
        prog <- gsub("\\\\", "\\\\\\\\", prog)
    }
    prog
}

# Internal function to check python cmd is okay
# @param python_cmd Python cmd to use
.assert_python_cmd <- function(python_cmd) {
    if(!is_python_sufficient(python_cmd, required_modules = c('argparse', 'json | simplejson'))) {
        stop(paste(sprintf("python executable %s either is not installed,", python_cmd), 
                "is not on the path, or does not have argparse, json modules",
                "please see INSTALL file"))
    }
}

# Internal function to find python cmd
# @param python_cmd  Python cmd to use
.find_python_cmd <- function(python_cmd) {
    if(is.null(python_cmd)) {
        python_cmd <- getOption("python_cmd")
    }
    if(is.null(python_cmd)) {
        required_modules <- c('argparse', 'json | simplejson')
        did_find_python3 <- can_find_python_cmd(minimum_version='3.0', 
                                                required_modules=required_modules,
                                                silent=TRUE)
        if(did_find_python3) {
            python_cmd <- attr(did_find_python3, "python_cmd")
        } else {
            python_cmd <- find_python_cmd(required_modules=required_modules) #nocov
        }
    }
    python_cmd
}

.stop <- function(message, r_note) {
        stop(paste(r_note, paste(message, collapse="\n"), sep="\n"))
}

# Internal function to print message
.print_message_and_exit <- function(message, r_note, status=0) {
    if (interactive()) {
        .stop(message, r_note) #nocov
    } else {
        cat(message, sep="\n")
        quit(status=0)
    }
}
