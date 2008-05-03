#
# Author:: Adam Jacob (<adam@hjksolutions.com>)
# Copyright:: Copyright (c) 2008 HJK Solutions, LLC
# License:: GNU General Public License version 2 or later
# 
# This program and entire repository is free software; you can
# redistribute it and/or modify it under the terms of the GNU 
# General Public License as published by the Free Software 
# Foundation; either version 2 of the License, or any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
# 

class Chef
  class Provider
    class Link < Chef::Provider
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
            ::File.symlink(@new_resource.source_file, @new_resource.target_file)
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