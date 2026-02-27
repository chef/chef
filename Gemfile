source "https://rubygems.org"

gem "chef", path: "."

gem "ohai", git: "https://github.com/chef/ohai.git", branch: "main"

gem "cheffish", git: "https://github.com/chef/cheffish.git", branch: "main"

# Upstream PR for 3.1 updates: https://github.com/rest-client/rest-client/pull/781
# Using our fork until they accept it.
gem "rest-client", git: "https://github.com/chef/rest-client", branch: "jfm/ucrt_update1"

if RUBY_PLATFORM.include?("mingw") || RUBY_PLATFORM.include?("darwin")
  gem "ffi", ">= 1.15.5", "< 1.18.0"
else
  gem "ffi", ">= 1.15.5", force_ruby_platform: true
end

gem "chef-utils", path: File.expand_path("chef-utils", __dir__) if File.exist?(File.expand_path("chef-utils", __dir__))
gem "chef-config", path: File.expand_path("chef-config", __dir__) if File.exist?(File.expand_path("chef-config", __dir__))

# required for FIPS or bundler will pick up default openssl
install_if -> { !Gem.platforms.any? { |platform| !platform.is_a?(String) && platform.os == "darwin" } } do
  gem "openssl", "= 3.3.1"
end

if File.exist?(File.expand_path("chef-bin", __dir__))
  # bundling in a git checkout
  gem "chef-bin", path: File.expand_path("chef-bin", __dir__)
else
  # bundling in omnibus
  gem "chef-bin" # rubocop:disable Bundler/DuplicatedGem
end

group(:omnibus_package) do
  gem "appbundler"
  gem "rb-readline"
  gem "inspec-core-bin", "= 7.0.95" # need to provide the binaries for inspec
  gem "chef-vault"
end

gem "repl_type_completor", "~> 0.1.12" # deprecation warnings in chef-shell

group(:omnibus_package, :pry) do
  # Locked because pry-byebug is broken with 13+.
  # some work is ongoing? https://github.com/deivid-rodriguez/pry-byebug/issues/343
  gem "pry", "~> 0.15.2"
  # byebug does not install on freebsd on ruby 3.0
  install_if -> { !RUBY_PLATFORM.match?(/freebsd/i) } do
    gem "pry-byebug"
  end
  gem "pry-stack_explorer"
end

# Everything except Windows
group(:ruby_shadow) do
  install_if -> { !RUBY_PLATFORM.match?(/mingw/) } do
    gem "chef-ruby-shadow", "~> 3.0.0", platforms: :ruby
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
  gem "crack", "~> 1.0.1"
  gem "fauxhai-ng" # for chef-utils gem
end

instance_eval(ENV["GEMFILE_MOD"]) if ENV["GEMFILE_MOD"]

# If you want to load debugging tools into the bundle exec sandbox,
# add these additional dependencies into Gemfile.local
eval_gemfile("./Gemfile.local") if File.exist?("./Gemfile.local")
