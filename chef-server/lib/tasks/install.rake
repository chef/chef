require 'rubygems'
require 'rake/gempackagetask'

task :install => :package do
  sh %{sudo gem install pkg/#{GEM}-#{CHEF_SERVER_VERSION} --no-rdoc --no-ri}
end

