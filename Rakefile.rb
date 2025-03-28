module Utils
  def self.compile_imgui_backend(source, target)
    if ENV["OS"] == "Windows_NT"
      system("cl /I \"lib/imgui/cimgui/imgui/backends\" /I \"temp/SDL/include\" /I \"lib/imgui/cimgui/imgui\" /c \"#{source}\" /Fo\"#{target}.obj\"")
    else
      system("g++ -std=c++14 -I \"lib/imgui/cimgui/imgui/backends\" -I \"temp/SDL/include\" -I \"lib/imgui/cimgui/imgui\" -c \"#{source}\" -o \"#{target}.o\"")
    end
  end
end

task :add_feature_anyolite do
  system("git clone --branch main https://github.com/Anyolite/anyolite lib/anyolite")
  Dir.chdir("lib/anyolite")
  system("crystal install.cr")
  Dir.chdir("../..")
  if File.exist?("lib/anyolite/build/mruby/lib/libmruby.lib") || File.exist?("lib/anyolite/build/mruby/lib/libmruby.a")
    puts "Anyolite was successfully installed."
  else
    raise "Could not install Anyolite."
  end
end

task :add_feature_imgui do
  orig_dir = Dir.pwd
  system("git clone --recursive https://github.com/oprypin/crystal-imgui lib/imgui")
  Dir.chdir("lib/imgui/cimgui")
  system("git checkout master --recurse-submodules")
  system("cmake -DCMAKE_CXX_FLAGS='-DIMGUI_USE_WCHAR32' .")
  system("cmake --build .")
  system("ln -s cimgui.so libcimgui.so")
  Dir.chdir(orig_dir)
  if ENV["OS"] == "Windows_NT"
    FileUtils.cp("lib/imgui/cimgui/Debug/cimgui.lib", "./cimgui.lib")
    FileUtils.cp("lib/imgui/cimgui/Debug/cimgui.dll", "./cimgui.dll")
  end
  Dir.mkdir("temp") if !Dir.exist?("temp")
  system("git clone https://github.com/libsdl-org/SDL temp/SDL")
  Utils.compile_imgui_backend("lib/imgui/cimgui/cimgui.cpp", "temp/cimgui")
  Utils.compile_imgui_backend("src/glue/imgui_impl_sdl3.cpp", "temp/imgui_impl_sdl3")
  Utils.compile_imgui_backend("lib/imgui/cimgui/imgui/backends/imgui_impl_sdl3.cpp", "temp/imgui_impl")
  Utils.compile_imgui_backend("lib/imgui/cimgui/imgui/backends/imgui_impl_sdlrenderer3.cpp", "temp/imgui_impl_renderer")
  ["imgui", "imgui_draw", "imgui_widgets", "imgui_tables", "imgui_demo"].each do |name|
    Utils.compile_imgui_backend("lib/imgui/cimgui/imgui/#{name}.cpp", "temp/#{name}")
  end
  if ENV["OS"] == "Windows_NT"
    system("lib /OUT:\"temp/imgui_impl_sdl3.lib\" \"temp/imgui_impl_sdl3.obj\" \"temp/imgui_impl_renderer.obj\" \"temp/cimgui.obj\" \"temp/imgui_impl.obj\" \"temp/imgui.obj\" \"temp/imgui_draw.obj\" \"temp/imgui_widgets.obj\" \"temp/imgui_tables.obj\" \"temp/imgui_demo.obj\"")
  else
    system("ar rcs \"temp/imgui_impl_sdl3.a\" \"temp/imgui_impl_sdl3.o\" \"temp/imgui_impl_renderer.o\" \"temp/cimgui.o\" \"temp/imgui_impl.o\" \"temp/imgui.o\" \"temp/imgui_draw.o\" \"temp/imgui_widgets.o\" \"temp/imgui_tables.o\" \"temp/imgui_demo.o\"")
  end
end

task :install_sdl_libraries do
  # TODO
end
