source "https://rubygems.org"
gemspec :name => "chef"

gem "activesupport", "< 4.0.0", :group => :compat_testing, :platform => "ruby"

gem 'chef-config', path: "chef-config"

# We are pinning chef-zero to 4.2.x until ChefFS can deal
# with V1 api calls or chef-zero supports both v0 and v1
gem "chef-zero", "~> 4.2.3"

group(:docgen) do
  gem "yard"
end

group(:maintenance) do
  gem "tomlrb"

  # To sync maintainers with github
  gem "octokit"
  gem "netrc"
end

group(:development, :test) do

  gem "simplecov"
  gem 'rack', "~> 1.5.1"

  gem 'cheffish', "~> 1.3", "!= 1.3.1"

  gem 'ruby-shadow', :platforms => :ruby unless RUBY_PLATFORM.downcase.match(/(aix|cygwin)/)
end

# If you want to load debugging tools into the bundle exec sandbox,
# add these additional dependencies into chef/Gemfile.local
eval(IO.read(__FILE__ + '.local'), binding) if File.exists?(__FILE__ + '.local')
