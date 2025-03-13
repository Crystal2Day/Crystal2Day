# A camera class, which affects all layers above it when drawn.
# It simply shifts all content above it by its position.

module Crystal2Day
  enum CameraMode : UInt8
    FREE
    FIXED_TO_ENTITY
  end
  
  class Camera < Crystal2Day::Drawable
    getter mode : Crystal2Day::CameraMode = CameraMode::FREE
    @position : Crystal2Day::Coords = Crystal2Day.xy
    @target : Crystal2Day::Entity?
    
    def initialize(@position : Crystal2Day::Coords = Crystal2Day.xy, render_target : Crystal2Day::RenderTarget = Crystal2Day.current_window)
      super(render_target)
    end

    def position
      case @mode
      when CameraMode::FIXED_TO_ENTITY then 
        ensure_target.position + @position
      else
        @position
      end
    end

    def position=(value : Coords)
      @position = value
      @mode = CameraMode::FREE
    end

    def follow_entity(entity : Entity, shift : Coords = Crystal2Day.xy)
      @target = entity
      @position = shift
      @mode = CameraMode::FIXED_TO_ENTITY
    end

    def ensure_target
      if target_entity = @target
        target_entity
      else
        Crystal2Day.error "Camera points to no entity"
      end
    end

    def draw_directly(offset : Coords)
      @render_target.renderer.position_shift = (position + offset) * (-1)
    end
  end
end