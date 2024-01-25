# Package: getopty.
#
# SPDX-License-Identifier: MIT or NCSA

version       = "1.0.0"
author        = "Amun"
description   = "POSIX compliant command line parser"
license       = "MIT or NCSA"
src_dir       = "src"

task test, "Run all tests":
  const test_file = "tests/parsing/test_getopty.nim"
  exec "nim r --hints=off -d=release " & test_file
  # exec "nim r --hints=off -d=release --opt=size  " & test_file
  # exec "nim r --hints=off -d=release --opt=speed  " & test_file
  # exec "nim r --hints=off -d=release -d=danger  " & test_file
  # exec "nim r --hints=off -d=release -d=danger --opt=size  " & test_file
  # exec "nim r --hints=off -d=release -d=danger --opt=speed  " & test_file

#[
task testjs, "Run tests with NodeJS":
  const test_file = "tests/parsing/test_getopty.nim"
  if "nodejs".findExe != "":
    exec "nim r -b=js -d=nodejs " & test_file
    exec "nim r -b=js -d=nodejs -d=release" & test_file
    exec "nim r -b=js -d=nodejs -d=release -d=danger" & test_file
  else:
    echo "Skipping NodeJS tests: nodejs not installed"
]#

# vim: set sts=2 et sw=2:
