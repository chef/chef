gems = %w[chef chefserverslice chef-server]

desc "Build the chef gems"
task :gem do
  gems.each do |dir|
    Dir.chdir(dir) { sh "rake package" }
  end
end
 
desc "Install the chef gems"
task :install do
  gems.each do |dir|
    Dir.chdir(dir) { sh "rake install" }
  end
end

desc "Uninstall the chef gems"
task :uninstall do
  gems.reverse.each do |dir|
    Dir.chdir(dir) { sh "rake uninstall" }
  end
end

desc "Run the rspec tests"
task :spec do
  gems.each do |dir|
    Dir.chdir(dir) { sh "rake spec" }
  end
end

namespace :dev do
  desc "Install a Devel instance of Chef with the example-repository"
  task :install do
    gems.each do |dir|
      Dir.chdir(dir) { sh "rake install" }
    end
    Dir.chdir("example-repository") { sh("rake install") }
  end
end
