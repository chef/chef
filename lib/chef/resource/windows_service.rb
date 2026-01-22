#
# Author:: Bryan McLellan <btm@loftninjas.org>
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

require_relative "service"
require_relative "../win32_service_constants"

class Chef
  class Resource
    class WindowsService < Chef::Resource::Service
      include Chef::Win32ServiceConstants

      ALLOWED_START_TYPES = {
        automatic: SERVICE_AUTO_START,
        manual: SERVICE_DEMAND_START,
        disabled: SERVICE_DISABLED,
      }.freeze

      # Until #1773 is resolved, you need to manually specify the windows_service resource
      # to use action :configure_startup and properties startup_type

      provides(:windows_service) { true }
      provides :service, os: "windows"

      description "Use the **windows_service** resource to create, delete, or manage a service on the Microsoft Windows platform."
      introduced "12.0"
      examples <<~DOC
      **Starting Services**

      Start a service with a `manual` startup type:

      ```ruby
      windows_service 'BITS' do
        action :configure_startup
        startup_type :manual
      end
      ```

      **Creating Services**

      Create a service named chef-client:

      ```ruby
      windows_service 'chef-client' do
        action :create
        binary_path_name "C:\\opscode\\chef\\bin"
      end
      ```

      Create a service with `service_name` and `display_name`:

      ```ruby
      windows_service 'Setup chef-client as a service' do
        action :create
        display_name 'CHEF-CLIENT'
        service_name 'chef-client'
        binary_path_name "C:\\opscode\\chef\\bin"
      end
      ```

      Create a service with the `manual` startup type:

      ```ruby
      windows_service 'chef-client' do
        action :create
        binary_path_name "C:\\opscode\\chef\\bin"
        startup_type :manual
      end
      ```

      Create a service with the `disabled` startup type:

      ```ruby
      windows_service 'chef-client' do
        action :create
        binary_path_name "C:\\opscode\\chef\\bin"
        startup_type :disabled
      end
      ```

      Create a service with the `automatic` startup type and delayed start enabled:

      ```ruby
      windows_service 'chef-client' do
        action :create
        binary_path_name "C:\\opscode\\chef\\bin"
        startup_type :automatic
        delayed_start true
      end
      ```

      Create a service with a description:

      ```ruby
      windows_service 'chef-client' do
        action :create
        binary_path_name "C:\\opscode\\chef\\bin"
        startup_type :automatic
        description "Chef client as service"
      end
      ```

      **Deleting Services**

      Delete a service named chef-client:

      ```ruby
      windows_service 'chef-client' do
        action :delete
      end
      ```

      Delete a service with the `service_name` property:

      ```ruby
      windows_service 'Delete chef client' do
        action :delete
        service_name 'chef-client'
      end
      ```

      **Configuring Services**

      Change an existing service from automatic to manual startup:

      ```ruby
      windows_service 'chef-client' do
        action :configure
        binary_path_name "C:\\opscode\\chef\\bin"
        startup_type :manual
      end
      ```
      DOC

      allowed_actions :configure_startup, :create, :delete, :configure

      property :timeout, Integer,
        description: "The amount of time (in seconds) to wait before timing out.",
        default: 60,
        desired_state: false

      property :display_name, String, regex: /^.{1,256}$/,
        description: "The display name to be used by user interface programs to identify the service. This string has a maximum length of 256 characters.",
        validation_message: "The display_name can only be a maximum of 256 characters!",
        introduced: "14.0"

      # https://github.com/chef/win32-service/blob/ffi/lib/win32/windows/constants.rb#L19-L29
      property :desired_access, Integer,
        default: SERVICE_ALL_ACCESS,
        introduced: "14.0"

      # https://github.com/chef/win32-service/blob/ffi/lib/win32/windows/constants.rb#L31-L41
      property :service_type, Integer, default: SERVICE_WIN32_OWN_PROCESS,
      introduced: "14.0"

      # Valid options:
      #   - :automatic
      #   - :manual
      #   - :disabled
      # Reference: https://github.com/chef/win32-service/blob/ffi/lib/win32/windows/constants.rb#L49-L54
      property :startup_type, [Symbol],
        equal_to: %i{automatic manual disabled},
        default: :automatic,
        description: "Use to specify the startup type of the service.",
        coerce: proc { |x|
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

      # 1 == delayed start is enabled
      # 0 == NO delayed start
      property :delayed_start, [TrueClass, FalseClass],
        introduced: "14.0",
        description: "Set the startup type to delayed start. This only applies if `startup_type` is `:automatic`",
        default: false, coerce: proc { |x|
          if x.is_a?(Integer)
            x == 0 ? false : true
          else
            x
          end
        }

      # https://github.com/chef/win32-service/blob/ffi/lib/win32/windows/constants.rb#L43-L47
      property :error_control, Integer,
        default: SERVICE_ERROR_NORMAL,
        introduced: "14.0"

      property :binary_path_name, String,
        introduced: "14.0",
        description: "The fully qualified path to the service binary file. The path can also include arguments for an auto-start service. This is required for `:create` and `:configure` actions"

      property :load_order_group, String,
        introduced: "14.0",
        description: "The name of the service's load ordering group(s)."

      property :dependencies, [String, Array],
        description: "A pointer to a double null-terminated array of null-separated names of services or load ordering groups that the system must start before this service. Specify `nil` or an empty string if the service has no dependencies. Dependency on a group means that this service can run if at least one member of the group is running after an attempt to start all members of the group.",
        introduced: "14.0"

      property :description, String,
        description: "Description of the service.",
        introduced: "14.0"

      property :run_as_user, String,
        description: "The user under which a Microsoft Windows service runs.",
        default: "localsystem",
        coerce: proc(&:downcase)

      property :run_as_password, String,
        description: "The password for the user specified by `run_as_user`.",
        default: ""
    end
  end
end
