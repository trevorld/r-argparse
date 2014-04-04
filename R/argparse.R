# Copyright (c) 2012-2014 Trevor L. Davis <trevor.l.davis@stanford.edu>  
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
#' \code{ArgumentParser} crates a parser object that acts as 
#' a wrapper to Python's argparse module
#' 
#' @param ... Arguments cleaned and passed to Pythons argparse.ArgumentParser()
#' @param python_cmd The python executable for \code{argparse} to use.
#'      Must have argparse and json modules (i.e. Python (>= 2.7)).  
#'      Default is \code{python}
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
#' @import rjson
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
ArgumentParser <- function(..., 
                    python_cmd=getOption("python_cmd", find_python_cmd(required_modules = c('argparse', 'json | simplejson')))) {
    if(!is_python_sufficient(python_cmd, required_modules = c('argparse', 'json | simplejson'))) {
        stop(paste(sprintf("python executable %s either is not installed,", python_cmd), 
                "is not on the path, or does not have argparse, json modules",
                "please see INSTALL file"))
    }
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
            # if(.Platform$OS.type == "unix") {
            #     output <- suppressWarnings(system(paste(python_cmd, "2>&1"),
            #                 input=python_code, intern=TRUE))
            # } else {
            #     output <- suppressWarnings(system(paste(python_cmd),
            #             input=python_code, intern=TRUE))
            output <- suppressWarnings(system2(python_cmd,
                        input=python_code, stdout=TRUE, stderr=TRUE))
            if(grepl("^usage:", output[1])) {
                cat(output, sep="\n")
                if(interactive()) stop("help requested") else quit(status=1) 
            } else {
                return(rjson::fromJSON(output))
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
    if(length(argument) > 1) {
        argument <- sprintf("[%s]", paste(argument, collapse=", "))
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
