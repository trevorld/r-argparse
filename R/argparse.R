# Copyright (c) 2012-2024 Trevor L. Davis <trevor.l.davis@gmail.com>
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
#' `ArgumentParser()` creates a parser object that acts as
#' a wrapper to Python's `argparse` module
#'
#' @param ... Arguments cleaned and passed to Pythons `argparse.ArgumentParser()`
#' @param python_cmd Python executable for `argparse` to use.
#'      Must have `argparse` and `json` modules (automatically bundled with Python 2.7 and 3.2+).
#'      If you need Unicode argument support then you must use Python 3.0+.
#'      Default will be to use `findpython` package to find suitable Python binary.
#' @return  `ArgumentParser()` returns a [Parser] R6 object which contains
#'    an `add_argument()` function to add arguments to the parser,
#'    a `parse_args()` function to parse command line arguments into
#'    a list, a `print_help()` and a `print_usage()` function to print
#'    usage information.  See code examples, package vignette,
#'    and corresponding python module for more information on how to use it.
#' @seealso [Parser], [ArgumentGroup], [MutuallyExclusiveGroup], and
#'   [Subparsers] for
#'   documentation of the R6 objects returned by `ArgumentParser()` and its
#'   methods.
#'
#' @references Python's `argparse` library, which this package is based on,
#'  is described here: \url{https://docs.python.org/3/library/argparse.html}
#'
#' @examples
#'
#' run_example <- argparse:::detects_python()
#' if (run_example) {
#'   parser <- ArgumentParser(description='Process some integers')
#'   parser$add_argument('integers', metavar='N', type = "integer", nargs='+',
#'                      help='an integer for the accumulator')
#'   parser$add_argument('--sum', dest='accumulate', action='store_const',
#'                      const='sum', default='max',
#'                      help='sum the integers (default: find the max)')
#'   parser$print_help()
#' }
#' if (run_example) {
#'   # default args for ArgumentParser()$parse_args are commandArgs(TRUE)
#'   # which is what you'd want for an Rscript but not for interactive use
#'   args <- parser$parse_args(c("--sum", "1", "2", "3"))
#'   accumulate_fn <- get(args$accumulate)
#'   print(accumulate_fn(args$integers))
#' }
#' @importFrom R6 R6Class
#' @export
ArgumentParser <- function(..., python_cmd = NULL) {
	python_cmd <- find_python_cmd(python_cmd)
	assert_python_cmd(python_cmd)
	initial_python_code <- c(
		"import argparse",
		"try:",
		"    import json",
		"except ImportError:",
		"    import simplejson as json",
		"",
		"def logical(s):",
		"    if isinstance(s, bool):",
		"        return s",
		"    elif s in ('T', 'TRUE', 'True', 'true'):",
		"        return True",
		"    elif s in ('F', 'FALSE', 'False', 'false'):",
		"        return False",
		"    else:",
		"        raise ValueError(\"could not convert string to logical: '{}'\".format(s))",
		"",
		sprintf(
			"parser = argparse.ArgumentParser(%s)",
			convert_..._to_arguments("ArgumentParser", ...)
		),
		""
	)
	Parser$new(Code$new(python_cmd, initial_python_code), "parser")
}

Code <- R6Class(
	"Code",
	cloneable = FALSE,
	public = list(
		append = function(new_code) {
			private$code <- c(private$code, new_code)
		},
		run = function(new_code) {
			code <- c(private$code, new_code)
			suppressWarnings(system2(private$cmd, input = code, stdout = TRUE, stderr = TRUE))
		},
		initialize = function(cmd, code = character(0)) {
			private$cmd <- cmd
			private$code <- code
		}
	),
	private = list(code = NULL, cmd = NULL)
)

