#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Daniel DeLeo (<dan@opscode.com>)
# Copyright:: Copyright (c) 2008, 2010 Opscode, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

gems = %w[chef chef-server-api chef-server-webui chef-solr chef-expander chef-server]
require 'rubygems'

desc "Build the chef gems"
task :gem do
  gems.each do |dir|
      Dir.chdir(dir) { sh "rake gem" }
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

def start_couchdb(type="normal")
  @couchdb_server_pid  = nil
  cid = fork
  if cid
    @couchdb_server_pid = cid
  else
    exec("couchdb")
  end
end

def start_rabbitmq(type="normal")
  @rabbitmq_server_pid = nil
  cid = fork
  if cid
    @rabbitmq_server_pid = cid
  else
    exec("rabbitmq-server")
  end
end

def configure_rabbitmq(type="normal")
  # hack. wait for rabbit to come up.
  sleep 2

  puts `rabbitmqctl add_vhost /chef`

  # create 'chef' user, give it the password 'testing'
  puts `rabbitmqctl add_user chef testing`

  # the three regexes map to config, write, read permissions respectively
  puts `rabbitmqctl set_permissions -p /chef chef ".*" ".*" ".*"`

  puts `rabbitmqctl list_users`
  puts `rabbitmqctl list_vhosts`
  puts `rabbitmqctl list_permissions -p /chef`

end

def start_chef_solr(type="normal")
  @chef_solr_pid = nil
  cid = fork
  if cid
    @chef_solr_pid = cid
  else
    case type
    when "normal"
      exec("./chef-solr/bin/chef-solr -l debug")
    when "features"
      p = fork { exec("./chef-solr/bin/chef-solr-installer -p /tmp/chef_solr_for_features --force") }
      Process.wait(p)
      exec("./chef-solr/bin/chef-solr -c #{File.join(File.dirname(__FILE__), "features", "data", "config", "server.rb")} -l debug")
    end
  end
end

def start_chef_expander(type="normal")
  @chef_solr_indexer   = nil
  @chef_solr_indexer_pid = fork do
    case type
    when "normal"
      exec("./chef-expander/bin/chef-expander -n 1 -i 1 -l debug")
    when "features"
      exec("./chef-expander/bin/chef-expander -c #{File.join(File.dirname(__FILE__), "features", "data", "config", "server.rb")} -l debug -n 1 -i 1")
    end
  end
end

def start_chef_server(type="normal")
  puts "Starting #{type} chef development server"
  @chef_server_pid     = nil
  mcid = fork
  if mcid # parent
    @chef_server_pid = mcid
  else # child
    case type
    when "normal"
      puts "Starting chef server for development with './chef-server-api/bin/chef-server -a thin -l debug -N'"
      exec("./chef-server-api/bin/chef-server -a thin -l debug -N")
    when "features"
      puts "Starting chef server for features with #{["./chef-server/bin/chef-server -a thin -C #{File.join(File.dirname(__FILE__), "features", "data", "config", "server.rb")} -l debug -N"].join(' ')}"
      exec("./chef-server-api/bin/chef-server -a thin -C #{File.join(File.dirname(__FILE__), "features", "data", "config", "server.rb")} -l debug -N")
    end
  end
end

def start_chef_webui(type="normal")
  puts "Starting #{type} chef development server webui"
  @chef_webui_pid     = nil
  mcid = fork
  if mcid # parent
    @chef_webui_pid = mcid
  else # child
    case type
    when "normal"
      puts "Starting chef webui for development with './chef-server/bin/chef-server-webui -a thin -l debug -N'"
      exec("./chef-server-webui/bin/chef-server-webui -a thin -l debug -N")
    when "features"
      puts "Starting chef server webui for features with #{["./chef-server/bin/chef-server-webui -a thin -C #{File.join(File.dirname(__FILE__), "features", "data", "config", "server.rb")} -l debug -N"].join(' ')}"
      exec("./chef-server-webui/bin/chef-server-webui -a thin -C #{File.join(File.dirname(__FILE__), "features", "data", "config", "server.rb")} -l debug -N")
    end
  end
end

def start_dev_environment(type="normal")
  start_couchdb(type)
  start_rabbitmq(type)
  sleep 2
  configure_rabbitmq(type)
  start_chef_solr(type)
  start_chef_expander(type)
  start_chef_server(type)
  start_chef_webui(type)
  puts "Running CouchDB at #{@couchdb_server_pid}"
  puts "Running RabbitMQ at #{@rabbitmq_server_pid}"
  puts "Running Chef Solr at #{@chef_solr_pid}"
  puts "Running Chef Solr Indexer at #{@chef_solr_indexer_pid}"
  puts "Running Chef at #{@chef_server_pid}"
  puts "Running Chef Web UI at #{@chef_webui_pid}"
