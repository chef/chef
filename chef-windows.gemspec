gemspec = eval(IO.read(File.expand_path("../chef.gemspec", __FILE__)))

gemspec.platform = Gem::Platform.new(%w{universal mingw32})

gemspec.add_dependency "ffi", "~> 1.9"
gemspec.add_dependency "win32-api", "~> 1.5.3"
gemspec.add_dependency "win32-dir", "~> 0.5.0"
gemspec.add_dependency "win32-event", "~> 0.6.1"
# Hard pin on win32-eventlog until djberg96/win32-eventlog#20 is resolved.
# win32-eventlog was stomping over the CreateEvent FFI bindings that
# win32-service needed, causing the chef service to not run.
gemspec.add_dependency "win32-eventlog", "0.6.3"
gemspec.add_dependency "win32-mmap", "~> 0.4.1"
gemspec.add_dependency "win32-mutex", "~> 0.4.2"
gemspec.add_dependency "win32-process", "~> 0.8.2"
gemspec.add_dependency "win32-service", "~> 0.8.7"
gemspec.add_dependency "windows-api", "~> 0.4.4"
gemspec.add_dependency "wmi-lite", "~> 1.0"
gemspec.extensions << "ext/win32-eventlog/Rakefile"
gemspec.files += %w{ext/win32-eventlog/Rakefile ext/win32-eventlog/chef-log.man}

gemspec.executables += %w{ chef-service-manager chef-windows-service }

gemspec