#' Argument group base class
#'
#' @description
#' `Group` is the parent R6 class of [ArgumentGroup] and
#' [MutuallyExclusiveGroup].
#' It provides the `add_argument()` method shared by both kinds of group.
#' Users won't usually work with `Group` objects directly.
#'
#' @seealso [ArgumentParser()], [Parser], [ArgumentGroup],
#'   [MutuallyExclusiveGroup]
#' @keywords internal
Group <- R6Class(
	"Group",
	cloneable = FALSE,
	public = list(
		#' @description
		#' Create a new `Group` object.
		#' Users should not call this directly but instead use the
		#' `add_argument_group()` or `add_mutually_exclusive_group()` methods.
		#' @param python_code An internal object that accumulates the Python
		#'   code used to build the parser.
		#' @param name Name of the Python variable holding this object.
		initialize = function(python_code, name) {
			private$python_code <- python_code
			private$name <- name
		},
		#' @description
		#' Define how a single command line argument should be parsed.
		#' @param ... Arguments cleaned and passed to Python's
		#'   `add_argument()` method.  The `type` argument may be one of
		#'   `"logical"`, `"integer"`, `"double"`, `"numeric"`, or
		#'   `"character"`.
		#' @return `NULL` (invisibly).
		add_argument = function(...) {
			private$python_code$append(sprintf(
				"%s.add_argument(%s)",
				private$name,
				convert_..._to_arguments("add_argument", ...)
			))
			invisible(NULL)
		}
	),
	private = list(python_code = NULL, name = NULL)
)

#' Argument group
#'
#' @description
#' An `ArgumentGroup` R6 object wraps a Python `argparse` argument group.
#' Objects of this class are returned by the `add_argument_group()` method
#' of [Parser] objects.
#' Argument groups are used to group related arguments together in the
#' help message.
#'
#' @seealso [ArgumentParser()], [Parser], [MutuallyExclusiveGroup]
#' @references
#'   <https://docs.python.org/3/library/argparse.html#argument-groups>
#' @examples
#' if (argparse:::detects_python()) {
#'   parser <- ArgumentParser(prog = "PROG", add_help = FALSE)
#'   group <- parser$add_argument_group("group")
#'   group$add_argument("--foo", help = "foo help")
#'   group$add_argument("bar", help = "bar help")
#'   parser$print_help()
#' }
ArgumentGroup <- R6Class(
	"ArgumentGroup",
	cloneable = FALSE,
	inherit = Group,
	public = list(
		#' @description
		#' Create a mutually exclusive group.  Only one of the arguments
		#' added to the group may be present on the command line.
		#' @param required If `TRUE` then exactly one of the arguments in the
		#'   group must be present on the command line.
		#' @return A [MutuallyExclusiveGroup] object.
		add_mutually_exclusive_group = function(required = FALSE) {
			add_mutually_exclusive_group(private, required)
		}
	),
	private = list(n_mutually_exclusive_groups = 0L)
)

#' Mutually exclusive argument group
#'
#' @description
#' A `MutuallyExclusiveGroup` R6 object wraps a Python `argparse` mutually
#' exclusive group.
#' Objects of this class are returned by the `add_mutually_exclusive_group()`
#' method of [Parser] and [ArgumentGroup] objects.
#' Only one of the arguments added to a mutually exclusive group may be
#' present on the command line.
#'
#' Unlike an [ArgumentGroup], a mutually exclusive group can't contain
#' nested groups (Python 3.14 and later no longer allow this).
#'
#' @seealso [ArgumentParser()], [Parser], [ArgumentGroup]
#' @references
#'   <https://docs.python.org/3/library/argparse.html#mutual-exclusion>
#' @examples
#' if (argparse:::detects_python()) {
#'   parser <- ArgumentParser(prog = "PROG")
#'   group <- parser$add_mutually_exclusive_group()
#'   group$add_argument("--foo", action = "store_true")
#'   group$add_argument("--bar", action = "store_false")
#'   parser$parse_args("--foo")
#' }
MutuallyExclusiveGroup <- R6Class(
	"MutuallyExclusiveGroup",
	cloneable = FALSE,
	inherit = Group
)

