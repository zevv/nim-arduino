import os, strutils, parseopt, osproc, npeg, tables, strformat, streams

# Helper procs

const nimInclude = "-I/home/ico/external/Nim/lib/"

proc err(s: string) =
  echo "\e[31;1m" & s & "\e[0m"
  quit 1

proc log(s: string) =
  echo "\e[33;1m" & s & "\e[0m"

proc dbg(s: string) =
  echo "\e[30;1m" & s & "\e[0m"

proc run(cmd: string, args: seq[string]): string =
  dbg "run: " & cmd & " " & args.join(" ")
  let p = startProcess(cmd, args=args, options={poUsePath,poStdErrToStdOut})
  let o = p.outputStream.readAll()
  let rv = p.waitForExit()
  p.close()
  if rv != 0:
    err "Error running command\n" & o
  result = o

  #let r = execCmd(s & " 2>&1")
  #if r != 0: err "Error executing command"

# Parse command line arguments. parseOpts has problems with whitespace in
# arguments, so for now do it with Npeg

let cmdLine = commandLineParams().join(" ")
var opt_cmd: string
var opt_args: Table[string, string]

let p = peg line:
  S <- *Space
  line <- cmd * S * ?args * !1
  args <- arg * *(S * arg)
  cmd <- +Alnum: opt_cmd = $0
  arg <- "--" * key * "=" * val: opt_args[$1] = $2
  key <- >+Alnum
  val <- >+Alnum | '"' * >+(1-'"') * '"'

if not p.match(cmdLine).ok:
  err "Error parsing command line"


# Dispatch subcommand

proc macros()
proc cpp()
proc c()

if opt_cmd == "macros": macros()
elif opt_cmd == "cpp": cpp()
elif opt_cmd == "c": c()
else: err "Unhandled command " & opt_cmd


# Preprocessor stage: run the sketch through the nim compiler and pass all the
# resulting cpp files through the preprocessor with the given command line.

proc macros() =
  log &"""macros {opt_args["input"]} -> {opt_args["output"]}"""

  let (input, output) = (opt_args["input"], opt_args["output"])
  let (dir, file) = input.splitPath
  let nimsrc = dir & DirSep & "sketch.nim"
  let nimcache = dir & DirSep & "nimcache"

  copyFile(opt_args["input"], nimsrc)
 
  let args = @[ "cpp",
                "-c",
                "--cpu:avr",
                "--os:any",
                "--gc:arc",
                "--nimcache:" & nimcache,
                "--exceptions:goto",
                "--noMain",
                "-d:noSignalHandler",
                "-d:danger",
                "-d:useMalloc",
                nimsrc]

  discard run("nim", args)
  
  var fout = open(opt_args["output"], fmWrite)
  
  for f in os.walkfiles(nimcache & "/*.cpp"):
    let cmd = opt_args["compiler"]
    var args = opt_args["cppflags"].splitWhiteSpace()
    args.add niminclude
    args.add f

    let o = run(cmd, args)
    fout.write(o)

  fout.close()


# Compilation stage

proc cpp() =
  let (input, output, compiler) = (opt_args["input"], opt_args["output"], opt_args["compiler"])
  let (dir, file) = input.splitPath
  let (bindir, _) = compiler.splitPath
  let nimsrc = dir & DirSep & "sketch.nim"
  let nimcache = dir & DirSep & "nimcache"
  log &"""g++ {input} -> {output}"""

  var ofiles: seq[string]
  if input.contains("sketch"):
    log "sketch"
    for cfile in os.walkfiles(nimcache & "/*.cpp"):
      let ofile = cfile & ".o"
      ofiles.add ofile
      var args = opt_args["cppflags"].splitWhiteSpace()
      args.add "-o"
      args.add ofile
      args.add cfile
      args.add nimInclude
      log run(opt_args["compiler"], args)

    var args = @["-rcs", output]
    args.add ofiles
    discard run(bindir & "/avr-ar", args)

  else:
    var args = opt_args["cppflags"].splitWhiteSpace()
    args.add input
    args.add "-o"
    args.add output
    log run(opt_args["compiler"], args)

proc c() =
  let (input, output) = (opt_args["input"], opt_args["output"])
  log &"""gcc {input} -> {output}"""
  var args = opt_args["cflags"].splitWhiteSpace()
  args.add input
  args.add "-o"
  args.add output
  log run(opt_args["compiler"], args)

