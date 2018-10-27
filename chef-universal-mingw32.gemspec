gemspec = eval(IO.read(File.expand_path("../chef.gemspec", __FILE__)))

gemspec.platform = Gem::Platform.new(%w{universal mingw32})

gemspec.add_dependency "win32-api", "~> 1.5.3"
gemspec.add_dependency "win32-dir", "~> 0.5.0"
gemspec.add_dependency "win32-event", "~> 0.6.1"
# TODO: Relax this pin and make the necessary updaets. The issue originally
# leading to this pin has been fixed in 0.6.5.
gemspec.add_dependency "win32-eventlog", "0.6.3"
gemspec.add_dependency "win32-mmap", "~> 0.4.1"
gemspec.add_dependency "win32-mutex", "~> 0.4.2"
gemspec.add_dependency "win32-process", "~> 0.8.2"
gemspec.add_dependency "win32-service", "~> 1.0"
gemspec.add_dependency "windows-api", "~> 0.4.4"
gemspec.add_dependency "wmi-lite", "~> 1.0"
gemspec.add_dependency "win32-taskscheduler", "~> 2.0"
gemspec.add_dependency "iso8601", "~> 0.12.1"
gemspec.extensions << "ext/win32-eventlog/Rakefile"
gemspec.files += Dir.glob("{distro,ext}/**/*")

gemspec.executables += %w{ chef-service-manager chef-windows-service }

gemspec
