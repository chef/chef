source :rubygems

omnibus_ruby_local_path = File.expand_path(File.join(File.dirname(__FILE__), "..", "omnibus-ruby"))
omnibus_software_local_path = File.expand_path(File.join(File.dirname(__FILE__), "..", "omnibus-software"))

#gem "omnibus", :path => omnibus_ruby_local_path
gem "omnibus", :git => "git://github.com/opscode/omnibus-ruby.git", :branch => 'master'

#gem "omnibus-software", :path => omnibus_software_local_path
gem "omnibus-software", :git => "git://github.com/opscode/omnibus-software.git", :branch => 'enable-libedit'

group :development do
  gem "vagrant", "~> 1.0"
end

