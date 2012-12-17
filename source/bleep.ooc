
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

    allocateChannels: func (numChannels: Int) {
        Mix allocateChannels
    }

    playMusic: func (path: String) {
        logger info("Loading music %s" format(path))
        mus := Mix loadMus(path)
        mus play(-1)
    } 

    /* only wav supported */
    loadSample: func (path: String) -> Sample {
        logger info("Loading sample %s" format(path))
        Sample new(Mix loadWav(path))
    }

    destroy: func {
        Mix closeAudio()
    }

}

Sample: class {

    chunk: MixChunk
    channel := -1

    init: func (=chunk) {

    }

    play: func (loops: Int) {
        channel = chunk play(-1, loops)
    }

    stop: func {
        if (channel != -1 && (Mix getChunk(channel) == chunk)) {
            Mix haltChannel(channel)
            channel = -1
        }
    }

}

