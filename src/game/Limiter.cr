# A singleton class, which schedules drawing and update calls.
# Usually, if your game is designed to run with 60 FPS, you can just ignore this.
# This class is mostly relevant for you if you want to change the FPS.
# You can even schedule the garbage collector with this.

module Crystal2Day
	class Limiter
    property max : UInt32
    property renders_per_second : UInt32
    property ticks_per_second : UInt32
    property gc_per_second : UInt32
    property track_fps : Bool = false

    @counter : UInt32 = 0u32
    @temp_counter : UInt32 = 0u32

    @render_interval : UInt32 = 0u32
    @tick_interval : UInt32 = 0u32
    @gc_interval : UInt32 = 0u32

    @update_block : Proc(Nil) | Nil = nil
    @draw_block : Proc(Nil) | Nil = nil
    @gc_block : Proc(Nil) | Nil = nil

    @current_draw_fps : Float64 = 0.0

    @timer : Time::Instant? = nil

    def reload
      @render_interval = (@max / @renders_per_second).to_u32
			@tick_interval = (@max / @ticks_per_second).to_u32
			@gc_interval = (@max / @gc_per_second).to_u32
    end

    def initialize(@max : UInt32 = 720u32, @renders_per_second : UInt32 = 60u32, @ticks_per_second : UInt32 = 60u32, @gc_per_second : UInt32 = 1u32)
			reload
    end

    def call_block(block : Proc(Nil) | Nil)
      if block.is_a?(Proc)
        block.call
      end
    end

    def set_update_routine(&block)
      @update_block = block
    end

    def set_draw_routine(&block)
      @draw_block = block
    end

    def set_gc_routine(&block)
      @gc_block = block
    end

    def change_renders_per_second(new_value)
			@renders_per_second = new_value
			@render_interval = (@max / @renders_per_second).to_u32
		end

    def current_draw_fps
      @track_fps = true
      @current_draw_fps
    end

    def tick
      @timer = Time.instant unless @timer

      is_update_frame = (@counter % @tick_interval == 0)
			is_draw_frame = (@counter % @render_interval == 0)
			is_gc_frame = (@counter % @gc_interval == 0)

      scheduled_frame = is_update_frame || is_draw_frame || is_gc_frame

      if is_update_frame
				call_block(@update_block)
			end

			return false if !Crystal2Day.scene

			if is_draw_frame
				call_block(@draw_block)
			end

			if is_gc_frame
				call_block(@gc_block)
			end

			@counter += 1

			if @counter == @max
				@counter = 0
			end

			if scheduled_frame
				while (Time.instant - @timer.not_nil!).total_seconds < (@temp_counter + 1) / @max.to_f
				end
        @current_draw_fps = 1.0 / (Time.instant - @timer.not_nil!).total_seconds if @track_fps
				@temp_counter = 0
				@timer = Time.instant
			else
				@temp_counter += 1
			end

			return true
    end
  end
end
