#
# Author:: Seth Chisamore <schisamo@chef.io>
# Copyright:: Copyright (c) Chef Software Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require_relative "../resource"
require "chef-utils/dist" unless defined?(ChefUtils::Dist)

class Chef
  class Resource
    class ChefHandler < Chef::Resource
      unified_mode true

      provides(:chef_handler) { true }

      description "Use the **chef_handler** resource to enable handlers during a #{ChefUtils::Dist::Infra::PRODUCT} run. The resource allows arguments to be passed to #{ChefUtils::Dist::Infra::PRODUCT}, which then applies the conditions defined by the custom handler to the node attribute data collected during a #{ChefUtils::Dist::Infra::PRODUCT} run, and then processes the handler based on that data.\nThe **chef_handler** resource is typically defined early in a node's run-list (often being the first item). This ensures that all of the handlers will be available for the entire #{ChefUtils::Dist::Infra::PRODUCT} run."
      introduced "14.0"
      examples <<~'DOC'
      **Enable the 'MyHandler' handler**

      The following example shows how to enable a fictional 'MyHandler' handler which is located on disk at `/etc/chef/my_handler.rb`. The handler will be configured to run with Chef Infra Client and will be passed values to the handler's initializer method:

      ```ruby
      chef_handler 'MyHandler' do
        source '/etc/chef/my_handler.rb' # the file should already be at this path
        arguments path: '/var/chef/reports'
        action :enable
      end
      ```

      **Enable handlers during the compile phase**

      ```ruby
      chef_handler 'Chef::Handler::JsonFile' do
        source 'chef/handler/json_file'
        arguments path: '/var/chef/reports'
        action :enable
        compile_time true
      end
      ```

      **Handle only exceptions**

      ```ruby
      chef_handler 'Chef::Handler::JsonFile' do
        source 'chef/handler/json_file'
        arguments path: '/var/chef/reports'
        type exception: true
        action :enable
      end
      ```

      **Cookbook Versions (a custom handler)**

      [@juliandunn](https://github.com/juliandunn) created a custom report handler that logs all of the cookbooks and cookbook versions that were used during a Chef Infra Client run, and then reports after the run is complete.

      cookbook_versions.rb:

      The following custom handler defines how cookbooks and cookbook versions that are used during a Chef Infra Client run will be compiled into a report using the `Chef::Log` class in Chef Infra Client:

      ```ruby
      require 'chef/log'

      module Chef
        class CookbookVersionsHandler < Chef::Handler
          def report
            cookbooks = run_context.cookbook_collection
            Chef::Log.info('Cookbooks and versions run: #{cookbooks.map {|x| x.name.to_s + ' ' + x.version }}')
          end
        end
      end
      ```

      default.rb:

      The following recipe is added to the run-list for every node on which a list of cookbooks and versions will be generated as report output after every Chef Infra Client run.

      ```ruby
      cookbook_file '/etc/chef/cookbook_versions.rb' do
        source 'cookbook_versions.rb'
        action :create
      end

      chef_handler 'Chef::CookbookVersionsHandler' do
        source '/etc/chef/cookbook_versions.rb'
        type report: true
        action :enable
      end
      ```

      This recipe will generate report output similar to the following:

      ```
      [2013-11-26T03:11:06+00:00] INFO: Chef Infra Client Run complete in 0.300029878 seconds
      [2013-11-26T03:11:06+00:00] INFO: Running report handlers
      [2013-11-26T03:11:06+00:00] INFO: Cookbooks and versions run: ["cookbook_versions_handler 1.0.0"]
      [2013-11-26T03:11:06+00:00] INFO: Report handlers complete
      ```

      **JsonFile Handler**

      The JsonFile handler is available from the `chef_handler` cookbook and can be used with exceptions and reports. It serializes run status data to a JSON file. This handler may be enabled in one of the following ways.

      By adding the following lines of Ruby code to either the client.rb file or the solo.rb file, depending on how Chef Infra Client is being run:

      ```ruby
      require 'chef/handler/json_file'
      report_handlers << Chef::Handler::JsonFile.new(path: '/var/chef/reports')
      exception_handlers << Chef::Handler::JsonFile.new(path: '/var/chef/reports')
      ```

      By using the `chef_handler` resource in a recipe, similar to the following:

      ```ruby
      chef_handler 'Chef::Handler::JsonFile' do
        source 'chef/handler/json_file'
        arguments path: '/var/chef/reports'
        action :enable
      end
      ```

      After it has run, the run status data can be loaded and inspected via Interactive Ruby (IRb):

      ```
      irb(main):002:0> require 'json' => true
      irb(main):003:0> require 'chef' => true
      irb(main):004:0> r = JSON.parse(IO.read('/var/chef/reports/chef-run-report-20110322060731.json')) => ... output truncated
      irb(main):005:0> r.keys => ['end_time', 'node', 'updated_resources', 'exception', 'all_resources', 'success', 'elapsed_time', 'start_time', 'backtrace']
      irb(main):006:0> r['elapsed_time'] => 0.00246
      ```

      Register the JsonFile handler

      ```ruby
      chef_handler 'Chef::Handler::JsonFile' do
        source 'chef/handler/json_file'
        arguments path: '/var/chef/reports'
        action :enable
      end
      ```

      **ErrorReport Handler**

      The ErrorReport handler is built into Chef Infra Client and can be used for both exceptions and reports. It serializes error report data to a JSON file. This handler may be enabled in one of the following ways.

      By adding the following lines of Ruby code to either the client.rb file or the solo.rb file, depending on how Chef Infra Client is being run:

      ```ruby
      require 'chef/handler/error_report'
      report_handlers << Chef::Handler::ErrorReport.new
      exception_handlers << Chef::Handler::ErrorReport.new
      ```

      By using the `chef_handler` resource in a recipe, similar to the following:

      ```ruby
      chef_handler 'Chef::Handler::ErrorReport' do
        source 'chef/handler/error_report'
        action :enable
      end
      ```
      DOC

      property :class_name, String,
        description: "The name of the handler class. This can be module name-spaced.",
        name_property: true

      property :source, String,
        description: "The full path to the handler file. Can also be a gem path if the handler ships as part of a Ruby gem."

      property :arguments, [Array, Hash],
        description: "Arguments to pass the handler's class initializer.",
        default: []

      property :type, Hash,
        description: "The type of handler to register as, i.e. :report, :exception or both.",
        default: { report: true, exception: true }

      # supports means a different thing in chef-land so we renamed it but
      # wanted to make sure we didn't break the world
      alias_method :supports, :type

      # This action needs to find an rb file that presumably contains the indicated class in it and the
      # load that file. It then instantiates that class by name and registers it as a handler.
      action :enable, description: "Enables the handler for the current #{ChefUtils::Dist::Infra::PRODUCT} run on the current node." do
        class_name = new_resource.class_name
        new_resource.type.each do |type, enable|
          next unless enable

          unregister_handler(type, class_name)
        end

        handler = nil

        require new_resource.source unless new_resource.source.nil?

        _, klass = get_class(class_name)
        handler = klass.send(:new, *collect_args(new_resource.arguments))

        new_resource.type.each do |type, enable|
          next unless enable

          register_handler(type, handler)
        end
      end

      action :disable, description: "Disables the handler for the current #{ChefUtils::Dist::Infra::PRODUCT} run on the current node." do
        new_resource.type.each_key do |type|
          unregister_handler(type, new_resource.class_name)
        end
      end

      action_class do
        # Registers a handler in Chef::Config.
        #
        # @param handler_type [Symbol] such as :report or :exception.
        # @param handler [Chef::Handler] handler to register.
        def register_handler(handler_type, handler)
          Chef::Log.info("Enabling #{handler.class.name} as a #{handler_type} handler.")
          Chef::Config.send("#{handler_type}_handlers") << handler
        end

        # Removes all handlers that match the given class name in Chef::Config.
        #
        # @param handler_type [Symbol] such as :report or :exception.
        # @param class_full_name [String] such as 'Chef::Handler::ErrorReport'.
        #
        # @return [void]
        def unregister_handler(handler_type, class_full_name)
          Chef::Config.send("#{handler_type}_handlers").delete_if do |v|
            # avoid a bit of log spam
            if v.class.name == class_full_name
              Chef::Log.info("Disabling #{class_full_name} as a #{handler_type} handler.")
              true
            end
          end
        end

        # Walks down the namespace hierarchy to return the class object for the given class name.
        # If the class is not available, NameError is thrown.
        #
        # @param class_full_name [String] full class name such as 'Chef::Handler::Foo' or 'MyHandler'.
        #
        # @return [Array] parent class and child class.
        def get_class(class_full_name)
          ancestors = class_full_name.split("::")
          class_name = ancestors.pop

          # We need to search the ancestors only for the first/uppermost namespace of the class, so we
          # need to enable the #const_get inherit parameter only when we are searching in Kernel scope
          # (see COOK-4117).
          parent = ancestors.inject(Kernel) { |scope, const_name| scope.const_get(const_name, scope === Kernel) }
          child = parent.const_get(class_name, parent === Kernel)
          [parent, child]
        end

        def collect_args(resource_args = [])
          if resource_args.is_a? Array
            resource_args
          else
            [resource_args]
          end
        end
      end
    end
  end
end
