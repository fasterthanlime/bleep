
use sdl2, sdl2-mixer
import sdl2/[Core, Mixer]

use deadlogger
import deadlogger/Log

import structs/ArrayList, os/Time, io/FileWriter

Bleep: class {

    logger := static Log getLogger("bleep")
    musicStopListeners := ArrayList<BleepListener> new()

    name: String

    instance: static This

    init: func {
        SDL init(SDL_INIT_EVERYTHING)

        if (Mix openAudio(44100, MixFormat default, 2, 1024)) {
            logger error("Couldn't initialize SDL mixer")
            raise("Error initializing SDL mixer")
        }

        if (instance) {
            logger error("Can't initialize two instances of bleep")
            raise("Can't initialize two instances of bleep")
        }

        instance = this
        Mix hookMusicFinished(_musicFinishedShim)
    }

    _musicFinishedShim: static func {
        // SDL2_mixer is stupid and ugly and doesn't accept
        // a user data pointer to pass to the callback for
        // when the music has stopped, so we have to do this
        // ugly hack.
        instance _musicFinished()
    }

    _musicFinished: func {
        for (l in musicStopListeners) {
            l f()
        }
    }

    allocateChannels: func (numChannels: Int) {
        Mix allocateChannels(numChannels)
    }

    playMusic: func (path: String, loops: Int) {
        logger info("Loading music %s" format(path))
        mus := Mix loadMus(path)
        mus play(loops)
    } 

    stopMusic: func {
        Mix haltMusic()
    }

    fadeMusic: func (milliseconds: Int) {
        Mix fadeOutMusic(milliseconds)
    }

    musicPlaying?: func -> Bool {
        Mix playingMusic()
    }

    musicPaused?: func -> Bool {
        Mix pausedMusic()
    }

    onMusicStop: func (f: Func) -> BleepListener {
        bl := BleepListener new(f)
        musicStopListeners add(bl)
        bl
    }

    unsubscribeOnMusicStop: func (bl: BleepListener) {
        musicStopListeners remove(bl)
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

BleepListener: class {
    f: Func

    init: func (=f)
}

