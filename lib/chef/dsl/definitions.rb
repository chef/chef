class Chef
  module DSL
    #
    # Module containing a method for each declared definition
    #
    # Depends on declare_resource(name, created_at, &block)
    #
    # @api private
    #
    module Definitions
      def self.add_definition(dsl_name)
        module_eval <<-EOM, __FILE__, __LINE__+1
          def #{dsl_name}(*args, &block)
            evaluate_resource_definition(#{dsl_name.inspect}, *args, &block)
          end
        EOM
      end

      # @api private
      def has_resource_definition?(name)
        run_context.definitions.has_key?(name)
      end

      # Processes the arguments and block as a resource definition.
      #
      # @api private
      def evaluate_resource_definition(definition_name, *args, &block)

        # This dupes the high level object, but we still need to dup the params
        new_def = run_context.definitions[definition_name].dup

        new_def.params = new_def.params.dup
        new_def.node = run_context.node
        # This sets up the parameter overrides
        new_def.instance_eval(&block) if block

        new_recipe = Chef::Recipe.new(cookbook_name, recipe_name, run_context)
        new_recipe.params = new_def.params
        new_recipe.params[:name] = args[0]
        new_recipe.instance_eval(&new_def.recipe)
      end
    end
  end
end
