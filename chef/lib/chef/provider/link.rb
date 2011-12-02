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
require 'chef/mixin/shell_out'
require 'chef/resource/link'
require 'chef/provider'

class Chef
  class Provider
    class Link < Chef::Provider
      include Chef::Mixin::ShellOut
      #include Chef::Mixin::Command

      def negative_complement(big)
        if big > 1073741823 # Fixnum max
          big -= (2**32) # diminished radix wrap to negative
        end
        big
      end

      private :negative_complement

      def load_current_resource
        @current_resource = Chef::Resource::Link.new(@new_resource.name)
        @current_resource.target_file(@new_resource.target_file)
        @current_resource.link_type(@new_resource.link_type)
        if @new_resource.link_type == :symbolic
          if ::File.exists?(@current_resource.target_file) && ::File.symlink?(@current_resource.target_file)
            @current_resource.to(
              ::File.expand_path(::File.readlink(@current_resource.target_file))
            )
            cstats = ::File.lstat(@current_resource.target_file)
            @current_resource.owner(cstats.uid)
            @current_resource.group(cstats.gid)
          else
            @current_resource.to("")
          end
        elsif @new_resource.link_type == :hard
          if ::File.exists?(@current_resource.target_file) && ::File.exists?(@new_resource.to)
            if ::File.stat(@current_resource.target_file).ino == ::File.stat(@new_resource.to).ino
              @current_resource.to(@new_resource.to)
            else
              @current_resource.to("")
            end
          else
            @current_resource.to("")
          end
        end
        @current_resource
      end

      def action_create
        if @current_resource.to != ::File.expand_path(@new_resource.to, @new_resource.target_file)
          if @new_resource.link_type == :symbolic
            unless (::File.symlink?(@new_resource.target_file) && ::File.readlink(@new_resource.target_file) == @new_resource.to)
              if ::File.symlink?(@new_resource.target_file) || ::File.exist?(@new_resource.target_file)
                ::File.unlink(@new_resource.target_file)
              end
              ::File.symlink(@new_resource.to,@new_resource.target_file)
              Chef::Log.debug("#{@new_resource} created #{@new_resource.link_type} link from #{@new_resource.to} -> #{@new_resource.target_file}")
              Chef::Log.info("#{@new_resource} created")
            end
          elsif @new_resource.link_type == :hard
            ::File.link(@new_resource.to, @new_resource.target_file)
            Chef::Log.debug("#{@new_resource} created #{@new_resource.link_type} link from #{@new_resource.to} -> #{@new_resource.target_file}")
            Chef::Log.info("#{@new_resource} created")
          end
          @new_resource.updated_by_last_action(true)
        end
        if @new_resource.link_type == :symbolic
          enforce_ownership_and_permissions
        end
      end

      def action_delete
        if @new_resource.link_type == :symbolic
          if ::File.symlink?(@new_resource.target_file)
            ::File.delete(@new_resource.target_file)
            Chef::Log.info("#{@new_resource} deleted")
            @new_resource.updated_by_last_action(true)
          elsif ::File.exists?(@new_resource.target_file)
            raise Chef::Exceptions::Link, "Cannot delete #{@new_resource} at #{@new_resource.target_file}! Not a symbolic link."
          end
        elsif @new_resource.link_type == :hard
          if ::File.exists?(@new_resource.target_file)
             if ::File.exists?(@new_resource.to) && ::File.stat(@current_resource.target_file).ino == ::File.stat(@new_resource.to).ino
               ::File.delete(@new_resource.target_file)
               Chef::Log.info("#{@new_resource} deleted")
               @new_resource.updated_by_last_action(true)
             else
               raise Chef::Exceptions::Link, "Cannot delete #{@new_resource} at #{@new_resource.target_file}! Not a hard link."
             end
          end
        end
      end
    end
  end
end
