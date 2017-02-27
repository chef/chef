#--
# Author:: Tyler Cloke (<tyler@chef.io>)
# Copyright:: Copyright 2012-2016, Chef Software Inc.
# License:: Apache License, Version 2.0
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

class Chef
  module Formatters
    # == Formatters::ErrorMapper
    # Collection of methods for creating and returning
    # Formatters::ErrorDescription objects based on node,
    # exception, and configuration information.
    module ErrorMapper

      # Failed to register this client with the server.
      def self.registration_failed(node_name, exception, config)
        error_inspector = ErrorInspectors::RegistrationErrorInspector.new(node_name, exception, config)
        headline = "Chef encountered an error attempting to create the client \"#{node_name}\""
        description = ErrorDescription.new(headline)
        error_inspector.add_explanation(description)
        description
      end

      def self.node_load_failed(node_name, exception, config)
        error_inspector = ErrorInspectors::NodeLoadErrorInspector.new(node_name, exception, config)
        headline = "Chef encountered an error attempting to load the node data for \"#{node_name}\""
        description = ErrorDescription.new(headline)
        error_inspector.add_explanation(description)
        description
      end

      def self.run_list_expand_failed(node, exception)
        error_inspector = ErrorInspectors::RunListExpansionErrorInspector.new(node, exception)
        headline = "Error expanding the run_list:"
        description = ErrorDescription.new(headline)
        error_inspector.add_explanation(description)
        description
      end

      def self.cookbook_resolution_failed(expanded_run_list, exception)
        error_inspector = ErrorInspectors::CookbookResolveErrorInspector.new(expanded_run_list, exception)
        headline = "Error Resolving Cookbooks for Run List:"
        description = ErrorDescription.new(headline)
        error_inspector.add_explanation(description)
        description
      end

      def self.cookbook_sync_failed(cookbooks, exception)
        error_inspector = ErrorInspectors::CookbookSyncErrorInspector.new(cookbooks, exception)
        headline = "Error Syncing Cookbooks:"
        description = ErrorDescription.new(headline)
        error_inspector.add_explanation(description)
        description
      end

      def self.resource_failed(resource, action, exception)
        error_inspector = ErrorInspectors::ResourceFailureInspector.new(resource, action, exception)
        headline = "Error executing action `#{action}` on resource '#{resource}'"
        description = ErrorDescription.new(headline)
        error_inspector.add_explanation(description)
        description
      end

      def self.file_load_failed(path, exception)
        error_inspector = ErrorInspectors::CompileErrorInspector.new(path, exception)
        headline = "Recipe Compile Error" + ( path ? " in #{path}" : "" )
        description = ErrorDescription.new(headline)
        error_inspector.add_explanation(description)
        description
      end
    end
  end
end
