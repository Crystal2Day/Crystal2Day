module Crystal2Day
  class UI
    INITIAL_CAPACITY_TEXTS = 32

    property texts : Hash(String, Text) = Hash(String, Text).new(initial_capacity: INITIAL_CAPACITY_TEXTS)
    property position : Crystal2Day::Coords = Crystal2Day.xy

    def add_text(name : String, text : Text)
      if @texts[name]?
        Crystal2Day.warning "Already existing text with name '#{name}' will be overwritten"
      end  
      
      @texts[name] = text
      @texts[name].rebuild
    end

    def update
      @texts.each_value do |text|
        text.update
      end
    end

    def draw(offset : Coords = Crystal2Day.xy)
      @texts.each_value do |text|
        text.draw(offset)
      end
    end
  end
end
