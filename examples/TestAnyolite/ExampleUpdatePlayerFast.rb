each_frame do
  entity.accelerate(Crystal2Day.xy(0, 1))
  
  x_input = false

  if Crystal2Day.im.key_down?("left")
    x_input = true
    entity.velocity.x = -5
    entity.compound.sprite.flip_x = false
  end
  if Crystal2Day.im.key_down?("right")
    x_input = true
    entity.velocity.x = 5
    entity.compound.sprite.flip_x = true
  end
  if Crystal2Day.im.key_down?("up")
    entity.velocity.y = -5
  end
  if Crystal2Day.im.key_down?("down")
    entity.velocity.y = 5
  end

  entity.velocity.x = 0 unless x_input

  entity.change_hook_page_to("main") unless Crystal2Day.im.key_down?("fast_mode")
end
