# getopty

This module provides the standard POSIX compliant command line parser.

## Supported Syntax

1. Short options: `-a`, `-bcd`, `-e 5`
2. Long options: `--foo`, `--bar=baz`
3. Arguments: everything that does not start with a `-` or everything after standalone `--`.

Command Line Examples:

- `-a` - short option `a`
- `-abcd` - short options `a`, `b`, `d` and `d`
- `-abcd` (when `-b` option requires an argument) - short option `a`,
  short option `b` with value of `cd`
- `--foo` - long option `foo`
- `--foo=bar` - long option `foo` with value of `bar`
- `-a b -c --d e` - short options `a` and `c`, long option `d`,
  arguments `b` and `e`
- `-a b -- -c --d e` - short option `a`, arguments `b`, `-c`, `--d`, `e`

## Install

```sh
nimble install https://github.com/amnr/getopty/
```

##  Usage

`getopts` is the iterator for iterating over command line options and arguments.

```nim
iterator getopts*(shortopts: string,
                  longopts: openArray[string] = [],
                  longopts_with_arg: openArray[string] = []): OptArg
```

Arguments:
- `shortopts` &mdash; the short options (one character) to be recognized; each character may be
  followed by one colon to indicate the option has required argument
- `longopts` &mdash; list of long options to be recognized
- `longopts_with_arg` &mdash; list of long options that have required argument

Iterator returns `OptArg` of a kind:
- `OPT_SHORT` &mdash; short option
- `OPT_LONG` &mdash; long option
- `OPT_ARGS` &mdash; command line arguments (always the last `OptArg` returned)
- `OPT_ERROR` &mdash; parse error

Errors returned:
- `OPTERR_EXTRA_ARG` &mdash; option doesn't allow an argument
- `OPTERR_INVALID` &mdash; invalid (unknown) option
- `OPTERR_REQ_ARG` &mdash; option requires an argument

## Example

```nim
import std/strformat

proc main() =
  for opt in getopts "ab:cd":
    case opt.kind
    of OPT_SHORT, OPT_LONG:
      if opt.name == "b":
        echo fmt"Option '{opt.name}' with value ", opt.value
      else:
        echo fmt"Option '{opt.name}'"
    of OPT_ARGS:
      echo "Arguments: ", opt.args
    of OPT_ERROR:
      echo program_name(), ": ", $opt
      quit QuitFailure

when isMainModule:
  main()
```

## Author

- [Amun](https://github.com/amnr/)

## License

`getopty` is released under either:

- [**MIT**](LICENSE-MIT.txt) &mdash; Nim license
- [**NCSA**](LICENSE-NCSA.txt) &mdash; author's license of choice

Pick the one you prefer (or both).
