

template setup*(code: untyped) =
  proc setup*() {.exportc.} =
    code 

template loop*(code: untyped) =
  proc loop*() {.exportc.} =
    code 

const LED_BUILTIN* = 13
const HIGH* = 1
const LOW* = 0
const INPUT* = 0
const OUTPUT* = 1

proc pinMode*(pin, state: uint8) {.importc.}
proc digitalWrite*(led, state: uint8) {.importc.}
proc delay*(s: culong) {.importc.}

type
  HardwareSerial* {.importcpp: "HardwareSerial", header: "Arduino.h", bycopy.} = object


var Serial* {.importcpp: "Serial", header: "Arduino.h".}: HardwareSerial
proc begin*(this: var HardwareSerial; baud: culong) {.importcpp: "begin", header: "Arduino.h".}
proc print*(this: var HardwareSerial; s: cstring) {.importcpp: "print", header: "Arduino.h".}

