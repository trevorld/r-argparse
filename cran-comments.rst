**Test environments**

* local (linux), R 3.4.4
* win-builder (windows), R release and R devel
* appveyor (windows), R release and R devel
* travis-ci (OSX), R release
* travis-ci (linux), R release and R devel

**R CMD check --as-cran results**

Status: OK

**Downstream dependencies**

This package does not have any downstream dependencies.

**Nota benes**

* Currently CRAN checks on the two OSX test machines for the previous release
  of ``argparse`` show a WARNING because they are unable to re-build the
  vignette due to a weird error::
     
      sh: +RTS: command not found
      Warning in system(command) : error in running command
      Error: processing vignette 'argparse.Rrst' failed with diagnostics:
      pandoc document conversion failed with error 127
      Execution halted

  Looking online it seems ``error 127`` is an issue with a virtual machine not
  having enough memory.  Perhaps ``--no-vignettes`` flag should be turned on
  for OSX test machines?  I am unable to reproduce this error in my Travis-CI
  OSX test environment (i.e. the vignette always builds fine).

* As in previous uploads while in a non-interactive session (i.e. in an
  Rscript) if `parse_args` observes a help flag it will print a usage
  message and then call ``quit``.  Additionally if a user specifically adds
  a 'version' argument to the command-line parser with `action='version'` then
  if `parse_args` also observes a version flag while in a non-interactive
  session then it will print the version number and then call ``quit``.

* This package has a Python dependency most easily satisfied having (C)Python
  3.2 or greater on the PATH.  See file INSTALL for more details.
