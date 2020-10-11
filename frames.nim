import 
  nimPNG, 
  strformat, 
  os, 
  terminal, 
  sequtils, 
  algorithm

var frames : seq[string]
var requested : seq[string] 

for kind, path in walkDir("./frames"):
  requested.add path

echo requested.sorted

proc loadFrame(path: string)=
  let frm = loadPNG32(path)
  var 
    width = frm.width
    height = frm.height
    data = frm.data
    pxSeq = distribute(toseq(data), width * height)

  var 
    buffer: string = ""
    counter: int = 0
    
  for pixel in pxSeq:
    buffer.add "\e[38;2;" & fmt"{int(byte(pixel[0]))};{int(byte(pixel[1]))};{int(byte(pixel[2]))}m█"
    if counter == width :
      buffer.add "\n"
      counter = 0
    counter += 1
  frames.add buffer

for frame in requested.sorted:
  loadFrame(frame)
hideCursor()
eraseScreen()
while true:

  for frame in frames:
    setCursorPos 0, 0
    sleep int(1000/24)
    echo frame

  setCursorPos 0, 0 

echo requested