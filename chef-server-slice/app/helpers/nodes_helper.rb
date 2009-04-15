#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: AJ Christensen (<aj@junglist.gen.nz>)
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

module Merb
  module ChefServerSlice
    module NodesHelper
      def recipe_list(node)
        response = ""
        node.recipes.each do |recipe|
          response << "<li>#{recipe}</li>\n"
        end
        response
      end

      def attribute_list(node)
        response = ""
        node.each_attribute do |k,v|
          response << "<li><b>#{k}</b>: #{v}</li>\n"
        end
        response
      end
      
      # Recursively build a tree of lists.
      def build_tree(node)
        list = "<dl>"
        list << "\n<!-- Beginning of Node Tree -->"
        walk = lambda do |key,value|
          case value
            when Hash, Array
              list << "\n<!-- Beginning of Enumerable obj -->"
              list << "\n<dt>#{key}</dt>"
              list << "<dd>"
              list << "\t<dl>\n"
              value.each(&walk)
              list << "\t</dl>\n"
              list << "</dd>"
              list << "\n<!-- End of Enumerable obj -->"
              
            else
              list << "\n<dt>#{key}</dt>"
              list << "<dd>#{value}</dd>"
          end
        end
        node.attribute.sort{ |a,b| a[0] <=> b[0] }.each(&walk)
        list << "</dl>"
      end
    end
  end
end
