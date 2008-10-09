gems = %w[chef chef-server]

desc "Build the chef gems"
task :build_gems do
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

namespace :dev do
  desc "Install a Devel instance of Chef with the example-repository"
  task :install do
    gems.each do |dir|
      Dir.chdir(dir) { sh "rake install" }
    end
    Dir.chdir("example-repository") { sh("rake install") }
  end
end