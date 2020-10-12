import nimPNG, slappy, times,
  strformat, os, terminal, sequtils, algorithm, system

# load all the frames
proc frameLoader(folder: string): seq[string] =
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
      buffer: string = ""
      counter: int = 0
      
    for pixel in pxSeq:
      if counter == width:
        buffer.add "\n"
        counter = 0
      buffer.add "\e[38;2;" & fmt"{int(byte(pixel[0]))};{int(byte(pixel[1]))};{int(byte(pixel[2]))}m█"
      
      counter += 1
    frames.add buffer

  for i, frame in requested.sorted:
    echo fmt"Loading frame {i}/{len(requested)}"
    loadFrame(frame)
  return frames

var 
  frameseq = frameLoader("./frames")
  threadframes {.threadvar.}: seq[string]
  cont* = true

proc leArtist*() =
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
      var ftime = int( (1000/24) - (delta * 1000))
      if ftime < 0: sleeptime = 0
      else: sleeptime = ftime

      echo "\n\x1b[0m" & fmt"Waiting {sleeptime}ms"
      sleep sleeptime 
  write stdout, "\x1b[0m"




proc main() =

  # Start playing audio when we are about to do something that takes awhile
  slappyInit()
  var 
    sound = newSound("tmp/bna.wav")
    source = sound.play()

  # Uncomment if you want to loop your audio
  #source.looping = true

  var spawned: Thread[void]
  createThread(spawned, leArtist)

  # Simulate doing something for 4 minutes
  sleep 240000
  cont = false
  # give us a moment to catch up
  # continue doing other stuff
  
  slappyClose()


main()

resetAttributes()
eraseScreen()
showCursor()

echo "Press any key to exit"
discard getch()