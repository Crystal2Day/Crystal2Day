# The collection of all files for Crystal2Day.
# Any deviation from alphabetic order is intended.

require "json"

require "sdl-crystal-bindings/sdl3-crystal-bindings"
require "sdl-crystal-bindings/sdl3-mixer-bindings-old"
require "sdl-crystal-bindings/sdl3-image-bindings"
require "sdl-crystal-bindings/sdl3-ttf-bindings"

require "tiled-crystal"

require "./config/AnyoliteConfig.cr"
require "./config/ImguiConfig.cr"

require "./base/Coords.cr"
require "./base/Database.cr"
require "./base/Helper.cr"
require "./base/Main.cr"
require "./base/Rect.cr"
require "./base/ResourceManager.cr"

require "./audio/Music.cr"
require "./audio/Sound.cr"
require "./audio/SoundBoard.cr"

require "./graphics/Drawable.cr"
require "./graphics/RenderTarget.cr"

require "./graphics/Animation.cr"
require "./graphics/Camera.cr"
require "./graphics/Color.cr"
require "./graphics/DebugGrid.cr"
require "./graphics/Font.cr"
require "./graphics/Map.cr"
require "./graphics/Renderer.cr"
require "./graphics/RenderQueue.cr"
require "./graphics/RenderSurface.cr"
require "./graphics/Shapes.cr"
require "./graphics/Sprite.cr"
require "./graphics/Text.cr"
require "./graphics/TextEngine.cr"
require "./graphics/Texture.cr"
require "./graphics/Tileset.cr"
require "./graphics/UI.cr"
require "./graphics/View.cr"
require "./graphics/Window.cr"

require "./game/Collishi.cr"
require "./game/CollisionMatrix.cr"
require "./game/CollisionReference.cr"
require "./game/CollisionShapes.cr"
require "./game/Entity.cr"
require "./game/EntityGroup.cr"
require "./game/EntityType.cr"
require "./game/GameData.cr"
require "./game/Limiter.cr"
require "./game/Part.cr"
require "./game/Scene.cr"

require "./input/Event.cr"
require "./input/InputManager.cr"
require "./input/Keyboard.cr"
require "./input/Mouse.cr"

require "./scripting/CoroutineTemplate.cr"
require "./scripting/Hook.cr"
require "./scripting/Parameter.cr"
require "./scripting/ProcCoroutine.cr"

require "./config/AnyolitePostConfig.cr"
