each_frame do
  entity.each_entity_collision do |collision|
    if entity.is_type?("Player") && collision.entity.is_exactly_type?("Figure")
      initial_param = collision.entity.get_initial_param
      # The following frequencies are for the notes [a, g, f, e, d], so this is essentially some weird pitch-shifted d minor
      pitches = [440.0, 391.995, 349.228, 329.628, 293.665]
      entity.set_state("sound_pitch", pitches[initial_param] / 440.0)
      entity.set_state("sound_channel", initial_param)
      entity.call_proc("PlaySound")
    end
    collision.entity.velocity.y = -1
  end
end
