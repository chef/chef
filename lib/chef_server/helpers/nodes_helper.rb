module Merb
  module NodesHelper
    def recipe_list(node)
      response = ""
      node.recipes.each do |recipe|
        response << "<li>#{recipe}</li>"
      end
      response
    end
    
    def attribute_list(node)
      response = ""
      node.each_attribute do |k,v|
        response << "<li><b>#{k}</b>: #{v}</li>"
      end
      response
    end
  end
end