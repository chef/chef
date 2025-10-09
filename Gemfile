source "https://rubygems.org"

gem "chef", path: "."

gem "ohai", git: "https://github.com/chef/ohai.git", branch: "18-stable"

# Nwed to file a bug with rest-client. In the meantime, we can use this until they accept the update.
gem "rest-client", git: "https://github.com/chef/rest-client", branch: "jfm/ucrt_update1"

gem "ffi", ">= 1.15.5", "<= 1.17.0"
gem "chef-utils", path: File.expand_path("chef-utils", __dir__) if File.exist?(File.expand_path("chef-utils", __dir__))
gem "chef-config", path: File.expand_path("chef-config", __dir__) if File.exist?(File.expand_path("chef-config", __dir__))

# required for FIPS or bundler will pick up default openssl
install_if -> { RUBY_PLATFORM !~ /darwin/ } do
  gem "openssl", "= 3.3.0"
end

# Bundler can try to install a newer fiddle than the Ruby default gem on 3.1,
# which causes activation conflicts (Ruby 3.1 ships fiddle 1.1.0). Force
# Bundler to use the Ruby-provided version on 3.1 to avoid conflicts.
install_if -> { RUBY_VERSION.start_with?("3.1") } do
  gem "fiddle", "= 1.1.0"
end

# Windows-only dependencies needed at test/runtime when using the non-universal gemspec
# These are intentionally duplicated from chef-universal-mingw-ucrt.gemspec because of the fiddle
# issue above. We want to avoid having to build multiple versions of the native gems
install_if -> { Gem.win_platform? } do
  gem "chef-powershell", "~> 18.1.0"
  gem "win32-api", "~> 1.10.0"
  gem "win32-event", "~> 0.6.1"
  gem "win32-eventlog", "= 0.6.3"
  gem "win32-mmap", "~> 0.4.1"
  gem "win32-mutex", "~> 0.4.2"
  gem "win32-process", ">= 0.9", "< 0.11"
  gem "win32-service", ">= 2.1.5", "< 3.0"
  gem "wmi-lite", "~> 1.0"
  gem "win32-taskscheduler", "~> 2.0"
  gem "iso8601", ">= 0.12.1", "< 0.14"
  gem "win32-certstore", "~> 0.6.15"
end

if File.exist?(File.expand_path("chef-bin", __dir__))
  # bundling in a git checkout
  gem "chef-bin", path: File.expand_path("chef-bin", __dir__)
else
  # bundling in omnibus
  gem "chef-bin" # rubocop:disable Bundler/DuplicatedGem
end

gem "cheffish", ">= 17"

group(:omnibus_package) do
  gem "appbundler"
  gem "rb-readline"
  gem "chef-vault"

  gem "inspec-core-bin", ">= 5", "< 6"
end

group(:omnibus_package, :pry) do
  # Locked because pry-byebug is broken with 13+.
  # some work is ongoing? https://github.com/deivid-rodriguez/pry-byebug/issues/343
  gem "pry", "= 0.13.0"
  # byebug does not install on freebsd on ruby 3.0
  gem "pry-byebug" unless RUBY_PLATFORM.match?(/freebsd/i)
  gem "pry-stack_explorer"
end

# Everything except AIX and Windows
group(:ruby_shadow) do
  install_if -> { RUBY_PLATFORM.match?(/linux|darwin|bsd|solaris/i) } do
    # if ruby-shadow does a release that supports ruby-3.0 this can be removed
    gem "ruby-shadow", git: "https://github.com/chef/ruby-shadow", branch: "lcg/ruby-3.0", platforms: :ruby
  end
end

# deps that cannot be put in the knife gem because they require a compiler and fail on windows nodes
group(:knife_windows_deps) do
  gem "ed25519", "~> 1.2" # ed25519 ssh key support
end

group(:development, :test) do
  gem "rake", ">= 12.3.3"
  gem "rspec"
  gem "webmock"
  gem "crack", "< 0.4.6" # due to https://github.com/jnunemaker/crack/pull/75
  gem "fauxhai-ng" # for chef-utils gem
end

gem "chefstyle"
# group(:chefstyle) do
#   # for testing new chefstyle rules
#   gem "chefstyle", git: "https://github.com/chef/chefstyle.git", branch: "main"
# end

instance_eval(ENV["GEMFILE_MOD"]) if ENV["GEMFILE_MOD"]

# If you want to load debugging tools into the bundle exec sandbox,
# add these additional dependencies into Gemfile.local
eval_gemfile("./Gemfile.local") if File.exist?("./Gemfile.local")