end

def stop_dev_environment
  if @chef_webui_pid
    puts "Stopping Chef Web UI"
    Process.kill("KILL", @chef_webui_pid)
  end
  if @chef_server_pid
    puts "Stopping Chef"
    Process.kill("KILL", @chef_server_pid)
  end
  if @chef_solr_pid
    puts "Stopping Chef Solr"
    Process.kill("INT", @chef_solr_pid)
  end
  if @chef_solr_indexer_pid
    puts "Stopping Chef Solr Indexer"
    Process.kill("INT", @chef_solr_indexer_pid)
  end
  if @couchdb_server_pid
    puts "Stopping CouchDB"
    Process.kill("KILL", @couchdb_server_pid)
  end
  if @rabbitmq_server_pid
    puts "Stopping RabbitMQ"
    Process.kill("KILL", @rabbitmq_server_pid)
  end
  puts "Have a nice day!"
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

desc "Run a development instance of Chef"
task :dev do
  start_dev_environment
  wait_for_ctrlc
end

namespace :dev do
  desc "Run a test instance of Chef suitable for cucumber tests"
  task :features do
    start_dev_environment("features")
    wait_for_ctrlc
  end

  namespace :features do

    namespace :start do
      desc "Start CouchDB for testing"
      task :couchdb do
        start_couchdb("features")
        wait_for_ctrlc
      end

      desc "Start RabbitMQ for testing"
      task :rabbitmq do
        start_rabbitmq("features")
        configure_rabbitmq("features")
        wait_for_ctrlc
      end

      desc "Start Chef Solr for testing"
      task :chef_solr do
        start_chef_solr("features")
        wait_for_ctrlc
      end

      desc "Start Chef Solr Indexer for testing"
      task :chef_expander do
        start_chef_expander("features")
        wait_for_ctrlc
      end

      desc "Start Chef Server for testing"
      task :chef_server do
        start_chef_server("features")
        wait_for_ctrlc
      end

      desc "Start Chef Web UI for testing"
      task :chef_webui do
        start_chef_webui("features")
        wait_for_ctrlc
      end

    end
  end

  namespace :start do
    desc "Start CouchDB"
    task :couchdb do
      start_couchdb
      wait_for_ctrlc
    end

    desc "Start RabbitMQ"
    task :rabbitmq do
      start_rabbitmq
      configure_rabbitmq
      wait_for_ctrlc
    end

    desc "Start Chef Solr"
    task :chef_solr do
      start_chef_solr
      wait_for_ctrlc
    end

    desc "Start Chef Solr Indexer"
    task :chef_solr_indexer do
      start_chef_expander
      wait_for_ctrlc
    end

    desc "Start Chef Server"
    task :chef_server do
      start_chef_server
      wait_for_ctrlc
    end

    desc "Start Chef Web UI"
    task :chef_webui do
      start_chef_webui
      wait_for_ctrlc
    end
  end
end

