# x86-mingw32 Gemspec #
gemspec = eval(IO.read(File.expand_path("../chef.gemspec", __FILE__)))

gemspec.platform = "x86-mingw32"

gemspec.add_dependency "systemu", "2.2.0"  # CHEF-3718
gemspec.add_dependency "ffi", "1.0.9"
gemspec.add_dependency "rdp-ruby-wmi", "0.3.1"
gemspec.add_dependency "windows-api", "0.4.0"
gemspec.add_dependency "windows-pr", "1.2.2"
gemspec.add_dependency "win32-api", "1.4.8"
gemspec.add_dependency "win32-dir", "0.3.7"
gemspec.add_dependency "win32-event", "0.5.2"
gemspec.add_dependency "win32-mutex", "0.3.1"
gemspec.add_dependency "win32-process", "0.7.3"
gemspec.add_dependency "win32-service", "0.8.2"

gemspec