# @param private The `private` environment of a `Parser` or `ArgumentGroup`
add_mutually_exclusive_group <- function(private, required = FALSE) {
	group_name <- paste0(
		private$name,
		"_mutually_exclusive_group",
		private$n_mutually_exclusive_groups
	)
	private$n_mutually_exclusive_groups <- private$n_mutually_exclusive_groups + 1L
	private$python_code$append(sprintf(
		"%s = %s.add_mutually_exclusive_group(%s)",
		group_name,
		private$name,
		ifelse(required, "required=True", "")
	))
	MutuallyExclusiveGroup$new(private$python_code, group_name)
}

#' Subparsers
#'
#' @description
#' A `Subparsers` R6 object wraps the Python `argparse` object used to add
#' sub-commands.
#' Objects of this class are returned by the `add_subparsers()` method of
#' [Parser] objects.
#'
#' @seealso [ArgumentParser()], [Parser]
#' @references
#'   <https://docs.python.org/3/library/argparse.html#sub-commands>
#' @examples
#' if (argparse:::detects_python()) {
#'   parser <- ArgumentParser(prog = "PROG")
#'   parser$add_argument("--foo", action = "store_true", help = "foo help")
#'   subparsers <- parser$add_subparsers(help = "sub-command help")
#'   parser_a <- subparsers$add_parser("a", help = "a help")
#'   parser_a$add_argument("bar", type = "integer", help = "bar help")
#'   parser$parse_args(c("a", "12"))
#' }
Subparsers <- R6Class(
	"Subparsers",
	cloneable = FALSE,
	public = list(
		#' @description
		#' Create a new `Subparsers` object.
		#' Users should not call this directly but instead use the `add_subparsers()` method of a [Parser] object.
		#' @param python_code An internal object that accumulates the Python
		#'   code used to build the parser.
		#' @param name Name of the Python variable holding this object.
		initialize = function(python_code, name) {
			private$python_code <- python_code
			private$name <- name
		},
		#' @description
		#' Add a sub-command parser.
		#' @param ... Arguments cleaned and passed to Python's `add_parser()`
		#'   method.  The first argument is usually the name of the
		#'   sub-command.  Accepts the same arguments as [ArgumentParser()]
		#'   as well as `help` and `aliases`.
		#' @return A [Parser] object.
		add_parser = function(...) {
			parser_name <- paste0(private$name, "_subparser", private$n_subparsers)
			private$n_subparsers <- private$n_subparsers + 1L
			private$python_code$append(sprintf(
				"%s = %s.add_parser(%s)",
				parser_name,
				private$name,
				convert_..._to_arguments("ArgumentParser", ...)
			))
			Parser$new(private$python_code, parser_name)
		}
	),
	private = list(python_code = NULL, name = NULL, n_subparsers = 0L)
)

