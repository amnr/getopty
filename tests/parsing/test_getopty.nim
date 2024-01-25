##  Tests.
#[
  SPDX-License-Identifier: MIT or NCSA
]#

discard """
  action: "run"
  batchable: true
  joinable: true
  matrix: "; -d=release --opt=speed"
  sortoutput: true
  valgrind: false
  targets: "c"
"""

when false and defined(linux) and (defined(gcc) or defined(clang)):
  {.passc: "-fsanitize=address,undefined".}
  {.passl: "-lasan -lubsan".}

when NimMajor >= 2:
  import std/cmdline
else:
  import std/os
import std/unittest

import getopty

# Required for changing argv to work.
disableParamFiltering()

# --------------------------------------------------------------------------- #
# Helpers                                                                     #
# --------------------------------------------------------------------------- #

proc collect_opts(shortopts: string, longopts: seq[string],
                  longopts_with_args: seq[string],
                  args: seq[string]): seq[OptArg] =
  # Set program args.
  set_param_args args

  # Parse and collect.
  result = @[]
  for opt in getopts(shortopts, longopts,
                     longopts_with_arg = longopts_with_args):
    result &= opt

proc collect_opts(shortopts: string, longopts: seq[string],
                  args: seq[string]): seq[OptArg] =
  collect_opts shortopts, longopts, @[], args

proc collect_opts(shortopts: string, args: seq[string]): seq[OptArg] =
  collect_opts shortopts, @[], @[], args

# --------------------------------------------------------------------------- #
# Parsing options                                                             #
# --------------------------------------------------------------------------- #

suite "Parsing arguments":
  # test "program_name":
  #   check program_name() == "testprog"

  test """cmdline "" returns nothing""":
    let opts = collect_opts("a", @[])
    check opts.len == 0

  test """cmdline "--" returns nothing""":
    let opts = collect_opts("a", @["--"])
    check opts.len == 0

  test """cmdline "foo bar" returns arguments foo and bar""":
    let opts = collect_opts("", @["foo", "bar"])
    check opts.len == 1

    check opts[0].kind == OPT_ARGS
    check opts[0].args == @["foo", "bar"]

suite "Parsing options":
  test """shortopts "a" cmdline "-a" returns short option -a""":
    let opts = collect_opts("a", @["-a"])
    check opts.len == 1

    check opts[0].kind == OPT_SHORT
    check opts[0].name == "a"
    check opts[0].value == ""

  test """shortopts "ab" cmdline "-a -b" returns options -a and -b""":
    let opts = collect_opts("ab", @["-a", "-b"])
    check opts.len == 2

    check opts[0].kind == OPT_SHORT
    check opts[0].name == "a"
    check opts[0].value == ""

    check opts[1].kind == OPT_SHORT
    check opts[1].name == "b"
    check opts[1].value == ""

  test """shortopts "ab" cmdline "-a -- -b" returns options -a and -b""":
    let opts = collect_opts("ab", @["-a", "--", "-b"])
    check opts.len == 2

    check opts[0].kind == OPT_SHORT
    check opts[0].name == "a"
    check opts[0].value == ""

    check opts[1].kind == OPT_ARGS
    check opts[1].args == @["-b"]

  test """shortopts "ab" cmdline "-ab" returns options -a and -b""":
    let opts = collect_opts("ab", @["-ab"])
    check opts.len == 2

    check opts[0].kind == OPT_SHORT
    check opts[0].name == "a"
    check opts[0].value == ""

    check opts[1].kind == OPT_SHORT
    check opts[1].name == "b"
    check opts[1].value == ""

  test """longopts ["foo"] cmdline "--foo" returns option --foo""":
    let opts = collect_opts("", @["foo"], @["--foo"])
    check opts.len == 1

    check opts[0].kind == OPT_LONG
    check opts[0].name == "foo"
    check opts[0].value == ""

  test """longopts ["foo", "bar"] cmdline "--foo --bar" returns options --foo and --bar""":
    let opts = collect_opts("", @["foo", "bar"], @["--foo", "--bar"])
    check opts.len == 2

    check opts[0].kind == OPT_LONG
    check opts[0].name == "foo"
    check opts[0].value == ""

    check opts[1].kind == OPT_LONG
    check opts[1].name == "bar"
    check opts[1].value == ""

# --------------------------------------------------------------------------- #
# Parsing option arguments                                                    #
# --------------------------------------------------------------------------- #

