class Chef
  class Telemetry
    # Guesses the run context of Chef - how were we invoked?
    # All stack values here are determined experimentally

    class RunContextProbe
      # Guess, using stack introspection, if we were called under
      # test-kitchen, chef-client, chef-zero, chef-apply, chef-solo or otherwise.
      ##### WIP: Implementation of run context probe class
      def self.guess_run_context(stack = nil)
        stack ||= caller_locations
        return "chef-apply" if chef_apply?(stack)
        return "chef-client" if chef_client?(stack)
        return "chef-zero" if chef_zero?(stack)
        return "chef-solo" if chef_solo?(stack)
        return "test-kitchen" if kitchen?(stack)

        "unknown"
      end

      def self.kitchen?(stack)
        #TOTEST
        stack_match(stack: stack, path: "kitchen/instance", label: "verify_action") &&
          stack_match(stack: stack, path: "kitchen/instance", label: "verify")
      end

      def self.chef_apply?(stack)
        stack_match(stack: stack, path: "application/apply", label: "run_application") &&
          stack_match(stack: stack, path: "application/apply", label: "run")
      end

      def self.chef_client?(stack)
        stack_match(stack: stack, path: "application/base", label: "run_application") &&
          stack_match(stack: stack, path: "bin/chef-client", label: "load")
      end

      def self.chef_solo?(stack)
        #TODO
        stack_match(stack: stack, path: "", label: "") &&
          stack_match(stack: stack, path: "", label: "")
      end

      def self.chef_zero?(stack)
        #TODO
        stack_match(stack: stack, path: "", label: "") &&
          stack_match(stack: stack, path: "", label: "")
      end

      def self.stack_match(stack: [], label: nil, path: nil)
        return false if stack.nil?

        stack.any? do |frame|
          if label && path
            frame.label == label && frame.absolute_path.include?(path)
          elsif label
            frame.label == label
          elsif path
            frame.absolute_path.include?(path)
          else
            false
          end
        end
      end
    end
  end
end