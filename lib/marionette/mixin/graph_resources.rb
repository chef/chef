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

class Marionette
  module Mixin
    module GraphResources
      # Find existing resources by searching the list of existing resources.  Takes
      # a hash of :resource_name => name, or :resource_name => [ name1, name2 ]. 
      # 
      # Returns one or an Array of matching resources. 
      #
      # Raises a Runtime Error if it can't find the resources you are looking for.
      def resource(args)
        unless args.kind_of?(Hash)
          raise ArgumentError, "resource requires a hash of :resources => names"
        end

        to_find = Array.new
        args.each do |resource_name, name_matches|
          names = name_matches.kind_of?(Array) ? name_matches : [ name_matches ]
          names.each do |name|
            to_find.push({
              :resource_name => resource_name,
              :name => name, 
              :found => false, 
              :object => nil}
            )
          end
        end

        @dg.each_vertex do |vres|
          next if vres == :top
          to_find.each do |resource|
            if vres.resource_name == resource[:resource_name]
              if vres.name == resource[:name]
                resource[:found] = true
                resource[:object] = vres
                break
              end
            end
          end
        end

        results = Array.new
        errors = Array.new
        to_find.each do |r|
          if r[:found]
            results.push(r)
          else
            errors.push(r)
          end
        end
        if errors.length > 0
          msg = "Cannot find resources (maybe not evaluated yet?):\n"
          errors.each do |e|
            msg << "  #{e[:resource_name].to_s}: #{e[:name].to_s}\n"
          end
          raise RuntimeError, msg
        end

        results.length == 1 ? results[0][:object] : results.collect { |r| r[:object] }
      end
    end
  end
end
