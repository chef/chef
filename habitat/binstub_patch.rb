require "rbconfig"

unless ENV["APPBUNDLER_ALLOW_RVM"]
  ENV["APPBUNDLER_ALLOW_RVM"] = "true"
end

chef_gem_dir = File.join(Dir.home, ".chef", "ruby", RbConfig::CONFIG["ruby_version"], "gems")
existing_paths = ENV["GEM_PATH"]&.split(File::PATH_SEPARATOR) || []
ENV["GEM_PATH"] = ([chef_gem_dir] + existing_paths).uniq.join(File::PATH_SEPARATOR)
