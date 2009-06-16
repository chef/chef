
class Chef
  class Provider
    class RubyBlock < Chef::Provider
      def load_current_resource
        Chef::Log.debug(@new_resource.inspect)
        true
      end

      def action_create
        @new_resource.block.call
      end
    end
  end
end
