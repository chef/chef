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
        branch_name = "chef-vendor-#{name_args[0]}"

        download = Chef::Knife::CookbookSiteDownload.new
        download.config[:file] = upstream_file 
        download.name_args = name_args
        download.run

        Chef::Log.info("Checking out the master branch.")
        Chef::Mixin::Command.run_command(:command => "git checkout master", :cwd => vendor_path) 
        Chef::Log.info("Checking the status of the vendor branch.")
        status, branch_output, branch_error = Chef::Mixin::Command.output_of_command("git branch --no-color | grep #{branch_name}", :cwd => vendor_path) 
        if branch_output =~ /#{branch_name}$/m
          Chef::Log.info("Vendor branch found.")
          Chef::Mixin::Command.run_command(:command => "git checkout #{branch_name}", :cwd => vendor_path)
        else
          Chef::Log.info("Creating vendor branch.")
          Chef::Mixin::Command.run_command(:command => "git checkout -b #{branch_name}", :cwd => vendor_path)
        end
        Chef::Log.info("Removing pre-existing version.")
        Chef::Mixin::Command.run_command(:command => "rm -r #{cookbook_path}", :cwd => vendor_path) if File.directory?(cookbook_path)
        Chef::Log.info("Uncompressing #{name_args[0]} version #{download.version}.")
        Chef::Mixin::Command.run_command(:command => "tar zxvf #{upstream_file}", :cwd => vendor_path)
        Chef::Mixin::Command.run_command(:command => "rm #{upstream_file}", :cwd => vendor_path)
        Chef::Log.info("Adding changes.")
        Chef::Mixin::Command.run_command(:command => "git add #{name_args[0]}", :cwd => vendor_path)
        Chef::Log.info("Committing changes.")
        begin
          Chef::Mixin::Command.run_command(:command => "git commit -a -m 'Import #{name_args[0]} version #{download.version}'", :cwd => vendor_path)
        rescue Chef::Exceptions::Exec => e
          Chef::Log.warn("Checking out the master branch.")
          Chef::Log.warn("No changes from current vendor #{name_args[0]}, aborting!")
          Chef::Mixin::Command.run_command(:command => "git checkout master", :cwd => vendor_path) 
          exit 1
        end
        Chef::Log.info("Creating tag chef-vendor-#{name_args[0]}-#{download.version}.")
        Chef::Mixin::Command.run_command(:command => "git tag -f chef-vendor-#{name_args[0]}-#{download.version}", :cwd => vendor_path)
        Chef::Log.info("Checking out the master branch.")
        Chef::Mixin::Command.run_command(:command => "git checkout master", :cwd => vendor_path)
        Chef::Log.info("Merging changes from #{name_args[0]} version #{download.version}.")

        Dir.chdir(vendor_path) do
          if system("git merge #{branch_name}")
            Chef::Log.info("Cookbook #{name_args[0]} version #{download.version} successfully vendored!")
            exit 0
          else
            Chef::Log.error("You have merge conflicts - please resolve manually!")
            Chef::Log.error("(Hint: cd #{vendor_path}; git status)") 
            exit 1
          end
        end
      end

    end
  end
end






