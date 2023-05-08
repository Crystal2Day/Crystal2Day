# A wrapper around the mruby interpreter, to avoid some Anyolite boilerplate.
# If you want to modify or use this, do it at your own risk.
# Make sure you know what you are doing, if you really want to.

module Crystal2Day
  module Interpreter
    @@rb_interpreter : Anyolite::RbInterpreter? = nil

    macro expose_module_only(class_or_module)
      Anyolite.wrap_module(Crystal2Day::Interpreter.get, {{class_or_module}}, {{class_or_module.stringify}})
    end

    macro expose_class_property(class_or_module, method, method_arg)
      Anyolite.wrap_class_method(Crystal2Day::Interpreter.get, {{class_or_module}}, {{method.stringify}}, {{class_or_module}}.{{method}})
      Anyolite.wrap_class_method(Crystal2Day::Interpreter.get, {{class_or_module}}, {{method.stringify + "="}}, {{class_or_module}}.{{method}}, {{method_arg}}, operator: "=")
      # TODO: Replace this with Anyolite class property wrappers if available
    end

    macro expose_class_function(class_or_module, method, method_args)
      Anyolite.wrap_class_method(Crystal2Day::Interpreter.get, {{class_or_module}}, {{method.stringify}}, {{class_or_module}}.{{method}}, {{method_args}})
    end

    macro expose_class(class_or_module, under = nil)
      Anyolite.wrap(Crystal2Day::Interpreter.get, {{class_or_module}}, under: {{under}})
    end

    def self.start
      if @@rb_interpreter
        Crystal2Day.error "An interpreter instance already exists."
      else
        @@rb_interpreter = Anyolite::RbInterpreter.new
        Anyolite::HelperClasses.load_all(Crystal2Day::Interpreter.get)
        Anyolite.disable_program_execution
      end
    end
  
    def self.close
      if rb = @@rb_interpreter
        rb.close
        @@rb_interpreter = nil
      else
        Crystal2Day.warning "No interpreter instance found."
      end
    end
  
    def self.active?
      !!@@rb_interpreter
    end

    def self.get
      @@rb_interpreter.not_nil!
    end

    def self.generate_ref(value)
      raw_ref = Anyolite::RbCast.return_value(Crystal2Day::Interpreter.get.to_unsafe, value)
      Anyolite::RbRef.new(raw_ref)
    end

    def self.inspect_ref(value : Anyolite::RbRef)
      ruby_str = Anyolite::RbCore.rb_inspect(Crystal2Day::Interpreter.get.to_unsafe, value.value)
      Anyolite::RbCast.cast_to_string(Crystal2Day::Interpreter.get.to_unsafe, ruby_str)
    end

    def self.fiber_from_proc(template_proc : Anyolite::RbRef)
      fiber_class = Anyolite.eval("Fiber")
      return Anyolite.call_rb_method_of_object(fiber_class, :new, block: template_proc)
    end

    def self.check_if_fiber_is_alive(fiber : Anyolite::RbRef)
      Anyolite.call_rb_method_of_object(fiber.to_unsafe, :"alive?", cast_to: Bool)
    end

    def self.resume_fiber(fiber : Anyolite::RbRef, arg : Anyolite::RbRef)
      idx = Anyolite::RbCore.rb_gc_arena_save(Crystal2Day::Interpreter.get.to_unsafe)
      Anyolite::RbCore.rb_fiber_resume(Crystal2Day::Interpreter.get.to_unsafe, fiber.to_unsafe, 1, [arg.to_unsafe])
      err = Anyolite::RbCore.get_last_rb_error(Crystal2Day::Interpreter.get.to_unsafe)
      converted_err = Anyolite.call_rb_method_of_object(err, "to_s", cast_to: String)
      raise "Error at Fiber execution: #{converted_err}" if converted_err != ""
      Anyolite::RbCore.rb_gc_arena_restore(Crystal2Day::Interpreter.get.to_unsafe, idx)
    end

    macro cast_ref_to(value, crystal_class)
      Anyolite::Macro.convert_from_ruby_to_crystal(Crystal2Day::Interpreter.get.to_unsafe, {{value}}.to_unsafe, {{crystal_class}})
    end

    def self.convert_json_to_ref(json_string : String)
      generate_ref(convert_json_to_value(json_string))
    end

    # TODO: Add other types like Colors as well
    alias JSONParserType = Nil | Bool | Int64 | Float64 | String | Crystal2Day::Coords | Crystal2Day::Rect | Array(JSONParserType)

    def self.convert_json_to_value(json_string : String)
      pull = JSON::PullParser.new(json_string)
      case pull.kind
      when JSON::PullParser::Kind::Null then return nil
      when JSON::PullParser::Kind::Bool then return pull.read_bool
      when JSON::PullParser::Kind::Int then return pull.read_int
      when JSON::PullParser::Kind::Float then return pull.read_float
      when JSON::PullParser::Kind::String then return pull.read_string
      when JSON::PullParser::Kind::BeginArray
        array = [] of JSONParserType
        pull.read_array do
          array.push convert_json_to_value(pull.read_raw)
        end
        return array
      when JSON::PullParser::Kind::BeginObject
        pull.read_next
        obj_key = pull.read_object_key
        case obj_key
        when "Coords" then
          return Crystal2Day::Coords.from_json(pull.read_raw)
        when "Rect" then
          return Crystal2Day::Rect.from_json(pull.read_raw)
        else
          Crystal2Day.error "Unknown object type from JSON: #{obj_key}"
        end
      else
        Crystal2Day.error "Something went wrong while parsing JSON string: #{json_string}"
      end
    end
  end
end