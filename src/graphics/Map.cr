# Two map classes, one for the actual map data and one for the rendering.

module Crystal2Day
  alias TileID = UInt32

  struct MapComboInfo
    property total_width_in_chunks : UInt32 = 0
    property total_height_in_chunks : UInt32 = 0
    property chunk_width : UInt32 = 0
    property chunk_height : UInt32 = 0
    property number_of_maps : UInt32 = 0
    property chunks : Array(Array(UInt32)) = [] of Array(UInt32)
    property map_starting_points : Array(Tuple(UInt32, UInt32)) = [] of Tuple(UInt32, UInt32)

    def intitialize
    end

    def get_from_parsed_json!(parsed_stream : JSON::Any)
      @total_width_in_chunks = parsed_stream["total_width_in_chunks"].as_i.to_u32
      @total_height_in_chunks = parsed_stream["total_height_in_chunks"].as_i.to_u32
      @chunk_width = parsed_stream["chunk_width"].as_i.to_u32
      @chunk_height = parsed_stream["chunk_height"].as_i.to_u32
      @chunks = parsed_stream["data"].as_a.map {|row| row.as_a.map{|element| element.as_i.to_u32}}
      
      map_names = parsed_stream["maps"].as_a.map {|name| name.as_s}

      @number_of_maps = map_names.size.to_u32
      @map_starting_points = Array(Tuple(UInt32, UInt32)).new(size: @number_of_maps, value: {@total_width_in_chunks, @total_height_in_chunks})

      0.upto(@number_of_maps - 1) do |i|
        0.upto(@total_height_in_chunks - 1) do |current_chunk_y|
          0.upto(@total_width_in_chunks - 1) do |current_chunk_x|
            map_index = @chunks[current_chunk_y][current_chunk_x]
            if map_index != 0
              old_starting_point = @map_starting_points[map_index - 1]
              lowest_starting_x = {old_starting_point[0], current_chunk_x}.min.to_u32
              lowest_starting_y = {old_starting_point[1], current_chunk_y}.min.to_u32
              @map_starting_points[map_index - 1] = {lowest_starting_x, lowest_starting_y}
            end
          end
        end
      end
    end
  end

  class MapCombo
    getter background_tile : TileID = 0u32  # NOTE: This is a background tile for when no chunk is found
    property combo_info : MapComboInfo = MapComboInfo.new
    property map_list : Array(MapContent) = [] of MapContent

    def width
      @combo_info.total_width_in_chunks * @combo_info.chunk_width
    end

    def height
      @combo_info.total_height_in_chunks * @combo_info.chunk_height
    end

    def background_tile=(value : TileID)
      @background_tile = value
      @map_list.each {|map_content| map_content.background_tile = @background_tile}
    end

    def get_tile(x : Int32, y : Int32)
      chunk_x = x // @combo_info.chunk_width
      chunk_y = y // @combo_info.chunk_height
      if chunk_x < 0 || chunk_x >= @combo_info.total_width_in_chunks || chunk_y < 0 || chunk_y >= @combo_info.total_height_in_chunks
        return @background_tile
      else
        chunk = @combo_info.chunks[chunk_y][chunk_x]
        if chunk == 0
          return @background_tile
        else
          relative_x = x - @combo_info.map_starting_points[chunk - 1][0] * @combo_info.chunk_width
          relative_y = y - @combo_info.map_starting_points[chunk - 1][1] * @combo_info.chunk_height
          return @map_list[chunk - 1].get_tile(relative_x, relative_y)
        end
      end
    end

    def load_from_tiled_layer!(parsed_layer : Tiled::Layer)
      # TODO: Error as this should not be implemented
    end

    def update_animations(tileset : Tileset)
      @map_list.each{|content| content.update_animations(tileset)}
    end

    # TODO: Add loading routine for non-tiled maps (or don't)

    # NOTE: Only use this to stream single layers - might become deprecated eventually
    def stream_from_file!(filename : String)
      full_filename = Crystal2Day.convert_to_absolute_path(filename)

      File.open(full_filename, "r") do |f|
        parsed_stream = JSON.parse(f)

        combo_info = MapComboInfo.new
        combo_info.get_from_parsed_json!(parsed_stream)
        
        map_names = parsed_stream["maps"].as_a.map {|name| name.as_s}
        parsed_maps = map_names.map {|map_name| Tiled.parse_map_from_file(Crystal2Day.convert_to_absolute_path(map_name))}

        @combo_info = combo_info
        @map_list = Array(MapContent).new(initial_capacity: combo_info.number_of_maps)

        0.upto(map_names.size - 1) do |i|
          map_content = MapContent.new
          map_content.load_from_tiled_layer!(parsed_maps[i].array_layer[layer_id])
          @map_list.push map_content
        end
      end
    end

    def load_from_legacy_text_file!(filename : String)
      full_filename = Crystal2Day.convert_to_absolute_path(filename)

      line_number = 0
      File.each_line(full_filename) do |line|
        if line_number == 0
        elsif line_number == 1
          @combo_info.total_width_in_chunks = line.split[0].to_u32
          @combo_info.total_height_in_chunks = line.split[1].to_u32
          @combo_info.chunk_width = line.split[2].to_u32
          @combo_info.chunk_height = line.split[3].to_u32
          @combo_info.number_of_maps = line.split[4].to_u32
          @combo_info.chunks = Array(Array(UInt32)).new(initial_capacity: @combo_info.total_height_in_chunks)
          @map_list = Array(MapContent).new(initial_capacity: @combo_info.number_of_maps)
          @combo_info.map_starting_points = Array(Tuple(UInt32, UInt32)).new(size: @combo_info.number_of_maps, value: {@combo_info.total_width_in_chunks, @combo_info.total_height_in_chunks})
        elsif line_number < 2 + @combo_info.total_height_in_chunks
          current_chunk_y = line_number - 2
          split_line = line.split
          @combo_info.chunks.push Array(UInt32).new(initial_capacity: @combo_info.total_width_in_chunks)
          split_line.each_with_index do |split_part, current_chunk_x|
            map_index = split_part.to_u32
            @combo_info.chunks[-1].push map_index
            if map_index != 0
              old_starting_point = @combo_info.map_starting_points[map_index - 1]
              lowest_starting_x = {old_starting_point[0], current_chunk_x}.min.to_u32
              lowest_starting_y = {old_starting_point[1], current_chunk_y}.min.to_u32
              @combo_info.map_starting_points[map_index - 1] = {lowest_starting_x, lowest_starting_y}
            end
          end
        else
          unless line.strip.empty?
            @map_list.push MapContent.new
            
            # TODO: Enable loading from Tiled files as well!
            @map_list[-1].load_from_text_file!(line.strip)
          end
        end
        line_number += 1
      end
    end
  end

  class MapContent
    getter width : UInt32 = 0
    getter height : UInt32 = 0
    getter tiles = [] of Array(TileID)

    property background_tile : TileID = 0u32

    def load_from_array!(array : Array(Array(TileID)))
      @height = array.size.to_u32
      width_obtained = false
      @tiles = Array(Array(TileID)).new(initial_capacity: @height)

      array.each do |line|
        if width_obtained
          Crystal2Day.error "Array has inconcistent sizes" if @width != line.size
        else
          @width = line.size.to_u32
          width_obtained = true
        end

        @tiles.push Array(TileID).new(initial_capacity: @width)

        line.each do |element|
          @tiles[-1].push element
        end
      end
    end

    def load_from_tiled_layer!(parsed_layer : Tiled::Layer)
      @width = parsed_layer.width
      @height = parsed_layer.height

      @tiles = Array(Array(TileID)).new(initial_capacity: @height)

      0.upto(@height - 1) do |ty|
        @tiles.push Array(TileID).new(initial_capacity: @width)
        0.upto(@width - 1) do |tx|
          parsed_tile = parsed_layer.data.not_nil!.content[ty * @width + tx]
          # Defined tiles start with 1, so we need to reduce them to zero
          # TODO: Include gid of parsed tileset
          @tiles[ty].push TileID.new(parsed_tile == 0 ? @background_tile : parsed_tile - 1)
        end
      end
    end

    def get_tile(x : Int32, y : Int32)
      invalid_tile = x < 0 || x.to_u32 >= @width || y < 0 || y.to_u32 >= @height
      invalid_tile ? @background_tile : @tiles[y][x]
    end

    def load_from_text_file!(filename : String)
      full_filename = Crystal2Day.convert_to_absolute_path(filename)

      line_number = 0
      File.each_line(full_filename) do |line|
        if line_number == 0
        elsif line_number == 1
          @width = line.split[0].to_u32
          @height = line.split[1].to_u32
          @tiles = Array(Array(TileID)).new(initial_capacity: @height)
        else
          split_line = line.split
          @tiles.push Array(TileID).new(initial_capacity: @width)
          split_line.each do |split_part|
            @tiles[-1].push TileID.new(split_part.to_u32)
          end
        end
        line_number += 1
      end
    end
  end

  class Map
    LAYERS_INITIAL_CAPACITY = 8

    property layers = Array(MapLayer).new(initial_capacity: LAYERS_INITIAL_CAPACITY)
    property tileset : Crystal2Day::Tileset = Crystal2Day::Tileset.new

    def initialize
    end

    def load_from_tiled_file!(filename : String, given_tileset : Tileset? = nil)
      @layers.clear

      full_filename = Crystal2Day.convert_to_absolute_path(filename)

      parsed_map = Tiled.parse_map_from_file(full_filename)

      # TODO: This might cause issues, test this at some point
      if given_tileset
        @tileset = given_tileset
      else
        # TODO: Currently only works with the first tileset
        @tileset.load_from_tiled_file!(Crystal2Day.convert_to_absolute_path(parsed_map.array_tileset[0].source))
      end

      parsed_map.array_layer.each do |parsed_layer|
        new_layer = MapLayer.new(self)
        new_layer.content.load_from_tiled_layer!(parsed_layer)
        add_layer(new_layer)
      end
    end

    def stream_from_file!(filename : String, @tileset : Tileset)
      @layers.clear
      
      full_filename = Crystal2Day.convert_to_absolute_path(filename)

      File.open(full_filename, "r") do |f|
        parsed_stream = JSON.parse(f)

        number_of_layers = parsed_stream["number_of_layers"].as_i.to_u32

        combo_info = MapComboInfo.new
        combo_info.get_from_parsed_json!(parsed_stream)
        
        map_names = parsed_stream["maps"].as_a.map {|name| name.as_s}
        parsed_maps = map_names.map {|map_name| Tiled.parse_map_from_file(Crystal2Day.convert_to_absolute_path(map_name))}

        number_of_layers.times do |layer_id|
          new_layer = MapLayer.new(self)
          new_layer.set_as_stream!

          new_layer.content.as(MapCombo).combo_info = combo_info
          new_layer.content.as(MapCombo).map_list = Array(MapContent).new(initial_capacity: combo_info.number_of_maps)

          0.upto(map_names.size - 1) do |i|
            map_content = MapContent.new
            map_content.load_from_tiled_layer!(parsed_maps[i].array_layer[layer_id])
            new_layer.content.as(MapCombo).map_list.push map_content
          end

          add_layer(new_layer)
        end
      end
    end

    def add_layer(map_layer)
      @layers.push(map_layer)
      return map_layer
    end

    def add_layer
      new_layer = MapLayer.new(self)
      @layers.push(new_layer)
      return new_layer
    end

    def draw_layer(layer_number : UInt8 = 0, offset : Coords = Crystal2Day.xy)
      # TODO: Add safeguards
      @layers[layer_number].draw(offset)
    end

    def pin_layer(layer_number : UInt8 = 0, offset : Coords = Crystal2Day.xy)
      @layers[layer_number].pin(offset)
    end

    def unpin_layer(layer_number : UInt8 = 0)
      @layers[layer_number].unpin
    end

    def number_of_layers
      return @layers.size
    end

    def draw_all_layers(offset : Coords = Crystal2Day.xy)
      0.upto(number_of_layers - 1) do |i|
        @layers[i].draw(offset)
      end
    end

    def pin_all_layers(offset : Coords = Crystal2Day.xy)
      0.upto(number_of_layers - 1) do |i|
        @layers[i].pin(offset)
      end
    end

    def unpin_all_layers
      0.upto(number_of_layers - 1) do |i|
        @layers[i].unpin
      end
    end

    def update
      @layers.each{|layer| layer.update}
    end

    def check_for_collision_with(other : EntityGroup | Map, use_precise_shapes : Bool = false)
      if other.is_a?(Map)
        Crystal2Day.error "Map-Map collisions are not implemented."
      else
        # No need to implement this twice
        other.check_for_collision_with(self, use_precise_shapes)
      end
    end
  end

  class MapLayer < Crystal2Day::Drawable
    property content : MapContent | MapCombo = MapContent.new
    property parent_map : Map

    property drawing_rect : Crystal2Day::Rect = Crystal2Day::Rect.new(width: Crystal2Day.current_window.width, height: Crystal2Day.current_window.height)

    property collision_disabled : Bool = false

    property animated_tiles : Array(TileID) = Array(TileID).new(initial_capacity: Tileset::INITIAL_CAPACITY)
    property frame_counter : Float32 = 0.0
    property milliseconds_per_animation_frame : Float64 = 1000.0 / 60.0 # TODO: Document this properly
    # TODO: Maybe add another mode that is based on actual time

    getter vertices = [] of LibSDL::Vertex

    VERTEX_SIGNATURE = [0, 1, 2, 0, 2, 3]

    def initialize(@parent_map : Map, render_target : Crystal2Day::RenderTarget = Crystal2Day.current_window)
      super(render_target)
    end

    def set_as_stream!
      @content = MapCombo.new
    end

    def generate_vertices(view_width : UInt32, view_height : UInt32)
      @vertices = Array(LibSDL::Vertex).new(size: view_width * view_height * 6) {LibSDL::Vertex.new}
    end

    def get_tile(x : Int32, y : Int32)
      @animated_tiles[@content.get_tile(x, y)]
    end

    def update_animations
      tileset = @parent_map.tileset

      @animated_tiles = (0u32..tileset.size - 1).map do |tile_id|
        max_duration = tileset.max_duration(tile_id.as(TileID))
        final_id = tile_id
        # TODO: Optimize this using cached frame positions!
        tileset.animations[tile_id].each do |frame|
          next if (@frame_counter % max_duration) > frame.cumulative_duration
          final_id = frame.tile
          break
        end
        final_id.to_u32.as(TileID)
      end
      @frame_counter += @milliseconds_per_animation_frame
    end

    def reload_vertex_grid(offset : Coords)
      tileset = @parent_map.tileset

      tile_width = tileset.tile_width
      tile_height = tileset.tile_height

      view_width = (drawing_rect.width / tile_width).ceil.to_u32 + 1
      view_height = (drawing_rect.height / tileset.tile_height).ceil.to_u32 + 1

      generate_vertices(view_width, view_height)

      pos_shift_x = @render_target.renderer.position_shift.x + offset.x
      pos_shift_y = @render_target.renderer.position_shift.y + offset.y

      rect_shift_dx = @drawing_rect.x - pos_shift_x
      rect_shift_dy = @drawing_rect.y - pos_shift_y

      exact_shift_x = rect_shift_dx + @drawing_rect.width / 2 - (view_width - 1) * (tile_width / 2) - 1
      exact_shift_y = rect_shift_dy + @drawing_rect.height / 2 - (view_height - 1) * (tile_height / 2) - 1

      n_tiles_x = tileset.texture.width // tile_width
      n_tiles_y = tileset.texture.height // tile_height

      0.upto(view_width - 1) do |x|
        0.upto(view_height - 1) do |y|
          exact_actual_x = x.to_f32 + exact_shift_x / tile_width
          exact_actual_y = y.to_f32 + exact_shift_y / tile_height

          # NOTE: The rounding here is to prevent floating point errors for now
          # This should work, but maybe there's a better solution
          actual_x = exact_actual_x.round(2).floor.to_i32
          actual_y = exact_actual_y.round(2).floor.to_i32

          tile_id = get_tile(actual_x, actual_y)

          tx = tile_id % n_tiles_x
          ty = tile_id // n_tiles_x

          0u64.upto(5) do |c|
            dx = (c == 1 || c == 2 || c == 4) ? 1 : 0
            dy = (c == 2 || c == 4 || c == 5) ? 1 : 0

            vx = ((actual_x + dx) * tile_width).to_f32 - rect_shift_dx
            vy = ((actual_y + dy) * tile_height).to_f32 - rect_shift_dy

            vtx = (tx + dx) / n_tiles_x
            vty = (ty + dy) / n_tiles_y

            vertex_no = (x * view_height + y) * 6 + c
            new_vertex = LibSDL::Vertex.new(position: LibSDL::FPoint.new(x: vx, y: vy), tex_coord: LibSDL::FPoint.new(x: vtx, y: vty), color: LibSDL::FColor.new(r: 1.0, g: 1.0, b: 1.0, a: 1.0))
            @vertices[vertex_no] = new_vertex
          end
        end
      end
    end

    def update
      update_animations
    end

    def draw_directly(offset : Coords)
      reload_vertex_grid(offset)
      # TODO: Currently there can be two renderers, maybe this should be fixed
      LibSDL.render_geometry(@parent_map.tileset.texture.renderer_data, @parent_map.tileset.texture.data, @vertices, @vertices.size, nil, 0)
    end
  end
end
