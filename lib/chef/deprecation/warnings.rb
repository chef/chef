#
# Author:: Serdar Sutay (<serdar@opscode.com>)
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

class Chef
  module Deprecation
    module Warnings

      def add_deprecation_warnings_for(method_names)
        method_names.each do |name|
          m = instance_method(name)
          define_method(name) do |*args|
            Chef::Log.warn "Method '#{name}' of '#{self.class}' is deprecated. It will be removed in Chef 12."
            Chef::Log.warn "Please update your cookbooks accordingly. Accessed from:"
            caller[0..3].each {|l| Chef::Log.warn l}
            super(*args)
          end
        end
      end

    end
  end
end

