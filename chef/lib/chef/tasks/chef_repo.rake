#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2008, 2009 Opscode, Inc.
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

require 'rubygems'
require 'json'
require 'chef'
require 'chef/role'
require 'chef/cookbook/metadata'
require 'tempfile'
require 'rake'

# Allow REMOTE options to be overridden on the command line
REMOTE_HOST = ENV["REMOTE_HOST"] if ENV["REMOTE_HOST"] != nil
REMOTE_SUDO = ENV["REMOTE_SUDO"] if ENV["REMOTE_SUDO"] != nil
if defined? REMOTE_HOST
  REMOTE_PATH_PREFIX = "#{REMOTE_HOST}:"
  REMOTE_EXEC_PREFIX = "ssh #{REMOTE_HOST}"
  REMOTE_EXEC_PREFIX += " sudo" if defined? REMOTE_SUDO
  LOCAL_EXEC_PREFIX = ""
else
  REMOTE_PATH_PREFIX = ""
  REMOTE_EXEC_PREFIX = ""
  LOCAL_EXEC_PREFIX = "sudo"
end

desc "Update your repository from source control"
task :update do
  puts "** Updating your repository"

  case $vcs
  when :svn
    sh %{svn up}
  when :git
    pull = false
    IO.foreach(File.join(TOPDIR, ".git", "config")) do |line|
      pull = true if line =~ /\[remote "origin"\]/
    end
    if pull
      sh %{git pull} 
    else
      puts "* Skipping git pull, no origin specified"
    end
  else
    puts "* No SCM configured, skipping update"
  end
end

