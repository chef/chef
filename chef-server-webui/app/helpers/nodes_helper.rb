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

# Possibly dead code. to revive it, move NodesHelper into the Merb namespace.
# module Merb
#   module ChefServerWebui
#     module NodesHelper
#       def recipe_list(node)
#         response = ""
#         node.recipes.each do |recipe|
#           response << "<li>#{recipe}</li>\n"
#         end
#         response
#       end
# 
#       def attribute_list(node)
#         response = ""
#         node.each_attribute do |k,v|
#           response << "<li><b>#{k}</b>: #{v}</li>\n"
#         end
#         response
#       end
#       
#     end
#   end
# end
# 