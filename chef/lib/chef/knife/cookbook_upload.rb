#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Christopher Walters (<cw@opscode.com>)
# Copyright:: Copyright (c) 2009, 2010 Opscode, Inc.
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

require 'chef/knife'

class Chef
  class Knife
    class CookbookUpload < Knife

      deps do
        require 'chef/exceptions'
        require 'chef/cookbook_loader'
        require 'chef/cookbook_uploader'
      end

      banner "knife cookbook upload [COOKBOOKS...] (options)"

      option :cookbook_path,
        :short => "-o PATH:PATH",
        :long => "--cookbook-path PATH:PATH",
        :description => "A colon-separated path to look for cookbooks in",
        :proc => lambda { |o| o.split(":") }

      option :freeze,
        :long => '--freeze',
        :description => 'Freeze this version of the cookbook so that it cannot be overwritten',
        :boolean => true

      option :all,
        :short => "-a",
        :long => "--all",
        :description => "Upload all cookbooks, rather than just a single cookbook"

      option :force,
        :long => '--force',
        :boolean => true,
        :description => "Update cookbook versions even if they have been frozen"

      option :environment,
        :short => '-E',
        :long  => '--environment ENVIRONMENT',
        :description => "Set ENVIRONMENT's version dependency match the version you're uploading."

      def run
        config[:cookbook_path] ||= Chef::Config[:cookbook_path]

        assert_environment_valid!
        version_constraints_to_update = {}

        if config[:all]
          cookbook_repo.each do |cookbook_name, cookbook|
            cookbook.freeze_version if config[:freeze]
            upload(cookbook)
            version_constraints_to_update[cookbook_name] = cookbook.version
          end
        else
          if @name_args.empty?
            show_usage
            Chef::Log.fatal("You must specify the --all flag or at least one cookbook name")
            exit 1
          end
          @name_args.each do |cookbook_name|
            begin
              cookbook = cookbook_repo[cookbook_name]
              cookbook.freeze_version if config[:freeze]
              upload(cookbook)
              version_constraints_to_update[cookbook_name] = cookbook.version
            rescue Exceptions::CookbookNotFoundInRepo => e
              Log.error("Could not find cookbook #{cookbook_name} in your cookbook path, skipping it")
              Log.debug(e)
            end
          end
        end

        update_version_constraints(version_constraints_to_update) if config[:environment]
      end

      def cookbook_repo
        @cookbook_loader ||= begin
          Chef::Cookbook::FileVendor.on_create { |manifest| Chef::Cookbook::FileSystemFileVendor.new(manifest, config[:cookbook_path]) }
          Chef::CookbookLoader.new(config[:cookbook_path])
        end
      end

      def update_version_constraints(new_version_constraints)
        new_version_constraints.each do |cookbook_name, version|
          environment.cookbook_versions[cookbook_name] = "= #{version}"
        end
        environment.save
      end


      def environment
        @environment ||= Environment.load(config[:environment])
      end

      private

      def assert_environment_valid!
        environment
      rescue Net::HTTPServerException => e
        if e.response.code.to_s == "404"
          Log.error "The environment #{config[:environment]} does not exist on the server"
          Log.debug(e)
          exit 1
        else
          raise
        end
      end

      def upload(cookbook)
        Chef::Log.info("** #{cookbook.name} **")
        Chef::CookbookUploader.new(cookbook, config[:cookbook_path], :force => config[:force]).upload_cookbook
      rescue Net::HTTPServerException => e
        case e.response.code
        when "401"
          Log.error "Request failed due to authentication (#{e}), check your client configuration (username, key)"
          Log.debug(e)
          exit 18
        when "409"
          Log.error "Version #{cookbook.version} of cookbook #{cookbook.name} is frozen. Use --force to override."
          Log.debug(e)
        else
          raise
        end
      end

    end
  end
end
