#
# Author:: Adam Jacob (<adam@chef.io>)
# Copyright:: Copyright 2009-2017, Chef Software Inc.
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

require "chef/knife"

class Chef
  class Knife
    class Configure < Knife
      attr_reader :chef_server, :new_client_name, :admin_client_name, :admin_client_key
      attr_reader :chef_repo, :new_client_key, :validation_client_name, :validation_key

      deps do
        require "ohai"
        Chef::Knife::ClientCreate.load_deps
        Chef::Knife::UserCreate.load_deps
      end

      banner "knife configure (options)"

      option :repository,
        :short => "-r REPO",
        :long => "--repository REPO",
        :description => "The path to the chef-repo"

      option :initial,
        :short => "-i",
        :long => "--initial",
        :boolean => true,
        :description => "Use to create a API client, typically an administrator client on a freshly-installed server"

      option :admin_client_name,
        :long => "--admin-client-name NAME",
        :description => "The name of the client, typically the name of the admin client"

      option :admin_client_key,
        :long => "--admin-client-key PATH",
        :description => "The path to the private key used by the client, typically a file named admin.pem"

      option :validation_client_name,
        :long => "--validation-client-name NAME",
        :description => "The name of the validation client, typically a client named chef-validator"

      option :validation_key,
        :long => "--validation-key PATH",
        :description => "The path to the validation key used by the client, typically a file named validation.pem"

      def configure_chef
        # We are just faking out the system so that you can do this without a key specified
        Chef::Config[:node_name] = "woot"
        super
        Chef::Config[:node_name] = nil
      end

      def run
        ask_user_for_config_path

        FileUtils.mkdir_p(chef_config_path)

        ask_user_for_config

        ::File.open(config[:config_file], "w") do |f|
          f.puts <<-EOH
node_name                '#{new_client_name}'
client_key               '#{new_client_key}'
validation_client_name   '#{validation_client_name}'
validation_key           '#{validation_key}'
chef_server_url          '#{chef_server}'
syntax_check_cache_path  '#{File.join(chef_config_path, "syntax_check_cache")}'
EOH
          unless chef_repo.empty?
            f.puts "cookbook_path [ '#{chef_repo}/cookbooks' ]"
          end
        end

        if config[:initial]
          ui.msg("Creating initial API user...")
          Chef::Config[:chef_server_url] = chef_server
          Chef::Config[:node_name] = admin_client_name
          Chef::Config[:client_key] = admin_client_key
          user_create = Chef::Knife::UserCreate.new
          user_create.name_args = [ new_client_name ]
          user_create.config[:user_password] = config[:user_password] ||
            ui.ask("Please enter a password for the new user: ") { |q| q.echo = false }
          user_create.config[:admin] = true
          user_create.config[:file] = new_client_key
          user_create.config[:yes] = true
          user_create.config[:disable_editing] = true
          user_create.run
        else
          ui.msg("*****")
          ui.msg("")
          ui.msg("You must place your client key in:")
          ui.msg("  #{new_client_key}")
          ui.msg("Before running commands with Knife")
          ui.msg("")
          ui.msg("*****")
          ui.msg("")
          ui.msg("You must place your validation key in:")
          ui.msg("  #{validation_key}")
          ui.msg("Before generating instance data with Knife")
          ui.msg("")
          ui.msg("*****")
        end

        ui.msg("Configuration file written to #{config[:config_file]}")
      end

      def ask_user_for_config_path
        config[:config_file] ||= ask_question("Where should I put the config file? ", :default => "#{Chef::Config[:user_home]}/.chef/knife.rb")
        # have to use expand path to expand the tilde character to the user's home
        config[:config_file] = File.expand_path(config[:config_file])
        if File.exists?(config[:config_file])
          confirm("Overwrite #{config[:config_file]}")
        end
      end

      def ask_user_for_config
        server_name = guess_servername
        @chef_server = config[:chef_server_url] || ask_question("Please enter the chef server URL: ", :default => "https://#{server_name}/organizations/myorg")
        if config[:initial]
          @new_client_name        = config[:node_name] || ask_question("Please enter a name for the new user: ", :default => Etc.getlogin)
          @admin_client_name      = config[:admin_client_name] || ask_question("Please enter the existing admin name: ", :default => "admin")
          @admin_client_key       = config[:admin_client_key] || ask_question("Please enter the location of the existing admin's private key: ", :default => "/etc/chef-server/admin.pem")
          @admin_client_key       = File.expand_path(@admin_client_key)
        else
          @new_client_name        = config[:node_name] || ask_question("Please enter an existing username or clientname for the API: ", :default => Etc.getlogin)
        end
        @validation_client_name = config[:validation_client_name] || ask_question("Please enter the validation clientname: ", :default => "chef-validator")
        @validation_key         = config[:validation_key] || ask_question("Please enter the location of the validation key: ", :default => "/etc/chef-server/chef-validator.pem")
        @validation_key         = File.expand_path(@validation_key)
        @chef_repo              = config[:repository] || ask_question("Please enter the path to a chef repository (or leave blank): ")

        @new_client_key = config[:client_key] || File.join(chef_config_path, "#{@new_client_name}.pem")
        @new_client_key = File.expand_path(@new_client_key)
      end

      def guess_servername
        o = Ohai::System.new
        o.load_plugins
        o.require_plugin "os"
        o.require_plugin "hostname"
        o[:fqdn] || o[:machinename] || o[:hostname] || "localhost"
      end

      def config_file
        config[:config_file]
      end

      def chef_config_path
        File.dirname(config_file)
      end
    end
  end
end
