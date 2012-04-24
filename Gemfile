source "http://rubygems.org"

omnibus_ruby_local_path = File.expand_path(File.join(File.dirname(__FILE__), "..", "omnibus-ruby"))
omnibus_software_local_path = File.expand_path(File.join(File.dirname(__FILE__), "..", "omnibus-software"))

if File.directory?(omnibus_ruby_local_path)
  gem "omnibus", :path => omnibus_ruby_local_path
else
  gem "omnibus", :git => "http://github.com/opscode/omnibus-ruby"
end

if File.directory?(omnibus_software_local_path)
  gem "omnibus-software", :path => omnibus_software_local_path
else
  gem "omnibus-software", :git => "http://github.com/opscode/omnibus-software"
end

group :development do
  gem "vagrant", "~> 1.0"
end