suite "Parsing option argument":
  test """shortopts "ab:" cmdline "-ab foo" returns -b = "foo"""":
    let opts = collect_opts("ab:", @["-ab", "foo"])
    check opts.len == 2

    check opts[0].kind == OPT_SHORT
    check opts[0].name == "a"
    check opts[0].value == ""

    check opts[1].kind == OPT_SHORT
    check opts[1].name == "b"
    check opts[1].value == "foo"

  test """shortopts "ab:" cmdline "-abfoo" returns -b = "foo"""":
    let opts = collect_opts("ab:", @["-abfoo"])
    check opts.len == 2

    check opts[0].kind == OPT_SHORT
    check opts[0].name == "a"
    check opts[0].value == ""

    check opts[1].kind == OPT_SHORT
    check opts[1].name == "b"
    check opts[1].value == "foo"

  test """shortopts "ab:" cmdline "-ab =" returns -b = "="""":
    let opts = collect_opts("ab:", @["-ab", "="])
    check opts.len == 2

    check opts[0].kind == OPT_SHORT
    check opts[0].name == "a"
    check opts[0].value == ""

    check opts[1].kind == OPT_SHORT
    check opts[1].name == "b"
    check opts[1].value == "="

  test """shortopts "ab:" cmdline "-ab=" returns -b = "="""":
    let opts = collect_opts("ab:", @["-ab="])
    check opts.len == 2

    check opts[0].kind == OPT_SHORT
    check opts[0].name == "a"
    check opts[0].value == ""

    check opts[1].kind == OPT_SHORT
    check opts[1].name == "b"
    check opts[1].value == "="

  test """longopts ["bar", "foo"] longargs ["foo"] cmdline "--bar --foo=baz" returns --foo = "baz"""":
    let opts = collect_opts("", @["bar", "foo"], @["foo"], @["--bar", "--foo=baz"])
    check opts.len == 2

    check opts[0].kind == OPT_LONG
    check opts[0].name == "bar"
    check opts[0].value == ""

    check opts[1].kind == OPT_LONG
    check opts[1].name == "foo"
    check opts[1].value == "baz"

# --------------------------------------------------------------------------- #
# Parse errors                                                                #
# --------------------------------------------------------------------------- #

suite "Parse errors":
  test """shortopts "abc" cmdline "-f" returns OPTERR_INVALID ('f')""":
    let opts = collect_opts("abc", @["-f"])
    check opts.len == 1

    check opts[0].kind == OPT_ERROR
    check opts[0].errtype == OPTERR_INVALID
    check opts[0].erropt == "f"

  test """shortopts "abc" cmdline "-a=" returns OPTERR_INVALID ('=')""":
    let opts = collect_opts("abc", @["-a="])
    check opts.len == 2

    check opts[1].kind == OPT_ERROR
    check opts[1].errtype == OPTERR_INVALID
    check opts[1].erropt == "="

  test """shortopts "abc" cmdline "-a:" returns OPTERR_INVALID (':')""":
    let opts = collect_opts("abc", @["-a:"])
    check opts.len == 2

    check opts[1].kind == OPT_ERROR
    check opts[1].errtype == OPTERR_INVALID
    check opts[1].erropt == ":"

  test """longopts ["foo"] cmdline "--bar" returns OPTERR_INVALID""":
    let opts = collect_opts("", @["foo"], @["--bar"])
    check opts.len == 1

    check opts[0].kind == OPT_ERROR
    check opts[0].errtype == OPTERR_INVALID
    check opts[0].erropt == "bar"

  test """longopts ["foo"] cmdline "--=" returns OPTERR_INVALID""":
    let opts = collect_opts("", @["foo"], @["--="])
    check opts.len == 1

    check opts[0].kind == OPT_ERROR
    check opts[0].errtype == OPTERR_INVALID
    check opts[0].erropt == "--="

  test """longopts ["foo"] cmdline "--foo=bar" returns OPTERR_EXTRA_ARG""":
    let opts = collect_opts("", @["foo"], @["--foo=bar"])
    check opts.len == 1

    check opts[0].kind == OPT_ERROR
    check opts[0].errtype == OPTERR_EXTRA_ARG
    check opts[0].erropt == "foo"

  test """longopts ["foo"] longargs ["foo"] cmdline "--foo" returns OPTERR_REQ_ARG""":
    let opts = collect_opts("", @["foo"], @["foo"], @["--foo"])
    check opts.len == 1

    check opts[0].kind == OPT_ERROR
    check opts[0].errtype == OPTERR_REQ_ARG
    check opts[0].erropt == "foo"

# vim: set sts=2 et sw=2:
