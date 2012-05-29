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

      def file_class
        @host_os_file ||= if Chef::Platform.windows?
          require 'chef/win32/file'
          Chef::ReservedNames::Win32::File
        else
          ::File
        end
      end

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
        if file_class.symlink?(@current_resource.target_file)
          @current_resource.link_type(:symbolic)
          @current_resource.to(
            canonicalize(file_class.readlink(@current_resource.target_file))
          )
          cstats = ::File.lstat(@current_resource.target_file)
          @current_resource.owner(cstats.uid)
          @current_resource.group(cstats.gid)
        else
          @current_resource.link_type(:hard)
          if ::File.exists?(@current_resource.target_file)
            if ::File.exists?(@new_resource.to) &&
               file_class.stat(@current_resource.target_file).ino ==
               file_class.stat(@new_resource.to).ino
              @current_resource.to(canonicalize(@new_resource.to))
            else
              @current_resource.to("")
            end
          end
        end
        @current_resource
      end

      def canonicalize(path)
        Chef::Platform.windows? ? path.gsub('/', '\\') : path
      end

      def action_create
        if @current_resource.to != canonicalize(@new_resource.to) ||
           @current_resource.link_type != @new_resource.link_type
          if @new_resource.link_type == :symbolic
            if @current_resource.to # nil if target_file does not exist
              ::File.unlink(@new_resource.target_file)
            end
            file_class.symlink(canonicalize(@new_resource.to),@new_resource.target_file)
            Chef::Log.debug("#{@new_resource} created #{@new_resource.link_type} link from #{@new_resource.to} -> #{@new_resource.target_file}")
            Chef::Log.info("#{@new_resource} created")
          elsif @new_resource.link_type == :hard
            if @current_resource.to # nil if target_file does not exist
              ::File.unlink(@new_resource.target_file)
            end
            file_class.link(@new_resource.to, @new_resource.target_file)
            Chef::Log.debug("#{@new_resource} created #{@new_resource.link_type} link from #{@new_resource.to} -> #{@new_resource.target_file}")
            Chef::Log.info("#{@new_resource} created")
          end
          @new_resource.updated_by_last_action(true)
        end
        if @new_resource.link_type == :symbolic
          enforce_ownership_and_permissions @new_resource.target_file
        end
      end

      def action_delete
        if @current_resource.to # Exists
          if @current_resource.link_type == @new_resource.link_type
            unless @current_resource.link_type == :hard && @current_resource.to == ''
              ::File.delete(@new_resource.target_file)
              Chef::Log.info("#{@new_resource} deleted")
              @new_resource.updated_by_last_action(true)
              return
            end
          end
          raise Chef::Exceptions::Link, "Cannot delete #{@new_resource} at #{@new_resource.target_file}! Not a #{@new_resource.link_type.to_s} link."
        end
      end
    end

    # private
    # def hardlink?(target, to)
    #   s = file_class()
    #   if file_class.respond_to?(:hardlink?)
    #     file_class.hardlink?(target)
    #   else
    #     ::File.stat(target).ino == ::File.stat(to).ino
    #   end
    # end
  end
end
