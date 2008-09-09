#
# Author:: Adam Jacob (<adam@hjksolutions.com>)
# Copyright:: Copyright (c) 2008 HJK Solutions, LLC
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

require File.join(File.dirname(__FILE__), "..", "mixin", "command")

class Chef
  class Provider
    class Package < Chef::Provider
      
      include Chef::Mixin::Command
      
      def initialize(node, new_resource)
        super(node, new_resource)
        @candidate_version = nil
      end
      
      def action_install  
        # First, select what version we should be using
        install_version = @new_resource.version
        install_version ||= @candidate_version
        
        unless install_version
          raise(Chef::Exception::Package, "No version specified, and no candidate version available!")
        end
        
        do_package = false
        # If it's not installed at all, install it
        if @current_resource.version == nil
          do_package = true
        # If we specified a version, and it's not the current version, move to the current version
        elsif @new_resource.version != nil
          if @new_resource.version != @current_resource.version
            do_package = true
          end
        end
        
        if do_package
          status = install_package(@new_resource.package_name, install_version)
          if status
            @new_resource.updated = true
            Chef::Log.info("Installed #{@new_resource} version #{install_version} successfully")
          end
        end
      end
      
      def action_upgrade
        if @current_resource.version != @candidate_version
          status = install_package(@new_resource.package_name, @candidate_version)
          if status
            @new_resource.updated = true
            Chef::Log.info("Upgraded #{@new_resource} version from #{@current_resource.version} to #{@candidate_version} successfully")
          end
        end
      end
      
      def action_remove
        if @current_resource.version != nil
          remove_package(@new_resource.package_name, @new_resource.version)
          @new_resource.updated = true
          Chef::Log.info("Removed #{@new_resource} successfully")
        end
      end
      
      def action_purge
        if @current_resource.version != nil
          purge_package(name, @new_resource.version)
          @new_resource.updated = true
          Chef::Log.info("Purged #{@new_resource} successfully")
        end
      end
      
      def install_package(name, version)
        raise Chef::Exception::UnsupportedAction, "#{self.to_s} does not support :install"
      end
      
      def upgrade_package(name, version)
        raise Chef::Exception::UnsupportedAction, "#{self.to_s} does not support :upgrade" 
      end
      
      def remove_package(name, version)
        raise Chef::Exception::UnsupportedAction, "#{self.to_s} does not support :remove" 
      end
      
      def purge_package(name, version)
        raise Chef::Exception::UnsupportedAction, "#{self.to_s} does not support :purge" 
      end
      
    end
  end
end
