#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2008 Opscode, Inc.
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

require 'chef/config'
require 'chef/log'
require 'chef/mixin/command'
require 'chef/resource/link'
require 'chef/provider'

class Chef
  class Provider
    class Link < Chef::Provider
      include Chef::Mixin::Command
      
      def load_current_resource
        @current_resource = Chef::Resource::Link.new(@new_resource.name)
        @current_resource.target_file(@new_resource.target_file)
        @current_resource.link_type(@new_resource.link_type)
        if @new_resource.link_type == :symbolic          
          if ::File.exists?(@current_resource.target_file) && ::File.symlink?(@current_resource.target_file)
            @current_resource.source_file(
              ::File.expand_path(::File.readlink(@current_resource.target_file))
            )
          else
            @current_resource.source_file("")
          end
        elsif @new_resource.link_type == :hard
          if ::File.exists?(@current_resource.target_file) && ::File.exists?(@new_resource.source_file)
            if ::File.stat(@current_resource.target_file).ino == ::File.stat(@new_resource.source_file).ino
              @current_resource.source_file(@new_resource.source_file)
            else
              @current_resource.source_file("")
            end
          else
            @current_resource.source_file("")
          end
        end
        @current_resource
      end      
      
      def action_create
        if @current_resource.source_file != @new_resource.source_file
          Chef::Log.info("Creating a #{@new_resource.link_type} link from #{@new_resource.source_file} -> #{@new_resource.target_file} for #{@new_resource}")
          if @new_resource.link_type == :symbolic
            run_command(
              :command => "ln -nfs #{@new_resource.source_file} #{@new_resource.target_file}"
            )
          elsif @new_resource.link_type == :hard
            ::File.link(@new_resource.source_file, @new_resource.target_file)
          end
          @new_resource.updated = true
        end
      end
      
      def action_delete
        if ::File.exists?(@new_resource.target_file) && ::File.writable?(@new_resource.target_file)
          Chef::Log.info("Deleting #{@new_resource} at #{@new_resource.target_file}")
          ::File.delete(@new_resource.target_file)
          @new_resource.updated = true
        else
          raise "Cannot delete #{@new_resource} at #{@new_resource_path}!"
        end
      end
    end
  end
end