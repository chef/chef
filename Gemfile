source "https://rubygems.org"
gemspec :name => "chef"

gem "activesupport", "< 4.0.0", :group => :compat_testing, :platform => "ruby"

gem 'chef-config', path: "chef-config" if File.exists?(__FILE__ + '../chef-config')

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
  # for profiling
  gem "ruby-prof"

  gem "simplecov"
  gem 'rack', "~> 1.5.1"


  gem 'ruby-shadow', :platforms => :ruby unless RUBY_PLATFORM.downcase.match(/(aix|cygwin)/)

  gem 'github_changelog_generator'

  # For external tests
#  gem 'chef-zero', github: 'chef/chef-zero'
#  gem 'cheffish', github: 'chef/cheffish'
#  gem 'chef-provisioning'#, github: 'chef/chef-provisioning'
#  gem 'chef-provisioning-aws', github: 'chef/chef-provisioning-aws'
#  gem 'test-kitchen'
#  gem 'chefspec'
#  gem 'chef-sugar'
#  gem 'poise', github: 'poise/poise', branch: 'deeecb890a6a0bc2037dfb09ce0fd0a8931519aa'
#  gem 'halite', github: 'poise/halite'
#  gem 'foodcritic', github: 'acrmp/foodcritic', branch: 'v5.0.0'
#  gem 'chef-rewind'
end

instance_eval(ENV['GEMFILE_MOD']) if ENV['GEMFILE_MOD']

# If you want to load debugging tools into the bundle exec sandbox,
# add these additional dependencies into chef/Gemfile.local
eval(IO.read(__FILE__ + '.local'), binding) if File.exists?(__FILE__ + '.local')
