#
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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
  class DataCollector

    # This module isolates the handling of collecting error descriptions to insert into the data_collector
    # report output.  For very early errors it is responsible for collecting the node_name for the report
    # to use.  For all failure conditions that have an ErrorMapper it collects the output.
    #
    # No external code should call anything in this module directly.
    #
    # @api private
    #
    module ErrorHandlers

      # @return [String] the fallback node name if we do NOT have a node due to early failures
      attr_reader :node_name

      # @return [Hash] JSON-formatted error description from the Chef::Formatters::ErrorMapper
      def error_description
        @error_description ||= {}
      end

      # This is an exceptionally "early" failure that results in not having a valid Chef::Node object,
      # so it must capture the node_name from the config.rb
      #
      # (see EventDispatch::Base#registration_failed)
      #
      def registration_failed(node_name, exception, config)
        description = Formatters::ErrorMapper.registration_failed(node_name, exception, config)
        @node_name = node_name
        @error_description = description.for_json
      end

      # This is an exceptionally "early" failure that results in not having a valid Chef::Node object,
      # so it must capture the node_name from the config.rb
      #
      # (see EventDispatch::Base#node_load_failed)
      #
      def node_load_failed(node_name, exception, config)
        description = Formatters::ErrorMapper.node_load_failed(node_name, exception, config)
        @node_name = node_name
        @error_description = description.for_json
      end

      # This is an "early" failure during run_list expansion
      #
      # (see EventDispatch::Base#run_list_expand_failed)
      #
      def run_list_expand_failed(node, exception)
        description = Formatters::ErrorMapper.run_list_expand_failed(node, exception)
        @error_description = description.for_json
      end

      # This is an "early" failure during cookbook resolution / depsolving / talking to cookbook_version endpoint on a server
      #
      # (see EventDispatch::Base#cookbook_resolution_failed)
      #
      def cookbook_resolution_failed(expanded_run_list, exception)
        description = Formatters::ErrorMapper.cookbook_resolution_failed(expanded_run_list, exception)
        @error_description = description.for_json
      end

      # This is an "early" failure during cookbook synchronization
      #
      # (see EventDispatch::Base#cookbook_sync_failed)
      #
      def cookbook_sync_failed(cookbooks, exception)
        description = Formatters::ErrorMapper.cookbook_sync_failed(cookbooks, exception)
        @error_description = description.for_json
      end

      # This failure happens during library loading / attribute file parsing, etc.
      #
      # (see EventDispatch::Base#file_load_failed)
      #
      def file_load_failed(path, exception)
        description = Formatters::ErrorMapper.file_load_failed(path, exception)
        @error_description = description.for_json
      end

      # This failure happens at converge time during recipe parsing
      #
      # (see EventDispatch::Base#recipe_not_failed)
      #
      def recipe_not_found(exception)
        description = Formatters::ErrorMapper.file_load_failed(nil, exception)
        @error_description = description.for_json
      end

      # This is a normal resource failure event during compile/converge phases
      #
      # (see EventDispatch::Base#resource_failed)
      #
      def resource_failed(new_resource, action, exception)
        description = Formatters::ErrorMapper.resource_failed(new_resource, action, exception)
        @error_description = description.for_json
      end
    end
  end
end
