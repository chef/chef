#
# Author:: Daniel DeLeo (<dan@chef.io>)
# Copyright:: Copyright 2011-2016, Chef Software, Inc.
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

require "chef/run_list"
require "chef/util/path_helper"
require "pathname"
require "chef/dist"

class Chef
  class Knife
    module Core
      # Instances of BootstrapContext are the context objects (i.e., +self+) for
      # bootstrap templates. For backwards compatibility, they +must+ set the
      # following instance variables:
      # * @config   - a hash of knife's config values
      # * @run_list - the run list for the node to boostrap
      #
      class BootstrapContext

        attr_accessor :client_pem

        def initialize(config, run_list, chef_config, secret = nil)
          @config       = config
          @run_list     = run_list
          @chef_config  = chef_config
          @secret       = secret
        end

        def bootstrap_environment
          @config[:environment]
        end

        def validation_key
          if @chef_config[:validation_key] &&
              File.exist?(File.expand_path(@chef_config[:validation_key]))
            IO.read(File.expand_path(@chef_config[:validation_key]))
          else
            false
          end
        end

        def client_d
          @client_d ||= client_d_content
        end

        def encrypted_data_bag_secret
          @secret
        end

        # Contains commands and content, see trusted_certs_content
        # @todo Rename to trusted_certs_script
        def trusted_certs
          @trusted_certs ||= trusted_certs_content
        end

        def get_log_location
          if !(@chef_config[:config_log_location].class == IO ) && (@chef_config[:config_log_location].nil? || @chef_config[:config_log_location].to_s.empty?)
            "STDOUT"
          elsif @chef_config[:config_log_location].equal?(:win_evt)
            raise "The value :win_evt is not supported for config_log_location on Linux Platforms \n"
          elsif @chef_config[:config_log_location].equal?(:syslog)
            ":syslog"
          elsif @chef_config[:config_log_location].equal?(STDOUT)
            "STDOUT"
          elsif @chef_config[:config_log_location].equal?(STDERR)
            "STDERR"
          elsif @chef_config[:config_log_location]
            %Q{"#{@chef_config[:config_log_location]}"}
          else
            "STDOUT"
          end
        end

        def config_content
          client_rb = <<~CONFIG
            chef_server_url  "#{@chef_config[:chef_server_url]}"
            validation_client_name "#{@chef_config[:validation_client_name]}"
          CONFIG

          if !(@chef_config[:config_log_level].nil? || @chef_config[:config_log_level].empty?)
            client_rb << %Q{log_level   :#{@chef_config[:config_log_level]}\n}
          end

          client_rb << "log_location   #{get_log_location}\n"

          if @config[:chef_node_name]
            client_rb << %Q{node_name "#{@config[:chef_node_name]}"\n}
          else
            client_rb << "# Using default node name (fqdn)\n"
          end

          # We configure :verify_api_cert only when it's overridden on the CLI
          # or when specified in the knife config.
          if !@config[:node_verify_api_cert].nil? || knife_config.key?(:verify_api_cert)
            value = @config[:node_verify_api_cert].nil? ? knife_config[:verify_api_cert] : @config[:node_verify_api_cert]
            client_rb << %Q{verify_api_cert #{value}\n}
          end

          # We configure :ssl_verify_mode only when it's overridden on the CLI
          # or when specified in the knife config.
          if @config[:node_ssl_verify_mode] || knife_config.key?(:ssl_verify_mode)
            value = case @config[:node_ssl_verify_mode]
                    when "peer"
                      :verify_peer
                    when "none"
                      :verify_none
                    when nil
                      knife_config[:ssl_verify_mode]
                    else
                      nil
                    end

            if value
              client_rb << %Q{ssl_verify_mode :#{value}\n}
            end
          end

          if @config[:ssl_verify_mode]
            client_rb << %Q{ssl_verify_mode :#{knife_config[:ssl_verify_mode]}\n}
          end

          if knife_config[:bootstrap_proxy]
            client_rb << %Q{http_proxy        "#{knife_config[:bootstrap_proxy]}"\n}
            client_rb << %Q{https_proxy       "#{knife_config[:bootstrap_proxy]}"\n}
          end

          if knife_config[:bootstrap_proxy_user]
            client_rb << %Q{http_proxy_user   "#{knife_config[:bootstrap_proxy_user]}"\n}
            client_rb << %Q{https_proxy_user  "#{knife_config[:bootstrap_proxy_user]}"\n}
          end

          if knife_config[:bootstrap_proxy_pass]
            client_rb << %Q{http_proxy_pass   "#{knife_config[:bootstrap_proxy_pass]}"\n}
            client_rb << %Q{https_proxy_pass  "#{knife_config[:bootstrap_proxy_pass]}"\n}
          end

          if knife_config[:bootstrap_no_proxy]
            client_rb << %Q{no_proxy       "#{knife_config[:bootstrap_no_proxy]}"\n}
          end

          if encrypted_data_bag_secret
            client_rb << %Q{encrypted_data_bag_secret "/etc/chef/encrypted_data_bag_secret"\n}
          end

          unless trusted_certs.empty?
            client_rb << %Q{trusted_certs_dir "/etc/chef/trusted_certs"\n}
          end

          if Chef::Config[:fips]
            client_rb << "fips true\n"
          end

          client_rb
        end

        def start_chef
          # If the user doesn't have a client path configure, let bash use the PATH for what it was designed for
          client_path = @chef_config[:chef_client_path] || "#{Chef::Dist::CLIENT}"
          # We know we can hardcode CHEF_LICENSE because the user cannot get here without accepting the license locally
          s = "CHEF_LICENSE=accept #{client_path} -j /etc/chef/first-boot.json"
          if @config[:verbosity] && @config[:verbosity] >= 3
            s << " -l trace"
          elsif @config[:verbosity] && @config[:verbosity] >= 2
            s << " -l debug"
          end
          s << " -E #{bootstrap_environment}" unless bootstrap_environment.nil?
          s << " --no-color" unless @config[:color]
          s
        end

        def knife_config
          @chef_config.key?(:knife) ? @chef_config[:knife] : {}
        end

        #
        # chef version string to fetch the latest current version from omnitruck
        # If user is on X.Y.Z, bootstrap will use the latest X release
        def latest_current_chef_version_string
          chef_version_string = if knife_config[:bootstrap_version]
                                  knife_config[:bootstrap_version]
                                else
                                  Chef::VERSION.split(".").first
                                end

          "-v #{chef_version_string}"
        end

        def first_boot
          (@config[:first_boot_attributes] || {}).tap do |attributes|
            if @config[:policy_name] && @config[:policy_group]
              attributes[:policy_name] = @config[:policy_name]
              attributes[:policy_group] = @config[:policy_group]
            else
              attributes[:run_list] = @run_list
            end

            attributes.delete(:run_list) if attributes[:policy_name] && !attributes[:policy_name].empty?
            attributes.merge!(tags: @config[:tags]) if @config[:tags] && !@config[:tags].empty?
          end
        end

        private

        # Returns a string for copying the trusted certificates on the workstation to the system being bootstrapped
        # This string should contain both the commands necessary to both create the files, as well as their content
        def trusted_certs_content
          content = ""
          if @chef_config[:trusted_certs_dir]
            Dir.glob(File.join(Chef::Util::PathHelper.escape_glob_dir(@chef_config[:trusted_certs_dir]), "*.{crt,pem}")).each do |cert|
              content << "cat > /etc/chef/trusted_certs/#{File.basename(cert)} <<'EOP'\n" +
                IO.read(File.expand_path(cert)) + "\nEOP\n"
            end
          end
          content
        end

        def client_d_content
          content = ""
          if @chef_config[:client_d_dir] && File.exist?(@chef_config[:client_d_dir])
            root = Pathname(@chef_config[:client_d_dir])
            root.find do |f|
              relative = f.relative_path_from(root)
              if f != root
                file_on_node = "/etc/chef/client.d/#{relative}"
                if f.directory?
                  content << "mkdir #{file_on_node}\n"
                else
                  content << "cat > #{file_on_node} <<'EOP'\n" +
                    f.read.gsub("'", "'\\\\''") + "\nEOP\n"
                end
              end
            end
          end
          content
        end

      end
    end
  end
end
