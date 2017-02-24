# This buys us the ability to be included in other Gemfiles
require_relative "tasks/gemfile_util"
extend GemfileUtil

source "https://rubygems.org"

# Note we do not use the gemspec DSL which restricts to the
# gemspec for the current platform and filters out other platforms
# during a bundle lock operation. We actually want dependencies from
# both of our gemspecs. Also note this this mimics gemspec behavior
# of bundler versions prior to 1.12.0 (https://github.com/bundler/bundler/commit/193a14fe5e0d56294c7b370a0e59f93b2c216eed)
gem "chef", path: "."

# tracking master of ohai for chef-13.0 development, this should be able to be deleted after release
gem "ohai", git: "https://github.com/chef/ohai.git"

gem "chef-config", path: File.expand_path("../chef-config", __FILE__) if File.exist?(File.expand_path("../chef-config", __FILE__))
gem "rake"
gem "bundler"
gem "cheffish" # required for rspec tests

group(:omnibus_package) do
  gem "appbundler"
  gem "rb-readline"
  gem "nokogiri"
end

group(:omnibus_package, :pry) do
  gem "pry"
  gem "pry-byebug"
  gem "pry-remote"
  gem "pry-stack_explorer"
end

# These are used for external tests
group(:integration) do
  gem "chef-provisioning"
  gem "chef-sugar"
  gem "chefspec"
  gem "halite", git: "https://github.com/poise/halite.git"
  gem "poise", git: "https://github.com/poise/poise.git"
  gem "poise-boiler", git: "https://github.com/poise/poise-boiler.git"
  gem "knife-windows"
  gem "foodcritic"

  # We pin this so nobody brings in a cucumber-core incompatible with cucumber latest
  gem "cucumber", ">= 2.4.0"
  # We pin oc-chef-pedant to prevent it from updating out of lockstep with chef-zero
  gem "oc-chef-pedant", git: "https://github.com/chef/chef-server"
end

group(:docgen) do
  gem "yard"
end

group(:maintenance) do
  gem "tomlrb"

  # To sync maintainers with github
  gem "octokit"
  gem "netrc"
end

# Everything except AIX
group(:linux, :bsd, :mac_os_x, :solaris, :windows) do
  # may need to disable this in insolation on fussy builds like AIX, RHEL4, etc
  gem "ruby-prof"
end

# Everything except AIX and Windows
group(:linux, :bsd, :mac_os_x, :solaris) do
  gem "ruby-shadow", platforms: :ruby
end

group(:development, :test) do
  gem "simplecov"

  # for testing new chefstyle rules
  # gem 'chefstyle', github: 'chef/chefstyle'
  gem "chefstyle", git: "https://github.com/chef/chefstyle.git", branch: "master"
end

group(:changelog) do
  gem "github_changelog_generator", git: "https://github.com/chef/github-changelog-generator"
  gem "mixlib-install"
end

group(:travis) do
  # See `bundler-audit` in .travis.yml
  gem "bundler-audit", git: "https://github.com/rubysec/bundler-audit.git"
  gem "travis"
end

instance_eval(ENV["GEMFILE_MOD"]) if ENV["GEMFILE_MOD"]

# If you want to load debugging tools into the bundle exec sandbox,
# add these additional dependencies into chef/Gemfile.local
eval(IO.read(__FILE__ + ".local"), binding) if File.exist?(__FILE__ + ".local")
