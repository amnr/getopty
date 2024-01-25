##  Cmdline patch for testing getopty.
#[
  SPDX-License-Identifier: MIT or NCSA
]#

var
  argv: seq[string] = @["testprog"]

proc getEnv*(key: string, default = ""): string =
  default

proc existsEnv*(key: string): bool =
  false

proc paramCount*(): int =
  argv.len - 1

proc paramStr*(i: int): string =
  argv[i]

proc set_param_args*(args: seq[string]) =
  when defined js:
    var i = 2
    for val in args:
      let val = val.cstring
      {.emit: "process.argv[`i`] = `val`;".}
      inc i
    let nargs = args.len
    {.emit: "process.argv = process.argv.slice(0, `nargs` + 2);".}
  else:
    argv = argv[0] & args

# vim: set sts=2 et sw=2:
