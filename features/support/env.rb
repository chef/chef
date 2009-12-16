# Copyright:: Copyright (c) 2008 Opscode, Inc.
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

%w{chef chef-server chef-server-slice chef-solr}.each do |inc_dir|
  $: << File.join(File.dirname(__FILE__), '..', '..', inc_dir, 'lib')
end

Thread.abort_on_exception = true

require 'rubygems'
require 'spec'
require 'chef'
require 'chef/config'
require 'chef/client'
require 'chef/data_bag'
require 'chef/data_bag_item'
require 'chef/api_client'
require 'chef/solr'
require 'chef/certificate'
require 'tmpdir'
require 'merb-core'
require 'merb_cucumber/world/webrat'
require 'chef/streaming_cookbook_uploader'
require 'webrick'

def Spec.run? ; true; end

ENV['LOG_LEVEL'] ||= 'error'

def setup_logging
  Chef::Config.from_file(File.join(File.dirname(__FILE__), '..', 'data', 'config', 'server.rb'))
  Merb.logger.auto_flush = true
  if ENV['DEBUG'] == 'true' || ENV['LOG_LEVEL'] == 'debug'
    Chef::Config[:log_level] = :debug
    Chef::Log.level = :debug
    Merb.logger.set_log(STDOUT, :debug) 
  else
    Chef::Config[:log_level] = ENV['LOG_LEVEL'].to_sym 
    Chef::Log.level = ENV['LOG_LEVEL'].to_sym
    Merb.logger.set_log(STDOUT, ENV['LOG_LEVEL'].to_sym)
  end
  Nanite::Log.logger = Ohai::Log.logger = Chef::Log.logger 
end

def setup_nanite
  Chef::Config[:nanite_identity] = "chef-integration-test"
  Chef::Nanite.in_event { Chef::Log.debug("Nanite is up!") } 
  Chef::Log.debug("Waiting for Nanites to register with us as a mapper")
  sleep 10
end

def delete_databases
  c = Chef::REST.new(Chef::Config[:couchdb_url], nil, nil)
  %w{chef_integration chef_integration_safe}.each do |db|
    begin
      c.delete_rest("#{db}/")
    rescue
    end
  end
end

def create_databases
  Chef::Log.info("Creating bootstrap databases")
  cdb = Chef::CouchDB.new(Chef::Config[:couchdb_url], "chef_integration")
  cdb.create_db
  cdb.create_id_map
  Chef::Node.create_design_document
  Chef::Role.create_design_document
  Chef::DataBag.create_design_document
  Chef::ApiClient.create_design_document
  Chef::Role.sync_from_disk_to_couchdb
  Chef::Certificate.generate_signing_ca
  Chef::Certificate.gen_validation_key
  Chef::Certificate.gen_validation_key(Chef::Config[:web_ui_client_name], Chef::Config[:web_ui_key])
  system("cp #{File.join(Dir.tmpdir, "chef_integration", "validation.pem")} #{Dir.tmpdir}")
  system("cp #{File.join(Dir.tmpdir, "chef_integration", "webui.pem")} #{Dir.tmpdir}")
end

def prepare_replicas
  c = Chef::REST.new(Chef::Config[:couchdb_url], nil, nil)
  c.put_rest("chef_integration_safe/", nil)
  c.post_rest("_replicate", { "source" => "#{Chef::Config[:couchdb_url]}/chef_integration", "target" => "#{Chef::Config[:couchdb_url]}/chef_integration_safe" })
  c.delete_rest("chef_integration")
end

def cleanup
  if File.exists?(Chef::Config[:validation_key])
    File.unlink(Chef::Config[:validation_key])
  end
  if File.exists?(Chef::Config[:web_ui_key])
    File.unlink(Chef::Config[:web_ui_key])
  end
end

Merb.start_environment(
  :merb_root => File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "chef-server")), 
  :testing => true, 
  :adapter => 'runner',
  :environment => ENV['MERB_ENV'] || 'test',
  :session_store => 'memory'
)

###
# Pre-testing setup
###
setup_logging
setup_nanite
cleanup
delete_databases
create_databases
prepare_replicas

Spec::Runner.configure do |config|
  config.include(Merb::Test::ViewHelper)
  config.include(Merb::Test::RouteHelper)
  config.include(Merb::Test::ControllerHelper)
end

Chef::Log.info("Ready to run tests")

###
# The Cucumber World
###
module ChefWorld

  attr_accessor :recipe, :cookbook, :response, :inflated_response, :log_level,
                :chef_args, :config_file, :stdout, :stderr, :status, :exception,
                :gemserver_thread

  def client
    @client ||= Chef::Client.new
  end

  def rest
    @rest ||= Chef::REST.new('http://localhost:4000', nil, nil)
  end

  def tmpdir
    @tmpdir ||= File.join(Dir.tmpdir, "chef_integration")
  end

  def server_tmpdir
    @server_tmpdir ||= File.expand_path(File.join(datadir, "tmp"))
  end
  
  def datadir
    @datadir ||= File.join(File.dirname(__FILE__), "..", "data")
  end

  def cleanup_files
    @cleanup_files ||= Array.new
  end

  def cleanup_dirs
    @cleanup_dirs ||= Array.new
  end

  def stash
    @stash ||= Hash.new
  end
  
  def gemserver
    @gemserver ||= WEBrick::HTTPServer.new(
      :Port         => 8000,
      :DocumentRoot => datadir + "/gems/",
      # Make WEBrick STFU
      :Logger       => Logger.new(StringIO.new),
      :AccessLog    => [ StringIO.new, WEBrick::AccessLog::COMMON_LOG_FORMAT ]
    )
  end
  
end

World(ChefWorld)

Before do
  system("mkdir -p #{tmpdir}")
  system("cp -r #{File.join(Dir.tmpdir, "validation.pem")} #{File.join(tmpdir, "validation.pem")}")
  system("cp -r #{File.join(Dir.tmpdir, "webui.pem")} #{File.join(tmpdir, "webui.pem")}")
  Chef::CouchDB.new(Chef::Config[:couchdb_url], "chef_integration").create_db
  c = Chef::REST.new(Chef::Config[:couchdb_url], nil, nil)
  c.post_rest("_replicate", { 
    "source" => "#{Chef::Config[:couchdb_url]}/chef_integration_safe",
    "target" => "#{Chef::Config[:couchdb_url]}/chef_integration" 
  })
end

After do
  r = Chef::REST.new(Chef::Config[:couchdb_url], nil, nil)
  r.delete_rest("chef_integration/")
  s = Chef::Solr.new
  s.solr_delete_by_query("*:*")
  s.solr_commit
  gemserver.shutdown
  gemserver_thread && gemserver_thread.join
  
  cleanup_files.each do |file|
    system("rm #{file}")
  end
  cleanup_dirs.each do |dir|
    system("rm -rf #{dir}")
  end
  cj = Chef::REST::CookieJar.instance
  cj.keys.each do |key|
    cj.delete(key)
  end
  data_tmp = File.join(File.dirname(__FILE__), "..", "data", "tmp")
  system("rm -rf #{data_tmp}/*")
  system("rm -rf #{tmpdir}")
end

