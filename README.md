
- symlink platform.local.txt into $ARDUINO/hardware/arduino/avr

- make sure ~/.nimble/bin is in your $PATH

- Type some nim in your sketch and hit Ctrl-R

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
