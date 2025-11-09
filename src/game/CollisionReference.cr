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
    @tileset : Tileset? = nil

    def initialize(kind : Kind, other_object : Entity | Tile | Nil = nil, other_position : Coords = Crystal2Day.xy, tileset : Tileset? = nil)
      @kind = kind
      @other_object = other_object
      @other_position = other_position
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

    def tile_overlap_on_x_axis(entity : Crystal2Day::Entity)
      (entity.position.x - @other_position.x - tileset.tile_width // 2).abs < entity.map_boxes["MapBox"].size.x
    end

    def tile_overlap_on_y_axis(entity : Crystal2Day::Entity)
      (entity.position.y - @other_position.y - tileset.tile_height // 2).abs < entity.map_boxes["MapBox"].size.y
    end
  end
end
