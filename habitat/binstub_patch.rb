require "rbconfig"

unless ENV["APPBUNDLER_ALLOW_RVM"]
  ENV["APPBUNDLER_ALLOW_RVM"] = "true"
end

# Vendor dir contains bundled runtime dependencies (addressable, train-core, etc.)
vendor_dir = File.expand_path(File.join(__dir__, "..", "vendor"))
# Chef-cli gem install path for plugins
chef_gem_dir = File.join(Dir.home, ".chef", "ruby", RbConfig::CONFIG["ruby_version"], "gems")
existing_paths = ENV["GEM_PATH"]&.split(File::PATH_SEPARATOR) || []
ENV["GEM_PATH"] = ([vendor_dir, chef_gem_dir] + existing_paths).uniq.join(File::PATH_SEPARATOR)
