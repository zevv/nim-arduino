
# Mostly translated with c2nim from Arduino.h and friends


const LED_BUILTIN* = 13
const HIGH* = 1
const LOW* = 0
const INPUT* = 0
const OUTPUT* = 1


proc F_CPU*(): culong {.importcpp: "F_CPU@".}

template interrupts*() = {.emit:"sei();".}
template nointerrupts*() = {.emit:"cli();".}

proc pinMode*(pin: uint8; mode: uint8) {.importcpp: "pinMode(@)",
                                        header: "Arduino.h".}
proc digitalWrite*(pin: uint8; val: uint8) {.importcpp: "digitalWrite(@)",
    header: "Arduino.h".}
proc digitalRead*(pin: uint8): cint {.importcpp: "digitalRead(@)",
                                    header: "Arduino.h".}
proc analogRead*(pin: uint8): cint {.importcpp: "analogRead(@)", header: "Arduino.h".}
proc analogReference*(mode: uint8) {.importcpp: "analogReference(@)",
                                    header: "Arduino.h".}
proc analogWrite*(pin: uint8; val: cint) {.importcpp: "analogWrite(@)",
                                        header: "Arduino.h".}
proc millis*(): culong {.importcpp: "millis(@)", header: "Arduino.h".}
proc micros*(): culong {.importcpp: "micros(@)", header: "Arduino.h".}
proc delay*(ms: culong) {.importcpp: "delay(@)", header: "Arduino.h".}
proc delayMicroseconds*(us: cuint) {.importcpp: "delayMicroseconds(@)",
                                  header: "Arduino.h".}
proc pulseIn*(pin: uint8; state: uint8; timeout: culong): culong {.
    importcpp: "pulseIn(@)", header: "Arduino.h".}
proc pulseInLong*(pin: uint8; state: uint8; timeout: culong): culong {.
    importcpp: "pulseInLong(@)", header: "Arduino.h".}
proc shiftOut*(dataPin: uint8; clockPin: uint8; bitOrder: uint8; val: uint8) {.
    importcpp: "shiftOut(@)", header: "Arduino.h".}
proc shiftIn*(dataPin: uint8; clockPin: uint8; bitOrder: uint8): uint8 {.
    importcpp: "shiftIn(@)", header: "Arduino.h".}
proc attachInterrupt*(interruptNum: uint8; userFunc: proc (); mode: cint) {.
    importcpp: "attachInterrupt(@)", header: "Arduino.h".}
proc detachInterrupt*(interruptNum: uint8) {.importcpp: "detachInterrupt(@)",
    header: "Arduino.h".}

type
  HardwareSerial* {.importcpp: "HardwareSerial", header: "Arduino.h", bycopy.} = object

var Serial* {.importcpp: "Serial", header: "Arduino.h".}: HardwareSerial
proc begin*(this: var HardwareSerial; baud: cint) {.importcpp: "begin", header: "Arduino.h".}
proc available*(this: var HardwareSerial): cint {.importcpp: "available", header: "Arduino.h".}
proc read*(this: var HardwareSerial): cint {.importcpp: "read", header: "Arduino.h".}
proc write*(this: var HardwareSerial; n: uint8): csize_t {.importcpp: "write", header: "HardwareSerial.h".}
proc print*(this: var HardwareSerial; s: cstring) {.importcpp: "print", header: "Arduino.h".}
proc println*(this: var HardwareSerial; s: cstring) {.importcpp: "println", header: "Arduino.h".}

proc pgmReadByte*(a: ptr uint8): uint8 {.importc:"pgm_read_byte", header:"avr/pgmspace.h" .}

{.pragma: progmem, codegenDecl: "const $# PROGMEM $#" .}

proc myputchar*(c: char, f: FILE): cint {.exportc,cdecl.} =
  discard Serial.write(c.uint8).cint
  result = 0

proc fdevopen*(put: proc (a1: char; a2: FILE): cint {.cdecl.};
               get: proc (a1: FILE): cint {.cdecl.} ): FILE {.importcpp: "fdevopen(@)", header: "stdio.h".}

# Convenience macros for the setup() and loop() functions

template setup*(code: untyped) =
  proc setup*() {.exportc.} =
    stdout = fdevopen(myputchar, nil)
    code 

template loop*(code: untyped) =
  proc loop*() {.exportc.} =
    code 


