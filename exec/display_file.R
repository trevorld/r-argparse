#!/usr/bin/env Rscript
suppressPackageStartupMessages(library("argparse"))

parser <- ArgumentParser()
parser$add_argument("-n", "--add_numbers", action="store_true", default=FALSE,
    help="Print line number at the beginning of each line [default]")
parser$add_argument("file", nargs=1, help="File to be displayed")

args <- parser$parse_args()

file <- args$file

if( file.access(file) == -1) {
    stop(sprintf("Specified file ( %s ) does not exist", file))
} else {
    file_text <- readLines(file)
}

if(args$add_numbers) {
    cat(paste(1:length(file_text), file_text), sep = "\n")
} else {
    cat(file_text, sep = "\n")
}
