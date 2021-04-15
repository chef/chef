gemspec = eval(IO.read(File.expand_path("chef.gemspec", __dir__)))

gemspec.platform = Gem::Platform.new(%w{universal mingw32})

gemspec.add_dependency "win32-api", "~> 1.5.3"
gemspec.add_dependency "win32-event", "~> 0.6.1"
# TODO: Relax this pin and make the necessary updaets. The issue originally
# leading to this pin has been fixed in 0.6.5.
gemspec.add_dependency "win32-eventlog", "0.6.3"
gemspec.add_dependency "win32-mmap", "~> 0.4.1"
gemspec.add_dependency "win32-mutex", "~> 0.4.2"
gemspec.add_dependency "win32-process", "~> 0.9"
gemspec.add_dependency "win32-service", ">= 2.1.5", "< 3.0"
gemspec.add_dependency "wmi-lite", "~> 1.0"
gemspec.add_dependency "win32-taskscheduler", "~> 2.0"
gemspec.add_dependency "iso8601", ">= 0.12.1", "< 0.14" # validate 0.14 when it comes out
gemspec.add_dependency "win32-certstore", "~> 0.6.2" # 0.5+ required for specifying user vs. system store
gemspec.extensions << "ext/win32-eventlog/Rakefile"
gemspec.files += Dir.glob("{distro,ext}/**/*")

gemspec
