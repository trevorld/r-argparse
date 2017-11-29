# Copyright (c) 2012-2017 Trevor L. Davis <trevor.l.davis@stanford.edu>  
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
#' @import proto
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
    python_code = c("import argparse",
    "try:",
    "    import json",
    "except ImportError:",
    "    import simplejson as json", 
    "",
    sprintf("parser = argparse.ArgumentParser(%s)", 
            convert_..._to_arguments("ArgumentParser", ...)),
    "")
    proto(expr = {
        python_code = python_code
        parse_args = function(., args=commandArgs(TRUE)) {
            python_code <- c(.$python_code, 
                    sprintf("args = parser.parse_args([%s])",
                            paste(sprintf("'%s'", args), collapse=", ")),
                    "print(json.dumps(args.__dict__, sort_keys=True))")
            output <- suppressWarnings(system2(python_cmd,
                        input=python_code, stdout=TRUE, stderr=TRUE))
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
            } else if (grepl("^SyntaxError: positional argument follows keyword argument", output[2])) {
                message <- paste("Positional argument following keyword argument.",
                                 "Please note ``ArgumentParser`` only accepts keyword arguments.")
                .stop(message, "syntax error:")
            } else if (grepl("^\\{", output)) {
                args <- jsonlite::fromJSON(paste(output, collapse=""))
                return (args)
            } else { # presumably version number request
                .print_message_and_exit(output, "version requested:")
            }
        }
        print_help <- function(.) {
            python_code <- c(.$python_code, "parser.print_help()")
            cat(system(python_cmd, input=python_code, intern=TRUE), sep="\n")   
            invisible(NULL)
        }
        print_usage <- function(.) {
            python_code <- c(.$python_code, "parser.print_usage()")
            cat(system(python_cmd, input=python_code, intern=TRUE), sep="\n")   
            invisible(NULL)
        }
        add_argument = function(., ...) {
            .$python_code <- c(.$python_code,
                    sprintf("parser.add_argument(%s)",
                            convert_..._to_arguments("add_argument", ...)))
            return(invisible(NULL))
        }
    })
}

# @param argument argument to be converted from R to Python
convert_argument <- function(argument) {
    if(is.character(argument)) argument <- shQuote(argument, type="sh") 
    if(is.logical(argument)) argument <- ifelse(argument, 'True', 'False') 
    if(is.null(argument)) argument <- 'None'
    if(length(argument) > 1) {
        argument <- sprintf("(%s)", paste(argument, collapse=", "))
    }
    argument
}

# @param mode Either "add_argument" or "ArgumentParser"
#' @import getopt
convert_..._to_arguments <- function(mode, ...) {

    argument_list <- list(...)
    argument_names <- names(argument_list)
    equals <- ifelse(argument_names == "", "", "=")
    arguments <- shQuote(as.character(argument_list), type="sh")
    proposed_arguments <- paste(argument_names, equals, arguments, sep="")
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
    # make sure nargs are what python wants
    if(mode == "add_argument" && any(grepl("nargs=", proposed_arguments))) {
        ii <- grep("nargs=", proposed_arguments)
        nargs <- argument_list[[ii]]
        if(is.numeric(nargs)) {
            nargs <- as.character(nargs)
        } else {
            nargs <- shQuote(nargs, type="sh")
        }
        proposed_arguments[ii] <- sprintf("nargs=%s", nargs)
    }
    if(mode == "add_argument" && any(grepl("choices=", proposed_arguments))) {
        ii <- grep("choices=", proposed_arguments)
        choices <- convert_argument(argument_list[[ii]])
        proposed_arguments[ii] <- sprintf("choices=%s", choices)
    }
    # Fix bug reported by Claire D McWhite
    if(mode == "add_argument" && any(grepl("required=", proposed_arguments))) {
        ii <- grep("required=", proposed_arguments)
        required <- convert_argument(argument_list[[ii]])
        proposed_arguments[ii] <- sprintf("required=%s", required)
    }
    # Feature request from Paul Newell
    if(mode == "add_argument" && any(grepl("metavar=", proposed_arguments))) {
        ii <- grep("metavar=", proposed_arguments)
        metavar <- convert_argument(argument_list[[ii]])
        proposed_arguments[ii] <- sprintf("metavar=%s", metavar)
    }
    # Make defaults are what Python wants, if specified
    default_string <- switch(mode,
           add_argument = "default=", 
           ArgumentParser = "argument_default=",
           stop(sprintf("Unknown mode %s", mode)))
    if(any(grepl(default_string, proposed_arguments))) {
        ii <- grep(default_string, proposed_arguments)
        default <- argument_list[[ii]]
        default <- convert_argument(default)
        proposed_arguments[ii] <- sprintf("%s%s", default_string, default)
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
                                                required_modules=required_modules)
        if(did_find_python3) {
            python_cmd <- attr(did_find_python3, "python_cmd")
        } else {
            python_cmd <- find_python_cmd(required_modules=required_modules)
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
        .stop(message, r_note)
    } else {
        cat(message, sep="\n")
        quit(status=0)
    }
}
