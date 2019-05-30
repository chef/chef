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
  gem "inspec-core", "~> 3"
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

# Everything except AIX
group(:ruby_prof) do
  gem "ruby-prof", "< 0.18.0" # 0.18 breaks appveyor tests
end

# Everything except AIX and Windows
group(:ruby_shadow) do
  gem "ruby-shadow", platforms: :ruby
end

group(:development, :test) do
  # we pin rake as a copy of rake is installed from the ruby source
  # if you bump the ruby version you should confirm we don't end up with
  # two rake gems installed again
  gem "rake", "<= 12.3.0"
  gem "simplecov"
  gem "webmock"

  # for testing new chefstyle rules
  gem "chefstyle", "=0.11.2"
end

instance_eval(ENV["GEMFILE_MOD"]) if ENV["GEMFILE_MOD"]

# If you want to load debugging tools into the bundle exec sandbox,
# add these additional dependencies into Gemfile.local
eval_gemfile(__FILE__ + ".local") if File.exist?(__FILE__ + ".local")

# These lines added for Windows development only.
# For FFI to call into PowerShell we need the binaries and assemblies located
# in the Ruby bindir.
#
# We copy (and overwrite) these files every time "bundle <exec|install>" is
# executed, just in case they have changed.
if RUBY_PLATFORM =~ /mswin|mingw|windows/
  instance_eval do
    ruby_exe_dir = RbConfig::CONFIG["bindir"]
    assemblies = Dir.glob(File.expand_path("distro/ruby_bin_folder", Dir.pwd) + "/*.dll")
    FileUtils.cp_r assemblies, ruby_exe_dir, verbose: false unless ENV["_BUNDLER_WINDOWS_DLLS_COPIED"]
    ENV["_BUNDLER_WINDOWS_DLLS_COPIED"] = "1"
  end
end
