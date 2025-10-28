# A simple music class.
# Use it for single background tracks.
# Looping is possible with certain file formats like OGG.

module Crystal2Day
  class Music
    Crystal2DayHelper.wrap_type(Pointer(LibSDL::MixAudio))

    def initialize
    end

    def free
      if @data
        LibSDL.mix_destroy_audio(data)
        @data = nil
      end
    end

    def finalize
      free
    end

    def self.load_from_file(filename : String)
      music = Crystal2Day::Music.new
      music.load_from_file!(filename)

      return music
    end

    def load_from_file!(filename : String)
      free

      full_filename = Crystal2Day.convert_to_absolute_path(filename)

      # Load music compressed
      @data = LibSDL.mix_load_audio(nil, full_filename, LibSDL::CFALSE)
      Crystal2Day.error "Could not load music from file #{full_filename}" unless @data
    end
  end
end