desc "Test your cookbooks for syntax errors"
task :test_recipes do
  puts "** Testing your cookbooks for syntax errors"

  if File.exists?(TEST_CACHE)
    cache = JSON.load(open(TEST_CACHE).read)
    trap("INT") { puts "INT received, flushing test cache"; write_cache(cache) }
  else
    cache = {}
  end

  recipes = ["*cookbooks"].map { |folder|
    Dir[File.join(TOPDIR, folder, "**", "*.rb")]
  }.flatten

  recipes.each do |recipe|
    print "Testing recipe #{recipe}: "

    recipe_mtime = File.stat(recipe).mtime.to_s
    if cache.has_key?(recipe)
      if cache[recipe]["mtime"] == recipe_mtime 
         puts "No modification since last test."
         next
      end
    else
      cache[recipe] = {}
    end


    sh %{ruby -c #{recipe}} do |ok, res|
      if ok
        cache[recipe]["mtime"] = recipe_mtime
      else
        write_cache(cache)
        raise "Syntax error in #{recipe}"
      end
    end
  end

  write_cache(cache)
end

desc "Test your templates for syntax errors"
task :test_templates do
  puts "** Testing your cookbooks for syntax errors"

  if File.exists?(TEST_CACHE)
    cache = JSON.load(open(TEST_CACHE).read)
    trap("INT") { puts "INT received, flushing test cache"; write_cache(cache) }
  else
    cache = {}
  end

  templates = ["*cookbooks"].map { |folder|
    Dir[File.join(TOPDIR, folder, "**", "*.erb")]
  }.flatten

  templates.each do |template|
    print "Testing template #{template}: "

    template_mtime = File.stat(template).mtime.to_s
    if cache.has_key?(template)
      if cache[template]["mtime"] == template_mtime 
         puts "No change since last test."
         next
      end
    else
      cache[template] = {}
    end

    sh %{erubis -x #{template} | ruby -c} do |ok, res|
      if ok
        cache[template]["mtime"] = template_mtime
      else
        write_cache(cache)
        raise "Syntax error in #{template}"
      end
    end

  end

  write_cache(cache)
end

desc "Test your cookbooks for syntax errors"
task :test => [ :test_recipes , :test_templates ]

def write_cache(cache)
  File.open(TEST_CACHE, "w") { |f| JSON.dump(cache, f) }
end

desc "Install the latest copy of the repository on this Chef Server"
task :install => [ :update, :test, :metadata, :roles ] do
  puts "** Installing your cookbooks"  
  directories = [ 
    COOKBOOK_PATH,
    SITE_COOKBOOK_PATH,
    CHEF_CONFIG_PATH
  ]
  puts "* Creating Directories"
  directories.each do |dir|
    sh "#{LOCAL_EXEC_PREFIX} #{REMOTE_EXEC_PREFIX} mkdir -p #{dir}"
    sh "#{LOCAL_EXEC_PREFIX} #{REMOTE_EXEC_PREFIX} chown root #{dir}"
  end
  puts "* Installing new Cookbooks"
  sh "#{LOCAL_EXEC_PREFIX} rsync -rlt --delete --exclude '.svn' --exclude '.git*' cookbooks/ #{REMOTE_PATH_PREFIX}#{COOKBOOK_PATH}"
  puts "* Installing new Site Cookbooks"
  sh "#{LOCAL_EXEC_PREFIX} rsync -rlt --delete --exclude '.svn' --exclude '.git*' site-cookbooks/ #{REMOTE_PATH_PREFIX}#{SITE_COOKBOOK_PATH}"
  puts "* Installing new Node Roles"
  sh "#{LOCAL_EXEC_PREFIX} rsync -rlt --delete --exclude '.svn' --exclude '.git*' roles/ #{REMOTE_PATH_PREFIX}#{ROLE_PATH}"
  
  if File.exists?(File.join(TOPDIR, "config", "server.rb"))
    puts "* Installing new Chef Server Config"
    sh "#{LOCAL_EXEC_PREFIX} rsync -rlt --delete --exclude '.svn' --exclude '.git*' config/server.rb #{REMOTE_PATH_PREFIX}#{CHEF_SERVER_CONFIG}"
  end
  if File.exists?(File.join(TOPDIR, "config", "client.rb"))
    puts "* Installing new Chef Client Config"
    sh "#{LOCAL_EXEC_PREFIX} rsync -rlt --delete --exclude '.svn' --exclude '.git*' config/client.rb #{REMOTE_PATH_PREFIX}#{CHEF_CLIENT_CONFIG}"
  end
end

desc "By default, run rake test"
task :default => [ :test ]

desc "Create a new cookbook (with COOKBOOK=name, optional CB_PREFIX=site-)"
task :new_cookbook do
  create_cookbook(File.join(TOPDIR, "#{ENV["CB_PREFIX"]}cookbooks"))
  create_readme(File.join(TOPDIR, "#{ENV["CB_PREFIX"]}cookbooks"))
  create_metadata(File.join(TOPDIR, "#{ENV["CB_PREFIX"]}cookbooks"))
end

def create_cookbook(dir)
  raise "Must provide a COOKBOOK=" unless ENV["COOKBOOK"]
  puts "** Creating cookbook #{ENV["COOKBOOK"]}"
  sh "mkdir -p #{File.join(dir, ENV["COOKBOOK"], "attributes")}" 
  sh "mkdir -p #{File.join(dir, ENV["COOKBOOK"], "recipes")}" 
  sh "mkdir -p #{File.join(dir, ENV["COOKBOOK"], "definitions")}" 
  sh "mkdir -p #{File.join(dir, ENV["COOKBOOK"], "libraries")}" 
  sh "mkdir -p #{File.join(dir, ENV["COOKBOOK"], "resources")}" 
  sh "mkdir -p #{File.join(dir, ENV["COOKBOOK"], "providers")}" 
  sh "mkdir -p #{File.join(dir, ENV["COOKBOOK"], "files", "default")}" 
  sh "mkdir -p #{File.join(dir, ENV["COOKBOOK"], "templates", "default")}" 
  unless File.exists?(File.join(dir, ENV["COOKBOOK"], "recipes", "default.rb"))
    open(File.join(dir, ENV["COOKBOOK"], "recipes", "default.rb"), "w") do |file|
      file.puts <<-EOH
#
# Cookbook Name:: #{ENV["COOKBOOK"]}
# Recipe:: default
#
# Copyright #{Time.now.year}, #{COMPANY_NAME}
#
EOH
      case NEW_COOKBOOK_LICENSE
      when :apachev2
        file.puts <<-EOH
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
EOH
      when :none
        file.puts <<-EOH
# All rights reserved - Do Not Redistribute
#
EOH
      end
    end
  end
end

def create_readme(dir)
  raise "Must provide a COOKBOOK=" unless ENV["COOKBOOK"]
  puts "** Creating README for cookbook: #{ENV["COOKBOOK"]}"
  unless File.exists?(File.join(dir, ENV["COOKBOOK"], "README.rdoc"))
    open(File.join(dir, ENV["COOKBOOK"], "README.rdoc"), "w") do |file|
      file.puts <<-EOH
= DESCRIPTION:

= REQUIREMENTS:

= ATTRIBUTES: 

= USAGE:

EOH
    end
  end
end

def create_metadata(dir)
  raise "Must provide a COOKBOOK=" unless ENV["COOKBOOK"]
  puts "** Creating metadata for cookbook: #{ENV["COOKBOOK"]}"
  
  case NEW_COOKBOOK_LICENSE
  when :apachev2
    license = "Apache 2.0"
  when :none
    license = "All rights reserved"
  end

  unless File.exists?(File.join(dir, ENV["COOKBOOK"], "metadata.rb"))
    open(File.join(dir, ENV["COOKBOOK"], "metadata.rb"), "w") do |file|
      if File.exists?(File.join(dir, ENV["COOKBOOK"], 'README.rdoc'))
        long_description = "long_description IO.read(File.join(File.dirname(__FILE__), 'README.rdoc'))"
      end
      file.puts <<-EOH
maintainer       "#{COMPANY_NAME}"
maintainer_email "#{SSL_EMAIL_ADDRESS}"
license          "#{license}"
description      "Installs/Configures #{ENV["COOKBOOK"]}"
#{long_description}
version          "0.1"
EOH
    end
  end
end

desc "Create a new self-signed SSL certificate for FQDN=foo.example.com"
task :ssl_cert do
  $expect_verbose = true
  fqdn = ENV["FQDN"]
  fqdn =~ /^(.+?)\.(.+)$/
  hostname = $1
  domain = $2
  keyfile = fqdn.gsub("*", "wildcard")
  raise "Must provide FQDN!" unless fqdn && hostname && domain
  puts "** Creating self signed SSL Certificate for #{fqdn}"
  sh("(cd #{CADIR} && openssl genrsa 2048 > #{keyfile}.key)")
  sh("(cd #{CADIR} && chmod 644 #{keyfile}.key)")
  puts "* Generating Self Signed Certificate Request"
  tf = Tempfile.new("#{keyfile}.ssl-conf")
  ssl_config = <<EOH
[ req ]
distinguished_name = req_distinguished_name
prompt = no

[ req_distinguished_name ]
C                      = #{SSL_COUNTRY_NAME}
ST                     = #{SSL_STATE_NAME}
L                      = #{SSL_LOCALITY_NAME}
O                      = #{COMPANY_NAME}
OU                     = #{SSL_ORGANIZATIONAL_UNIT_NAME}
CN                     = #{fqdn}
emailAddress           = #{SSL_EMAIL_ADDRESS}
EOH
  tf.puts(ssl_config)
  tf.close
  sh("(cd #{CADIR} && openssl req -config '#{tf.path}' -new -x509 -nodes -sha1 -days 3650 -key #{keyfile}.key > #{keyfile}.crt)")
  sh("(cd #{CADIR} && openssl x509 -noout -fingerprint -text < #{keyfile}.crt > #{keyfile}.info)")
  sh("(cd #{CADIR} && cat #{keyfile}.crt #{keyfile}.key > #{keyfile}.pem)")
  sh("(cd #{CADIR} && chmod 644 #{keyfile}.pem)")
end

@cookbook_loader = nil
rule(%r{\b(?:site-)?cookbooks/[^/]+/metadata\.json\Z} => [ proc { |task_name| task_name.sub(/\.[^.]+$/, '.rb') } ]) do |t|
  Chef::Config[:cookbook_path] = [ File.join(TOPDIR, 'cookbooks'), File.join(TOPDIR, 'site-cookbooks') ]
  @cookbook_loader ||= Chef::CookbookLoader.new
  cookbook = @cookbook_loader[t.source[%r{\bcookbooks/([^/]+)/metadata\.rb\Z}, 1]]
  cook_meta = Chef::Cookbook::Metadata.new(cookbook)
  puts "Generating metadata for #{cookbook.name}"
  cook_meta.from_file(t.source)
  File.open(t.name, "w") do |f|
    f.write(JSON.pretty_generate(cook_meta))
  end
end

desc "Build cookbook metadata.json from metadata.rb"
task :metadata => FileList[File.join(TOPDIR, '*cookbooks', ENV['COOKBOOK'] || '*', 'metadata.rb')].pathmap('%X.json')

rule(%r{\broles/\S+\.json\Z} => [ proc { |task_name| task_name.sub(/\.[^.]+$/, '.rb') } ]) do |t|
  Chef::Config[:role_path] = File.join(TOPDIR, 'roles')
  short_name = File.basename(t.source, '.rb')
  puts "Generating role JSON for #{short_name}"
  role = Chef::Role.new
  role.name(short_name)
  role.from_file(t.source)
  File.open(t.name, "w") do |f|
    f.write(JSON.pretty_generate(role))
  end
end

desc "Build roles from roles/role_name.json from role_name.rb"
task :roles  => FileList[File.join(TOPDIR, 'roles', '**', '*.rb')].pathmap('%X.json')

desc "Upload all cookbooks"
task :upload_cookbooks => [ :metadata ]
task :upload_cookbooks do
  Chef::Config[:cookbook_path] = [ File.join(TOPDIR, 'cookbooks'), File.join(TOPDIR, 'site-cookbooks') ]
  cl = Chef::CookbookLoader.new
  cl.each do |cookbook|
    cook_meta = Chef::Cookbook::Metadata.new(cookbook)
    upload_single_cookbook(cookbook.name.to_s, cook_meta.version)
    puts "* Uploaded #{cookbook.name.to_s}"
  end
end

desc "Upload a single cookbook"
task :upload_cookbook => [ :metadata ]
task :upload_cookbook, :cookbook do |t, args|
  upload_single_cookbook(args.cookbook)
  puts "* Uploaded #{args.cookbook}"
end

def upload_single_cookbook(cookbook_name, version=nil)
  require 'chef/streaming_cookbook_uploader'
  Chef::Log.level = :error
  Mixlib::Authentication::Log.logger = Chef::Log.logger
  raise ArgumentError, "OPSCODE_KEY must be set to your API Key" unless ENV.has_key?("OPSCODE_KEY")
  raise ArgumentError, "OPSCODE_USER must be set to your Username" unless ENV.has_key?("OPSCODE_USER")

  Chef::Config.from_file("/etc/chef/client.rb")

  tarball_name = "#{cookbook_name}.tar.gz"
  temp_dir = File.join(Dir.tmpdir, "chef-upload-cookbooks")
  temp_cookbook_dir = File.join(temp_dir, cookbook_name)
  FileUtils.mkdir(temp_dir) 
  FileUtils.mkdir(temp_cookbook_dir)
 
  child_folders = [ "cookbooks/#{cookbook_name}", "site-cookbooks/#{cookbook_name}" ]
  child_folders.each do |folder|
    file_path = File.join(TOPDIR, folder, ".")
    FileUtils.cp_r(file_path, temp_cookbook_dir) if File.directory?(file_path)
  end 
      
  system("tar", "-C", temp_dir, "-czf", File.join(temp_dir, tarball_name), "./#{cookbook_name}")

  r = Chef::REST.new(Chef::Config[:chef_server_url], ENV['OPSCODE_USER'], ENV['OPSCODE_KEY'])
  begin
    cb = r.get_rest("cookbooks/#{cookbook_name}")
    cookbook_uploaded = true
  rescue Net::HTTPServerException
    cookbook_uploaded = false
  end
  puts "* Uploading #{cookbook_name} (#{cookbook_uploaded ? 'new version' : 'first time'})"
  if cookbook_uploaded
    Chef::StreamingCookbookUploader.put("#{Chef::Config[:chef_server_url]}/cookbooks/#{cookbook_name}/_content", ENV["OPSCODE_USER"], ENV["OPSCODE_KEY"], {:file => File.new(File.join(temp_dir, tarball_name)), :name => cookbook_name})
  else
    Chef::StreamingCookbookUploader.post("#{Chef::Config[:chef_server_url]}/cookbooks", ENV["OPSCODE_USER"], ENV["OPSCODE_KEY"], {:file => File.new(File.join(temp_dir, tarball_name)), :name => cookbook_name})
  end

  #delete temp files (e.g. /tmp/cookbooks and /tmp/cookbooks.tgz)
  FileUtils.rm_rf temp_dir
end

