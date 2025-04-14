module Crystal2Day
  class Database
    ENTITY_TYPES_INITIAL_CAPACITY = 256
    ENTITY_PROCS_INITIAL_CAPACITY = 1024

    @entity_types = Hash(String, Crystal2Day::EntityType).new(initial_capacity: ENTITY_TYPES_INITIAL_CAPACITY)
    @entity_procs = Hash(String, Proc(Entity, Nil)).new(initial_capacity: ENTITY_PROCS_INITIAL_CAPACITY)

    def load_entity_type_from_file(filename)
      full_filename = Crystal2Day.convert_to_absolute_path(filename)

      entity_type = Crystal2Day::EntityType.from_json_file(filename)
      if @entity_types[entity_type.name]?
        Crystal2Day.debug_log "Updated entity type: #{entity_type.name} from #{full_filename}."
      end
      @entity_types[entity_type.name] = entity_type
    end

    def get_entity_type(name)
      @entity_types[name]
    end

    def add_entity_proc(name : String, proc : Proc(Entity, Nil))
      @entity_procs[name] = proc
    end

    def add_entity_proc(name : String, &proc : Crystal2Day::Entity -> Nil)
      @entity_procs[name] = proc
    end

    def call_entity_proc(name : String, entity : Crystal2Day::Entity)
      @entity_procs[name].call(entity)
    end
  end
end
