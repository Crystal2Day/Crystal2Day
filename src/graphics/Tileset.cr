# Tile information for maps.
# These specify what exactly to draw when rendering a tile.
# Also, you can extend the `Tile` class for custom tile information.

module Crystal2Day
  class Tile
    FLAGS_INITIAL_CAPACITY = 16

    # Hard-coded options
    property name : String = ""
    property dummy : Bool = false # Marks a tile as being in the tileset for animation purposes only (NOTE: It still has an individual Tile ID!)
    property no_collision : Bool = false  # The tile will not be tested for any collisions, TODO: Do we need this here?

    @flags = Hash(String, Bool).new(initial_capacity: FLAGS_INITIAL_CAPACITY)
    # TODO: More options in other data formats
  
    def initialize
    end

    def get_flag(name : String, default_value : Bool = false)
      @flags[name]? ? @flags[name] : default_value
    end

    def set_flag(name : String, value : Bool = true)
      @flags[name] = value
    end
  end

  struct TileAnimationFrame
    property tile : TileID = 0
    property duration : UInt32 = 0
    property cumulative_duration : UInt32 = 0

    def initialize(@tile : TileID, @duration : UInt32, @cumulative_duration : UInt32)
    end
  end

  class Tileset
    INITIAL_CAPACITY = 256

    getter texture : Crystal2Day::Texture = Crystal2Day::Texture.new
    property tile_width : UInt32 = 50u32
    property tile_height : UInt32 = 50u32
    
    property tiles : Array(Tile) = Array(Tile).new(initial_capacity: INITIAL_CAPACITY)
    property animations : Array(Array(TileAnimationFrame)) = Array(Array(TileAnimationFrame)).new(initial_capacity: INITIAL_CAPACITY)

    {% if CRYSTAL2DAY_CONFIGS_ANYOLITE %}
      @refs : Array(Anyolite::RbRef) = Array(Anyolite::RbRef).new(initial_capacity: INITIAL_CAPACITY)
    {% end %}

    def initialize
    end

    # TODO: Add support for different render targets
    def initialize(pull : JSON::PullParser)
      pull.read_object do |key|
        case key
        when "texture"
          @texture = Crystal2Day.rm.load_texture(pull.read_string)
        when "tile_width"
          @tile_width = pull.read_int.to_u32
        when "tile_height"
          @tile_height = pull.read_int.to_u32
        when "tiles"
          pull.read_array do
            new_tile = Tile.new
            pull.read_object do |tile_property|
              case tile_property
              when "name"
                new_tile.name = pull.read_string
              when "dummy"
                new_tile.dummy = pull.read_bool
              when "no_collision"
                new_tile.no_collision = pull.read_bool
              else
                # TODO: Maybe add more options than bools?
                new_tile.set_flag(tile_property, pull.read_bool)
              end
            end
            add_tile(new_tile)
          end
        end
      end
    end

    def link_texture(texture : Crystal2Day::Texture)
      @texture = texture
    end
  
    def get_tile(identification : Crystal2Day::TileID)
      @tiles[identification]? ? @tiles[identification] : Crystal2Day.error "Undefined tile with tile ID: #{identification}"
    end
  
    def size
      @tiles.size
    end
  
    def add_tile(tile : Tile)
      {% if CRYSTAL2DAY_CONFIGS_ANYOLITE %}
        new_ref = Crystal2Day::Interpreter.generate_ref(tile)
        @refs.push new_ref
      {% end %}
      
      @tiles.push(tile)
    end

    def fill_with_default_tiles(number : UInt32)
      number.times {add_tile(Tile.new)}
    end
  
    def tiles
      @tiles
    end

    def max_duration(tile_id : TileID)
      @animations[tile_id].empty? ? 1 : @animations[tile_id].last.cumulative_duration
    end

    def load_from_tiled_file!(filename : String, given_texture : Texture? = nil)
      full_filename = Crystal2Day.convert_to_absolute_path(filename)

      parsed_tileset = Tiled.parse_tileset_from_file(full_filename)

      @tile_width = parsed_tileset.tilewidth
      @tile_height = parsed_tileset.tileheight

      if given_texture
        @texture = given_texture
      else
        @texture = Crystal2Day.rm.load_texture(Crystal2Day.convert_to_absolute_path(parsed_tileset.image.not_nil!.source.not_nil!))
      end

      parsed_tileset.tilecount.times do |tile_id|
        add_tile(Tile.new)
        @animations.push(Array(TileAnimationFrame).new)
      end

      parsed_tileset.array_tile.each do |parsed_tile|
        tile_id = parsed_tile.id

        if properties = parsed_tile.properties
          properties.array_property.each do |prop|
            if prop.name == "no_collision"
              @tiles[tile_id].no_collision = true
            elsif prop.type == "bool"
              @tiles[tile_id].set_flag(prop.name, prop.value != "0")
            else
              # Currently unsupported, might receive support in the future
            end
          end
        end

        total_duration = 0u32
        if anim = parsed_tile.animation
          anim.array_frame.each do |tile_anim|
            total_duration += tile_anim.duration
            frame = TileAnimationFrame.new(tile_anim.tileid.as(TileID), tile_anim.duration, total_duration)
            @animations[tile_id].push(frame)
          end
        end
      end
    end
  end
end
