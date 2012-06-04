#
# Author:: Daniel DeLeo (<dan@opscode.com>)
# Author:: Prajakta Purohit (prajakta@opscode.com>)
#
# Copyright:: Copyright (c) 2012 Opscode, Inc.
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
  class ResourceReporter

    class ResourceReport < Struct.new(:new_resource, :current_resource, :action, :exception)

      def self.new_with_current_state(new_resource, action, current_resource)
        report = new
        report.new_resource = new_resource
        report.action = action
        report.current_resource = current_resource
        report
      end

      def self.new_for_exception(new_resource, action)
        report = new
        report.new_resource = new_resource
        report.action = action
        report
      end

      def for_json
        as_hash = {}
        as_hash["type"]   = new_resource.class.dsl_name
        # as_hash["name"]   = new_resource.name
        # as_hash["id"]     = new_resource.identity
        as_hash["after"]  = new_resource.state
        as_hash["before"] = current_resource.state if current_resource
        if success?
        else
          #as_hash["result"] = "failed"
        end
        as_hash

      end

      def success?
        !self.exception
      end
    end

    attr_reader :updated_resources
    attr_reader :status
    attr_reader :exception

    def initialize
      @updated_resources = []
      @pending_update  = nil
      @status = "success"
      @exception = nil
    end

    def resource_current_state_loaded(new_resource, action, current_resource)
      @pending_update = ResourceReport.new_with_current_state(new_resource, action, current_resource)
    end

    def resource_up_to_date(new_resource, action)
      @pending_update = nil
    end

    def resource_updated(new_resource, action)
      @updated_resources << @pending_update
      @pending_update = nil
    end

    def resource_failed(new_resource, action, exception)
      @pending_update ||= ResourceReport.new_for_exception(new_resource, action)
      @pending_update.exception = exception
      @updated_resources << @pending_update
      @pending_update = nil
    end

    def run_completed
    end

    def run_failed(exception)
      @exception = exception
      @status = "failed"
    end

    def report
      run_data = {}
      run_data["resources"] = updated_resources.map do |resource_record|
        resource_record.for_json
      end
      run_data
    end

  end
end
