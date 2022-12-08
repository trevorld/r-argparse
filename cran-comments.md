## Notes

* As in previous uploads while in a non-interactive session (i.e. in an
  Rscript) if ``parse_args()`` observes a help flag it will print a usage
  message and then call ``quit()``.  Additionally if a user specifically adds
  a 'version' argument to the command-line parser with `action='version'` then
  if ``parse_args()`` observes a version flag while in a non-interactive
  session then it will print the version number and then call ``quit()``.

* This package has a Python dependency most easily satisfied having (C)Python
  3.2 or greater on the PATH.  See file INSTALL for more details.

## Test environments

* local (linux), R 4.2.2
* win-builder (windows), R devel
* Github Actions (linux), R devel, release, oldrel
* Github Actions (windows), R release
* Github Actions (OSX), R release

## R CMD check --as-cran results

Status: OK

## revdepcheck results

We checked 3 reverse dependencies (0 from CRAN + 3 from Bioconductor), comparing R CMD check results across CRAN and dev versions of this package.

 * We saw 0 new problems
 * We failed to check 0 packages
