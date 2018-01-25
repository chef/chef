#
# Author:: Bryan McLellan <btm@loftninjas.org>
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

require "chef/resource/service"
require "chef/win32_service_constants"

class Chef
  class Resource
    # Use the windows_service resource to manage a service on the Microsoft Windows platform.
    #
    # @since 12.0
    class WindowsService < Chef::Resource::Service
      include Chef::Win32ServiceConstants

      ALLOWED_START_TYPES = {
        automatic: SERVICE_AUTO_START,
        manual: SERVICE_DEMAND_START,
        disabled: SERVICE_DISABLED,
      }

      # Until #1773 is resolved, you need to manually specify the windows_service resource
      # to use action :configure_startup and attribute startup_type

      provides :windows_service, os: "windows"
      provides :service, os: "windows"

      allowed_actions :configure_startup, :create, :delete, :configure

      identity_attr :service_name

      state_attrs :enabled, :running

      property :service_name, name_property: true

      # The display name to be used by user interface programs to identify the
      # service. This string has a maximum length of 256 characters.
      property :display_name, String, regex: /^.{1,256}$/

      # https://github.com/djberg96/win32-service/blob/ffi/lib/win32/windows/constants.rb#L19-L29
      property :desired_access, Integer, default: SERVICE_ALL_ACCESS

      # https://github.com/djberg96/win32-service/blob/ffi/lib/win32/windows/constants.rb#L31-L41
      property :service_type, Integer, default: SERVICE_WIN32_OWN_PROCESS

      # Valid options:
      #   - :automatic
      #   - :manual
      #   - :disabled
      # Reference: https://github.com/djberg96/win32-service/blob/ffi/lib/win32/windows/constants.rb#L49-L54
      property :startup_type, [Symbol], equal_to: [:automatic, :manual, :disabled], default: :automatic, coerce: proc { |x|
        if x.is_a?(Integer)
          ALLOWED_START_TYPES.invert.fetch(x) do
            Chef::Log.warn("Unsupported startup_type #{x}, falling back to :automatic")
            :automatic
          end
        elsif x.is_a?(String)
          x.to_sym
        else
          x
        end
      }

      # This only applies if startup_type is :automatic
      # 1 == delayed start is enabled
      # 0 == NO delayed start
      property :delayed_start, [TrueClass, FalseClass], default: false, coerce: proc { |x|
        if x.is_a?(Integer)
          x.zero? ? false : true
        else
          x
        end
      }

      # https://github.com/djberg96/win32-service/blob/ffi/lib/win32/windows/constants.rb#L43-L47
      property :error_control, Integer, default: SERVICE_ERROR_NORMAL

      # The fully qualified path to the service binary file. The path can also
      # include arguments for an auto-start service.
      #
      # This is required for :create and :configure actions -- intentionally
      # not setting required: true here to support other actions
      property :binary_path_name, String

      # The names of the load ordering group of which this service is a member.
      # Specify nil or an empty string if the service does not belong to a group.
      property :load_order_group, String

      # A pointer to a double null-terminated array of null-separated names of
      # services or load ordering groups that the system must start before this
      # service. Specify nil or an empty string if the service has no
      # dependencies. Dependency on a group means that this service can run if
      # at least one member of the group is running after an attempt to start
      # all members of the group.
      property :dependencies, [String, Array]

      property :description, String

      property :run_as_user, String, default: 'LocalSystem'
      property :run_as_password, String, default: ''
    end
  end
end
