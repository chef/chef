unless ENV["APPBUNDLER_ALLOW_RVM"]
  vendor_dir = File.expand_path(File.join(__dir__, "..", "vendor"))
  ENV["APPBUNDLER_ALLOW_RVM"] = "true"
  ENV["GEM_PATH"] = vendor_dir
  ENV["GEM_HOME"] = vendor_dir
end
