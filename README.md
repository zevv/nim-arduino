
# Nim for Arduino

Let's start with a warning: this project is only an experimental hack. The
Arduino development environment does not support other languages then C++, and
the authors of the Arduino IDE have not shown any interest in allowing 3d
party langauge integrations. To make this work, we create a fake compiler that
looks like a C++ from the perspective of the Arduino IDE, but is actually a
wrapper around the Nim compiler.

The current status of this project is "Works For Me, but Don't Complain If It
Doesn't For You". I *am* interested in any improvements, patches or other ideas
to make this work better.

There are two distinct parts to this project:

- The host side: on the host the Arduino toolchain is reconfigured to use the
  Nim compiler by changing the normal recipes, this is done my overwriting some
  Arduino IDE parameters in a `platform.local.txt` file. Instead of invoking
  the normal AVR compiler, it will now invoke the `nim_arduino` tool, which
  will cross-compile the sketch with the Nim compiler.

- The Arduino side: in the sketch the `arduino` module can be imported, which
  provides the binding from Nim to the usual Arduino standard library.


## Setup

- If running from git, first do `nimble install` to build the `nim_arduino`
  tool, and `nimble develop` to make the library available in your default
  `.nimble` repo.

- Symlink or copy platform.local.txt into `$ARDUINO/hardware/arduino/avr`

- Make sure ~/.nimble/bin is in your $PATH

- Write your sketch and type Ctrl-R to compile as usual.

Note: the below configuration will reconfigure the default toolchain for the
Arduino IDE, so you can no longer compile normal sketches. I am looking for a
way to make this configurable, but that might require some changes from the
upstream Arduino developers. For now, simply remove the `platform.local.txt`
file from the arduino tree to restore the original configuration.


## Example

```nim
import arduino

setup:
  pinMode LED_BUILTIN, OUTPUT

loop:
  digitalWrite LED_BUILTIN, HIGH
  delay 500
  digitalWrite LED_BUILTIN, LOW  
  delay 500
```

## Misc

When using multiple source files, the Arduino IDE will concatenate all of those and feed them
to the compiler, so this will not allow Nim to use the usual `import` mechanism. Instead, you
can enable code reordering feature in Nim to make this work as expected: use the following
pragma at the top of your sketch:

```nim
`{.experimental: "codeReordering".}`
```
