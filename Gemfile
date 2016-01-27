source "https://rubygems.org"
gemspec name: "chef"

gem "activesupport", "< 4.0.0", group: :compat_testing, platform: "ruby"

gem "chef-config", path: "chef-config" if File.exist?(__FILE__ + "../chef-config")

group(:docgen) do
  gem "yard"
end

group(:maintenance) do
  gem "tomlrb"

  # To sync maintainers with github
  gem "octokit"
  gem "netrc"
end

group(:ruby_prof) do
  # may need to disable this in insolation on fussy builds like AIX, RHEL4, etc
  gem "ruby-prof"
end

group(:development, :test) do
  gem "simplecov"
  gem "rack", "~> 1.5.1"

  # for testing new chefstyle rules
  # gem 'chefstyle', github: 'chef/chefstyle'
  gem "chefstyle", git: "https://github.com/chef/chefstyle.git", branch: "master"

  gem "ruby-shadow", platforms: :ruby unless RUBY_PLATFORM.downcase.match(/(aix|cygwin)/)

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

group(:travis) do
  # See `bundler-audit` in .travis.yml
  gem "bundler-audit", git: "https://github.com/rubysec/bundler-audit.git", ref: "4e32fca"
end

gem "chef-zero", github: "chef/chef-zero", branch: "cd/run-acl-specs"

instance_eval(ENV["GEMFILE_MOD"]) if ENV["GEMFILE_MOD"]

# If you want to load debugging tools into the bundle exec sandbox,
# add these additional dependencies into chef/Gemfile.local
eval(IO.read(__FILE__ + ".local"), binding) if File.exist?(__FILE__ + ".local")
