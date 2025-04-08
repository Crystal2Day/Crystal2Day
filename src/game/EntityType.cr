# A template for entities.
# Each instance is essentially a different entity type.
# You can add default state values and coroutines.

module Crystal2Day
  struct ConnectionUpdate
    include JSON::Serializable

    property path : Array(String)
    property value : PartConnectionTemplate
  end

  struct CompoundUpdate
    include JSON::Serializable

    property added_connections = Array(ConnectionUpdate).new
    property removed_connections = Array(Array(String)).new

    def initialize
    end
  end

  struct EntityTypeBase
    include JSON::Serializable
    
    property entity_type : String = ""

    property overwrite_default_state : Bool = false
    property overwrite_options : Bool = false
    property overwrite_coroutine_templates : Bool = false
    property overwrite_bounding_boxes : Bool = false
    property overwrite_map_boxes : Bool = false
    property overwrite_shapes : Bool = false
    property overwrite_hitshapes : Bool = false
    property overwrite_hurtshapes : Bool = false
    property overwrite_compound : Bool = false

    def initialize
    end
  end

  class EntityType
    EMPTY_NAME = "<empty>"
    DEFAULT_NAME = "<default$>"

    @default_state = {} of String => Crystal2Day::Parameter
    @coroutine_templates = {} of String => Crystal2Day::CoroutineTemplate

    @options = Hash(String, Int64).new

    @bounding_boxes = Hash(String, Crystal2Day::CollisionShapeBox).new
    @map_boxes = Hash(String, Crystal2Day::CollisionShapeBox).new
    @shapes = Hash(String, Crystal2Day::CollisionShape).new
    @hitshapes = Hash(String, Crystal2Day::CollisionShape).new
    @hurtshapes = Hash(String, Crystal2Day::CollisionShape).new

    @compound : Crystal2Day::PartTemplate? = nil
    @compound_updates = CompoundUpdate.new

    @based_on : EntityTypeBase = EntityTypeBase.new
    
    property name : String = EMPTY_NAME

    def initialize(name : String = EMPTY_NAME)
      if name == EMPTY_NAME
        @name = DEFAULT_NAME.gsub("$", object_id.to_s)
      else
        @name = name
      end
    end

    def based_on?(other_type_name : String)
      if @name == other_type_name
        return true
      elsif @based_on.entity_type == other_type_name
        return true
      elsif @based_on.entity_type != ""
        Crystal2Day.database.get_entity_type(@based_on.entity_type).based_on?(other_type_name)
      else
        return false
      end
    end

    # TODO: Add hitshapes, hurtshapes, etc to the following routine

    def initialize(pull : JSON::PullParser)
      pull.read_object do |key|
        case key
        when "name" then @name = pull.read_string
        when "based_on" then @based_on = EntityTypeBase.from_json(pull.read_raw)
        when "options"
          pull.read_object do |option_key|
            @options[option_key] = pull.read_int
          end
        when "default_state"
          pull.read_object do |state_key|
            add_default_state_from_raw_json(name: state_key, raw_json: pull.read_raw)
          end
        when "compound"
          @compound = Crystal2Day::PartTemplate.from_json(pull.read_raw)
        when "compound_updates"
          @compound_updates = Crystal2Day::CompoundUpdate.from_json(pull.read_raw)
        when "coroutine_templates"
          pull.read_object do |coroutine_key|
            # TODO: Cache loaded files, similar to textures
            pull.read_object do |coroutine_type|
              case coroutine_type
              when "file"
                full_filename = Crystal2Day.convert_to_absolute_path(pull.read_string)
                coroutine = Crystal2Day::CoroutineTemplate.from_string(File.read(full_filename), "entity")
                add_coroutine_template(coroutine_key, coroutine)
              when "code"
                coroutine = Crystal2Day::CoroutineTemplate.from_string(pull.read_string, "entity")
                add_coroutine_template(coroutine_key, coroutine)
              when "proc"
                coroutine = Crystal2Day::CoroutineTemplate.from_proc_name(pull.read_string)
                add_coroutine_template(coroutine_key, coroutine)
              when "pages"
                string_hash = Hash(String, String).new
                proc_hash = Hash(String, String).new

                pull.read_object do |page_name|
                  pull.read_object do |page_coroutine_type|
                    case page_coroutine_type
                    when "file"
                      full_filename = Crystal2Day.convert_to_absolute_path(pull.read_string)
                      string_hash[page_name] = File.read(full_filename)
                    when "code"
                      string_hash[page_name] = pull.read_string
                    when "proc"
                      proc_hash[page_name] = pull.read_string
                    else
                      Crystal2Day.error "Unknown EntityType loading option for pages: #{coroutine_type}"
                    end
                  end
                end

                coroutine = Crystal2Day::CoroutineTemplate.from_hashes(string_hash, proc_hash, "entity")
                add_coroutine_template(coroutine_key, coroutine)
              else
                Crystal2Day.error "Unknown EntityType loading option: #{coroutine_type}"
              end
            end
          end
        when "map_boxes"
          pull.read_object do |box_key|
            add_map_box_from_raw_json(name: box_key, raw_json: pull.read_raw)
          end
        when "bounding_boxes"
          pull.read_object do |box_key|
            add_collision_box_from_raw_json(name: box_key, raw_json: pull.read_raw)
          end
        when "shapes"
          pull.read_object do |shape_key|
            add_collision_shape_from_raw_json(name: shape_key, raw_json: pull.read_raw)
          end
        when "hitshapes"
          # TODO
        when "hurtshapes"
          # TODO
        when "description"
          # TODO
        end
      end
    end
    
    {% if CRYSTAL2DAY_CONFIGS_ANYOLITE %}
      def add_default_state(name : String, value)
        @default_state[name] = Crystal2Day::Interpreter.generate_ref(value)
      end
    {% else %}
      def add_default_state(name : String, value : Crystal2Day::ParamType)
        @default_state[name] = Crystal2Day::Parameter.new(value)
      end
    {% end %}

    def add_default_state_from_raw_json(name : String, raw_json : String)
      {% if CRYSTAL2DAY_CONFIGS_ANYOLITE %}
        @default_state[name] = Crystal2Day::Interpreter.convert_json_to_ref(raw_json)
      {% else %}
        @default_state[name] = Crystal2Day::Parameter.new(Crystal2Day::Parameter.convert_json_to_value(raw_json))
      {% end %}
    end

    def add_coroutine_template(name : String, template : Crystal2Day::CoroutineTemplate)
      @coroutine_templates[name] = template
    end

    def add_collision_box(name : String,collision_box : Crystal2Day::CollisionShapeBox)
      @bounding_boxes[name] = collision_box
    end

    def add_collision_box_from_raw_json(name : String,raw_json : String)
      @bounding_boxes[name] = Crystal2Day::CollisionShapeBox.from_json(raw_json)
    end

    def add_collision_shape(name : String,collision_shape : Crystal2Day::CollisionShape)
      @shapes[name] = collision_box
    end

    def add_collision_shape_from_raw_json(name : String,raw_json : String)
      @shapes[name] =  Crystal2Day::CollisionShape.from_json(raw_json)
    end

    def add_map_box(name : String,collision_box : Crystal2Day::CollisionShapeBox)
      @map_boxes[name] =  collision_box
    end

    def add_map_box_from_raw_json(name : String,raw_json : String)
      @map_boxes[name] =  Crystal2Day::CollisionShapeBox.from_json(raw_json)
    end

    # TODO: Adding routines for hitshapes and hurtshapes
    # TODO: Maybe add some checks for duplicates

    def transfer_default_state
      unless @based_on.entity_type.empty?
        if @based_on.overwrite_default_state
          @default_state
        else
          Crystal2Day.database.get_entity_type(@based_on.entity_type).transfer_default_state.merge(@default_state)
        end
      else
        @default_state
      end
    end

    def transfer_coroutine_templates
      unless @based_on.entity_type.empty?
        if @based_on.overwrite_coroutine_templates
          @coroutine_templates
        else
          Crystal2Day.database.get_entity_type(@based_on.entity_type).transfer_coroutine_templates.merge(@coroutine_templates)
        end
      else
        @coroutine_templates
      end
    end

    def transfer_bounding_boxes
      unless @based_on.entity_type.empty?
        if @based_on.overwrite_bounding_boxes
          @bounding_boxes
        else
          Crystal2Day.database.get_entity_type(@based_on.entity_type).transfer_bounding_boxes.merge(@bounding_boxes)
        end
      else
        @bounding_boxes
      end
    end

    def transfer_map_boxes
      unless @based_on.entity_type.empty?
        if @based_on.overwrite_map_boxes
          @map_boxes
        else
          Crystal2Day.database.get_entity_type(@based_on.entity_type).transfer_map_boxes.merge(@map_boxes)
        end
      else
        @map_boxes
      end
    end

    def transfer_shapes
      unless @based_on.entity_type.empty?
        if @based_on.overwrite_shapes
          @shapes
        else
          Crystal2Day.database.get_entity_type(@based_on.entity_type).transfer_shapes.merge(@shapes)
        end
      else
        @shapes
      end
    end

    def transfer_hitshapes
      unless @based_on.entity_type.empty?
        if @based_on.overwrite_hitshapes
          @hitshapes
        else
          Crystal2Day.database.get_entity_type(@based_on.entity_type).transfer_hitshapes.merge(@hitshapes)
        end
      else
        @hitshapes
      end
    end

    def transfer_hurtshapes
      unless @based_on.entity_type.empty?
        if @based_on.overwrite_hurtshapes
          @hurtshapes
        else
          Crystal2Day.database.get_entity_type(@based_on.entity_type).transfer_hurtshapes.merge(@hurtshapes)
        end
      else
        @hurtshapes
      end
    end

    def transfer_options
      unless @based_on.entity_type.empty?
        if @based_on.overwrite_options
          @options
        else
          Crystal2Day.database.get_entity_type(@based_on.entity_type).transfer_options.merge(@options)
        end
      else
        @options
      end
    end

    def transfer_compound
      unless @based_on.entity_type.empty?
        if @based_on.overwrite_compound
          base_compound = @compound
        else
          base_compound = Crystal2Day.database.get_entity_type(@based_on.entity_type).transfer_compound
        end
      else
        base_compound = @compound
      end

      if @compound_updates.removed_connections.empty? && @compound_updates.added_connections.empty?
        return base_compound
      elsif !base_compound
        Crystal2Day.error("Could not add or remove connections to/from empty compound")
      else
        return PartTemplate.generate_modified(base_compound.not_nil!, @compound_updates)
      end
    end
  end
end
