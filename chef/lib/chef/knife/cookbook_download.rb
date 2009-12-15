#
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
    class CookbookDownload < Knife

      banner "Sub-Command: cookbook download COOKBOOK (options)"

      option :file,
       :short => "-f FILE",
       :long => "--file FILE",
       :description => "The filename to write to"

      def run 
        cookbook = rest.get_rest("cookbooks/#{@name_args[0]}")
        version = cookbook["metadata"]["version"] 
        Chef::Log.info("Downloading #{@name_args[0]} cookbook version #{version}")
        rest.sign_on_redirect = false
        tf = rest.get_rest("cookbooks/#{@name_args[0]}/_content", true)
        rest.sign_on_redirect = true 
        unless config[:file]
          if version
            config[:file] = File.join(Dir.pwd, "#{@name_args[0]}-#{version}.tar.gz")
          else
            config[:file] = File.join(Dir.pwd, "#{@name_args[0]}.tar.gz")
          end
        end
        FileUtils.cp(tf.path, config[:file])
        Chef::Log.info("Cookbook saved: #{config[:file]}")
      end

    end
  end
end





