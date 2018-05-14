source "https://rubygems.org"

# Note we do not use the gemspec DSL which restricts to the
# gemspec for the current platform and filters out other platforms
# during a bundle lock operation. We actually want dependencies from
# both of our gemspecs. Also note this this mimics gemspec behavior
# of bundler versions prior to 1.12.0 (https://github.com/bundler/bundler/commit/193a14fe5e0d56294c7b370a0e59f93b2c216eed)
gem "chef", path: "."

gem "chef-config", path: File.expand_path("../chef-config", __FILE__) if File.exist?(File.expand_path("../chef-config", __FILE__))
gem "cheffish", "~> 14"

group(:omnibus_package) do
  gem "appbundler"
  gem "rb-readline"
  gem "inspec-core", "~> 2"
  gem "chef-vault"
end

group(:omnibus_package, :pry) do
  gem "pry"
  gem "pry-byebug"
  gem "pry-remote"
  gem "pry-stack_explorer"
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
group(:ruby_prof) do
  gem "ruby-prof"
end

# Everything except AIX and Windows
group(:ruby_shadow) do
  gem "ruby-shadow", platforms: :ruby
end

group(:development, :test) do
  gem "rake"
  gem "simplecov"
  gem "webmock"

  # for testing new chefstyle rules
  # gem 'chefstyle', github: 'chef/chefstyle'
  gem "chefstyle", git: "https://github.com/chef/chefstyle.git", branch: "master"
end

group(:travis) do
  gem "travis"
end

instance_eval(ENV["GEMFILE_MOD"]) if ENV["GEMFILE_MOD"]

# If you want to load debugging tools into the bundle exec sandbox,
# add these additional dependencies into Gemfile.local
eval_gemfile(__FILE__ + ".local") if File.exist?(__FILE__ + ".local")
