#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2010 Opscode, Inc.
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
    class CookbookSiteVendor < Knife

      banner "Sub-Command: cookbook site vendor COOKBOOK [VERSION] (options)"

      def run
        vendor_path = File.join(Chef::Config[:cookbook_path].first)
        cookbook_path = File.join(vendor_path, name_args[0])
        upstream_file = File.join(vendor_path, "#{name_args[0]}.tar.gz")
        branch_name = "#{name_args[0]}-chef-upstream"

        download = Chef::Knife::CookbookSiteDownload.new
        download.config[:file] = upstream_file 
        download.name_args = name_args
        download.run

        Dir.chdir(vendor_path) do 
          Chef::Log.info("Checking out the master branch")
          system("git checkout master")
          branch_output = `git branch --no-color | grep #{branch_name}`
          if branch_output =~ /#{branch_name}$/m
            system("git checkout #{branch_name}")
          else
            system("git checkout -b #{branch_name}")
          end
          system("rm -r #{cookbook_path}")
          system("tar zxvf #{upstream_file}")
          system("rm #{upstream_file}")
          system("git add #{name_args[0]}")
          system("git commit -a -m 'Import #{name_args[0]} version #{download.version}'")
          system("git tag -f #{name_args[0]}-#{download.version}")
          system("git checkout master")
          system("git merge #{branch_name}")
        end
        Chef::Log.info("Cookbook #{name_args[0]} version #{download.version} successfully vendored")
      end

    end
  end
end






