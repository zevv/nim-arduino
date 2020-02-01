import arduino
import math


setup:
  Serial.begin 115200
  pinMode LED_BUILTIN, OUTPUT
  echo "Hello, Nim!"

const intensity = [    
  0.uint8, 0, 0, 16, 32, 64, 128, 254, 254, 200, 150, 100, 60, 40, 30,
  30, 60, 120, 240, 230, 200, 170, 140, 110, 90, 70, 50, 40, 30, 20, 10,
  7, 5, 4, 3, 2, 1, 0, 0, 0, 0, 0, 0, 0, 0 
]


var i: int

loop:
  for j in 0..100:
    let v = intensity[i]
    digitalWrite LED_BUILTIN, HIGH
    delayMicroseconds(v)
    digitalWrite LED_BUILTIN, LOW  
    delayMicroseconds(254-v)
  i = (i + 1) mod (sizeof intensity)

