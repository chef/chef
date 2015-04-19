class Chef
  module DSL
    #
    # Module containing a method for each globally declared Resource
    #
    # Depends on declare_resource(name, created_at, &block)
    #
    # @api private
    module Resources
      def self.add_resource_dsl(dsl_name)
        module_eval <<-EOM, __FILE__, __LINE__+1
          def #{dsl_name}(name, created_at=nil, &block)
            declare_resource(#{dsl_name.inspect}, name, created_at || caller[0], &block)
          end
        EOM
      end
      def self.remove_resource_dsl(dsl_name)
        remove_method dsl_name if method_defined?(dsl_name)
      end
    end
  end
end
