module Crystal2Day
  class PartConnection
    property part : Crystal2Day::Part
    property joint : Crystal2Day::Coords

    def initialize(@part : Crystal2Day::Part, @joint : Crystal2Day::Coords)
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

          parent_joint_x = (connection.joint.x - @sprite.center.x) * render_rect.w
          parent_joint_y = (connection.joint.y - @sprite.center.y) * render_rect.h

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
