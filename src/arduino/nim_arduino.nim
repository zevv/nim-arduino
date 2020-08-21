import os, strutils, parseopt, osproc, npeg, tables, strformat, streams

# Helper procs


const (nimBindir, tmp1) = getCurrentCompilerExe().splitPath()
const (nimDir, tmp2) = nimBindir.splitPath()
const nimInclude = "-I" & nimdir & os.DirSep & "lib"

proc err(s: string) =
  echo ">>> " & s
  quit 1

proc log(s: string) =
  echo ">>> " & s

proc dbg(s: string) =
  echo ">>> " & s

proc run(cmd: string, args: seq[string]): string =
  dbg cmd & " " & args.join(" ")
  let p = startProcess(cmd, args=args, options={poUsePath,poStdErrToStdOut})
  let o = p.outputStream.readAll()
  let rv = p.waitForExit()
  p.close()
  if rv != 0:
    err "Error running command\n" & o
  result = o



# Split c/c++ compiler flags into a seq[string]. We can't just split on white space
# because there might be spaces in include paths passed by arduino

proc splitFlags2(s: string): seq[string] = splitWhiteSpace(s)

proc splitFlags(s: string): seq[string] =
  var flags: seq[string]
  let p = peg flags:
    s <- *Space
    flags <- *(s * flag * s)
    flag <- flagI | flagx | flagOther
    flagI <- "-I" * +flagCharWithSpace: flags.add $0
    flagx <- >"-x" * " " * >+Graph: flags.add $1 & $2
    flagOther <- "-" * +Graph: flags.add $0
    flagCharWithSpace <- Graph | flagSpace
    flagSpace <- " " * !"-"
  let r = p.match(s)
  #for f in flags:
  #  echo "  '", f, "'"
  return flags


#let fs = splitFlags(" -c  -g  -Os  -w  -std=gnu++11  -fpermissive  -fno -exceptions  -ffunction -sections  -fdata -sections  -fno -threadsafe -statics  -Wno -error=narrowing  -flto  -w  -x c++  -E  -CC  -mmcu=atmega328p  -DF_CPU=16000000L  -DARDUINO=10813  -DARDUINO_AVR_UNO  -DARDUINO_ARCH_AVR  -I/opt/arduino 1.8.13/hardware/arduino/avr/cores/arduino  -I/opt/arduino 1.8.13/hardware/arduino/avr/variants/standard -I/opt/nim-1.2.6/lib /tmp/arduino")


# Parse command line arguments. parseOpts has problems with whitespace in
# arguments, so for now do it with Npeg

let cmdLine = commandLineParams().join(" ")
log cmdLine
var opt_cmd: string
var opt_args: Table[string, string]

let p = peg line:
  S <- *Space
  line <- cmd * S * ?args * !1
  args <- arg * *(S * arg)
  cmd <- +Alnum: opt_cmd = $0
  arg <- arg_long | arg_short
  arg_short <- "-" * +(Alnum | '_')
  arg_long <- "--" * key * "=" * val: opt_args[$1] = $2
  key <- >+Alnum
  val <- >+Alnum | '"' * >+(1-'"') * '"'

let r = p.match(cmdLine)
if not r.ok:
  let l1 = r.matchMax
  let l2 = min(r.matchMax+30, cmdLine.len)
  err "Error parsing command line at: " & cmdLine[l1..<l2]

for k, v in opt_args:
  log("  " & k & " = " & v)


# Dispatch subcommand

proc macros()
proc cpp()
proc c()
proc link()

case opt_cmd:
  of "macros": macros()
  of "cpp":    cpp()
  of "c":      c()
  of "link":   link()
  else: err "Unhandled command " & opt_cmd

proc macros() =
  #log &"""macros {opt_args["input"]} -> {opt_args["output"]}"""
  let (input, output) = (opt_args["input"], opt_args["output"])
  let (dir, file) = input.splitPath
  let nimsrc = dir & DirSep & "sketch.nim"
  let nimcache = dir & DirSep & "nimcache"

  # Build nim command line and compile the sketch

  var args = @[ "cpp", "-c", "--nimcache:" & nimcache ]
  args.add opt_args["nimflags"].splitWhiteSpace()
  args.add nimsrc

  copyFile(opt_args["input"], nimsrc)
  discard run("nim", args)
  
  var fout = open(opt_args["output"], fmWrite)
  for f in os.walkfiles(nimcache & "/*.cpp"):
    let cmd = opt_args["compiler"]
    var args = opt_args["cppflags"].splitFlags()
    args.add niminclude
    args.add f
    let o = run(cmd, args)
    fout.write(o)
  fout.close()


proc cpp() =
  let (input, output, compiler) = (opt_args["input"], opt_args["output"], opt_args["compiler"])
  let (dir, file) = input.splitPath
  let (bindir, _) = compiler.splitPath
  let nimsrc = dir & DirSep & "sketch.nim"
  let nimcache = dir & DirSep & "nimcache"
  #log &"""g++ {input} -> {output}"""

  var ofiles: seq[string]
  if input.contains("sketch"):
    log "sketch"
    for cfile in os.walkfiles(nimcache & "/*.cpp"):
      let ofile = cfile & ".o"
      ofiles.add ofile
      var args = opt_args["cppflags"].splitFlags()
      args.add "-o"
      args.add ofile
      args.add cfile
      args.add nimInclude
      log run(opt_args["compiler"], args)

    var args = @["-rcs", output]
    args.add ofiles
    discard run(bindir & "/avr-ar", args)

  else:
    var args = opt_args["cppflags"].splitFlags()
    args.add input
    args.add "-o"
    args.add output
    log run(opt_args["compiler"], args)


proc c() =
  let (input, output) = (opt_args["input"], opt_args["output"])
  #log &"""gcc {input} -> {output}"""
  var args = opt_args["cflags"].splitFlags()
  args.add input
  args.add "-o"
  args.add output
  log run(opt_args["compiler"], args)


proc link() =
  let (input, output) = (opt_args["input"], opt_args["output"])
  #log &"""link {input} -> {output}"""
  let (dir, file) = input.splitPath
  let nimcache = dir & DirSep & "nimcache"

  var args: seq[string]
  for f in walkfiles(nimcache & "/*.o"):
    args.add f
  args.add opt_args["ldflags"].splitWhiteSpace

  args.add "-o"
  args.add output
  log run(opt_args["linker"], args)

# vi: ts=2 sw=2 ft=nim
