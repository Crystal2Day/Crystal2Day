module Crystal2Day
  alias AtomicParamTypes = Nil | Bool | Int32 | Int64 | Float32 | Float64 | String | Crystal2Day::Coords | Crystal2Day::Rect | Crystal2Day::Color | Crystal2Day::CollisionShape
  alias ParamType = AtomicParamTypes | Array(ParamType)

  {% if CRYSTAL2DAY_CONFIGS_ANYOLITE %}
    alias Parameter = Anyolite::RbRef
  {% else %}
    class Parameter
      getter content : ParamType

      def initialize(@content : ParamType)
      end

      def self.convert_json_to_value(json_string : String)
        pull = JSON::PullParser.new(json_string)
        case pull.kind
        when JSON::PullParser::Kind::Null then return nil
        when JSON::PullParser::Kind::Bool then return pull.read_bool
        when JSON::PullParser::Kind::Int then return pull.read_int
        when JSON::PullParser::Kind::Float then return pull.read_float
        when JSON::PullParser::Kind::String then return pull.read_string
        when JSON::PullParser::Kind::BeginArray
          array = [] of Crystal2Day::ParamType
          pull.read_array do
            array.push self.convert_json_to_value(pull.read_raw)
          end
          return array
        when JSON::PullParser::Kind::BeginObject
          pull.read_next
          obj_key = pull.read_object_key

          # TODO: Maybe it's possible to introduce a serialized dummy class here
          case obj_key
          when "Coords" then
            return Crystal2Day::Coords.from_json(pull.read_raw)
          when "Rect" then
            return Crystal2Day::Rect.from_json(pull.read_raw)
          when "Color" then
            return Crystal2Day::Color.from_json(pull.read_raw)
          when "Shape" then
            return Crystal2Day::CollisionShape.from_json(pull.read_raw)
          else
            Crystal2Day.error "Unknown object type from JSON: #{obj_key}"
          end
        else
          Crystal2Day.error "Something went wrong while parsing JSON string: #{json_string}"
        end
      end

      def to_b
        @content.as(Bool)
      end

      def to_i
        @content.as(Int)
      end

      def to_i32
        @content.as(Int).to_i32
      end

      def to_f
        @content.as(Float)
      end

      def to_f32
        @content.as(Float).to_f32
      end

      def to_s
        @content.as(String)
      end

      def to_coords
        @content.as(Crystal2Day::Coords)
      end

      def to_xy
        to_coords
      end

      def to_rect
        @content.as(Crystal2Day::Rect)
      end

      def to_color
        @content.as(Crystal2Day::Color)
      end

      def to_shape
        @content.as(Crystal2Day::CollisionShape)
      end
    end
  {% end %}
end
