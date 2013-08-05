source "https://rubygems.org"

gemspec

gem "activesupport", "< 4.0.0", :group => :compat_testing, :platform => "ruby"

group(:docgen) do
  gem "ronn"
  gem "yard"
end

group(:development, :test) do
  gem "simplecov"
  gem 'rack', "~> 1.5.1"

  gem 'ruby-shadow', :platforms => :ruby unless RUBY_PLATFORM.downcase.match(/(darwin|freebsd|aix)/)
#  gem 'awesome_print'
#  gem 'pry'
end

platforms :mswin, :mingw do
  gem "systemu", "2.2.0"  # CHEF-3718
  gem "ffi", "1.3.1"
  gem "rdp-ruby-wmi", "0.3.1"
  gem "windows-api", "0.4.2"
  gem "windows-pr", "1.2.2"
  gem "win32-api", "1.4.8"
  gem "win32-dir", "0.4.1"
  gem "win32-event", "0.6.0"
  gem "win32-mutex", "0.4.0"
  gem "win32-process", "0.6.5"
  gem "win32-service", "0.7.2"
end

platforms :mingw_18 do
  gem "win32-open3", "0.3.2"
end

# If you want to load debugging tools into the bundle exec sandbox,
# add these additional dependencies into chef/Gemfile.local
eval(IO.read(__FILE__ + '.local'), binding) if File.exists?(__FILE__ + '.local')
