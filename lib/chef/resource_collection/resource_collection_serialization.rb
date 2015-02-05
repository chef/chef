#
# Author:: Tyler Ball (<tball@getchef.com>)
# Copyright:: Copyright (c) 2014 Chef Software, Inc.
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
  class ResourceCollection
    module ResourceCollectionSerialization
      # Serialize this object as a hash
      def to_hash
        instance_vars = Hash.new
        self.instance_variables.each do |iv|
          instance_vars[iv] = self.instance_variable_get(iv)
        end
        {
            'json_class' => self.class.name,
            'instance_vars' => instance_vars
        }
      end

      def to_json(*a)
        Chef::JSONCompat.to_json(to_hash, *a)
      end

      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def json_create(o)
          collection = self.new()
          o["instance_vars"].each do |k,v|
            collection.instance_variable_set(k.to_sym, v)
          end
          collection
        end
      end

      def is_chef_resource!(arg)
        unless arg.kind_of?(Chef::Resource)
          raise ArgumentError, "Cannot insert a #{arg.class} into a resource collection: must be a subclass of Chef::Resource"
        end
        true
      end
    end
  end
end
