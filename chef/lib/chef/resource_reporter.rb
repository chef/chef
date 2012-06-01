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

    attr_reader :updated_resources

    def initialize
      @updated_resources = []
      @pending_update  = nil
    end

    def resource_current_state_loaded(new_resource, action, current_resource)
      @pending_update = {:current_resource => current_resource,
                         :new_resource => new_resource}
    end

    def resource_up_to_date(new_resource, action)
      @pending_update = nil
    end

    def resource_updated(new_resource, action)
      @updated_resources << @pending_update
      @pending_update = nil
    end

    def resource_failed(new_resource, action, exception)
      @pending_update ||= {:new_resource => new_resource}
      @updated_resources << @pending_update
      @pending_update = nil
    end

  end
end
