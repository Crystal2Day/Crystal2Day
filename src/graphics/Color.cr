# A color class with some predefined values.

module Crystal2Day
  class Color
    getter data : LibSDL::Color

    # TODO: Add constructor to load color from hex string

    def initialize(r : Number = 0, g : Number = 0, b : Number = 0, a : Number = 255)
      @data = LibSDL::Color.new(r: r, g: g, b: b, a: a)
    end

    def initialize(pull : JSON::PullParser)
      @data = LibSDL::Color.new(r: 0, g: 0, b: 0, a: 255)

      pull.read_object do |key|
        case key
        when "r" then self.r = pull.read_int
        when "g" then self.g = pull.read_int
        when "b" then self.b = pull.read_int
        when "a" then self.a = pull.read_int     
        end
      end
    end

    def r
      @data.r
    end

    def g
      @data.g
    end
    
    def b
      @data.b
    end

    def a
      @data.a
    end

    def r=(value : Number)
      @data.r = value
    end

    def g=(value : Number)
      @data.g = value
    end
    
    def b=(value : Number)
      @data.b = value
    end

    def a=(value : Number)
      @data.a = value
    end

    # TODO: Maybe internally represent the color as float in the first place?
    def to_float_color
      LibSDL::FColor.new(r: (r / 255.0), g: (g / 255.0), b: (b / 255.0), a: (a / 255.0))
    end

    def self.max_red
      Crystal2Day::Color.new(255, 0, 0)
    end

    def self.red
      self.max_red
    end

    def self.max_green
      Crystal2Day::Color.new(0, 255, 0)
    end

    def self.lime
      self.max_green
    end

    def self.max_blue
      Crystal2Day::Color.new(0, 0, 255)
    end

    def self.blue
      self.max_blue
    end

    def self.black
      Crystal2Day::Color.new(0, 0, 0)
    end

    def self.white
      Crystal2Day::Color.new(255, 255, 255)
    end

    def self.gray
      Crystal2Day::Color.new(128, 128, 128)
    end

    def self.grey
      self.gray
    end

    def self.cyan
      Crystal2Day::Color.new(0, 255, 255)
    end

    def self.magenta
      Crystal2Day::Color.new(255, 0, 255)
    end

    def self.yellow
      Crystal2Day::Color.new(255, 255, 0)
    end

    def self.maroon
      Crystal2Day::Color.new(128, 0, 0)
    end

    def self.olive
      Crystal2Day::Color.new(128, 128, 0)
    end

    def self.purple
      Crystal2Day::Color.new(128, 0, 128)
    end

    def self.teal
      Crystal2Day::Color.new(0, 128, 128)
    end

    def self.navy
      Crystal2Day::Color.new(0, 0, 128)
    end

    def self.green
      Crystal2Day::Color.new(0, 128, 0)
    end

    def self.transparent
      Crystal2Day::Color.new(0, 0, 0, 0)
    end

    # TODO: More color codes (orange, brown, dark/light tones, silver, pink, ...)
  end
end