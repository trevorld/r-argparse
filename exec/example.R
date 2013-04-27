#!/usr/bin/env Rscript
# Note:  This example is a port of an example in the getopt package
#        which is Copyright 2008 Allen Day
suppressPackageStartupMessages(library("argparse"))

# create parser object
parser <- ArgumentParser()

# specify our desired options 
# by default ArgumentParser will add an help option 
parser$add_argument("-v", "--verbose", action="store_true", default=TRUE,
    help="Print extra output [default]")
parser$add_argument("-q", "--quietly", action="store_false", 
    dest="verbose", help="Print little output")
parser$add_argument("-c", "--count", type="integer", default=5, 
    help="Number of random normals to generate [default %(default)s]",
    metavar="number")
parser$add_argument("--generator", default="rnorm", 
    help = "Function to generate random deviates [default \"%(default)s\"]")
parser$add_argument("--mean", default=0, type="double",
    help="Mean if generator == \"rnorm\" [default %(default)s]")
parser$add_argument("--sd", default=1, type="double",
        metavar="standard deviation",
    help="Standard deviation if generator == \"rnorm\" [default %(default)s]")
                                        
# get command line options, if help option encountered print help and exit,
# otherwise if options not found on command line then set defaults, 
args <- parser$parse_args()

# print some progress messages to stderr if "quietly" wasn't requested
if ( args$verbose ) { 
    write("writing some verbose output to standard error...\n", stderr()) 
}

# do some operations based on user input
if( args$generator == "rnorm") {
    cat(paste(rnorm(args$count, mean=args$mean, sd=args$sd), collapse="\n"))
} else {
    cat(paste(do.call(args$generator, list(args$count)), collapse="\n"))
}
cat("\n")
