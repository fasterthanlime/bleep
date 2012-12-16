
use sdl, sdl-mixer
import sdl/[Core, Mixer]

use deadlogger
import deadlogger/Log

import structs/ArrayList, os/Time, io/FileWriter

Bleep: class {

  logger := static Log getLogger("bleep")

  name: String

  init: func {
    SDL init(SDL_INIT_EVERYTHING)

    if (Mix openAudio(44100, MixFormat default, 2, 1024)) {
      "Error initializing SDL mixer" println()
      exit(-1)
    }
  }

  play: func (path: String) {
    playMusic(path)
  }

  playMusic: func (path: String) {
    mus := Mix loadMus(path)
    mus play(0)
  } 

  destroy: func {
  }

}

