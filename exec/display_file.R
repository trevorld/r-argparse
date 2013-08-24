#!/usr/bin/env Rscript
# Copyright 2012-2013 Trevor L Davis <trevor.l.davis@stanford.edu>
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
