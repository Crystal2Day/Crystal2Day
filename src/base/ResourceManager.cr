# A window-specific resource manager.

module Crystal2Day
  class ResourceManager
    macro add_resource_type(name, resource_class, initial_capacity, additional_arg = nil, additional_init_args = ["", ""], plural = "s")
      @{{(name + plural).id}} = Hash(String, Crystal2Day::{{resource_class}}).new(initial_capacity: {{initial_capacity}})

      def load_{{name.id}}(filename : String, additional_tag : String = ""{{additional_init_args[0].id}})
        unless @{{(name + plural).id}}[filename + additional_tag]?
          {% if additional_arg %}
            {{name.id}} = Crystal2Day::{{resource_class}}.new({{additional_arg}})
          {% else %}
            {{name.id}} = Crystal2Day::{{resource_class}}.new
          {% end %}
          {{name.id}}.load_from_file!(filename{{additional_init_args[1].id}})
          @{{(name + plural).id}}[filename + additional_tag] = {{name.id}}
        end

        @{{(name + plural).id}}[filename + additional_tag]
      end

      def add_{{name.id}}(tag : String, value : Crystal2Day::{{resource_class}})
        unless @{{(name + plural).id}}[tag]?
          @{{(name + plural).id}}[tag] = value
        end

        @{{(name + plural).id}}[tag]
      end

      def unload_{{name.id}}(filename : String, additional_tag : String = "")
        @{{(name + plural).id}}[filename + additional_tag].delete if @{{(name + plural).id}}[filename + additional_tag]?
      end
  
      def unload_all_{{(name + plural).id}}
        @{{(name + plural).id}}.clear
      end
    end

    TEXTURES_INITIAL_CAPACITY = 256
    SOUNDS_INITIAL_CAPACITY = 256
    MUSICS_INITIAL_CAPACITY = 256
    FONTS_INITIAL_CAPACITY = 8
    
    property render_target : Crystal2Day::RenderTarget? = nil

    add_resource_type("texture", Texture, TEXTURES_INITIAL_CAPACITY, additional_arg: @render_target.not_nil!)
    add_resource_type("sound", Sound, SOUNDS_INITIAL_CAPACITY)
    add_resource_type("music", Music, MUSICS_INITIAL_CAPACITY, plural: "")
    add_resource_type("font", Font, FONTS_INITIAL_CAPACITY, additional_init_args: [", size : Number = 16", ", size"])

    # TODO: Maybe add sprite templates here

    def clear
      @textures.clear
      @sounds.clear
      @music.clear
      @fonts.clear
    end

    def initialize
    end

    def finalize
      clear
    end
  end
end
