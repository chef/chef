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

require 'digest/md5'
require 'etc'
require File.join(File.dirname(__FILE__), "file")

class Chef
  class Provider
    class Directory < Chef::Provider::File
      def load_current_resource
        @current_resource = Chef::Resource::Directory.new(@new_resource.name)
        @current_resource.path(@new_resource.path)
        if ::File.exist?(@current_resource.path) && ::File.directory?(@current_resource.path)
          cstats = ::File.stat(@current_resource.path)
          @current_resource.owner(cstats.uid)
          @current_resource.group(cstats.gid)
          @current_resource.mode("%o" % (cstats.mode & 007777))
        end
        @current_resource
      end      
      
      def action_create
        unless ::File.exists?(@new_resource.path)
          Chef::Log.info("Creating #{@new_resource} at #{@new_resource.path}")
          ::Dir.mkdir(@new_resource.path)
          @new_resource.updated = true
        end
        set_owner if @new_resource.owner != nil
        set_group if @new_resource.group != nil
        set_mode if @new_resource.mode != nil
      end
      
      def action_delete
        if ::File.exists?(@new_resource.path) && ::File.writable?(@new_resource.path)
          Chef::Log.info("Deleting #{@new_resource} at #{@new_resource.path}")
          ::Dir.delete(@new_resource.path)
          @new_resource.updated = true
        else
          raise RuntimeError, "Cannot delete #{@new_resource} at #{@new_resource_path}!" if ::File.exists?(@new_resource.path)
        end
      end
    end
  end
end