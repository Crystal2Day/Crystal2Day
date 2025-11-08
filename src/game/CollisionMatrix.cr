module Crystal2Day
  class CollisionMatrix
    ELEMENTS_INITIAL_CAPACITY = 16
    MATRIX_INITIAL_CAPACITY = ELEMENTS_INITIAL_CAPACITY * ELEMENTS_INITIAL_CAPACITY

    @elements : Array(EntityGroup | Map) = Array(EntityGroup | Map).new(initial_capacity: ELEMENTS_INITIAL_CAPACITY)
    @matrix : Hash(Tuple(Int32, Int32), Bool) = Hash(Tuple(Int32, Int32), Bool).new(initial_capacity: MATRIX_INITIAL_CAPACITY)

    @hook_base_name : String

    def initialize(@hook_base_name : String)
    end

    def add(obj : EntityGroup | Map)
      @elements.push obj
    end

    def link(obj_1 : EntityGroup | Map, obj_2 : EntityGroup | Map = obj_1)
      @elements.push obj_1 unless @elements.index(obj_1)
      @elements.push obj_2 unless @elements.index(obj_2)

      index_1 = @elements.index(obj_1).not_nil!
      index_2 = @elements.index(obj_2).not_nil!

      set_entry(index_1, index_2, true)
    end

    def set_entry(index_1 : Int, index_2 : Int, value : Bool = true)
      @matrix[{index_1, index_2}.minmax] = value
    end

    def get_entry(index_1 : Int, index_2 : Int)
      @matrix[{index_1, index_2}.minmax]?
    end

    def determine_collisions
      0.upto(@elements.size - 1) do |index_1|
        index_1.upto(@elements.size - 1) do |index_2|
          if get_entry(index_1, index_2)
            @elements[index_1].check_for_collision_with(@elements[index_2])
          end
        end
      end
    end

    def call_hooks
      @elements.each do |element|
        if element.is_a?(EntityGroup)
          element.as(EntityGroup).call_collision_hooks(@hook_base_name)
        end
      end
    end
  end
end
