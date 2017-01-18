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

      def self.included(base)
        # When this file is mixed in, make sure we also add the class methods
        base.send :extend, ClassMethods
      end

      module ClassMethods
        def versioned_interfaces
          @versioned_interfaces ||= []
        end

        def add_api_version(klass)
          versioned_interfaces << klass
        end
      end

      def select_api_version
        self.class.versioned_interfaces.select do |klass|
          version = klass.send(:supported_api_version)
          # min and max versions will be nil if we've not made a request to the server yet,
          # in which case we'll just start with the highest version and see what happens
          ServerAPIVersions.instance.min_server_version.nil? || (version >= ServerAPIVersions.instance.min_server_version && version <= ServerAPIVersions.instance.max_server_version)
        end
          .sort { |a, b| a.send(:supported_api_version) <=> b.send(:supported_api_version) }
          .last
      end
    end
  end
end
