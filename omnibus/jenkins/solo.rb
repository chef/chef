pwd = File.expand_path(File.dirname(__FILE__))
file_cache_path "#{pwd}/chef-solo/cache"
cookbook_path ["#{pwd}/../cookbooks", "#{pwd}/../vendor/cookbooks"]
