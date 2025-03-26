# An overlay to the renderer, which allows for z-ordering and pinned objects.
# Unless you explicitly want to build your own rendering system, you can leave this alone.

module Crystal2Day
  class RenderQueue
    NUMBER_OF_LAYERS = 256
    INITIAL_CAPACITY = 100

    alias ContentTuple = Tuple(Drawable, Coords)
    alias ContentDeque = Deque(ContentTuple)
    alias ContentArray = StaticArray(ContentDeque, NUMBER_OF_LAYERS)

    @static_content : ContentArray = ContentArray.new do |i|
      capacity = Crystal2Day::RenderQueue::INITIAL_CAPACITY
      Crystal2Day::RenderQueue::ContentDeque.new(initial_capacity: capacity)
    end

    @content : ContentArray = ContentArray.new do |i|
      capacity = Crystal2Day::RenderQueue::INITIAL_CAPACITY
      Crystal2Day::RenderQueue::ContentDeque.new(initial_capacity: capacity)
    end
    
    @highest_z : UInt8 = 0
    @highest_static_z : UInt8 = 0

    def initialize
    end

    def add(obj : Drawable, z : UInt8, offset : Coords)
      @content[z].push({obj, offset})
      @highest_z = z if z > @highest_z
    end

    def add_static(obj : Drawable, z : UInt8, offset : Coords)
      @static_content[z].push({obj, offset})
      @highest_static_z = z if z > @highest_static_z
    end

    def delete_static(obj : Drawable, z : UInt8)
      @static_content[z].delete(@static_content[z].find{|element| element[0] == obj})
      # TODO: Maybe even check for the proper z coordinate instead of passing it?
      # TODO: Maybe update @highest_static_z
    end

    def delete_static_content
      0.upto(@highest_static_z) do |z|
        @static_content[z].clear
      end
      @highest_static_z = 0
    end

    # Draw contents and clear the queue
    def draw
      max_z = {@highest_z, @highest_static_z}.max

      0.upto(max_z) do |z|
        if z <= @highest_static_z
          @static_content[z].each do |element|
            element[0].draw_directly(element[1])
          end
        end
        if z <= @highest_z
          @content[z].reject! do |element|
            element[0].draw_directly(element[1])
            true
          end
        end
      end
      @highest_z = 0
    end
  end
end
