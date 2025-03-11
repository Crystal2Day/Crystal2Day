module Crystal2Day
  class PartConnectionTemplate
    include JSON::Serializable

    property part : Crystal2Day::PartTemplate
    property joint : Crystal2Day::Coords
  end

  class PartTemplate
    include JSON::Serializable

    property z : UInt8 = 0
    # TODO: Add boxes and shapes
    property sprite : String

    property connections = Hash(String, Crystal2Day::PartConnectionTemplate).new
  end

  class PartConnection
    property part : Crystal2Day::Part
    property joint : Crystal2Day::Coords

    def initialize(@part : Crystal2Day::Part, @joint : Crystal2Day::Coords)
    end

    def initialize(template : PartConnectionTemplate, entity : Crystal2Day::Entity, render_target : Crystal2Day::RenderTarget = Crystal2Day.current_window)
      @part = Crystal2Day::Part.new(template.part, entity, render_target)
      @joint = template.joint.dup
    end
  end
  
  class Part
    property z : UInt8 = 0

    # We only want one sprite which serves as the reference for transformations
    getter sprite : Crystal2Day::Sprite

    getter bounding_boxes = Hash(String, Crystal2Day::CollisionShapeBox).new
    getter map_boxes = Hash(String, Crystal2Day::CollisionShapeBox).new
    getter shapes = Hash(String, Crystal2Day::CollisionShape).new
    getter hitshapes = Hash(String, Crystal2Day::CollisionShape).new
    getter hurtshapes = Hash(String, Crystal2Day::CollisionShape).new

    property connections = Hash(String, Crystal2Day::PartConnection).new

    def initialize(@sprite : Crystal2Day::Sprite)
    end

    def initialize(template : Crystal2Day::PartTemplate, entity : Crystal2Day::Entity, render_target : Crystal2Day::RenderTarget = Crystal2Day.current_window)
      @z = template.z
      @sprite = Crystal2Day::Sprite.new(entity.sprite_templates[template.sprite], render_target)
      # TODO: Add boxes
      template.connections.each do |name, connection_template|
        @connections[name] = Crystal2Day::PartConnection.new(connection_template, entity, render_target)
      end
    end

    def get_part(name : String)
      if @connections[name]?
        return @connections[name].part
      else
        # TODO
        Crystal2Day.error("TODO")
      end
    end

    def rotate_by(angle : Number)
      @sprite.angle += angle
      @connections.each_value do |connection|
        connection.part.rotate_by(angle)
      end
    end

    def rotate_to(angle : Number)
      @sprite.angle = angle
      @connections.each_value do |connection|
        connection.part.rotate_to(angle)
      end
    end

    def scale_x_to(value : Number)
      @sprite.scale_x = value
      @connections.each_value do |connection|
        connection.part.scale_x_to(value)
      end
    end

    def scale_y_to(value : Number)
      @sprite.scale_y = value
      @connections.each_value do |connection|
        connection.part.scale_y_to(value)
      end
    end

    # TODO: Respect flipped sprites
    def draw(offset : Coords = Crystal2Day.xy)
      Crystal2Day.with_z_offset(@z) do
        @sprite.draw(offset)

        x_rot = Math.cos(@sprite.angle / 180.0 * Math::PI)
        y_rot = Math.sin(@sprite.angle / 180.0 * Math::PI)

        # Recursion
        @connections.each_value do |connection|
          connection_sprite = connection.part.sprite

          render_rect = @sprite.determine_final_render_rect(offset)
          render_rect_part = connection_sprite.determine_final_render_rect(offset)

          flipped_connection_x = (@sprite.flip_x ? 1.0 - connection.joint.x : connection.joint.x)
          flipped_connection_y = (@sprite.flip_y ? 1.0 - connection.joint.y : connection.joint.y)

          parent_joint_x = (flipped_connection_x - @sprite.center.x) * render_rect.w
          parent_joint_y = (flipped_connection_y - @sprite.center.y) * render_rect.h

          rotated_joint_x = x_rot * parent_joint_x - y_rot * parent_joint_y + render_rect.x + @sprite.center.x * render_rect.w
          rotated_joint_y = y_rot * parent_joint_x + x_rot * parent_joint_y + render_rect.y + @sprite.center.y * render_rect.h

          child_joint_x = connection_sprite.center.x * render_rect_part.w + connection_sprite.position.x * connection_sprite.scale_x
          child_joint_y = connection_sprite.center.y * render_rect_part.h + connection_sprite.position.y * connection_sprite.scale_y

          joint = Crystal2Day.xy(rotated_joint_x - child_joint_x, rotated_joint_y - child_joint_y)

          # NOTE: The position of the part is compensated here again, making it obsolete - only the joints matter
          connection.part.draw(joint)
        end
      end
    end
  end
end
