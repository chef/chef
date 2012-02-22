# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2009 Opscode, Inc.
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
    class CookbookSiteDownload < Knife

      banner "knife cookbook site download COOKBOOK [VERSION] (options)"
      category "cookbook site"

      option :file,
        :short => "-f FILE",
        :long => "--file FILE",
        :description => "The filename to write to"

      option :force,
        :long => "--force",
        :description => "Force download deprecated version"

      def run
        if current_cookbook_deprecated?
          message = 'DEPRECATION: This cookbook has been deprecated. '
          message << "It has been replaced by #{replacement_cookbook}."
          ui.warn message

          unless config[:force]
            ui.warn 'Use --force to force download deprecated cookbook.'
            return
          end
        end

        download_cookbook
      end

      private
      def cookbooks_api_url
        'http://cookbooks.opscode.com/api/v1/cookbooks'
      end

      def current_cookbook_data
        @current_cookbook_data ||= begin
          noauth_rest.get_rest "#{cookbooks_api_url}/#{@name_args[0]}"
        end
      end

      def current_cookbook_deprecated?
        current_cookbook_data['deprecated'] == true
      end

      def desired_cookbook_data
        @desired_cookbook_data ||= begin
          uri = if @name_args.length == 1
            current_cookbook_data['latest_version']
          else
            specific_cookbook_version_url
          end

          noauth_rest.get_rest uri
        end
      end

      def download_cookbook
        ui.info "Downloading #{@name_args[0]} from the cookbooks site at version #{version} to #{download_location}"
        noauth_rest.sign_on_redirect = false
        tf = noauth_rest.get_rest desired_cookbook_data["file"], true

        FileUtils.cp tf.path, download_location
        ui.info "Cookbook saved: #{download_location}"
      end

      def download_location
        config[:file] ||= File.join Dir.pwd, "#{@name_args[0]}-#{version}.tar.gz"
        config[:file]
      end

      def replacement_cookbook
        replacement = File.basename(current_cookbook_data['replacement'])
      end

      def specific_cookbook_version_url
        "#{cookbooks_api_url}/#{@name_args[0]}/versions/#{@name_args[1].gsub('.', '_')}"
      end

      def version
        @version = desired_cookbook_data['version']
      end

    end
  end
end
