
# Nim for Arduino

This is an experimental project to allow integration of the Nim programming
language into the Arduino IDE. There are two distinct parts to this:

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

```
import arduino

setup:
  pinMode LED_BUILTIN, OUTPUT

loop:
  digitalWrite LED_BUILTIN, HIGH
  delay 500
  digitalWrite LED_BUILTIN, LOW  
  delay 500
```
