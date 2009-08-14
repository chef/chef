gems = %w[chef chef-server-slice chef-server]
require 'rubygems'
require 'cucumber/rake/task'

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
  Dir.chdir("chef") { sh "rake spec" }
end

task :default => :spec

def start_dev_environment(type="normal")
  @couchdb_server_pid = nil
  @chef_server_pid    = nil
  @chef_indexer_pid   = nil
  @stompserver_pid    = nil
  
  ccid = fork
  if ccid
    @couchdb_server_pid = ccid
  else
    exec("couchdb")
  end

  scid = fork
  if scid
    @stompserver_pid = scid
  else
    exec("stompserver")
  end

  mcid = fork
  if mcid # parent
    @chef_indexer_pid = mcid
  else # child
    case type
    when "normal"
      exec("chef-indexer -l debug")
    when "features"
      exec("chef-indexer -c #{File.join(File.dirname(__FILE__), "features", "data", "config", "server.rb")} -l debug")
    end
  end

  mcid = fork
  if mcid # parent
    @chef_server_pid = mcid
  else # child
    case type
    when "normal"
      exec("chef-server -l debug -N -c 2")
    when "features"
      exec("chef-server -C #{File.join(File.dirname(__FILE__), "features", "data", "config", "server.rb")} -l debug -N -c 2")
      
    end
  end

  puts "Running Chef at #{@chef_server_pid}"
  puts "Running Chef Indexer at #{@chef_indexer_pid}"
  puts "Running CouchDB at #{@couchdb_server_pid}"
  puts "Running Stompserver at #{@stompserver_pid}"
end

def stop_dev_environment
  puts "Stopping CouchDB"
  Process.kill("KILL", @couchdb_server_pid) 
  puts "Stopping Stomp server"
  Process.kill("KILL", @stompserver_pid) 
  puts "Stopping Chef Server"
  Process.kill("INT", @chef_server_pid)
  puts "Stopping Chef Indexer"
  Process.kill("INT", @chef_indexer_pid)
  puts "\nCouchDB, Stomp, Chef Server and Chef Indexer killed - have a nice day!"
end

def wait_for_ctrlc
  puts "Hit CTRL-C to destroy development environment"
  trap("CHLD", "IGNORE")
  trap("INT") do
    stop_dev_environment
    exit 1
  end
  while true
    sleep 10
  end
end

desc "Run a Devel instance of Chef"
task :dev => "dev:install" do
  start_dev_environment
  wait_for_ctrlc
end

namespace :dev do  
  desc "Install a test instance of Chef for doing features against"
  task :features do
    gems.each do |dir|
      Dir.chdir(dir) { sh "rake install" }
    end
    start_dev_environment("features")
    wait_for_ctrlc
  end
end

Cucumber::Rake::Task.new(:features) do |t|
  t.profile = "default"
end

namespace :features do
  Cucumber::Rake::Task.new(:api) do |t|
    t.profile = "api"
  end

  namespace :api do
    [ :nodes, :roles].each do |api|
        Cucumber::Rake::Task.new(api) do |apitask|
          apitask.profile = "api_#{api.to_s}"
        end
      namespace api do
        %w{create delete list show update}.each do |action|
          Cucumber::Rake::Task.new("#{action}") do |t|
            t.profile = "api_#{api.to_s}_#{action}"
          end
        end
      end
    end
  end

  Cucumber::Rake::Task.new(:client) do |t|
    t.profile = "client"
  end

  namespace :client do
    Cucumber::Rake::Task.new(:roles) do |t|
      t.profile = "client_roles"
    end
  end

  Cucumber::Rake::Task.new(:search) do |t|
    t.profile = "search"
  end

  Cucumber::Rake::Task.new(:language) do |t|
    t.profile = "language"
  end

  namespace :language do
    Cucumber::Rake::Task.new(:recipe_include) do |t|
      t.profile = "recipe_inclusion"
    end
  end

  namespace :provider do
    Cucumber::Rake::Task.new(:template) do |t|
      t.profile = "provider_template"
    end

    Cucumber::Rake::Task.new(:remote_file) do |t|
      t.profile = "provider_remote_file"
    end
    
    namespace :package do
      Cucumber::Rake::Task.new(:macports) do |t|
        t.profile = "provider_package_macports"
      end
    end
  end
end
