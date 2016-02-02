#
# Author:: Tyler Ball (<tball@chef.io>)
# Copyright:: Copyright 2014-2016, Chef Software, Inc.
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
    class Notification

      attr_accessor :resource, :action, :notifying_resource

      def initialize(resource, action, notifying_resource)
        @resource = resource
        @action = action
        @notifying_resource = notifying_resource
      end

      def duplicates?(other_notification)
        unless other_notification.respond_to?(:resource) && other_notification.respond_to?(:action)
          msg = "only duck-types of Chef::Resource::Notification can be checked for duplication "\
                "you gave #{other_notification.inspect}"
          raise ArgumentError, msg
        end
        other_notification.resource == resource && other_notification.action == action
      end

      # If resource and/or notifying_resource is not a resource object, this will look them up in the resource collection
      # and fix the references from strings to actual Resource objects.
      def resolve_resource_reference(resource_collection)
        return resource if resource.kind_of?(Chef::Resource) && notifying_resource.kind_of?(Chef::Resource)

        if not(resource.kind_of?(Chef::Resource))
          fix_resource_reference(resource_collection)
        end

        if not(notifying_resource.kind_of?(Chef::Resource))
          fix_notifier_reference(resource_collection)
        end
      end

      # This will look up the resource if it is not a Resource Object.  It will complain if it finds multiple
      # resources, can't find a resource, or gets invalid syntax.
      def fix_resource_reference(resource_collection)
        matching_resource = resource_collection.find(resource)
        if Array(matching_resource).size > 1
          msg = "Notification #{self} from #{notifying_resource} was created with a reference to multiple resources, "\
          "but can only notify one resource. Notifying resource was defined on #{notifying_resource.source_line}"
          raise Chef::Exceptions::InvalidResourceReference, msg
        end
        self.resource = matching_resource

      rescue Chef::Exceptions::ResourceNotFound => e
        err = Chef::Exceptions::ResourceNotFound.new(<<-FAIL)
resource #{notifying_resource} is configured to notify resource #{resource} with action #{action}, \
but #{resource} cannot be found in the resource collection. #{notifying_resource} is defined in \
#{notifying_resource.source_line}
        FAIL
        err.set_backtrace(e.backtrace)
        raise err
      rescue Chef::Exceptions::InvalidResourceSpecification => e
        err = Chef::Exceptions::InvalidResourceSpecification.new(<<-F)
Resource #{notifying_resource} is configured to notify resource #{resource} with action #{action}, \
but #{resource.inspect} is not valid syntax to look up a resource in the resource collection. Notification \
is defined near #{notifying_resource.source_line}
        F
        err.set_backtrace(e.backtrace)
        raise err
      end

      # This will look up the notifying_resource if it is not a Resource Object.  It will complain if it finds multiple
      # resources, can't find a resource, or gets invalid syntax.
      def fix_notifier_reference(resource_collection)
        matching_notifier = resource_collection.find(notifying_resource)
        if Array(matching_notifier).size > 1
          msg = "Notification #{self} from #{notifying_resource} was created with a reference to multiple notifying "\
          "resources, but can only originate from one resource.  Destination resource was defined "\
          "on #{resource.source_line}"
          raise Chef::Exceptions::InvalidResourceReference, msg
        end
        self.notifying_resource = matching_notifier

      rescue Chef::Exceptions::ResourceNotFound => e
        err = Chef::Exceptions::ResourceNotFound.new(<<-FAIL)
Resource #{resource} is configured to receive notifications from #{notifying_resource} with action #{action}, \
but #{notifying_resource} cannot be found in the resource collection. #{resource} is defined in \
#{resource.source_line}
        FAIL
        err.set_backtrace(e.backtrace)
        raise err
      rescue Chef::Exceptions::InvalidResourceSpecification => e
        err = Chef::Exceptions::InvalidResourceSpecification.new(<<-F)
Resource #{resource} is configured to receive notifications from  #{notifying_resource} with action #{action}, \
but #{notifying_resource.inspect} is not valid syntax to look up a resource in the resource collection. Notification \
is defined near #{resource.source_line}
        F
        err.set_backtrace(e.backtrace)
        raise err
      end

      def ==(other)
        return false unless other.is_a?(self.class)
        other.resource == resource && other.action == action && other.notifying_resource == notifying_resource
      end

    end
  end
end
