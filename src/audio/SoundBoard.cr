module Crystal2Day
  class SoundBoard
    # TODO: Store a pointer to the mixer for more flexibility

    @sound_channels : Array(Pointer(LibSDL::MixTrack)) = [] of Pointer(LibSDL::MixTrack)
    @music_channels : Array(Pointer(LibSDL::MixTrack)) = [] of Pointer(LibSDL::MixTrack)

    def create_channels(mixer : Pointer(LibSDL::MixMixer), num_sound_channels : UInt8 = 8u8, num_music_channels : UInt8 = 1u8)
      0.upto(num_sound_channels - 1) do |i|
        @sound_channels.push(LibSDL.mix_create_track(mixer))
      end
      
      0.upto(num_music_channels - 1) do |i|
        @music_channels.push(LibSDL.mix_create_track(mixer))
      end
    end

    def free
      if @sound_channels.size > 0
        @sound_channels.clear
      end

      if @music_channels.size > 0
        @music_channels.clear
      end
    end

    def finalize
      free
    end

    def play_sound(filename : String, channel : Int = 0, volume : Float = 1.0, pitch : Float = 1.0, number_of_loops : Int = 0)
      sound = Crystal2Day.rm.load_sound(filename)

      LibSDL.mix_set_track_audio(@sound_channels[channel], sound.data)

      LibSDL.mix_set_track_gain(@sound_channels[channel], volume)
      LibSDL.mix_set_track_frequency_ratio(@sound_channels[channel], pitch)

      properties = LibSDL.create_properties
      LibSDL.set_number_property(properties, LibSDL::MIX_PROP_PLAY_LOOPS_NUMBER, number_of_loops)

      LibSDL.mix_play_track(@sound_channels[channel], properties)

      LibSDL.destroy_properties(properties)
    end

    def pause_sound(channel : Int = 0, fadeout_frames : Int = 0)
      LibSDL.mix_stop_track(@sound_channels[channel], fadeout_frames)
    end

    def sound_playing?(channel : Int = 0)
      return (LibSDL.mix_track_playing(@sound_channels[channel]) != 0)
    end

    def play_music(filename : String, channel : Int = 0, volume : Float = 1.0, pitch : Float = 1.0, number_of_loops : Int = -1)
      music = Crystal2Day.rm.load_music(filename)

      LibSDL.mix_set_track_audio(@music_channels[channel], music.data)
      
      LibSDL.mix_set_track_gain(@music_channels[channel], volume)
      LibSDL.mix_set_track_frequency_ratio(@music_channels[channel], pitch)

      properties = LibSDL.create_properties
      LibSDL.set_number_property(properties, LibSDL::MIX_PROP_PLAY_LOOPS_NUMBER, number_of_loops)

      LibSDL.mix_play_track(@music_channels[channel], properties)

      LibSDL.destroy_properties(properties)
    end

    def pause_music(channel : Int = 0, fadeout_frames : Int = 0)
      LibSDL.mix_stop_track(@music_channels[channel], fadeout_frames)
    end

    def resume_music(channel : Int = 0)
      LibSDL.mix_resume_track(@music_channels[channel])
    end

    def rewind_music(channel : Int = 0)
      LibSDL.mix_set_track_playback_position(@music_channels[channel], 0)
    end

    def music_playing?(channel : Int = 0)
      return (LibSDL.mix_track_playing(@music_channels[channel]) != 0)
    end
  end
end
