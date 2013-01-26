#
# Author:: Adam Edwards (<adamed@opscode.com>)
# Copyright:: Copyright (c) 2013 Opscode, Inc.
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

require 'chef/exceptions'

class Chef
  module Mixin
    module WindowsArchitectureHelper

      def node_windows_architecture(node)
        node[:kernel][:machine].to_sym
      end

      def node_supports_windows_architecture?(node, desired_architecture)
        assert_valid_windows_architecture!(desired_architecture)
        return (node_windows_architecture(node) == :x86_64 || desired_architecture == :i386) ? true : false
      end

      def valid_windows_architecture?(architecture)
        return (architecture == :x86_64) || (architecture == :i386)
      end

      def assert_valid_windows_architecture!(architecture)
        if ! valid_windows_architecture?(architecture)
          raise Chef::Exceptions::Win32ArchitectureIncorrect,
          "The specified architecture was not valid. It must be one of :i386 or :x86_64"
        end
      end
      
    end
  end
end
