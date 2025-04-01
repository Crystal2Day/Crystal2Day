# The main module.
# This is globally accessible to allow for a cleaner syntax.
# You will most likely need this for running your game.

module Crystal2Day
  MAX_VOLUME = LibSDL::MIX_MAX_VOLUME

  class_property scene : Crystal2Day::Scene | Nil
  class_property next_scene : Crystal2Day::Scene | Bool | Nil
  class_property limiter : Crystal2Day::Limiter = Crystal2Day::Limiter.new
  class_getter windows : Array(Crystal2Day::Window) = [] of Crystal2Day::Window
  class_property clean_windows_on_scene_exit : Bool = true
  class_property game_data : Crystal2Day::GameData = Crystal2Day::GameData.new
  class_property physics_time_step : Float32 = 1.0
  class_property number_of_physics_steps : UInt32 = 0
  class_property max_number_of_physics_step_splits : UInt32 = 10  # Essentially reduces the physics resolution
  class_property grid_alignment : Int64 = 0
  class_property last_event : Crystal2Day::Event? = nil
  class_property last_colliding_entity : Crystal2Day::Entity? = nil
  class_property database : Crystal2Day::Database = Crystal2Day::Database.new
  class_property input_manager : Crystal2Day::InputManager = Crystal2Day::InputManager.new
  class_property sound_board : Crystal2Day::SoundBoard = Crystal2Day::SoundBoard.new
  class_property custom_loading_path : String = ""

  @@current_window : Crystal2Day::Window?

  @@debug : Bool = false

  def self.rm
    self.current_window.resource_manager
  end

  def self.rm=(value)
    self.current_window.resource_manager = value
  end

  def self.db
    self.database
  end

  def self.db=(value)
    self.database = value
  end

  def self.im
    self.input_manager
  end

  def self.im=(value)
    self.input_manager = value
  end

  def self.sb
    self.sound_board
  end

  def self.sb=(value)
    self.sound_board = value
  end

  macro call_scene_routine(scene, name)
    %scene_temp = {{scene}}
    if %scene_temp.is_a?(Crystal2Day::Scene)
      %scene_temp.{{name.id}}
    else
      puts "WARNING: Scene variable {{scene}} is set to #{%scene_temp.inspect}"
    end
  end

  def self.run(debug : Bool = false)
    Crystal2Day.init(debug: debug)
    {% if CRYSTAL2DAY_CONFIGS_ANYOLITE %}
      Crystal2Day.run_interpreter do
        yield
      end
    {% else %}
      yield
    {% end %}
    Crystal2Day.quit
  end

  def self.convert_to_absolute_path(filename : String)
    original_path = Path[filename]
    if original_path.absolute? || Crystal2Day.custom_loading_path.empty?
      return original_path.expand.to_s
    else
      return Path.new(Crystal2Day.custom_loading_path, original_path).expand.to_s
    end
  end

  def self.main_routine
    @@limiter.set_update_routine do
      if current_scene = @@scene
        Crystal2Day.call_scene_routine(current_scene, :process_events)
        Crystal2Day.call_scene_routine(current_scene, :main_update)
      else
        Crystal2Day.error "Could not update without a scene"
      end

      if !@@next_scene
        if current_scene = @@scene
          Crystal2Day.call_scene_routine(current_scene, :exit_routine)
        else
          Crystal2Day.error "Could not exit empty scene properly"
        end

        @@scene = nil
      elsif @@next_scene != true
        if current_scene = @@scene
          Crystal2Day.call_scene_routine(current_scene, :exit_routine)
        else
          Crystal2Day.error "Could not exit empty scene properly"
        end

        @@scene = @@next_scene.as?(Crystal2Day::Scene).not_nil!
        @@next_scene = true
        Crystal2Day.call_scene_routine(@@scene, :init)
      end
    end

    @@limiter.set_draw_routine do
      if current_scene = @@scene
        Crystal2Day.call_scene_routine(current_scene, :main_draw)
      else
        Crystal2Day.error "Could not draw without a scene"
      end
    end

    @@limiter.set_gc_routine do
      GC.collect
    end

    Crystal2Day.call_scene_routine(@@scene, :init)
    @@next_scene = true

    while @@next_scene
      break if !@@limiter.tick
    end
  end

  def self.init(debug : Bool = false)
    # TODO: Do we need more flags?
    if LibSDL.init(LibSDL::InitFlags::VIDEO | LibSDL::InitFlags::AUDIO) == 0
      Crystal2Day.error "Could not initialize SDL"
    end
    
    if LibSDL.ttf_init == 0
      Crystal2Day.error "Could not initialize SDL_ttf"
    end

    spec = LibSDL::AudioSpec.new(freq: LibSDL::MIX_DEFAULT_FREQUENCY, format: LibSDL::MIX_DEFAULT_FORMAT, channels: LibSDL::MIX_DEFAULT_CHANNELS)

    if LibSDL.mix_open_audio(0, pointerof(spec)) == 0
      Crystal2Day.error "Could not initialize SDL_mixer"
    end

    @@debug = true if debug
  end

  # NOTE: FPS tracking is disabled by default. Calling this function will enable it.
  def self.get_fps
    @@limiter.current_draw_fps
  end

  def self.current_window
    if window = @@current_window
      window
    else
      Crystal2Day.error "No window available"
    end
  end

  def self.current_window_if_any
    @@current_window
  end

  def self.current_window=(window : Crystal2Day::Window?)
    @@current_window = window
  end

  def self.register_window(window : Crystal2Day::Window)
    @@windows.push(window) unless @@windows.includes?(window)
  end

  def self.unregister_window(window : Crystal2Day::Window)
    @@windows.delete(window)
    window.cleanup
  end

  def self.for_window(window : Crystal2Day::Window)
    previous_window = @@current_window
    @@current_window = window
    if win = @@current_window
      if win.open? 
        yield nil
      end
    end
    @@current_window = previous_window
  end

  # TODO: Should these be deprecated?
  def self.with_z_offset(z_offset : Number, render_target : Crystal2Day::RenderTarget = Crystal2Day.current_window)
    render_target.with_z_offset(z_offset) do
      yield nil
    end
  end

  def self.with_view(view : Crystal2Day::View, z_offset : Number = 0u8, render_target : Crystal2Day::RenderTarget = Crystal2Day.current_window)
    render_target.with_view(view, z_offset) do
      yield nil
    end
  end

  def self.with_pinned_view(view : Crystal2Day::View, z_offset : Number = 0u8, render_target : Crystal2Day::RenderTarget = Crystal2Day.current_window)
    render_target.with_pinned_view(view, z_offset) do
      yield nil
    end
  end

  def self.get_mouse_focused_window
    raw_window = LibSDL.get_mouse_focus

    @@windows.each do |window|
      if window.data == raw_window
        return window
      end
    end

    return nil
  end

  def unpin_all(render_target : Crystal2Day::RenderTarget = Crystal2Day.current_window)
    render_target.unpin_all
  end

  def self.quit
    @@windows.each do |window|
      window.cleanup
    end
    @@windows.clear
    @@current_window = nil
    # TODO: Close audio device if necessary
    LibSDL.mix_quit
    LibSDL.ttf_quit
    LibSDL.quit
  end

  def self.error(message : String)
    sdl_error = String.new(LibSDL.get_error)
    raise "#{message}" + (sdl_error.empty? ? "" : " (SDL Error: #{sdl_error})")
  end

  def self.check_for_internal_errors
    sdl_error = String.new(LibSDL.get_error)
    if sdl_error.empty?
      nil
    else
      sdl_error
    end
  end

  def self.debug?
    @@debug
  end

  def self.debug_log(message : String)
    puts "DEBUG: #{message}" if Crystal2Day.debug?
  end

  def self.log(message : String)
    puts "LOG: #{message}"
  end

  def self.warning(message : String)
    puts "WARNING: #{message}"
  end

  def self.poll_events
    while LibSDL.poll_event(out raw_event) != 0
      yield Crystal2Day::Event.new(raw_event)
    end
  end
end
