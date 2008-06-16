module Merb
  module GlobalHelpers
    # helpers defined here available to all views. 
    def resource_collection(collection)
      html = "<ul>"
      collection.each do |resource|
        html << "<li><b>#{resource.class}</b></li>"
      end
      html << "</ul>"
      html
    end
    
    def node_escape(node)
      node.gsub(/\./, '_')
    end
  end
end
