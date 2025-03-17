# A sprite class for more flexibility with textures.
# It allows for geometric operations and serves as a thin layer.

module Crystal2Day
  struct SpriteTemplate
    include JSON::Serializable

    @[JSON::Field(key: "texture")]
    property texture_filename : String = ""

    property base_offset : Crystal2Day::Coords = Crystal2Day.xy  # TODO: Rename to offset
    property source_rect : Crystal2Day::Rect?
    property render_rect : Crystal2Day::Rect?
    property animation_template : Crystal2Day::AnimationTemplate = Crystal2Day::AnimationTemplate.new
    property center : Crystal2Day::Coords = Crystal2Day.xy(0.5, 0.5)  # NOTE: This one is too general to be removed
    property z : UInt8 = 0
    # NOTE: All other properties were removed for now, but maybe they can be added for singular sprites again somewhere else
  end

  class Sprite < Crystal2Day::Drawable
    @texture : Crystal2Day::Texture
    
    property base_offset : Crystal2Day::Coords = Crystal2Day.xy
    property source_rect : Crystal2Day::Rect?
    property render_rect : Crystal2Day::Rect?
    property angle : Float32 = 0.0f32
    property center : Crystal2Day::Coords = Crystal2Day.xy(0.5, 0.5)
    property animation : Crystal2Day::Animation = Crystal2Day::Animation.new
    property parallax : Crystal2Day::Coords = Crystal2Day.xy(1.0, 1.0)
    property active : Bool = true
    property flip_x : Bool = false
    property flip_y : Bool = false
    property scale_x : Float32 = 1.0
    property scale_y : Float32 = 1.0
    property blend_color : Crystal2Day::Color = Crystal2Day::Color.white

    def initialize(from_texture : Crystal2Day::Texture = Crystal2Day::Texture.new, source_rect : Crystal2Day::Rect? = nil)
      @source_rect = source_rect
      @texture = from_texture
      super(@texture.render_target)
    end

    def initialize(sprite_template : Crystal2Day::SpriteTemplate, render_target : Crystal2Day::RenderTarget = Crystal2Day.current_window)
      @texture = render_target.resource_manager.load_texture(sprite_template.texture_filename)
      @base_offset = sprite_template.base_offset
      @source_rect = sprite_template.source_rect
      @render_rect = sprite_template.render_rect
      @center = sprite_template.center
      @z = sprite_template.z
      @animation = Animation.new(sprite_template.animation_template)
      super(render_target)
    end

    def update_source_rect_by_frame(frame : UInt16)
      if source_rect = @source_rect
        n_tiles_x = @texture.width // source_rect.width
        source_rect.x = (frame % n_tiles_x) * source_rect.width
        source_rect.y = (frame // n_tiles_x) * source_rect.height
      else
        # TODO: This should only throw an error for a nontrivial frame 
        # Crystal2Day.error "No source rect defined"
      end
    end

    def update
      return unless active
      @animation.update
      if @animation.has_changed # TODO: This might likely be discarded
        update_source_rect_by_frame(@animation.current_frame)
      end
    end

    def link_texture(texture : Crystal2Day::Texture)
      @texture = texture
    end

    def determine_unscaled_render_rect(offset : Coords, ignore_camera_shift : Bool = false)
      final_offset = @base_offset + (ignore_camera_shift ? Crystal2Day.xy : @render_target.parallax_center + (@render_target.renderer.position_shift - @render_target.parallax_center).scale(@parallax)) + offset
      unscaled_render_rect = (render_rect = @render_rect) ? (render_rect + final_offset).data : ((available_source_rect = @source_rect) ? (available_source_rect.unshifted + final_offset).data : @texture.raw_boundary_rect(shifted_by: final_offset))
      return unscaled_render_rect
    end

    def determine_true_center
      # TODO: Simplify this
      final_source_rect = (source_rect = @source_rect) ? source_rect.data : @texture.raw_boundary_rect
      true_center_point = Crystal2Day.xy(@center.x * final_source_rect.w * @scale_x, @center.y * final_source_rect.h * @scale_y)
      return true_center_point
    end

    def determine_final_render_rect(offset : Coords, ignore_camera_shift : Bool = false)
      unscaled_render_rect = determine_unscaled_render_rect(offset, ignore_camera_shift)

      # TODO: This is still a bit complicated, can this be simplified?

      if @flip_x || @flip_y
        cos_value = Math.cos(@angle / 180.0 * Math::PI)
        sin_value = Math.sin(@angle / 180.0 * Math::PI)
      else
        cos_value = 0.0
        sin_value = 0.0
      end

      unflipped_render_x = unscaled_render_rect.x
      unflipped_render_y = unscaled_render_rect.y

      # NOTE: The signs are intended here, this is analoguous to a 2D rotation matrix

      flip_x_correction_for_x = (@flip_x ? (2.0 * @center.x - 1) * @scale_x * unscaled_render_rect.w : 0) * cos_value
      flip_x_correction_for_y = (@flip_x ? (2.0 * @center.x - 1) * @scale_x * unscaled_render_rect.w : 0) * sin_value

      flip_y_correction_for_y = (@flip_y ? (2.0 * @center.y - 1) * @scale_y * unscaled_render_rect.h : 0) * cos_value
      flip_y_correction_for_x = (@flip_y ? (2.0 * @center.y - 1) * @scale_y * unscaled_render_rect.h : 0) * (-sin_value)

      final_render_x = unflipped_render_x + flip_x_correction_for_x + flip_y_correction_for_x
      final_render_y = unflipped_render_y + flip_y_correction_for_y + flip_x_correction_for_y

      final_render_rect = LibSDL::FRect.new(x: final_render_x, y: final_render_y, w: unscaled_render_rect.w * @scale_x, h: unscaled_render_rect.h * @scale_y)
      return final_render_rect
    end

    def draw_directly(offset : Coords)
      return unless active
      final_source_rect = (source_rect = @source_rect) ? source_rect.data : @texture.raw_boundary_rect
      flip_flag = (@flip_x ? LibSDL::FlipMode::HORIZONTAL : LibSDL::FlipMode::NONE) | (@flip_y ? LibSDL::FlipMode::VERTICAL : LibSDL::FlipMode::NONE)
      # TODO: Cache flip flag
      # TODO: Set flip flag based on scale sign and remove flip flag attributes
      # TODO: Optimize this a bit
      true_center_point = determine_true_center
      final_center_point = true_center_point.data
      final_render_rect = determine_final_render_rect(offset)
      LibSDL.set_texture_color_mod(@texture.data, @blend_color.r, @blend_color.g, @blend_color.b)
      LibSDL.render_texture_rotated(renderer_data, @texture.data, pointerof(final_source_rect), pointerof(final_render_rect), @angle, pointerof(final_center_point), flip_flag)
    end
  end
end