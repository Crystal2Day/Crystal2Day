# A sound class, which can be used for short-time sound effects.
# Multiple sounds can be played at the same time when using different channels.
# You can also pitch-shift the sounds. However, you should avoid shifting up.
# Shifting the pitch up might sound artificial due to information loss.

# TODO: Is the separation between Sound and Music really necessary?

module Crystal2Day
  class Sound
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
      sound = Crystal2Day::Sound.new
      sound.load_from_file!(filename)

      return sound
    end

    def load_from_file!(filename : String)
      free 

      full_filename = Crystal2Day.convert_to_absolute_path(filename)

      # Load sounds uncompressed
      @data = LibSDL.mix_load_audio(nil, full_filename, LibSDL::CTRUE)
      Crystal2Day.error "Could not load sound from file #{full_filename}" unless @data
    end
  end
end
