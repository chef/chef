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
        begin
          module_eval(<<-EOM, __FILE__, __LINE__+1)
            def #{dsl_name}(*args, &block)
              Chef.log_deprecation("Cannot create resource #{dsl_name} with more than one argument. All arguments except the name (\#{args[0].inspect}) will be ignored. This will cause an error in Chef 13. Arguments: \#{args}") if args.size > 1
              declare_resource(#{dsl_name.inspect}, args[0], caller[0], &block)
            end
          EOM
        rescue SyntaxError
          # Handle the case where dsl_name has spaces, etc.
          define_method(dsl_name.to_sym) do |*args, &block|
            Chef.log_deprecation("Cannot create resource #{dsl_name} with more than one argument. All arguments except the name (#{args[0].inspect}) will be ignored. This will cause an error in Chef 13. Arguments: #{args}") if args.size > 1
            declare_resource(dsl_name, args[0], caller[0], &block)
          end
        end
      end
      def self.remove_resource_dsl(dsl_name)
        remove_method(dsl_name) if method_defined?(dsl_name)
      end
    end
  end
end
