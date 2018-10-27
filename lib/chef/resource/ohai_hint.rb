#
# Copyright:: Copyright 2011-2018, Chef Software, Inc.
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

require "chef/resource"

class Chef
  class Resource
    class OhaiHint < Chef::Resource
      resource_name :ohai_hint
      provides(:ohai_hint) { true }

      description "Use the ohai_hint resource to aid in configuration detection by passing hint data to Ohai."
      introduced "14.0"

      property :hint_name, String,
               description: "The name of the hints file, if it differs from the resource name.",
               name_property: true

      property :content, Hash,
               description: "Values to include in the hint file."

      property :compile_time, [TrueClass, FalseClass],
               description: "Determines whether or not the resource is executed during the compile time phase.",
               default: true, desired_state: false

      action :create do
        description "Create an Ohai hint file."

        directory ::Ohai::Config.ohai.hints_path.first do
          action :create
          recursive true
        end

        file ohai_hint_file_path(new_resource.hint_name) do
          action :create
          content format_content(new_resource.content)
        end
      end

      action :delete do
        description "Delete an Ohai hint file."

        file ohai_hint_file_path(new_resource.hint_name) do
          action :delete
          notifies :reload, ohai[reload ohai post hint removal]
        end

        ohai "reload ohai post hint removal" do
          action :nothing
        end
      end

      action_class do
        # given a hint filename return the platform specific hint file path
        # @param filename [String] the name of the hint file
        # @return [String] absolute path to the file
        def ohai_hint_file_path(filename)
          path = ::File.join(::Ohai::Config.ohai.hints_path.first, filename)
          path << ".json" unless path.end_with?(".json")
          path
        end

        # format content hash as JSON
        # @param content [Hash] the content of the hint file
        # @return [JSON] json representation of the content of an empty string if content was nil
        def format_content(content)
          return "" if content.nil? || content.empty?
          JSON.pretty_generate(content)
        end
      end

      # this resource forces itself to run at compile_time
      def after_created
        return unless compile_time
        Array(action).each do |action|
          run_action(action)
        end
      end
    end
  end
end
