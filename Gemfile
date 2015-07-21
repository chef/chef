source "https://rubygems.org"
gemspec :name => "chef"

gem "activesupport", "< 4.0.0", :group => :compat_testing, :platform => "ruby"

gem 'chef-config', path: "chef-config"

# REMOVEME once there is a release of Ohai with these changes, and the
# chef.gemspec is updated.
gem 'ohai', github: 'chef/ohai',
            ref: '7556a1d55808c459f3a9fad88e2a2371f361f3e0'

group(:docgen) do
  gem "tomlrb"
  gem "yard"
end

group(:development, :test) do
  gem "simplecov"
  gem 'rack', "~> 1.5.1"
  gem 'cheffish', "~> 1.2"

  gem 'ruby-shadow', :platforms => :ruby unless RUBY_PLATFORM.downcase.match(/(aix|cygwin)/)
end

# If you want to load debugging tools into the bundle exec sandbox,
# add these additional dependencies into chef/Gemfile.local
eval(IO.read(__FILE__ + '.local'), binding) if File.exists?(__FILE__ + '.local')
