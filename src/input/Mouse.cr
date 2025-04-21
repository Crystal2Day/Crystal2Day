# A module to handle mouse state and input.

module Crystal2Day
  module Mouse
    BUTTON_LEFT = LibSDL::MouseButtonFlags::LEFT.to_u32
    BUTTON_MIDDLE = LibSDL::MouseButtonFlags::MIDDLE.to_u32
    BUTTON_RIGHT = LibSDL::MouseButtonFlags::RIGHT.to_u32
    BUTTON_X1 = LibSDL::MouseButtonFlags::X1.to_u32
    BUTTON_X2 = LibSDL::MouseButtonFlags::X2.to_u32

    def self.position_change
      LibSDL.get_relative_mouse_state(out x, out y)
      Crystal2Day::Coords.new(x, y)
    end

    def self.position
      LibSDL.get_mouse_state(out x, out y)
      Crystal2Day::Coords.new(x, y)
    end

    def self.global_position
      LibSDL.get_global_mouse_state(out x, out y)
      Crystal2Day::Coords.new(x, y)
    end

    def self.position=(pos : Crystal2Day::Coords)
      if window = Crystal2Day.current_window_if_any
        LibSDL.warp_mouse_in_window(window.data, pos.x, pos.y)
      else
        Crystal2Day.error "Could not set position in closed or invalid window"
      end
    end

    def self.global_position=(pos : Crystal2Day::Coords)
      LibSDL.warp_mouse_global(pos.x, pos.y)
    end

    def self.focused_window
      Crystal2Day.get_mouse_focused_window
    end

    def self.button_down?(button : Int)
      mouse_state = LibSDL.get_mouse_state(nil, nil).to_i
      LibSDLMacro.button_mask(mouse_state).to_u32 == button
    end

    def self.left_button_down?
      LibSDLMacro.button_mask(LibSDL.get_mouse_state(nil, nil).to_i).to_u32 == BUTTON_LEFT
    end

    def self.right_button_down?
      LibSDLMacro.button_mask(LibSDL.get_mouse_state(nil, nil).to_i).to_u32 == BUTTON_RIGHT
    end

    def self.middle_button_down?
      LibSDLMacro.button_mask(LibSDL.get_mouse_state(nil, nil).to_i).to_u32 == BUTTON_MIDDLE
    end

    def self.set_relative_mode(window : Crystal2Day::Window = Crystal2Day.current_window)
      LibSDL.set_window_relative_mouse_mode(window.data, LibSDL::CBool.new(1))
    end

    def self.reset_relative_mode(window : Crystal2Day::Window = Crystal2Day.current_window)
      LibSDL.set_window_relative_mouse_mode(window.data, LibSDL::CBool.new(0))
    end

    def self.set_window_rect(rect : Crystal2Day::Rect, window : Crystal2Day::Window = Crystal2Day.current_window)
      rect_data = rect.int_data
      LibSDL.set_window_mouse_rect(window.data, pointerof(rect_data))
    end

    def self.reset_window_rect(window : Crystal2Day::Window = Crystal2Day.current_window)
      LibSDL.set_window_mouse_rect(window.data, nil)
    end
  end
end
