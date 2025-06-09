module Crystal2Day
  struct PartConnectionTemplate
    include JSON::Serializable

    property part : Crystal2Day::PartTemplate
    property joint : Crystal2Day::Coords = Crystal2Day.xy
    property rigid : Bool = false

    def dup
      return_value = PartConnectionTemplate.new(part: @part.dup, joint: @joint.dup)
      return_value.rigid = @rigid

      return return_value
    end

    def initialize(@part : Crystal2Day::PartTemplate, @joint : Crystal2Day::Coords)
    end
  end

  struct PartTemplate
    include JSON::Serializable

    property z : UInt8 = 0
    # TODO: Add boxes and shapes
    property sprite : String

    property angle : Float32 = 0.0f32
    property center : Crystal2Day::Coords? = nil
    property parallax : Crystal2Day::Coords = Crystal2Day.xy(1.0, 1.0)
    property active : Bool = true
    property flip_x : Bool = false
    property flip_y : Bool = false
    property scale_x : Float32 = 1.0
    property scale_y : Float32 = 1.0
    property starting_animation : String? = nil
    property reset_base_offset : Bool = false

    property connections = Hash(String, Crystal2Day::PartConnectionTemplate).new

    def dup
      return_value = PartTemplate.new(sprite: @sprite.dup)

      return_value.z = @z
      return_value.angle = @angle
      return_value.center = @center.dup
      return_value.parallax = @parallax.dup
      return_value.flip_x = @flip_x
      return_value.flip_y = @flip_y
      return_value.scale_x = @scale_x
      return_value.scale_y = @scale_y
      return_value.starting_animation = @starting_animation.dup
      return_value.reset_base_offset = @reset_base_offset
    
      @connections.each do |name, connection|
        return_value.connections[name] = connection.dup
      end

      return return_value
    end

    def self.generate_modified(base : PartTemplate, updates : CompoundUpdate)
      new_copy = base.dup

      updates.removed_connections.each do |connection|
        current_part = new_copy
        connection[0..-2].each do |path_iterator|
          current_part = current_part.connections[path_iterator].part
        end
        current_part.connections.delete(connection[-1])
      end

      updates.added_connections.each do |connection|
        current_part = new_copy
        connection.path[0..-2].each do |path_iterator|
          current_part = current_part.connections[path_iterator].part
        end
        current_part.connections[connection.path[-1]] = connection.value.dup
      end

      return new_copy
    end

    def initialize(@sprite : String)
    end
  end

  class PartConnection
    property part : Crystal2Day::Part
    property joint : Crystal2Day::Coords
    property rigid : Bool

    def initialize(@part : Crystal2Day::Part, @joint : Crystal2Day::Coords = Crystal2Day.xy, @rigid : Bool = false)
    end

    def initialize(template : PartConnectionTemplate, entity : Crystal2Day::Entity, render_target : Crystal2Day::RenderTarget = Crystal2Day.current_window)
      @part = Crystal2Day::Part.new(template.part, entity, render_target)
      @joint = template.joint.dup
      @rigid = template.rigid
    end
  end
  
  class Part
    property z : UInt8 = 0

    # We only want one sprite which serves as the reference for transformations
    property sprite : Crystal2Day::Sprite

    getter bounding_boxes = Hash(String, Crystal2Day::CollisionShapeBox).new
    getter map_boxes = Hash(String, Crystal2Day::CollisionShapeBox).new
    getter shapes = Hash(String, Crystal2Day::CollisionShape).new
    getter hitshapes = Hash(String, Crystal2Day::CollisionShape).new
    getter hurtshapes = Hash(String, Crystal2Day::CollisionShape).new

    property connections = Hash(String, Crystal2Day::PartConnection).new

    def initialize(@sprite : Crystal2Day::Sprite)
    end

    # TODO: Remove entity from constructor?
    def initialize(template : Crystal2Day::PartTemplate, entity : Crystal2Day::Entity, render_target : Crystal2Day::RenderTarget = Crystal2Day.current_window)
      @z = template.z # NOTE: This is additional to the sprite z coordinate

      @sprite = Crystal2Day::Sprite.new(render_target.resource_manager.load_sprite_template(template.sprite), render_target, template.starting_animation)
      @sprite.base_offset = Crystal2Day.xy if template.reset_base_offset

      @sprite.angle = template.angle
      if cen = template.center
        @sprite.center = cen
      end
      @sprite.parallax = template.parallax
      @sprite.active = template.active
      @sprite.flip_x = template.flip_x
      @sprite.flip_y = template.flip_y
      @sprite.scale_x = template.scale_x
      @sprite.scale_y = template.scale_y

      # TODO: Add boxes
      template.connections.each do |name, connection_template|
        @connections[name] = Crystal2Day::PartConnection.new(connection_template, entity, render_target)
      end
    end

    def part(name : String)
      if @connections[name]?
        return @connections[name].part
      else
        Crystal2Day.error("Part '#{name}' was not found")
      end
    end

    def part(names : Array(String) = [] of String)
      current_part = self
      names.each do |name|
        current_part = current_part.part(name)
      end
      return current_part
    end

    def rotate_by(angle : Number)
      @sprite.angle += angle
      @connections.each_value do |connection|
        next if connection.rigid
        connection.part.rotate_by(angle)
      end
    end

    def rotate_to(angle : Number)
      @sprite.angle = angle.to_f32
      @connections.each_value do |connection|
        next if connection.rigid
        connection.part.rotate_to(angle)
      end
    end

    def scale_x_by(factor : Number)
      @sprite.scale_x *= factor
      @connections.each_value do |connection|
        next if connection.rigid
        connection.part.scale_x_by(factor)
      end
    end

    def scale_y_by(factor : Number)
      @sprite.scale_y *= factor
      @connections.each_value do |connection|
        next if connection.rigid
        connection.part.scale_y_by(factor)
      end
    end

    def scale_x_to(value : Number)
      @sprite.scale_x = value.to_f32
      @connections.each_value do |connection|
        next if connection.rigid
        connection.part.scale_x_to(value)
      end
    end

    def scale_y_to(value : Number)
      @sprite.scale_y = value.to_f32
      @connections.each_value do |connection|
        next if connection.rigid
        connection.part.scale_y_to(value)
      end
    end

    def flip_x_axis
      @sprite.flip_x = !@sprite.flip_x
      @connections.each_value do |connection|
        next if connection.rigid
        connection.part.flip_x_axis
      end
    end

    def flip_y_axis
      @sprite.flip_y = !@sprite.flip_y
      @connections.each_value do |connection|
        next if connection.rigid
        connection.part.flip_y_axis
      end
    end

    def flip_x_axis_to(value : Bool)
      if @sprite.flip_x != value
        @sprite.flip_x = value
        @connections.each_value do |connection|
          next if connection.rigid
          connection.part.flip_x_axis
        end
      end
    end

    def flip_y_axis_to(value : Bool)
      if @sprite.flip_y != value
        @sprite.flip_y = value
        @connections.each_value do |connection|
          next if connection.rigid
          connection.part.flip_y_axis
        end
      end
    end

    # TODO: Couple this to Anyolite (currently excluded)
    def each_part(args : Array(String) = [] of String, &block : Array(String), Part -> Nil)
      yield args, self
      @connections.each do |name, connection|
        new_args = args + [name]
        connection.part.each_part(new_args, &block)
      end
    end

    def update
      @sprite.update
      @connections.each_value do |connection|
        connection.part.update
      end
    end

    def draw(offset : Coords = Crystal2Day.xy)
      @sprite.render_target.with_z_offset(@z) do
        @sprite.draw(offset)

        x_rot = Math.cos(@sprite.flipped_angle / 180.0 * Math::PI)
        y_rot = Math.sin(@sprite.flipped_angle / 180.0 * Math::PI)

        # Recursion
        @connections.each_value do |connection|
          connection_sprite = connection.part.sprite

          render_rect = @sprite.determine_final_render_rect(offset, ignore_camera_shift: true)
          render_rect_part = connection_sprite.determine_final_render_rect(offset, ignore_camera_shift: true)

          flipped_connection_x = (@sprite.flip_x ? 1.0 - connection.joint.x : connection.joint.x)
          flipped_connection_y = (@sprite.flip_y ? 1.0 - connection.joint.y : connection.joint.y)

          parent_joint_x = (flipped_connection_x - @sprite.center.x) * render_rect.w
          parent_joint_y = (flipped_connection_y - @sprite.center.y) * render_rect.h

          rotated_joint_x = x_rot * parent_joint_x - y_rot * parent_joint_y + render_rect.x + @sprite.center.x * render_rect.w
          rotated_joint_y = y_rot * parent_joint_x + x_rot * parent_joint_y + render_rect.y + @sprite.center.y * render_rect.h

          child_joint_x = connection_sprite.center.x * render_rect_part.w
          child_joint_y = connection_sprite.center.y * render_rect_part.h

          joint = Crystal2Day.xy(rotated_joint_x - child_joint_x, rotated_joint_y - child_joint_y)

          connection.part.draw(joint)
        end
      end
    end
  end
end
