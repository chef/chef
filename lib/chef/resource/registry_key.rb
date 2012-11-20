# Author:: Doug MacEachern (<dougm@vmware.com>)
# Author:: Seth Chisamore (<schisamo@opscode.com>)
# Cookbook Name:: windows
# Resource:: registry
#
# Copyright:: 2010, VMware, Inc.
# Copyright:: 2011, Opscode, Inc.
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
require 'chef/provider/registry_key'
require 'chef/resource'

class Chef
  class Resource
    class RegistryKey < Chef::Resource

      identity_attr :key_name
      state_attrs :values, :type

      def initialize(name, run_context=nil)
        super
        @resource_name = :registry_key
        #@action = :modify
        @architecture = :machine
        @recursive = true
        @key_name = name
        @allowed_actions.push(:create, :create_if_missing, :delete, :delete_key)
        #@provider = Chef::Provider::RegistryKey
      end

      def key(arg=nil)
        set_or_return(
          :key,
          arg,
          :kind_of => String,
          :name_attribute => true
        )
      end
      def values(arg=nil)
        set_or_return(
          :values,
          arg,
          :kind_of => Array
        )
      end
      def recursive(arg=nil)
        set_or_return(
          :recursive,
          arg,
          :kind_of => Boolean,
        )
      end
      def architecture(arg=nil)
        set_or_return(
          :architecture,
          arg,
          :kind_of => Symbol
        )
      end

    end
  end
end
