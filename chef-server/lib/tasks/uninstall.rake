require 'rubygems'
require 'rake/gempackagetask'

task :uninstall do
  sh %{sudo gem uninstall #{GEM} -x -v #{CHEF_SERVER_VERSION}}
end

