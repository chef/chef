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

require File.join(File.dirname(__FILE__), "file")
require 'uri'

class Chef
  class Provider
    class Template < Chef::Provider::File
      
      def action_create
        r = Chef::REST.new(Chef::Config[:template_url])
        template_url = nil
        if @new_resource.template =~ /^http/          
          template_url = @new_resource.template
        else
          template_url = "cookbooks/#{@new_resource.cookbook_name}/templates/#{@new_resource.template}"
        end
        template = r.get_rest(template_url)
        
        
        unless ::File.exists?(@new_resource.path)
          Chef::Log.info("Creating #{@new_resource} at #{@new_resource.path}")
          ::File.open(@new_resource.path, "w+") { |f| }
          @new_resource.updated = true
        end
        set_owner if @new_resource.owner != nil
        set_group if @new_resource.group != nil
        set_mode if @new_resource.mode != nil
      end
      
      def action_delete
        if ::File.exists?(@new_resource.path) && ::File.writable?(@new_resource.path)
          Chef::Log.info("Deleting #{@new_resource} at #{@new_resource.path}")
          ::File.delete(@new_resource.path)
          @new_resource.updated = true
        else
          raise "Cannot delete #{@new_resource} at #{@new_resource_path}!"
        end
      end
      
      def action_touch
        action_create
        time = Time.now
        Chef::Log.info("Updating #{@new_resource} with new atime/mtime of #{time}")
        ::File.utime(time, time, @new_resource.path)
        @new_resource.updated = true
      end

    end
  end
end