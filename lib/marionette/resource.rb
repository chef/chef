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

require 'yaml'

class Marionette
  class Resource
          
    attr_accessor :before, :require, :notify, :subscribe, :tag
    
    def initialize(name)
      @name = name
      @tag = Array.new
      @alias = nil
      @noop = nil
      @tag = nil
      @before = nil
      @require = nil
      @notify = nil
      @subscribe = nil
      @tag = nil
    end
    
    def name
      @name
    end
    
    def name=(name)
      raise ArgumentError, "name must be a string!" unless name.kind_of?(String)
      @name = name
    end
    
    def alias
      @alias
    end
    
    def alias=(alias_name)
      raise ArgumentError, "alias must be a string!" unless alias_name.kind_of?(String)
      @alias = alias_name
    end
    
    def noop
      @noop
    end
    
    def noop=(tf)      
      raise ArgumentError, "noop must be true or false!" unless tf == true || tf == false
      @noop = tf
    end
    
    def tag
      @tag
    end
    
    def tag=(args)
      if args.kind_of?(Array)
        args.each do |t|
          @tag << t
        end
      else
        @tag << args
      end
      @tag
    end
    
    def valid?()
      return false unless self.name
      true
    end
  end
end