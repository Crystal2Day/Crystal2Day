# Some helper classes for defining and iterating animations

module Crystal2Day
  struct AnimationTemplate
    include JSON::Serializable

    property start_frame : UInt16 = 0u16
    property loop_end_frame : UInt16 = 0u16
    property loop_start_frame : UInt16? = nil
    property repeat_times : Int32 = -1
    property frame_delay : UInt32 = 0
    property return_to_start_after_finishing : Bool = true

    @[JSON::Field(ignore: true)]
    property actual_loop_start_frame : UInt16 = 0u16

    def initialize(@start_frame : UInt16 = 0u16, @loop_end_frame : UInt16 = 0u16, loop_start_frame : UInt16? = nil, @repeat_times : Int32 = -1, @frame_delay : UInt32 = 0)
      @actual_loop_start_frame = @loop_start_frame ? @loop_start_frame.not_nil! : @start_frame
    end

    def after_initialize
      @actual_loop_start_frame = @loop_start_frame ? @loop_start_frame.not_nil! : @start_frame
    end
  end

  class Animation
    getter delay_counter : UInt32 = 0
    getter repeat_counter : UInt32 = 0
    getter current_frame : UInt16 = 0u16
    getter finished : Bool = false
    getter has_changed : Bool = true  # We want the initial change, too
    
    getter template : AnimationTemplate = AnimationTemplate.new

    def initialize(@template : AnimationTemplate = AnimationTemplate.new)
      restart
    end

    def update
      return if @finished
      first_frame = (@repeat_counter == 0 && @delay_counter == @template.frame_delay) # TODO: Maybe this can be optimized
      if @delay_counter == 0
        @delay_counter = @template.frame_delay
        if @current_frame < @template.loop_end_frame
          @current_frame += 1
          @has_changed = true
        else
          @repeat_counter += 1
          if @template.repeat_times >= 0 && @repeat_counter > @template.repeat_times
            if @template.return_to_start_after_finishing
              @current_frame = @template.actual_loop_start_frame 
              @has_changed = true
            end
            @finished = true
          else
            @current_frame = @template.actual_loop_start_frame
            @has_changed = true
          end
        end
      else
        @delay_counter -= 1
        @has_changed = first_frame
      end
    end

    def restart
      @current_frame = @template.start_frame
      @delay_counter = @template.frame_delay
      @repeat_counter = 0
      @finished = false
      @has_changed = true
    end
  end
end
