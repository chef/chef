unless(defined?(ChefPackageHelper))
  class ChefPackageHelper
    class << self

      def plat_walker(hash)
        hash.each_pair do |k,v|
          if(v.is_a?(Hash))
            if(v[:package])
              v[:chef_package] = v[:package]
            else
              plat_walker(v)
            end
          end
        end
      end

      def descendents(klass, *args)
        k = klass.to_s.split('::')
        parent = k.slice(0, k.size - 1).inject(Object){|m,o|
          m.const_get(o)
        }
        d = parent.constants.map{ |const|
          parent.const_get(const)
        }.find_all{|k|
          k < klass if k.is_a?(Class)
        }
        d.unshift(klass) if args.include?(:with_self)
        d
      end
    end
  end

  module ChefPackageResourcer
    module Notifier
      def chef_run_action(*args)
        if(args.first.respond_to?(:chef_based_resource?) && args.first.chef_based_resource?)
          if(args.first.updated_by_last_action?)
            run_context.immediate_notifications(args.first).each do |notification|
              Chef::Log.info "#{args.first} sending #{notification.action} to #{notification.resource} (immediate)"
              run_action(notification.resource, notification.action, :immediate, args.first)
            end
            run_context.delayed_notifications(args.first).each do |notification|
              if(delayed_action.any?{|ex_not| ex_not.duplicates?(notification)})
                Chef::Log.info "#{args.first} not queuing delayed action " << 
                  "#{notification.action} on #{notification.resource} " <<
                  "(delayed), as it's already been queued"
              end
            end
          end
          args.first.chef_based_resource = nil
          args.first.updated_by_last_action(false)
        else
          original_run_action(*args)
        end
      end

      class << self
        def included(base)
          base.class_eval do
            alias_method :original_run_action, :run_action
            alias_method :run_action, :chef_run_action
          end
        end
      end
    end
    module Updater
      def chef_based_resource?
        !!@chef_based_resource
      end

      def chef_based_resource
        @chef_based_resource
      end

      def chef_based_resource=(r)
        @chef_based_resource = r
      end

      def chef_updated_by_last_action?
        @chef_based_resource ? @chef_based_resource.updated? : original_updated_by_last_action?
      end

      def chef_load_prior_resource
        orig_state = @chef_based_resource
        @chef_based_resource = false
        result = original_load_prior_resource
        @chef_based_resource = orig_state
        result
      end

      class << self
        def included(base)
          base.class_eval do
            unless(instance_methods.include?(:original_updated_by_last_action?))
              alias_method :original_updated_by_last_action?, :updated_by_last_action?
              alias_method :updated_by_last_action?, :chef_updated_by_last_action?
              alias_method :original_load_prior_resource, :load_prior_resource
              alias_method :load_prior_resource, :chef_load_prior_resource
            end
          end
        end
      end
    end

    module AfterCreated

      def chef_initialize(*args)
        original_initialize(*args)
        @original_resource = base_resource.new(@name, @run_context)
        @original_resource.chef_based_resource = self
        @run_context.resource_collection.insert(@original_resource)
        @resource_name = Chef::Mixin::ConvertToClassName.snake_case_basename(self.class.name).to_sym
      end
      
      def base_resource
        parts = self.class.name.split('::')
        Chef::Resource.const_get(parts.last.sub(/^Chef/, ''))
      end

      def chef_after_created
        original_after_created
        [@action].flatten.each do |action|
          run_action(action)
        end
      end

      class << self
        def included(base)
          camel_name = Chef::Mixin::ConvertToClassName.snake_case_basename(base.name).to_sym
          base.class_eval do
            unless(instance_methods.include?(:original_initialize))
              provides camel_name, :on_platforms => :all
              alias_method :original_after_created, :after_created
              alias_method :after_created, :chef_after_created
              alias_method :original_initialize, :initialize
              alias_method :initialize, :chef_initialize
            end
          end
        end
      end
    end

  end
  klasses = []

  ChefPackageHelper.descendents(::Chef::Resource::Package, :with_self).each do |klass|
    parts = klass.name.split('::')
    next if parts.last.start_with?('Chef')
    new_name = parts.push("Chef#{parts.pop}").join('::')
    klasses << new_name
    Kernel.eval("class #{new_name} < #{klass}; end;")
    ::Chef::Resource.const_get(new_name.split('::').last).send(:include, ChefPackageResourcer::AfterCreated)
    klass.send(:include, ChefPackageResourcer::Updater)
  end

  Chef::Log.info "Added new internal chef package resources: #{klasses.sort.join(', ')}"

  ChefPackageHelper.plat_walker(Chef::Platform.platforms)
  Chef::Runner.send(:include, ChefPackageResourcer::Notifier) 

end
