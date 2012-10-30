source :rubygems

gemspec

gem "activesupport", :group => :compat_testing, :platform => "ruby"
gem "ronn"

group(:development, :test) do
  gem 'rack'

  # The 'ruby' platform is surprisingly just unix-y platforms
  # thin requires eventmachine, which won't work under Ruby 1.9 on Windows
  # http://gembundler.com/man/gemfile.5.html
  gem 'thin', :platforms => :ruby

  # Eventmachine 1.0.0 is causing functional test failures on Solaris
  # 9 SPARC. Pinning em to 0.12.10 solves this issue until we can
  # replace thin with webrat or some other alternative.
  gem 'eventmachine', '0.12.10', :platforms => :ruby

  gem 'ruby-shadow', :platforms => :ruby unless RUBY_PLATFORM.downcase.match(/(darwin|freebsd)/)
#  gem 'awesome_print'
#  gem 'pry'
end

platforms :mswin, :mingw do
  gem "ffi", "1.0.9"
  gem "rdp-ruby-wmi", "0.3.1"
  gem "windows-api", "0.4.0"
  gem "windows-pr", "1.2.1"
  gem "win32-api", "1.4.8"
  gem "win32-dir", "0.3.7"
  gem "win32-event", "0.5.2"
  gem "win32-mutex", "0.3.1"
  gem "win32-process", "0.6.5"
  gem "win32-service", "0.7.2"
end

platforms :mingw_18 do
  gem "win32-open3", "0.3.2"
end

# If you want to load debugging tools into the bundle exec sandbox,
# add these additional dependencies into chef/Gemfile.local
eval(IO.read(__FILE__ + '.local'), binding) if File.exists?(__FILE__ + '.local')
