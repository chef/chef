# x86-mingw32 Gemspec #
gemspec = eval(IO.read(File.expand_path("../mixlib-shellout.gemspec", __FILE__)))

gemspec.platform = "x86-mingw32"

gemspec.add_dependency "win32-process"
gemspec.add_dependency "windows-pr"
gemspec.add_dependency "windows-api"
gemspec.add_dependency "win32-api"


gemspec
