# Helper classes

module Crystal2DayHelper
  macro wrap_type(x)
    @data : {{x}}?
    
    def data
      if data = @data
        data.not_nil!
      else
        Crystal2Day.error "Internal data of type {{x}} was used after being reset"
      end
    end

    def unsafe_set_data(new_data)
      if @data
        Crystal2Day.warning "Old data value of type {{x}} was overriden without being freed"
      end
      @data = new_data
    end

    def data?
      !!@data
    end
  end

  PRELOADED_JSON_FILES = {} of String => String

  # NOTE: This is still an early feature, so it might change completely in the future
  macro preload_json_file(filename)
    Crystal2DayHelper::PRELOADED_JSON_FILES[{{filename}}] = {{read_file(filename)}}
  end
end

class Object
  def Object.from_json_file(filename : String)
    full_filename = Crystal2Day.convert_to_absolute_path(filename)
    result = uninitialized self
    if Crystal2DayHelper::PRELOADED_JSON_FILES[filename]?
      result = self.from_json(Crystal2DayHelper::PRELOADED_JSON_FILES[filename])
    else
      File.open(full_filename, "r") do |f|
        result = self.from_json(f)
      end
    end
    return result
  end
end
