import nimPNG, slappy, times,
  strformat, os, terminal, sequtils, algorithm, system, strutils, 
  base64

# Make hardcoded values easier to find
var
  framefolder: string = "./eva2"
  soundfile: string = "tmp/eva.wav"
  loopAudio: bool = true

  framerate: int = 24
  sleeptime: int = 92500

  doCondense: bool = true
  readCondensed: bool = true


# load all the frames
proc frameLoader(folder: string, condense: bool, readCond: bool): seq[string] =
  var 
    frames : seq[string]
    requested : seq[string] 

  for kind, path in walkDir(folder):
    requested.add path

  proc loadFrame(path: string)=
    let frm = loadPNG32(path)
    var 
      width = frm.width
      height = frm.height
      data = frm.data
      pxSeq = distribute(toseq(data), width * height)
      pxSeqRows = distribute(pxSeq, height)
      buffer: string = ""
      counter: int = 0

    for j, row in pxSeqRows:
      # Skip every other row
      if ((j) mod 2) != 1 :
        for i, pixel in row:
          if counter == width:
            buffer.add "\n"
            counter = 0
          var 
            nxtrowPx: seq[char]
          if j + 1 < height:
            nxtrowPx = pxSeqRows[j + 1][i]
            buffer.add "\e[38;2;" & fmt"{int(byte(pixel[0]))};{int(byte(pixel[1]))};{int(byte(pixel[2]))}m" & "\e[48;2;" & fmt"{int(byte(nxtrowPx[0]))};{int(byte(nxtrowPx[1]))};{int(byte(nxtrowPx[2]))}m▀"
          
          counter += 1
    frames.add buffer

  if not readCond:
    for i, frame in requested.sorted:
      echo fmt"Loading frame {i}/{len(requested)}"
      loadFrame(frame)
    
    if condense:
      var buffer: string
      for frame in frames:
        buffer.add encode(frame) & "\n"
      writeFile("condensed.frames", buffer)
      return frames
    else:
      return frames
  else:
    echo "Loading condensed frames file"

    var 
      starttime = cpuTime()
      cond = readFile("condensed.frames")

    echo fmt"Reading file took {(cpuTime() - starttime ) * 1000}ms"
    echo "Splitting file"

    var 
      splitstarttime = cpuTime()
      parseCond = cond.split("\n")
      donetime = (cpuTime() - splitstarttime ) * 1000

    echo fmt"Splitting file took {donetime}ms"
    echo fmt"Parsing {parseCond.len} frames"

    for i, f in parseCond:
      
      frames.add f.decode

    echo fmt"Total loading time: {(cpuTime() - starttime ) * 1000}ms"

    return frames

var 
  frameseq = frameLoader(framefolder, doCondense, readCondensed)
  threadframes {.threadvar.}: seq[string]
  cont* = true

proc leArtist*() {.thread.} =
  {.gcsafe.}:
    deepcopy(threadframes, frameseq)  
  hideCursor()
  eraseScreen()

  var 
    starttime: float
    delta: float
    sleeptime: int = 41
  # Thank you lyla

  while cont:
    for frame in threadframes:

      # Get the current cpu time
      starttime = cpuTime()
      if not cont:
        break
      setCursorPos 0, 0
      write stdout, frame

      # Calculate the time it took to do all that
      delta = cpuTime() - starttime
      
      echo "\n\x1b[0m" & fmt"Frame time: {delta * 1000}ms"

      # Calculate how long we need to wait in order to maintain a smooth 24
      var ftime = int( (1000/framerate) - (delta * 1000))
      if ftime < 0: sleeptime = 0
      else: sleeptime = ftime

      sleep sleeptime 
  write stdout, "\x1b[0m"

proc main() =

  # Start playing audio when we are about to do something that takes awhile
  slappyInit()
  var 
    sound = newSound(soundfile)
    source = sound.play()

  source.looping = loopAudio

  var spawned: Thread[void]
  createThread(spawned, leArtist)

  # Simulate doing something for awhile
  sleep(sleeptime)
  cont = false
  
  slappyClose()


main()

resetAttributes()
eraseScreen()
showCursor()
discard getch()
