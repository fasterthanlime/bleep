
use cubeb
import cubeb

use vorbis
import vorbis

use deadlogger
import deadlogger/Log

import structs/ArrayList, os/Time, io/FileWriter

Bleep: class {

  logger := static Log getLogger("bleep")

  name: String
  context: CubeContext

  init: func {
    context = CubeContext new("bleep")
    if (!context) {
      "Error initializing cubeb stream" println()
      exit(-1)
    }
  }

  play: func (path: String) -> CubeStream {
    oggPlayer := OggPlayer new(context, path)
    oggPlayer start()
    oggPlayer
  } 

  destroy: func {
    context destroy()
  }

}

DataSource: abstract class {

  channels: Int
  rate: Int
  width: Int

  init: func (=channels, =rate, =width) {

  }

  read: abstract func (ptr: Pointer, bytes: Int) -> Int

  getFrameSize: func -> Int {
    channels * width / 8
  }

}

OggSource: class extends DataSource {

  path: String
  file: OggFile

  init: func (=path) {
    "Opening ogg file %s" printfln(path)
    file = OggFile new(path)

    "Opened file, %s endian, %s words, %s" printfln(
      file endianness == OggEndianness LITTLE ? "little" : "big",
      file wordSize == OggWordsize WORD_8BIT ? "8bit" : "16bit",
      file signedness == OggSignedness UNSIGNED ? "unsigned" : "signed"
    )
    "rate = %d, channels = %d" printfln(file info@ rate, file info@ channels)

    super(file info@ channels, file info@ rate, file wordSize == OggWordsize WORD_8BIT ? 8 : 16)
  }

  read: func (ptr: Pointer, bytes: Int) -> Int {
    file read(ptr, bytes)
  }

}

OggPlayer: class extends CubeStream {

  source: DataSource
  pipe: FramePipe
  playing := true

  init: func (context: CubeContext, path: String) {
    source = OggSource new(path)
    pipe = FramePipe new(65_536, source)

    params: CubeStreamParams
    params format = CubeSampleFormat S16LE
    params rate = source rate
    params channels = source channels
    super(context, "oggplayer: %s" format(path), params, 250)
  }

  stateChange: func (state: CubeState) {
    match state {
      case CubeState STARTED =>
        "stream started" println()
      case CubeState STOPPED =>
        "stream stopped" println()
      case CubeState DRAINED =>
        "stream drained" println()
        playing = false
      case =>
        "unknown stream state" println()
    }
  }

  refill: func (dst: Int16*, nframes: Long) -> Long {
    pipe write(dst, nframes)
  }

}

FramePipe: class {

  data: UInt8*
  capacity: Long
  size: Long = 0
  offset: Long = 0
  hasMore := true

  channels: Int
  framesize: Int

  source: DataSource

  init: func (=capacity, =source) {
    framesize = source getFrameSize()
    data = gc_malloc(capacity)
  }

  write: func (dst: UInt8*, requestedFrames: Long) -> Long {
    written := 0
    requested := requestedFrames * framesize

    while (written < requested && hasMore) {
      available := size - offset
      if (available <= 0) {
        read()
        continue
      }

      remaining := requested - written

      copysize := remaining < available ? remaining : available
      memcpy(dst + written, data + offset, copysize)
      offset += copysize
      written += copysize
    }

    written / framesize
  }

  read: func {
    offset = 0
    size = source read(data, capacity)    

    if (size == 0) {
      hasMore = false
    }
  }

}