#' Argument parser
#'
#' @description
#' A `Parser` R6 object wraps a Python `argparse` argument parser.
#' Objects of this class are returned by [ArgumentParser()] and by the
#' `add_parser()` method of [Subparsers] objects.
#'
#' If a parse error occurs (or help or version information is requested)
#' then in an interactive session an error is raised whereas in a
#' non-interactive session (i.e. a script) a message is printed and R exits.
#'
#' @seealso [ArgumentParser()], [ArgumentGroup], [MutuallyExclusiveGroup],
#'   [Subparsers]
#' @references Python's `argparse` documentation:
#'   <https://docs.python.org/3/library/argparse.html>
#' @examples
#' run_example <- argparse:::detects_python()
#' if (run_example) {
#'   parser <- ArgumentParser(description = "Process some integers")
#'   parser$add_argument("integers", metavar = "N", type = "integer",
#'                       nargs = "+", help = "an integer for the accumulator")
#'   parser$add_argument("--sum", dest = "accumulate", action = "store_const",
#'                       const = "sum", default = "max",
#'                       help = "sum the integers (default: find the max)")
#'   parser$print_usage()
#' }
#' if (run_example) {
#'   args <- parser$parse_args(c("--sum", "1", "2", "3"))
#'   print(args)
#' }
#' if (run_example) {
#'   args <- parser$parse_known_args(c("--sum", "1", "2", "--unknown"))
#'   print(args)
#' }
Parser <- R6Class(
	"Parser",
	cloneable = FALSE,
	public = list(
		#' @description
		#' Parse command line arguments.
		#' @param args A character vector of command line arguments.
		#' @return A named list of argument values.
		parse_args = function(args = commandArgs(TRUE)) {
			new_code <- c(
				sprintf(
					"args = %s.parse_args([%s])",
					private$name,
					paste(sprintf("'%s'", args), collapse = ", ")
				),
				"print(json.dumps(args.__dict__, sort_keys=True))"
			)
			output <- private$python_code$run(new_code)
			parse_args_output(output)
		},
		#' @description
		#' Parse command line arguments allowing optional and positional
		#' arguments to be intermixed.
		#' @param args A character vector of command line arguments.
		#' @return A named list of argument values.
		parse_intermixed_args = function(args = commandArgs(TRUE)) {
			new_code <- c(
				sprintf(
					"args = %s.parse_intermixed_args([%s])",
					private$name,
					paste(sprintf("'%s'", args), collapse = ", ")
				),
				"print(json.dumps(args.__dict__, sort_keys=True))"
			)
			output <- private$python_code$run(new_code)
			parse_args_output(output)
		},
		#' @description
		#' Parse command line arguments without raising an error for
		#' unrecognized arguments.
		#' @param args A character vector of command line arguments.
		#' @return A list of length two.  The first element is a named list of
		#'   argument values.  The second element is a character vector of the
		#'   remaining unrecognized arguments.
		parse_known_args = function(args = commandArgs(TRUE)) {
			new_code <- c(
				sprintf(
					"args_remainder = %s.parse_known_args([%s])",
					private$name,
					paste(sprintf("'%s'", args), collapse = ", ")
				),
				"print(json.dumps((args_remainder[0].__dict__, args_remainder[1])))"
			)
			output <- private$python_code$run(new_code)
			parse_known_args_output(output)
		},
		#' @description
		#' Parse command line arguments allowing optional and positional
		#' arguments to be intermixed and without raising an error for
		#' unrecognized arguments.
		#' @param args A character vector of command line arguments.
		#' @return A list of length two.  The first element is a named list of
		#'   argument values.  The second element is a character vector of the
		#'   remaining unrecognized arguments.
		parse_known_intermixed_args = function(args = commandArgs(TRUE)) {
			new_code <- c(
				sprintf(
					"args_remainder = %s.parse_known_intermixed_args([%s])",
					private$name,
					paste(sprintf("'%s'", args), collapse = ", ")
				),
				"print(json.dumps((args_remainder[0].__dict__, args_remainder[1])))"
			)
			output <- private$python_code$run(new_code)
			parse_known_args_output(output)
		},
		#' @description
		#' Format the help message.
		#' @return A string containing the help message.
		format_help = function() {
			paste(
				private$python_code$run(sprintf("%s.print_help()", private$name)),
				collapse = "\n"
			)
		},
		#' @description
		#' Format the usage message.
		#' @return A string containing the usage message.
		format_usage = function() {
			paste(
				private$python_code$run(sprintf("%s.print_usage()", private$name)),
				collapse = "\n"
			)
		},
		#' @description
		#' Print the help message.
		#' @return `NULL` (invisibly).
		print_help = function() {
			cat(private$python_code$run(sprintf("%s.print_help()", private$name)), sep = "\n")
			invisible(NULL)
		},
		#' @description
		#' Print the usage message.
		#' @return `NULL` (invisibly).
		print_usage = function() {
			cat(private$python_code$run(sprintf("%s.print_usage()", private$name)), sep = "\n")
			invisible(NULL)
		},
		#' @description
		#' Not currently supported.  Always raises an error.
		#' @param ... Ignored.
		get_default = function(...) {
			stop("We don't currently support `get_default()`")
		},
		#' @description
		#' Set parser-level default values for arguments.
		#' @param ... Named arguments cleaned and passed to Python's
		#'   `set_defaults()` method.
		#' @return `NULL` (invisibly).
		set_defaults = function(...) {
			private$python_code$append(sprintf(
				"%s.set_defaults(%s)",
				private$name,
				convert_..._to_arguments("add_argument", ...)
			))
			invisible(NULL)
		},
		#' @description
		#' Define how a single command line argument should be parsed.
		#' @param ... Arguments cleaned and passed to Python's
		#'   `add_argument()` method.  The `type` argument may be one of
		#'   `"logical"`, `"integer"`, `"double"`, `"numeric"`, or
		#'   `"character"`.
		#' @return `NULL` (invisibly).
		add_argument = function(...) {
			private$python_code$append(sprintf(
				"%s.add_argument(%s)",
				private$name,
				convert_..._to_arguments("add_argument", ...)
			))
			invisible(NULL)
		},
		#' @description
		#' Create an argument group.  Arguments added to the group are
		#' displayed together in the help message.
		#' @param ... Arguments cleaned and passed to Python's
		#'   `add_argument_group()` method such as `title` and `description`.
		#' @return An [ArgumentGroup] object.
		add_argument_group = function(...) {
			group_name <- paste0(private$name, "_group", private$n_groups)
			private$n_groups <- private$n_groups + 1L
			private$python_code$append(sprintf(
				"%s = %s.add_argument_group(%s)",
				group_name,
				private$name,
				convert_..._to_arguments("add_argument", ...)
			))
			ArgumentGroup$new(private$python_code, group_name)
		},
		#' @description
		#' Create a mutually exclusive group.  Only one of the arguments
		#' added to the group may be present on the command line.
		#' @param required If `TRUE` then exactly one of the arguments in the
		#'   group must be present on the command line.
		#' @return A [MutuallyExclusiveGroup] object.
		add_mutually_exclusive_group = function(required = FALSE) {
			add_mutually_exclusive_group(private, required)
		},
		#' @description
		#' Add support for sub-commands.
		#' @param ... Arguments cleaned and passed to Python's
		#'   `add_subparsers()` method such as `title`, `description`, `help`,
		#'   `dest`, and `required`.
		#' @return A [Subparsers] object.
		add_subparsers = function(...) {
			subparsers_name <- paste0(private$name, "_subparsers")
			private$python_code$append(sprintf(
				"%s = %s.add_subparsers(%s)",
				subparsers_name,
				private$name,
				convert_..._to_arguments("add_argument", ...)
			))
			Subparsers$new(private$python_code, subparsers_name)
		},
		#' @description
		#' Create a new `Parser` object.
		#' Users should not call this directly but instead use [ArgumentParser()].
		#' @param python_code An internal object that accumulates the Python
		#'   code used to build the parser.
		#' @param name Name of the Python variable holding this object.
		initialize = function(python_code, name) {
			private$python_code <- python_code
			private$name <- name
		}
	),
	private = list(python_code = NULL, name = NULL, n_mutually_exclusive_groups = 0L, n_groups = 0L)
)

