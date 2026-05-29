class Chef
  module Formatters
    module ErrorInspectors
      module Instrumentation
        def log_inspector_invocation
          fields = {
            event: "error_inspector.add_explanation",
            inspector: self.class.name,
            exception_class: exception.class.name,
          }

          fields[:node_name] = node_name if respond_to?(:node_name) && !node_name.nil?
          fields[:node_name] = node.name if respond_to?(:node) && node.respond_to?(:name) && !node.name.nil?
          fields[:path] = path if respond_to?(:path) && !path.nil?
          fields[:action] = action if respond_to?(:action) && !action.nil?
          fields[:resource] = resource.to_s if respond_to?(:resource) && !resource.nil?
          fields[:cookbook_count] = cookbooks.size if respond_to?(:cookbooks) && cookbooks.respond_to?(:size)
          fields[:expanded_run_list_count] = expanded_run_list.size if respond_to?(:expanded_run_list) && expanded_run_list.respond_to?(:size)

          Chef::Log.debug(fields.map { |key, value| "#{key}=#{value.inspect}" }.join(" "))
        end
      end
    end
  end
end
