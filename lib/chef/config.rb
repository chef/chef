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

require File.join(File.dirname(__FILE__), "mixin", "check_helper")

class Chef
  class Config
    
    include Chef::Mixin::CheckHelper
    
    def initialize
      set_defaults
    end
    
    def self.load_file(file)
      config = Chef::Config.new
      if File.exists?(file) && File.readable?(file)
        begin
          config.instance_eval(IO.read(file), file, 1)
        rescue NoMethodError => e
          new_message = "You probably tried to use a config variable that doesn't exist!\n"
          new_message += e.message
          raise e.exception(new_message)
        end
      else
        raise IOError, "Cannot find or read #{file}!"
      end
      config
    end
    
    def cookbook_path(*args)
      if args.length == 0
        @cookbook_path
      else
        flat_args = args.flatten
        flat_args.each do |a|
          unless a.kind_of?(String)
            raise ArgumentError, "You must pass strings to cookbook_path!"
          end
        end
        @cookbook_path = flat_args
      end
    end
    
    def set_defaults
      @cookbook_path = [ 
        "/etc/chef/site-cookbook",
        "/etc/chef/cookbook",
      ]
    end
  end
end