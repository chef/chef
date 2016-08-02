#
# Author:: Adam Leff (<adamleff@chef.io>)
# Author:: Ryan Cragun (<ryan@chef.io>)
#
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
  class DataCollector
    class ResourceReport

      attr_reader :action, :elapsed_time, :new_resource, :status
      attr_accessor :conditional, :current_resource, :exception

      def initialize(new_resource, action, current_resource = nil)
        @new_resource     = new_resource
        @action           = action
        @current_resource = current_resource
        @status           = "unprocessed"
      end

      def skipped(conditional)
        @status      = "skipped"
        @conditional = conditional
      end

      def updated
        @status = "updated"
      end

      def failed(exception)
        @current_resource = nil
        @status           = "failed"
        @exception        = exception
      end

      def up_to_date
        @status = "up-to-date"
      end

      def finish
        @elapsed_time = new_resource.elapsed_time
      end

      def elapsed_time_in_milliseconds
        elapsed_time.nil? ? nil : (elapsed_time * 1000).to_i
      end

      def potentially_changed?
        %w{updated failed}.include?(status)
      end

      def to_hash
        hash = {
          "type"           => new_resource.resource_name.to_sym,
          "name"           => new_resource.name.to_s,
          "id"             => new_resource.identity.to_s,
          "after"          => new_resource.state_for_resource_reporter,
          "before"         => current_resource ? current_resource.state_for_resource_reporter : {},
          "duration"       => elapsed_time_in_milliseconds.to_s,
          "delta"          => new_resource.respond_to?(:diff) && potentially_changed? ? new_resource.diff : "",
          "ignore_failure" => new_resource.ignore_failure,
          "result"         => action.to_s,
          "status"         => status,
        }

        if new_resource.cookbook_name
          hash["cookbook_name"]    = new_resource.cookbook_name
          hash["cookbook_version"] = new_resource.cookbook_version.version
          hash["recipe_name"]      = new_resource.recipe_name
        end

        hash["conditional"]   = conditional.to_text if status == "skipped"
        hash["error_message"] = exception.message unless exception.nil?

        hash
      end
      alias :to_h :to_hash
      alias :for_json :to_hash
    end
  end
end
