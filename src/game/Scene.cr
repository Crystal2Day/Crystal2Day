# An abstract scene class.
# Just derive your own scene class from it and overload the empty methods.

module Crystal2Day
  class Scene
    ENTITY_GROUP_INITIAL_CAPACITY = 8
    UPDATE_GROUP_INITIAL_CAPACITY = 8
    PHYSICS_GROUP_INITIAL_CAPACITY = 8
    EVENT_GROUP_INITIAL_CAPACITY = 8
    DRAW_GROUP_INITIAL_CAPACITY = 8
    MAPS_INITIAL_CAPACITY = 8
    UIS_INITIAL_CAPACITY = 8
    SPRITES_INITIAL_CAPACITY = 256
    TEMP_ANIMATIONS_INITIAL_CAPACITY = 8

    property use_own_draw_implementation : Bool = false

    getter entity_groups : Hash(String, EntityGroup) = Hash(String, EntityGroup).new(initial_capacity: ENTITY_GROUP_INITIAL_CAPACITY)
    getter update_groups : Array(EntityGroup) = Array(EntityGroup).new(initial_capacity: UPDATE_GROUP_INITIAL_CAPACITY)
    getter physics_groups : Array(EntityGroup) = Array(EntityGroup).new(initial_capacity: PHYSICS_GROUP_INITIAL_CAPACITY)
    getter event_groups : Array(EntityGroup) = Array(EntityGroup).new(initial_capacity: EVENT_GROUP_INITIAL_CAPACITY)
    getter draw_groups : Array(EntityGroup) = Array(EntityGroup).new(initial_capacity: DRAW_GROUP_INITIAL_CAPACITY)

    getter maps : Hash(String, Map) = Hash(String, Map).new(initial_capacity: MAPS_INITIAL_CAPACITY)
    getter uis : Hash(String, UI) = Hash(String, UI).new(initial_capacity: UIS_INITIAL_CAPACITY)
    getter sprites : Hash(String, Sprite) = Hash(String, Sprite).new(initial_capacity: SPRITES_INITIAL_CAPACITY)
    getter temp_animations : Array(Sprite) = Array(Sprite).new(initial_capacity: TEMP_ANIMATIONS_INITIAL_CAPACITY)

    getter collision_matrix : CollisionMatrix = CollisionMatrix.new

    getter using_imgui : Bool = false

    property pause_auto_update : Bool = false
    property pause_auto_draw : Bool = false
    property pause_auto_draw_ui : Bool = false
    property pause_auto_draw_queue : Bool = false
    property pause_auto_handle_event : Bool = false
    
    def handle_event(event)
    end

    def init
    end

    def exit
    end

    def update
    end

    def post_update
    end

    def draw
    end

    def imgui_draw
    end

    def initialize
    end

    def process_events
      Crystal2Day.poll_events do |event|
        {% if CRYSTAL2DAY_CONFIGS_IMGUI %}
          if @using_imgui
            p = event.data
            ImGuiImplSDL.process_event(pointerof(p))
          end
        {% end %}

        handle_event(event.not_nil!)

        unless @pause_auto_handle_event
          @event_groups.each {|member| member.handle_event(event.not_nil!)}
        end
      end
    end

    def main_update
      unless @pause_auto_update
        # TODO: Maybe rearrange the order if necessary
        @maps.each_value {|map| map.update}
        @sprites.each_value {|sprite| sprite.update}

        @temp_animations.reject! do |anim|
          anim.update
          anim.animation.finished
        end
      end

      update

      unless @pause_auto_update
        @update_groups.each {|member| member.update}

        update_physics

        @update_groups.each {|member| member.post_update}
      end

      post_update
    end

    def get_max_speed
      max_speed = 0.0
      @physics_groups.each do |member|
        max_velocity = member.get_max_velocity
        potential_max_speed = {max_velocity.x, max_velocity.y}.max
        max_speed = potential_max_speed if potential_max_speed > max_speed
      end
      max_speed
    end

    def update_physics
      @physics_groups.each {|member| member.acceleration_step}

      # TODO: Maybe put some graphics resolution factor here
      # TODO: Obtain max speed from first acceleration loop

      if Crystal2Day.number_of_physics_steps == 0
        dynamic_number_of_physics_steps = {Crystal2Day.max_number_of_physics_step_splits, get_max_speed.round.to_i}.min
        dynamic_number_of_physics_steps.times do |i|
          collision_step
          physics_step(Crystal2Day.physics_time_step / dynamic_number_of_physics_steps)
        end
      else
        Crystal2Day.number_of_physics_steps.times do |i|
          collision_step
          physics_step(Crystal2Day.physics_time_step / Crystal2Day.number_of_physics_steps)
        end
      end

      @physics_groups.each {|member| member.reset_acceleration}
    end

    def physics_step(time_step : Float32)
      @physics_groups.each {|member| member.update_physics(time_step)}
    end

    def collision_step
      @collision_matrix.determine_collisions
      @collision_matrix.call_hooks
    end

    def main_draw
      if @use_own_draw_implementation
        call_inner_draw_block
      elsif win = Crystal2Day.current_window_if_any
        win.clear
        call_inner_draw_block
        unless @pause_auto_draw_queue
          win.render
        end
        render_imgui
        win.display
      end
    end

    def exit_routine
      exit
      Crystal2Day.windows.each do |window|
        window.unpin_all
      end
      @update_groups.clear
      @physics_groups.clear
      @event_groups.clear
      @draw_groups.clear
      @entity_groups.clear
      
      @maps.clear
      @uis.clear
      @sprites.clear
      @temp_animations.clear

      GC.collect
    end

    def call_inner_draw_block
      draw
      unless @pause_auto_draw
        @draw_groups.each {|member| member.draw}
      end
      unless @pause_auto_draw_ui
        @uis.each_value {|member| member.draw}
      end
      imgui_frame if @using_imgui
      imgui_draw if @using_imgui
    end

    def add_entity_group(name, auto_update : Bool = false, auto_physics : Bool = false, auto_events : Bool = false, auto_draw : Bool = false, capacity : UInt32 = 0, render_target : RenderTarget = Crystal2Day.current_window)
      if @entity_groups[name]?
        Crystal2Day.warning "Already existing entity group with name '#{name}' will be overwritten"
      end
      
      new_entity_group = capacity == 0 ? EntityGroup.new(render_target: render_target) : EntityGroup.new(capacity: capacity, render_target: render_target)
      @entity_groups[name] = new_entity_group

      @update_groups.push new_entity_group if auto_update
      @physics_groups.push new_entity_group if auto_physics
      @event_groups.push new_entity_group if auto_events
      @draw_groups.push new_entity_group if auto_draw

      return new_entity_group
    end

    def add_entity(group : String, type : String | EntityType, position : Crystal2Day::Coords = Crystal2Day.xy, initial_param : Crystal2Day::ParamType = nil)
      @entity_groups[group].add_entity(type, position, initial_param)
    end

    def add_map(name : String, tileset : Tileset? = nil)
      if @maps[name]?
        Crystal2Day.warning "Already existing map with name '#{name}' will be overwritten"
      end

      new_map = Crystal2Day::Map.new
      new_map.tileset = tileset.not_nil! if tileset
      @maps[name] = new_map

      return new_map
    end

    def add_map_layer(map_name : String)
      if !@maps[map_name]?
        Crystal2Day.error "Map with name '#{map_name}' does not exist"
      end

      new_layer = Crystal2Day::MapLayer.new
      @maps[map_name].add_layer(new_layer)

      return new_layer
    end

    # TODO: Methods to delete maps and UIs

    def add_ui(name : String)
      if @uis[name]?
        Crystal2Day.warning "Already existing UI with name '#{name}' will be overwritten"
      end

      new_ui = UI.new
      @uis[name] = new_ui

      return new_ui
    end

    def add_sprite(name : String, template : Crystal2Day::SpriteTemplate, position : Crystal2Day::Coords = Crystal2Day.xy)
      if @sprites[name]?
        Crystal2Day.warning "Already existing sprite with name '#{name}' will be unpinned and overwritten"
        @sprites[name].unpin
      end

      new_sprite = Sprite.new(template)
      new_sprite.pin(position)
      @sprites[name] = new_sprite

      return new_sprite
    end

    def delete_sprite(name : String)
      if !@sprites[name]?
        Crystal2Day.warning "No existing sprite with '#{name}' found"
      else
        @sprites[name].unpin
        @sprites.delete(name)
      end
    end

    def play_sprite_animation(sprite_template : Crystal2Day::SpriteTemplate, animation_name : String, position : Crystal2Day::Coords = Crystal2Day.xy)
      new_animation = Sprite.new(sprite_template)
      new_animation.pin(position)
      new_animation.run_animation(animation_name)
      @temp_animations.push(new_animation)

      return new_animation
    end

    def init_imgui
      # TODO: Support multiple windows for Imgui instead of just the current one
      {% if CRYSTAL2DAY_CONFIGS_IMGUI %}
        ctx = ImGui.create_context
        win = Crystal2Day.current_window
        ImGuiImplSDL.init(pointerof(ctx), win.data, win.renderer.data)
        @using_imgui = true
      {% else %}
        {% raise "Feature for Imgui is not activated." %}
      {% end %}
    end
  
    def shutdown_imgui
      {% if CRYSTAL2DAY_CONFIGS_IMGUI %}
        @using_imgui = false
        ImGuiImplSDL.shutdown
        ImGui.destroy_context
      {% end %}
    end

    def imgui_frame
      {% if CRYSTAL2DAY_CONFIGS_IMGUI %}
        ImGuiImplSDL.new_frame
        ImGui.new_frame
      {% end %}
    end

    def render_imgui
      {% if CRYSTAL2DAY_CONFIGS_IMGUI %}
        if @using_imgui
          ImGui.render
          ImGuiImplSDL.render(Crystal2Day.current_window.renderer.data)
        end
      {% end %}
    end
  end
end
