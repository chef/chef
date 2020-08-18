source "https://rubygems.org"

# Note we do not use the gemspec DSL which restricts to the
# gemspec for the current platform and filters out other platforms
# during a bundle lock operation. We actually want dependencies from
# both of our gemspecs. Also note this this mimics gemspec behavior
# of bundler versions prior to 1.12.0 (https://github.com/bundler/bundler/commit/193a14fe5e0d56294c7b370a0e59f93b2c216eed)
gem "chef", path: "."

gem "ohai", git: "https://github.com/chef/ohai.git", branch: "master"

gem "chef-utils", path: File.expand_path("chef-utils", __dir__) if File.exist?(File.expand_path("chef-utils", __dir__))
gem "chef-config", path: File.expand_path("chef-config", __dir__) if File.exist?(File.expand_path("chef-config", __dir__))

if File.exist?(File.expand_path("chef-bin", __dir__))
  # bundling in a git checkout
  gem "chef-bin", path: File.expand_path("chef-bin", __dir__)
else
  # bundling in omnibus
  gem "chef-bin" # rubocop:disable Bundler/DuplicatedGem
end

gem "cheffish", ">= 14"

gem "chef-telemetry", ">=1.0.8" # 1.0.8 removes the http dep

group(:omnibus_package) do
  gem "appbundler"
  gem "rb-readline"
  gem "inspec-core", "~> 4.18"
  gem "inspec-core-bin", "~> 4.18" # need to provide the binaries for inspec
  gem "chef-vault"
  gem "ed25519" # ed25519 ssh key support done here as it's a native gem we can't put in train
  gem "bcrypt_pbkdf", ">= 1.1.0.rc1" # ed25519 ssh key support done here as it's a native gem we can't put in train
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

# Everything except AIX
group(:ruby_prof) do
  # ruby-prof 1.3.0 does not compile on our centos6 builders/kitchen testers
  gem "ruby-prof", "< 1.3.0"
end

# Everything except AIX and Windows
group(:ruby_shadow) do
  gem "ruby-shadow", platforms: :ruby
end

group(:development, :test) do
  gem "rake"
  gem "rspec-core", "~> 3.5"
  gem "rspec-mocks", "~> 3.5"
  gem "rspec-expectations", "~> 3.5"
  gem "rspec_junit_formatter", "~> 0.2.0"
  gem "webmock"
  gem "fauxhai-ng" # for chef-utils gem
end

group(:chefstyle) do
  # for testing new chefstyle rules
  gem "chefstyle", git: "https://github.com/chef/chefstyle.git", branch: "master"
end

instance_eval(ENV["GEMFILE_MOD"]) if ENV["GEMFILE_MOD"]

# If you want to load debugging tools into the bundle exec sandbox,
# add these additional dependencies into Gemfile.local
eval_gemfile("./Gemfile.local") if File.exist?("./Gemfile.local")

# These lines added for Windows development only.
# For FFI to call into PowerShell we need the binaries and assemblies located
# in the Ruby bindir.
# The Powershell DLL source lives here: https://github.com/chef/chef-powershell-shim
#
# We copy (and overwrite) these files every time "bundle <exec|install>" is
# executed, just in case they have changed.
if RUBY_PLATFORM.match?(/mswin|mingw|windows/)
  instance_eval do
    ruby_exe_dir = RbConfig::CONFIG["bindir"]
    assemblies = Dir.glob(File.expand_path("distro/ruby_bin_folder", File.dirname(__FILE__)) + "/*.dll")
    FileUtils.cp_r assemblies, ruby_exe_dir, verbose: false unless ENV["_BUNDLER_WINDOWS_DLLS_COPIED"]
    ENV["_BUNDLER_WINDOWS_DLLS_COPIED"] = "1"
  end
end
