# This class serves as a container for multiple entities.
# Use these to group similar entities together, for easier management.
# Using this class also takes care of any mruby memory management.

module Crystal2Day
  class EntityGroup
    BASE_INITIAL_CAPACITY = 128u32

    getter members : Array(Crystal2Day::Entity)

    property skip_physics : Bool = false
    property skip_updates : Bool = false
    property skip_draws : Bool = false
    property skip_events : Bool = false
    property skip_collisions : Bool = false
    
    {% if CRYSTAL2DAY_CONFIGS_ANYOLITE %}
      @refs : Array(Anyolite::RbRef) = [] of Anyolite::RbRef
    {% end %}
    
    @render_target : Crystal2Day::RenderTarget

    def initialize(capacity : UInt32 = BASE_INITIAL_CAPACITY, @render_target : Crystal2Day::RenderTarget = Crystal2Day.current_window)
      @members = Array(Crystal2Day::Entity).new(initial_capacity: capacity)

      {% if CRYSTAL2DAY_CONFIGS_ANYOLITE %}
        @refs = Array(Anyolite::RbRef).new(initial_capacity: capacity)
      {% end %}
    end

    def number
      @members.size
    end

    def add_entity(entity_type_name : String, position : Crystal2Day::Coords = Crystal2Day.xy, initial_param : Crystal2Day::ParamType = nil)
      entity_type = Crystal2Day.database.get_entity_type(entity_type_name)
      new_entity = Crystal2Day::Entity.new(entity_type, render_target: @render_target)
      new_entity.position = position
      register_new_entity(new_entity, initial_param)
      return new_entity
    end

    def add_entity(entity_type : Crystal2Day::EntityType, position : Crystal2Day::Coords = Crystal2Day.xy, initial_param : Crystal2Day::ParamType = nil)
      new_entity = Crystal2Day::Entity.new(entity_type, render_target: @render_target)
      new_entity.position = position
      register_new_entity(new_entity, initial_param)
      return new_entity
    end

    def register_new_entity(entity : Crystal2Day::Entity, initial_param : Crystal2Day::ParamType = nil)
      @members.push entity

      {% if CRYSTAL2DAY_CONFIGS_ANYOLITE %}
        new_ref = Crystal2Day::Interpreter.generate_ref(entity)
        @refs.push new_ref
        entity.init(new_ref, initial_param)
      {% else %}
        entity.init(initial_param)
      {% end %}
      return @members.size
    end

    def get_entity(index : Number)
      @members[index]
    end

    def delete_entity_at(index : Number)
      {% if CRYSTAL2DAY_CONFIGS_ANYOLITE %}
        @members.delete_at(index).delete(@refs.delete_at(index))
      {% else %}
        @members.delete_at(index).delete
      {% end %}
    end

    def update
      return if @skip_updates

      0.upto(@members.size - 1) do |index|
        {% if CRYSTAL2DAY_CONFIGS_ANYOLITE %}
          @members[index].update(@refs[index])
        {% else %}
          @members[index].update
        {% end %}
      end
    end

    def handle_event(event : Crystal2Day::Event)
      return if @skip_events

      Crystal2Day.last_event = event
      0.upto(@members.size - 1) do |index|
        {% if CRYSTAL2DAY_CONFIGS_ANYOLITE %}
          @members[index].handle_event(@refs[index])
        {% else %}
          @members[index].handle_event
        {% end %}
      end
      Crystal2Day.last_event = nil
    end

    def update_physics(time_step : Float32)
      return if @skip_physics

      0.upto(@members.size - 1) do |index|
        {% if CRYSTAL2DAY_CONFIGS_ANYOLITE %}
          @members[index].update_physics(@refs[index], time_step)
        {% else %}
          @members[index].update_physics(time_step)
        {% end %}
      end
    end

    def acceleration_step
      @members.each do |member|
        member.acceleration_step
      end
    end

    def reset_acceleration
      @members.each do |member|
        member.reset_acceleration
      end
    end

    def post_update
      0.upto(@members.size - 1) do |index|
        {% if CRYSTAL2DAY_CONFIGS_ANYOLITE %}
          @members[index].post_update(@refs[index])
        {% else %}
          @members[index].post_update
        {% end %}
      end
    end

    def check_for_collision_with(other : EntityGroup | Map)
      return if @skip_collisions

      if other.is_a?(EntityGroup)
        if other == self
          0.upto(@members.size - 1) do |index_1|
            index_1.upto(@members.size - 1) do |index_2|
              entity_1 = @members[index_1]
              entity_2 = @members[index_2]

              entity_1.check_for_collision_with(entity_2)
            end
          end
        else
          @members.each do |entity_1|
            other.as(EntityGroup).members.each do |entity_2|
              entity_1.check_for_collision_with(entity_2)
            end
          end
        end
      else
        @members.each do |entity|
          entity.check_for_collision_with(other.as(Map))
        end
      end
    end

    def call_collision_hooks(base_name : String)
      0.upto(@members.size - 1) do |index|
        {% if CRYSTAL2DAY_CONFIGS_ANYOLITE %}
          @members[index].call_collision_hooks(base_name, @refs[index])
        {% else %}
          @members[index].call_collision_hooks(base_name)
        {% end %}
      end
    end

    def get_max_velocity
      velocity = Crystal2Day.xy

      @members.each do |entity|
        velocity.x = entity.velocity.x.abs if entity.velocity.abs > velocity.x
        velocity.y = entity.velocity.y.abs if entity.velocity.abs > velocity.y
      end

      velocity
    end

    def clear
      0.upto(@members.size - 1) do |index|
        delete_entity_at(-1)
      end
    end

    def draw(offset : Coords = Crystal2Day.xy)
      return if @skip_draws

      @members.each do |entity|
        entity.draw(offset)
      end
    end

    def finalize
      clear
    end
  end
end
