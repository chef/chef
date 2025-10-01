#
# Author:: Christopher Webber (<cwebber@chef.io>)
# Copyright:: Copyright (c) Chef Software Inc.
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

require_relative "../knife"

class Chef
  class Knife
    class SupermarketDownload < Knife

      banner "knife supermarket download COOKBOOK [VERSION] (options)"
      category "supermarket"

      deps do
        require "fileutils" unless defined?(FileUtils)
      end

      option :file,
        short: "-f FILE",
        long: "--file FILE",
        description: "The filename to write to."

      option :force,
        long: "--force",
        description: "Force download deprecated version."

      option :supermarket_site,
        short: "-m SUPERMARKET_SITE",
        long: "--supermarket-site SUPERMARKET_SITE",
        description: "The URL of the Supermarket site.",
        default: "https://supermarket.chef.io"

      def run
        if current_cookbook_deprecated?
          message = "DEPRECATION: This cookbook has been deprecated. "
          replacement = replacement_cookbook
          if !replacement.to_s.strip.empty?
            message << "It has been replaced by #{replacement}."
          else
            message << "No replacement has been defined."
          end
          ui.warn message

          unless config[:force]
            ui.warn "Use --force to force download deprecated cookbook."
            return
          end
        end

        download_cookbook
      end

      def version
        @version = desired_cookbook_data["version"]
      end

      private

      def cookbooks_api_url
        "#{config[:supermarket_site]}/api/v1/cookbooks"
      end

      def current_cookbook_data
        @current_cookbook_data ||= noauth_rest.get "#{cookbooks_api_url}/#{@name_args[0]}"
      end

      def current_cookbook_deprecated?
        current_cookbook_data["deprecated"] == true
      end

      def desired_cookbook_data
        @desired_cookbook_data ||= begin
                                     uri = if @name_args.length == 1
                                             current_cookbook_data["latest_version"]
                                           else
                                             specific_cookbook_version_url
                                           end

                                     noauth_rest.get uri
                                   end
      end

      def download_cookbook
        ui.info "Downloading #{@name_args[0]} from Supermarket at version #{version} to #{download_location}"
        tf = noauth_rest.streaming_request(desired_cookbook_data["file"])

        ::FileUtils.cp tf.path, download_location
        ui.info "Cookbook saved: #{download_location}"
      end

      def download_location
        config[:file] ||= File.join Dir.pwd, "#{@name_args[0]}-#{version}.tar.gz"
        config[:file]
      end

      def replacement_cookbook
        File.basename(current_cookbook_data["replacement"] || "")
      end

      def specific_cookbook_version_url
        "#{cookbooks_api_url}/#{@name_args[0]}/versions/#{@name_args[1].tr(".", "_")}"
      end
    end
  end
end
