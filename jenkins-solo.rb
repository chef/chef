pwd = File.dirname(__FILE__)
file_cache_path "#{pwd}/chef-solo/cache"
cookbook_path "#{ENV["omnibus_path"]}/cookbooks"
