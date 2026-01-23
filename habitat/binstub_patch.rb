unless ENV["APPBUNDLER_ALLOW_RVM"]
  ENV["APPBUNDLER_ALLOW_RVM"] = "true"
  ENV["GEM_PATH"] = [File.expand_path(File.join(__dir__, "..", "vendor")), ENV["GEM_PATH"]].compact.join(File::PATH_SEPARATOR)
end