parse_args_output <- function(output) {
	if (grepl("^usage:", output[1])) {
		has_positional_arguments <- any(grepl("^positional arguments:", output))
		has_optional_arguments <- any(grepl("^optional arguments:|^options:", output))
		if (has_positional_arguments || has_optional_arguments) {
			print_message_and_exit(output, "help requested:")
		} else {
			pa_stop(output, "parse error:")
		}
	} else if (grepl("^Traceback", output[1])) {
		pa_stop(output, "python error:")
	} else if (any(grepl("^SyntaxError: Non-ASCII character", output))) {
		message <- paste(
			"Non-ASCII character detected.",
			"If you wish to use Unicode arguments/options",
			"please upgrade to Python 3.2+",
			"Please see file INSTALL for more details."
		)
		pa_stop(message, "non-ascii character error:")
	} else if (
		any(grepl("^SyntaxError: positional argument follows keyword argument", output)) ||
			grepl("^SyntaxError: non-keyword arg after keyword arg", output[2])
	) {
		message <- "Positional argument following keyword argument."
		pa_stop(message, "syntax error:")
	} else if (grepl("^\\{|^\\[", output)) {
		jsonlite::fromJSON(paste(output, collapse = ""))
	} else {
		# presumably version number request
		print_message_and_exit(output, "version requested:")
	}
}

