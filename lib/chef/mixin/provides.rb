
require 'chef/mixin/descendants_tracker'

class Chef
  module Mixin
    module Provides
      include Chef::Mixin::DescendantsTracker

      def node_map
        @node_map ||= Chef::NodeMap.new
      end

      def provides(short_name, opts={}, &block)
        if !short_name.kind_of?(Symbol)
          # YAGNI: this is probably completely unnecessary and can be removed?
          Chef::Log.deprecation "Passing a non-Symbol to Chef::Resource#provides will be removed"
          if short_name.kind_of?(String)
            short_name.downcase!
            short_name.gsub!(/\s/, "_")
          end
          short_name = short_name.to_sym
        end
        node_map.set(short_name, true, opts, &block)
      end

      # provides a node on the resource (early binding)
      def provides?(node, resource_name)
        resource_name = resource_name.resource_name if resource_name.is_a?(Chef::Resource)
        node_map.get(node, resource_name)
      end
    end
  end
end
