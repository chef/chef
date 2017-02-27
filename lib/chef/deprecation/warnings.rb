#
# Author:: Serdar Sutay (<serdar@chef.io>)
# Copyright:: Copyright 2013-2016, Chef Software Inc.
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
          define_method(name) do |*args|
            message = "Method '#{name}' of '#{self.class}' is deprecated. It will be removed in Chef 13."
            message << " Please update your cookbooks accordingly."
            Chef.deprecated(:internal_api, message)
            super(*args)
          end
        end
      end

    end
  end
end