# `jsonlite::fromJSON()` simplifies an empty JSON array to `list()`
parse_known_args_output <- function(output) {
	args_remainder <- parse_args_output(output)
	args_remainder[[2L]] <- as.character(args_remainder[[2L]])
	args_remainder
}

# @param argument argument to be converted from R to Python
convert_argument <- function(argument, as_list = FALSE) {
	if (is.character(argument)) {
		argument <- convert_character(argument)
	}
	if (is.numeric(argument)) {
		argument <- as.character(argument)
	}
	if (is.logical(argument)) {
		argument <- ifelse(argument, "True", "False")
	}
	if (is.null(argument)) {
		argument <- "None"
	}
	if (as_list) {
		argument <- sprintf("[%s]", paste(argument, collapse = ", "))
	} else if (length(argument) > 1) {
		argument <- sprintf("(%s)", paste(argument, collapse = ", "))
	}
	argument
}

convert_character <- function(s) {
	bool <- substr(s, nchar(s), nchar(s)) == '"'
	ifelse(bool, paste0("r'''", s, "'''"), paste0('r"""', s, '"""'))
}

get_python_type <- function(type, proposed_arguments) {
	python_type <- switch(
		type,
		character = "str",
		double = "float",
		integer = "int",
		logical = "logical",
		numeric = "float",
		stop(paste(
			sprintf("type %s not supported,", type),
			"supported types:",
			"'logical', 'integer', 'double' or 'character'"
		))
	)
	sprintf("type=%s", python_type)
}

should_as_list <- function(name, argument_list) {
	if (
		name == "default" &&
			(argument_list[["action"]] %||% "store") == "append"
	) {
		TRUE
	} else {
		FALSE
	}
}

`%||%` <- function(x, y) if (is.null(x)) y else x # nolint

# @param mode Either "add_argument" or "ArgumentParser"
convert_..._to_arguments <- function(mode, ...) {
	argument_list <- list(...)
	argument_names <- names(argument_list)
	if (is.null(argument_names)) {
		argument_names <- rep_len("", length(argument_list))
	}
	equals <- ifelse(argument_names == "", "", "=")
	proposed_arguments <- c()
	for (ii in seq_along(argument_list)) {
		name <- argument_names[ii]
		equal <- equals[ii]
		as_list <- should_as_list(name, argument_list)
		argument <- convert_argument(argument_list[[ii]], as_list)
		proposed_arguments <- append(proposed_arguments, paste0(name, equal, argument))
	}
	# Make sure types are what Python wants
	if (mode == "add_argument" && any(grepl("type=", proposed_arguments))) {
		ii <- grep("type=", proposed_arguments)
		type <- argument_list[[ii]]
		proposed_arguments[ii] <- get_python_type(type, proposed_arguments)
	}
	# Don't put quotes around formatter_class argument
	if (mode == "ArgumentParser" && any(grepl("formatter_class=", proposed_arguments))) {
		ii <- grep("formatter_class=", proposed_arguments)
		formatter_class <- argument_list[[ii]]
		proposed_arguments[ii] <- sprintf("formatter_class=%s", formatter_class)
	}
	# Set right default prog name if not specified, if possible
	# Do last to not screw up other fixes with prog insertion
	if (mode == "ArgumentParser" && needs_prog(argument_names)) {
		prog <- get_Rscript_filename()
		if (is.na(prog)) {
			prog <- "PROGRAM"
		}
		proposed_arguments <- c(sprintf("prog='%s'", prog), proposed_arguments)
	}
	paste(proposed_arguments, collapse = ", ")
}

