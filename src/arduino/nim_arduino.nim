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
  arg <- "--" * key * "=" * val: opt_args[$1] = $2
  key <- >+Alnum
  val <- >+Alnum | '"' * >+(1-'"') * '"'

let r = p.match(cmdLine)
if not r.ok:
  let l1 = r.matchMax
  let l2 = min(r.matchMax+30, cmdLine.len)
  err "Error parsing command line at: " & cmdLine[l1..<l2]



# Dispatch subcommand

proc macros()
proc cpp()
proc c()
proc link()

if opt_cmd == "macros": macros()
elif opt_cmd == "cpp": cpp()
elif opt_cmd == "c": c()
elif opt_cmd == "link": link()
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
    var args = opt_args["cppflags"].splitWhiteSpace()
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
  #log &"""gcc {input} -> {output}"""
  var args = opt_args["cflags"].splitWhiteSpace()
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

