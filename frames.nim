import nimPNG, threadproxy, slappy,
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
      buffer.add "\e[38;2;" & fmt"{int(byte(pixel[0]))};{int(byte(pixel[1]))};{int(byte(pixel[2]))}m█"
      if counter == width :
        buffer.add "\n"
        counter = 0
      counter += 1
    frames.add buffer

  for frame in requested.sorted:
    loadFrame(frame)
  return frames

var 
  frameseq = frameLoader("./frames")
  threadframes {.threadvar.}: seq[string]
  cont = true
  threadcont {.threadvar.}: bool

proc leArtist() =
  {.gcsafe.}:
    deepcopy(threadframes, frameseq)  
  hideCursor()
  eraseScreen()

  while true:
    if not cont:
      break
    for frame in threadframes:
      if not cont:
        break
      setCursorPos 0, 0
      sleep int(1000/35)
      echo frame


proc main() =

  # Start playing audio when we are about to do something that takes awhile
  slappyInit()
  var 
    sound = newSound("tmp/bna.wav")
    source = sound.play()
  source.looping = true
 # proxy.createThread("drawFrames", leArtist) 
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

discard getch()