needs_prog <- function(argument_names) {
	if (length(argument_names) == 0L) {
		TRUE
	} else if (argument_names[1L] == "") {
		FALSE
	} else if (any(argument_names == "prog")) {
		FALSE
	} else {
		TRUE
	}
}

# Manually copied over from getopt to eliminate it as a dependency
get_Rscript_filename <- function() {
	args <- command_args()
	args_idx <- match("--args", args)
	if (!is.na(args_idx)) {
		args <- args[seq_len(args_idx - 1L)]
	}
	prog <- sub("--file=", "", grep("^--file=", args, value = TRUE)[1L])
	if (is.na(prog)) {
		prog <- littler_script_path()
	}
	if (!is.na(prog) && .Platform$OS.type == "windows") {
		prog <- gsub("\\\\", "\\\\\\\\", prog)
	}
	prog
}

command_args <- function() commandArgs()

littler_script_path <- function() Sys.getenv("LITTLER_SCRIPT_PATH", unset = NA_character_)

# Internal function to check python cmd is okay
# @param python_cmd Python cmd to use
assert_python_cmd <- function(python_cmd) {
	if (
		!findpython::is_python_sufficient(
			python_cmd,
			required_modules = c("argparse", "json | simplejson")
		)
	) {
		stop(paste(
			sprintf("python executable %s either is not installed,", python_cmd),
			"is not on the path, or does not have argparse, json modules",
			"please see INSTALL file"
		))
	}
}

required_modules <- c("argparse", "json | simplejson")

detects_python <- function(...) {
	python_cmd <- try(find_python_cmd())
	!inherits(python_cmd, "try-error") &&
		findpython::is_python_sufficient(python_cmd, ..., required_modules = required_modules)
}

# Internal function to find python cmd
# @param python_cmd  Python cmd to use
find_python_cmd <- function(python_cmd = NULL) {
	if (is.null(python_cmd)) {
		python_cmd <- getOption("python_cmd")
	}
	if (is.null(python_cmd)) {
		did_find_python3 <- findpython::can_find_python_cmd(
			minimum_version = "3.0",
			required_modules = required_modules,
			silent = TRUE
		)
		if (did_find_python3) {
			python_cmd <- attr(did_find_python3, "python_cmd")
		} else {
			python_cmd <- findpython::find_python_cmd(required_modules = required_modules)
		}
	}
	python_cmd <- normalizePath(python_cmd, mustWork = FALSE)
	python_cmd
}

quieter_error_handler <- function(e) {
	quit('no', status = 1, runLast = FALSE)
}

pa_stop <- function(message, r_note) {
	msg <- paste(c(r_note, message), collapse = "\n")
	cnd <- errorCondition(
		msg,
		call = "argparse::parse_args_output(output)",
		class = "argparse_parse_error"
	)
	if (interactive()) {
		stop(cnd)
	} else {
		signalCondition(cnd)
		cat(message, sep = "\n", file = stderr())
		opt <- options(
			error = getOption("error", quieter_error_handler),
			show.error.messages = FALSE
		)
		on.exit(options(opt))
		stop(cnd)
	}
}

# Internal function to print message
print_message_and_exit <- function(message, r_note) {
	if (interactive()) {
		pa_stop(message, r_note)
	} else {
		cat(message, sep = "\n")
		quit(status = 0L)
	}
}
