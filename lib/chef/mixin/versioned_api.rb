#--
# Copyright:: Copyright 2017, Chef Software Inc.
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
  module Mixin
    module VersionedAPI

      def minimum_api_version(version = nil)
        if version
          @minimum_api_version = version
        else
          @minimum_api_version
        end
      end

    end

    module VersionedAPIFactory

      def versioned_interfaces
        @versioned_interfaces ||= []
      end

      def add_versioned_api_class(klass)
        versioned_interfaces << klass
      end

      def versioned_api_class
        get_class_for(:max_server_version)
      end

      def get_class_for(type)
        versioned_interfaces.select do |klass|
          version = klass.send(:minimum_api_version)
          # min and max versions will be nil if we've not made a request to the server yet,
          # in which case we'll just start with the highest version and see what happens
          ServerAPIVersions.instance.min_server_version.nil? || (version >= ServerAPIVersions.instance.min_server_version && version <= ServerAPIVersions.instance.send(type))
        end
          .sort { |a, b| a.send(:minimum_api_version) <=> b.send(:minimum_api_version) }
          .last
      end

      def def_versioned_delegator(method)
        line_no = __LINE__; str = %{
          def self.#{method}(*args, &block)
            versioned_api_class.__send__(:#{method}, *args, &block)
          end
        }
        module_eval(str, __FILE__, line_no)
      end

      # When teeing up an HTTP request, we need to be able to ask which API version we should use.
      # Something in Net::HTTP seems to expect to strip headers, so we return this as a string.
      def best_request_version
        klass = get_class_for(:max_server_version)
        klass.minimum_api_version.to_s
      end

      def possible_requests
        versioned_interfaces.length
      end

      def new(*args)
        object = versioned_api_class.allocate
        object.send(:initialize, *args)
        object
      end
    end
  end
end
