# A window-specific resource manager.

module Crystal2Day
  class ResourceManager
    macro add_resource_type(name, resource_class, initial_capacity, additional_arg = nil, additional_init_args = ["", ""], plural = "s", load_from_json = false)
      @{{(name + plural).id}} = Hash(String, Crystal2Day::{{resource_class}}).new(initial_capacity: {{initial_capacity}})

      def load_{{name.id}}(filename : String, additional_tag : String = ""{{additional_init_args[0].id}})
        unless @{{(name + plural).id}}[filename + additional_tag]?
          {% if load_from_json %}
            # NOTE: Currently no additional_arg is needed here - change this if needed
            {{name.id}} = Crystal2Day::{{resource_class}}.from_json_file(filename{{additional_init_args[1].id}})
          {% else %}
            {% if additional_arg %}
              {{name.id}} = Crystal2Day::{{resource_class}}.new({{additional_arg}})
            {% else %}            
              {{name.id}} = Crystal2Day::{{resource_class}}.new
            {% end %}
            {{name.id}}.load_from_file!(filename{{additional_init_args[1].id}})
          {% end %}
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

      def get_{{name.id}}(tag : String)
        if @{{(name + plural).id}}[tag]?
          return @{{(name + plural).id}}[tag]
        else
          Crystal2Day.error("{{name.id}} with tag #{tag} was not loaded.")
        end
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
    SPRITE_TEMPLATES_INITIAL_CAPACITY = 256
    
    property render_target : Crystal2Day::RenderTarget? = nil

    add_resource_type("texture", Texture, TEXTURES_INITIAL_CAPACITY, additional_arg: @render_target.not_nil!)
    add_resource_type("sound", Sound, SOUNDS_INITIAL_CAPACITY)
    add_resource_type("music", Music, MUSICS_INITIAL_CAPACITY, plural: "")
    add_resource_type("font", Font, FONTS_INITIAL_CAPACITY, additional_init_args: [", size : Number = 16", ", size"])
    add_resource_type("sprite_template", SpriteTemplate, SPRITE_TEMPLATES_INITIAL_CAPACITY, load_from_json: true)

    def load_sprite_templates_from_file(filename : String)
      Hash(String, Crystal2Day::SpriteTemplate).from_json_file("SpriteTemplates.json").each do |name, value|
        add_sprite_template(name, value)
      end
    end

    def clear
      @textures.clear
      @sounds.clear
      @music.clear
      @fonts.clear
      @sprite_templates.clear
    end

    def initialize
    end

    def finalize
      clear
    end
  end
end
