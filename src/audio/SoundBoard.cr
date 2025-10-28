module Crystal2Day
  class SoundBoard
    Crystal2DayHelper.wrap_type(Pointer(LibSDL::MixMixer))

    @sound_channels : Array(Pointer(LibSDL::MixTrack)) = [] of Pointer(LibSDL::MixTrack)
    @music_channels : Array(Pointer(LibSDL::MixTrack)) = [] of Pointer(LibSDL::MixTrack)

    def create_channels(mixer : Pointer(LibSDL::MixMixer), num_sound_channels : UInt8 = 8u8, num_music_channels : UInt8 = 1u8)
      @data = mixer

      0.upto(num_sound_channels - 1) do |i|
        @sound_channels.push(LibSDL.mix_create_track(data))
      end
      
      0.upto(num_music_channels - 1) do |i|
        @music_channels.push(LibSDL.mix_create_track(data))
      end
    end

    def free
      # Channels are automatically freed when the mixer is destroyed, so we just need to clear the arrays
      if @sound_channels.size > 0
        @sound_channels.clear
      end

      if @music_channels.size > 0
        @music_channels.clear
      end

      if @data
        LibSDL.mix_destroy_mixer(data)
        @data = nil
      end
    end

    def finalize
      free
    end

    def volume
      LibSDL.mix_get_master_gain(data)
    end

    def volume=(value : Number)
      LibSDL.mix_set_master_gain(data, value)
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

    def stop_sound(channel : Int = 0, fadeout_time_in_ms : Int = 0)
      LibSDL.mix_stop_track(@sound_channels[channel], fadeout_time_in_ms)
    end

    def pause_sound(channel : Int = 0)
      LibSDL.mix_pause_track(@sound_channels[channel])
    end

    def resume_sound(channel : Int = 0)
      LibSDL.mix_resume_track(@sound_channels[channel])
    end

    def sound_playing?(channel : Int = 0)
      return (LibSDL.mix_track_playing(@sound_channels[channel]) != 0)
    end

    def tag_sound_channel(channel : Int, tag : String)
      LibSDL.mix_tag_track(@sound_channels[channel], tag)
    end

    def untag_sound_channel(channel : Int, tag : String)
      LibSDL.mix_untag_track(@sound_channels[channel], tag)
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

    def stop_music(channel : Int = 0, fadeout_time_in_ms : Int = 0)
      LibSDL.mix_stop_track(@music_channels[channel], fadeout_time_in_ms)
    end

    def pause_music(channel : Int = 0)
      LibSDL.mix_pause_track(@music_channels[channel])
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

    def tag_music_channel(channel : Int, tag : String)
      LibSDL.mix_tag_track(@music_channels[channel], tag)
    end

    def untag_music_channel(channel : Int, tag : String)
      LibSDL.mix_untag_track(@music_channels[channel], tag)
    end

    def set_volume_for_tag(tag : String, volume : Float = 1.0)
      LibSDL.mix_set_tag_gain(data, tag, volume)
    end

    def pause_for_tag(tag : String)
      LibSDL.mix_pause_tag(data, tag)
    end

    def stop_for_tag(tag : String, fadeout_time_in_ms : Int = 0)
      LibSDL.mix_stop_tag(data, tag, fadeout_time_in_ms)
    end

    def resume_for_tag(tag : String)
      LibSDL.mix_resume_tag(data, tag)
    end
  end
end
