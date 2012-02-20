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

      attr_reader :version

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
        current = noauth_rest.get_rest("http://cookbooks.opscode.com/api/v1/cookbooks/#{name_args[0]}")
        if current["deprecated"] == true
          replacement = File.basename(current["replacement"])
          ui.warn("DEPRECATION: This cookbook has been deprecated. It has been replaced by #{replacement}.")
          unless config[:force]
            ui.warn("Use --force to force download deprecated cookbook.")
            return
          end
        end
        cookbook_data = if @name_args.length == 1
                          noauth_rest.get_rest(current["latest_version"])
                        else
                          noauth_rest.get_rest("http://cookbooks.opscode.com/api/v1/cookbooks/#{name_args[0]}/versions/#{name_args[1].gsub('.', '_')}")
                        end

        @version = cookbook_data['version']
        unless config[:file]
          config[:file] = File.join(Dir.pwd, "#{@name_args[0]}-#{cookbook_data['version']}.tar.gz")
        end
        ui.info("Downloading #{@name_args[0]} from the cookbooks site at version #{cookbook_data['version']} to #{config[:file]}")
        noauth_rest.sign_on_redirect = false
        tf = noauth_rest.get_rest(cookbook_data["file"], true)

        FileUtils.cp(tf.path, config[:file])
        ui.info("Cookbook saved: #{config[:file]}")
      end

    end
  end
end
