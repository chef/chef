#
# Author:: Lamont Granquist (<lamont@opscode.com>)
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

#
# Helper functions to access the windows registry from within recipes and
# the not_if/only_if blocks in resources.  This only exposes the methods
# in the chef/win32/registry class which are reasonably side-effect-free.
# The actual modification of the registry should be done via the registry_key
# resource in a more idempotent way.
#
#
class Chef
  module DSL
    module RegistryHelper
      # the registry instance is cheap to build and throwing it away ensures we
      # don't carry any state (e.g. magic 32-bit/64-bit settings) between calls
      def registry_key_exists?(key_path, architecture = :machine)
        registry = Chef::Win32::Registry.new(run_context, architecture)
        registry.key_exists?(key_path)
      end
      def registry_get_values(key_path, architecture = :machine)
        registry = Chef::Win32::Registry.new(run_context, architecture)
        registry.get_values(key_path)
      end
      def registry_has_subkeys?(key_path, architecture = :machine)
        registry = Chef::Win32::Registry.new(run_context, architecture)
        registry.has_subkeys?(key_path)
      end
      def registry_get_subkeys(key_path, architecture = :machine)
        registry = Chef::Win32::Registry.new(run_context, architecture)
        registry.get_subkeys(key_path)
      end
      def registry_value_exists?(key_path, value, architecture = :machine)
        registry = Chef::Win32::Registry.new(run_context, architecture)
        registry.value_exists?(key_path, value)
      end
      def registry_data_exists?(key_path, value, architecture = :machine)
        registry = Chef::Win32::Registry.new(run_context, architecture)
        registry.data_exists?(key_path, value)
      end
    end
  end
end

