#[
  SPDX-License-Identifier: MIT or NCSA
]#
##  This module provides the standard POSIX compliant command line parser.
##
##  Supported Syntax
##  ================
##
##  1. Short options: `-a`, `-bcd`, `-e 5`
##  2. Long options: `--foo`, `--bar=baz`
##  3. Arguments: everything that does not start with a `-` or everything
##     after standalone `--`.
##
##  Command line examples:
##
##  * `-a` - short option `a`
##  * `-abcd` - short options `a`, `b`, `d` and `d`
##  * `-abcd` (when `-b` option requires an argument) - short option `a`,
##    short option `b` with value of `cd`
##  * `--foo` - long option `foo`
##  * `--foo=bar` - long option `foo` with value of `bar`
##  * `-a b -c --d e` - short options `a` and `c`, long option `d`,
##    arguments `b` and `e`
##  * `-a b -- -c --d e` - short option `a`, arguments `b`, `-c`, `--d`, `e`
##
##  Usage
##  =====
##
##  Example:
##
##  ```nim
##  import std/strformat
##
##  proc main() =
##    for opt in getopts "ab:cd":
##      case opt.kind
##      of OPT_SHORT, OPT_LONG:
##        if opt.name == "b":
##          echo fmt"Option '{opt.name}' with value ", opt.value
##        else:
##          echo fmt"Option '{opt.name}'"
##      of OPT_ARGS:
##        echo "Arguments: ", opt.args
##      of OPT_ERROR:
##        echo program_name(), ": ", $opt
##        quit QuitFailure
##
##  when isMainModule:
##    main()
##  ```

when NimMajor >= 2:
  import std/cmdline
else:
  from std/os import paramCount, paramStr
from std/strutils import startsWith

{.push raises: [].}

type
  OptKind* = enum
    ##  Option type.
    OPT_SHORT     ##  Short option.
    OPT_LONG      ##  Long option.
    OPT_ARGS      ##  Arguments.
    OPT_ERROR     ##  Parse error.

  OptErr* = enum
    ##  Option parsing error.
    # OPTERR_AMBIGUOUS    ##  Ambiguous option.
    OPTERR_EXTRA_ARG      ##  Option doesn't allow an argument.
    OPTERR_REQ_ARG        ##  Option requires an argument.
    OPTERR_INVALID        ##  Invalid option.

  OptArg* = object
    ##  Option.
    case kind*: OptKind
    of OPT_SHORT, OPT_LONG:
      name*     : string        ##  Option name.
      value*    : string        ##  Option value.
    of OPT_ARGS:
      args*     : seq[string]   ##  Command line arguments.
    of OPT_ERROR:
      errtype*  : OptErr        ##  Error.
      erropt*   : string        ##  Option that caused the error.
      # msg*    : string        ##  Error message.

func shortopt(T: typedesc[OptArg], name: char,
              value: string = ""): T {.inline.} =
  OptArg(kind: OPT_SHORT, name: $name, value: value)

func longopt(T: typedesc[OptArg], name: string,
             value: string = ""): T {.inline.} =
  OptArg(kind: OPT_LONG, name: name, value: value)

func error(T: typedesc[OptArg], err: OptErr, eopt: string): T {.inline.} =
  OptArg(kind: OPT_ERROR, errtype: err, erropt: eopt)

proc program_name*(): string =
  ##  Returns the program filename.
  paramStr 0

proc `$`*(self: OptArg): string =
  ##  Returns string representation of `OptArg`.
  ##
  ##  - `OPT_SHORT`:
  ##    "option '-name'"
  ##  - `OPT_LONG`:
  ##    "option '--name'"
  ##  - `OPT_ARGS`:
  ##    "arguments {arguments}"
  ##  - `OPT_ERROR`:
  ##    - `OPTERR_EXTRA_ARG`:
  ##      "progname: option '--name' doesn't allow an argument"
  ##    - `OPTERR_INVALID`:
  ##      "progname: invalid option -- 'name'"
  ##    - `OPTERR_REQ_ARG`:
  ##      "progname: option requires an argument -- 'name'"
  case self.kind
  of OPT_SHORT:
    "option '-" & self.name & "'"
  of OPT_LONG:
    "option '--" & self.name & "'"
  of OPT_ARGS:
    "arguments " & $self.args
  of OPT_ERROR:
    case self.errtype
    of OPTERR_EXTRA_ARG:
      "option '--" & self.erropt & "' doesn't allow an argument"
    of OPTERR_INVALID:
      "invalid option -- '" & self.erropt & "'"
    of OPTERR_REQ_ARG:
      "option requires an argument -- '" & self.erropt & "'"

func shortopt_requies_arg(shortopts: string, opt: char): bool =
  ##  Returns `true` if short option requires an argument.
  let pos = shortopts.find opt
  pos >= 0 and pos < shortopts.high and shortopts[pos + 1] == ':'

