use bleep, vorbis
import bleep

import structs/ArrayList, os/Time

main: func (args: ArrayList<String>) {

  bleep := Bleep new()

  path := args size > 1 ? args[1] : "tiling.ogg"
  bleep playMusic(path, 0)

  Time sleepSec(10_000)
  bleep destroy()

}

