# TODO: missing license header.


# possibly dead code. to revive, move SearchHelper to the Merb namespace.

# module Merb
#   module ChefServerWebui
#     module SearchHelper
#       def output_path(attributes)
#         res = Hash.new
#         attributes.each do |path|
#           parts = path.split("/")
#           unless parts[0].nil?
#             parts.shift if parts[0].length == 0
#           end
#           res[path] = ohai_walk(parts)
#         end
#         res
#       end
#       
#       def ohai_walk(path)
#         unless path[0]
#           @@ohai.to_json
#         else
#           ohai_walk_r(@@ohai, path)
#         end
#       end
#           
#       def ohai_walk_r(ohai, path)
#         hop = (ohai.is_a?(Array) ? path.shift.to_i : path.shift)
#         if ohai[hop]
#           if path[0]
#             ohai_walk_r(ohai[hop], path)
#           else
#             ohai[hop].to_json
#           end
#         else
#           nil
#         end
#       end
#     end
#   end  
# end # Merb
# 
