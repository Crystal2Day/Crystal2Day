module Crystal2Day
  struct CollisionReference
    enum Kind : UInt8
      EMPTY
      ENTITY
      TILE
    end
    
    property kind : Kind = Kind::EMPTY
    property other_object : Entity | Tile | Nil = nil
    property other_position : Coords = Crystal2Day.xy
    property shape_own : CollisionShape = CollisionShapePoint.new
    property shape_other : CollisionShape = CollisionShapePoint.new

    @tileset : Tileset? = nil

    def initialize(kind : Kind, other_object : Entity | Tile | Nil, shape_own : CollisionShape, shape_other : CollisionShape, other_position : Coords = Crystal2Day.xy, tileset : Tileset? = nil)
      @kind = kind
      @other_object = other_object
      @other_position = other_position
      @shape_own = shape_own
      @shape_other = shape_other
      @tileset = tileset
    end

    def tileset
      @tileset.not_nil!
    end

    def tileset=(value : Tileset?)
      @tileset = value
    end

    def with_tile?
      @kind == Kind::TILE
    end

    def with_entity?
      @kind = Kind::ENTITY
    end

    def tile
      if with_tile?
        other_object.as(Tile)
      else
        Crystal2Day.error "Collision reference is not for a tile"
      end
    end

    def entity
      if with_entity?
        other_object.as(Entity)
      else
        Crystal2Day.error "Collision reference is not for an entity"
      end
    end

    def inspect
      "Kind: #{@kind}, with: #{other_object}"
    end

    # TODO: Test these

    # These functions test whether a given entity and a tile overlap if projected onto a given axis.
    # Note that this excludes point-like overlap. This might seem odd, but these functions actually have a use.
    # Imagine a scenario with the following tiles:
    # EXXX
    # XTXX
    # If E is the entity, X a solid tile and T a tile to be checked for interaction, you likely don't want E to interact with T.
    # However, a direct box collision will give a positive collision result, so you can use the methods presented here to avoid that.
    # If however the X right to E is removed and E moves a pixel to the right, it will correctly interact with T again.

    def tile_overlap_on_x_axis?(entity : Crystal2Day::Entity)
      (entity.position.x + @shape_own.position.x - @other_position.x).abs < @shape_own.as(CollisionShapeBox).size.x // 2 + @shape_other.as(CollisionShapeBox).size.x // 2
    end

    def tile_overlap_on_y_axis?(entity : Crystal2Day::Entity)
      (entity.position.y + @shape_own.position.y - @other_position.y).abs < @shape_own.as(CollisionShapeBox).size.y // 2 + @shape_other.as(CollisionShapeBox).size.y // 2
    end

    def tile_touching_at_the_left?(entity : Crystal2Day::Entity)
      line_start = @shape_own.position
      line = CollisionShapeLine.new(line_start, Crystal2Day.xy(0, @shape_own.as(CollisionShapeBox).size.y))
      
      return Collider.test(line, entity.position, @shape_other, @other_position)
    end

    def tile_touching_at_the_right?(entity : Crystal2Day::Entity)
      line_start = @shape_own.position + Crystal2Day.xy(@shape_own.as(CollisionShapeBox).size.x, 0)
      line = CollisionShapeLine.new(line_start, Crystal2Day.xy(0, @shape_own.as(CollisionShapeBox).size.y))
      
      return Collider.test(line, entity.position, @shape_other, @other_position)
    end

    def tile_touching_at_the_top?(entity : Crystal2Day::Entity)
      line_start = @shape_own.position
      line = CollisionShapeLine.new(line_start, Crystal2Day.xy(@shape_own.as(CollisionShapeBox).size.x, 0))
      
      return Collider.test(line, entity.position, @shape_other, @other_position)
    end

    def tile_touching_at_the_bottom?(entity : Crystal2Day::Entity)
      line_start = @shape_own.position + Crystal2Day.xy(0, @shape_own.as(CollisionShapeBox).size.y)
      line = CollisionShapeLine.new(line_start, Crystal2Day.xy(@shape_own.as(CollisionShapeBox).size.x, 0))
      
      return Collider.test(line, entity.position, @shape_other, @other_position)
    end

    def entity_center_inside_tile?(entity : Crystal2Day::Entity)
      entity_center_point = CollisionShapePoint.new(@shape_own.position + @shape_own.as(CollisionShapeBox).size * 0.5)
      return true if Collider.test(entity_center_point, entity.position, @shape_other, @other_position)
    end

    def tile_overlapping_at_the_left?(entity : Crystal2Day::Entity)
      distance = entity.position.x + @shape_own.position.x - @other_position.x
      return (distance > 0) && (distance < (@shape_own.as(CollisionShapeBox).size.x // 2 + @shape_other.as(CollisionShapeBox).size.x // 2))
    end

    def tile_overlapping_at_the_right?(entity : Crystal2Day::Entity)
      distance = entity.position.x + @shape_own.position.x - @other_position.x
      return (distance < 0) && (distance > -(@shape_own.as(CollisionShapeBox).size.x // 2 + @shape_other.as(CollisionShapeBox).size.x // 2))
    end

    def tile_overlapping_at_the_top?(entity : Crystal2Day::Entity)
      distance = entity.position.y + @shape_own.position.y - @other_position.y
      return (distance > 0) && (distance < (@shape_own.as(CollisionShapeBox).size.y // 2 + @shape_other.as(CollisionShapeBox).size.y // 2))
    end

    def tile_overlapping_at_the_bottom?(entity : Crystal2Day::Entity)
      distance = entity.position.y + @shape_own.position.y - @other_position.y
      return (distance < 0) && (distance > -(@shape_own.as(CollisionShapeBox).size.y // 2 + @shape_other.as(CollisionShapeBox).size.y // 2))
    end

    def tile_touching_without_edges_at_the_left?(entity : Crystal2Day::Entity)
      return tile_overlap_on_y_axis?(entity) && tile_touching_at_the_left?(entity)
    end

    def tile_touching_without_edges_at_the_right?(entity : Crystal2Day::Entity)
      return tile_overlap_on_y_axis?(entity) && tile_touching_at_the_right?(entity)
    end

    def tile_touching_without_edges_at_the_top?(entity : Crystal2Day::Entity)
      return tile_overlap_on_x_axis?(entity) && tile_touching_at_the_top?(entity)
    end

    def tile_touching_without_edges_at_the_bottom?(entity : Crystal2Day::Entity)
      return tile_overlap_on_x_axis?(entity) && tile_touching_at_the_bottom?(entity)
    end

    def tile_overlapping_without_edges_at_the_left?(entity : Crystal2Day::Entity)
      return tile_overlap_on_y_axis?(entity) && tile_overlapping_at_the_left?(entity)
    end

    def tile_overlapping_without_edges_at_the_right?(entity : Crystal2Day::Entity)
      return tile_overlap_on_y_axis?(entity) && tile_overlapping_at_the_right?(entity)
    end

    def tile_overlapping_without_edges_at_the_top?(entity : Crystal2Day::Entity)
      return tile_overlap_on_x_axis?(entity) && tile_overlapping_at_the_top?(entity)
    end

    def tile_overlapping_without_edges_at_the_bottom?(entity : Crystal2Day::Entity)
      return tile_overlap_on_x_axis?(entity) && tile_overlapping_at_the_bottom?(entity)
    end

    # TODO: Add more checks for positioning?
  end
end