begin
  require 'cucumber/rake/task'

  Cucumber::Rake::Task.new(:features) do |t|
    t.profile = "default"
  end

  namespace :features do
    desc "Run cucumber tests for the REST API"
    Cucumber::Rake::Task.new(:api) do |t|
      t.profile = "api"
    end

    namespace :api do
      [ :nodes, :roles, :clients, :environments ].each do |api|
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

      namespace :environments do
        Cucumber::Rake::Task.new("cookbooks") do |t|
          t.profile = "api_environments_cookbook_list"
        end

        Cucumber::Rake::Task.new("nodes") do |t|
          t.profile = "api_environments_node_list"
        end
      end

      namespace :nodes do
        Cucumber::Rake::Task.new("sync") do |t|
          t.profile = "api_nodes_sync"
        end
      end

      desc "Run cucumber tests for the cookbooks portion of the REST API"
      Cucumber::Rake::Task.new(:cookbooks) do |t|
        t.profile = "api_cookbooks"
      end
      namespace :cookbooks do
        %w{list show upload download delete}.each do |action|
          Cucumber::Rake::Task.new(action) do |t|
            t.profile = "api_cookbooks_#{action}"
          end
        end

        Cucumber::Rake::Task.new(:cookbook_tarballs) do |t|
          t.profile = "api_cookbooks_tarballs"
        end
      end

      namespace :data do
        desc "Run cucumber tests for the data portion of the REST API"
        Cucumber::Rake::Task.new(:data) do |t|
          t.profile = "api_data"
        end

        desc "Run cucumber tests for deleting data via the REST API"
        Cucumber::Rake::Task.new(:delete) do |t|
          t.profile = "api_data_delete"
        end
        desc "Run cucumber tests for adding items via the REST API"
        Cucumber::Rake::Task.new(:item) do |t|
          t.profile = "api_data_item"
        end
      end

      namespace :search do
        desc "Run cucumber tests for searching via the REST API"
        Cucumber::Rake::Task.new(:search) do |t|
          t.profile = "api_search"
        end

        desc "Run cucumber tests for listing search endpoints via the REST API"
        Cucumber::Rake::Task.new(:list) do |t|
          t.profile = "api_search_list"
        end
        desc "Run cucumber tests for searching via the REST API"
        Cucumber::Rake::Task.new(:show) do |t|
          t.profile = "api_search_show"
        end
        desc "Run cucumber tests for searching via the REST API"
        Cucumber::Rake::Task.new(:reindex) do |t|
          t.profile = "api_search_reindex"
        end
      end
    end

    desc "Run cucumber tests for the chef client"
    Cucumber::Rake::Task.new(:client) do |t|
      t.profile = "client"
    end

    namespace :client do
      Cucumber::Rake::Task.new(:roles) do |t|
        t.profile = "client_roles"
      end

      Cucumber::Rake::Task.new(:run_interval) do |t|
        t.profile = "client_run_interval"
      end

      Cucumber::Rake::Task.new(:cookbook_sync) do |t|
        t.profile = "client_cookbook_sync"
      end
    end

    desc "Run cucumber tests for the cookbooks"
    Cucumber::Rake::Task.new(:cookbooks) do |t|
      t.profile = "cookbooks"
    end

    namespace :cookbook do

      desc "Run cucumber tests for the cookbook metadata"
      Cucumber::Rake::Task.new(:metadata) do |t|
        t.profile = "cookbook_metadata"
      end
    end

    desc "Run cucumber tests for the recipe language"
    Cucumber::Rake::Task.new(:language) do |t|
      t.profile = "language"
    end

    Cucumber::Rake::Task.new(:attribute_settings) do |t|
      t.profile = "attribute_settings"
    end

    desc "Run cucumber tests for searching in recipes"
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
      Cucumber::Rake::Task.new(:attribute_include) do |t|
        t.profile = "attribute_inclusion"
      end
    end

    Cucumber::Rake::Task.new(:lwrp) do |t|
      t.profile = "lwrp"
    end

    desc "Run cucumber tests for providers"
    Cucumber::Rake::Task.new(:provider) do |t|
      t.profile = "provider"
    end


    namespace :provider do
      desc "Run cucumber tests for deploy resources"
      Cucumber::Rake::Task.new(:deploy) do |t|
        t.profile = "provider_deploy"
      end

      desc "Run cucumber tests for directory resources"
      Cucumber::Rake::Task.new(:directory) do |t|
        t.profile = "provider_directory"
      end

      desc "Run cucumber tests for execute resources"
      Cucumber::Rake::Task.new(:execute) do |t|
        t.profile = "provider_execute"
      end

      desc "Run cucumber tests for file resources"
      Cucumber::Rake::Task.new(:file) do |t|
        t.profile = "provider_file"
      end

      desc "Run cucumber tests for remote_file resources"
      Cucumber::Rake::Task.new(:remote_file) do |t|
        t.profile = "provider_remote_file"
      end

      desc "Run cucumber tests for template resources"
      Cucumber::Rake::Task.new(:template) do |t|
        t.profile = "provider_template"
      end

      Cucumber::Rake::Task.new(:remote_directory) do |t|
        t.profile = "provider_remote_directory"
      end

      Cucumber::Rake::Task.new(:git) do |t|
        t.profile = "provider_git"
      end

      namespace :package do
        desc "Run cucumber tests for macports packages"
        Cucumber::Rake::Task.new(:macports) do |t|
          t.profile = "provider_package_macports"
        end

        Cucumber::Rake::Task.new(:gems) do |g|
          g.profile = "provider_package_rubygems"
        end
      end

      desc "Run cucumber tests for knife"
      Cucumber::Rake::Task.new(:knife) do |t|
        t.profile = "knife"
      end

    end
  end
rescue LoadError
  STDERR.puts "\n*** Cucumber is missing. (sudo) gem install cucumber to run integration tests. ***\n\n"
end
