#
# Author:: Thom May (<thom@chef.io>)
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

class Chef
  class Provider
    class Noop < Chef::Provider
      def load_current_resource; end

      def respond_to_missing?(method_sym, include_private = false)
        method_sym.to_s.start_with?("action_") || super
      end

      def method_missing(method_sym, *arguments, &block)
        if /^action_/.match?(method_sym.to_s)
          logger.trace("NoOp-ing for #{method_sym}")
        else
          super
        end
      end
    end
  end
end