proc optarg_avail(i: int): bool =
  ##  Returns `true` if there's an argument available for an option.
  (i + 1) <= paramCount()

iterator getopts*(shortopts: string, longopts: openArray[string] = [],
                  # short_opts_with_arg: string = "",
                  longopts_with_arg: openArray[string] = []): OptArg =
  ##  Iterator for iterating over command line options and arguments.
  ##
  ##  Arguments:
  ##  - `shortopts` &mdash; the short options (one character) to be recognized; each character may be
  ##    followed by one colon to indicate the option has required argument
  ##  - `longopts` &mdash; list of long options to be recognized
  ##  - `longopts_with_arg` &mdash; list of long options that have required argument
  ##
  ##  `short_opts_with_arg` is a list of short options that require an argument.
  ##
  ##  Iterator returns `OptArg<#OptArg>`_ of a kind:
  ##    * `OPT_SHORT` — short option
  ##    * `OPT_LONG` — long option
  ##    * `OPT_ARGS` — command line arguments (always the last `OptArg` returned)
  ##    * `OPT_ERROR` — parse error
  ##
  ##  Errors returned:
  ##  - `OPTERR_EXTRA_ARG` &mdash; option doesn't allow an argument
  ##  - `OPTERR_INVALID` &mdash; invalid (unknown) option
  ##  - `OPTERR_REQ_ARG` &mdash; option requires an argument
  let num_params = paramCount()
  var args: seq[string] = @[]
  var no_more_opts = false
  var skip_next_token = false

  for i in 1 .. num_params:
    let token = paramStr i
    if skip_next_token:
      # Skip next token.
      skip_next_token = false
    elif no_more_opts:
      # Add an argument regardless of its value.
      args.add token
    elif token == "--":
      # Treat the rest of the tokens as arguments.
      no_more_opts = true
    elif token.startsWith "--":
      ##  Long option.
      let idx = token.find '='
      if idx > 2:
        let lname = token[2 .. idx - 1]
        if lname notin longopts:
          yield OptArg.error(OPTERR_INVALID, lname)
        elif lname notin longopts_with_arg:
          yield OptArg.error(OPTERR_EXTRA_ARG, lname)
        else:
          let lvalue = token[idx + 1 .. ^1]
          yield OptArg.longopt(lname, lvalue)
      elif idx < 0:
        let lname = token[2 .. ^1]
        if lname notin longopts:
          yield OptArg.error(OPTERR_INVALID, lname)
        elif lname in longopts_with_arg:
          yield OptArg.error(OPTERR_REQ_ARG, lname)
        else:
          yield OptArg.longopt(lname)
      else:
        yield OptArg.error(OPTERR_INVALID, token)   # "--=".
    elif token.len > 1 and token.startsWith '-':
      # Short option(s).
      for j in 1 ..< token.len:
        let optname = token[j]
        if optname notin shortopts:
          yield OptArg.error(OPTERR_INVALID, $optname)
        elif shortopts.shortopt_requies_arg optname:
        # elif optname in short_opts_with_arg:
          # Short option that requires a value.
          if j == token.high:
            # Single option with or last option in combined short option string.
            if not optarg_avail i:
              yield OptArg.error(OPTERR_REQ_ARG, $optname)
              continue
            skip_next_token = true
            yield OptArg.shortopt(optname, paramStr i + 1)
          else:
            # Short option in short option string (before the last option).
            # Example: given 'b' requires an argument, "-abcd" results with
            #          option 'b' having a value of "cd".
            yield OptArg.shortopt(optname, token[j + 1 .. ^1])
            break
        else:
          # Short option with no argument.
          yield OptArg.shortopt(optname)
    else:
      # Plain argument.
      args.add token

  if args.len > 0:
    yield OptArg(kind: OPT_ARGS, args: args)

when isMainModule:
  proc main() =
    for opt in getopts "d":
      case opt.kind
      of OPT_SHORT, OPT_LONG:
        if opt.name == "d":
          echo "Option '", opt.name, "' with value ", opt.value
        else:
          echo "Option '", opt.name, "'"
      of OPT_ARGS:
        echo "Arguments: ", opt.args
      of OPT_ERROR:
        echo $opt
        # let pname = program_name()
        # case opt.errtype
        # # of OPTERR_AMBIGUOUS:
        # #   echo program_name(), ": option '", opt.eopt, "' is ambiguous"
        # of OPTERR_EXTRA_ARG:
        #   echo pname, ": option '--", opt.erropt, "' doesn't allow an argument"
        # of OPTERR_INVALID:
        #   echo program_name(), ": invalid option -- '", opt.erropt, "'"
        # of OPTERR_REQ_ARG:
        #   echo program_name(), ": option requires an argument -- '",
        #        opt.erropt, "'"

  main()

# vim: set sts=2 et sw=2:
