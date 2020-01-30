
import arduino

var rxbuf: string
var newData: bool

proc recvWithEndMarker() =
  while Serial.available > 0:
    let c = Serial.read().char
    if rxbuf.len < 32:
      rxbuf.add c
    if c == '\n':
      newData = true

proc showNewData() =
  if newData:
    Serial.println "This just in ... "
    Serial.println rxbuf
    newData = false
    rxbuf = ""
    
setup:
  Serial.begin 9600
  Serial.println "<Arduino is ready>"

loop:
  recvWithEndMarker()
  showNewData()

