import slappy, os, math


slappyInit()
block:
  echo "playing ogg file"
  let sound = newSound("tmp/bna.wav")
  assert sound.duration != 0
  echo "duration ", sound.duration
  discard sound.play()
  sleep(3000)

slappyClose()