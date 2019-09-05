#
# Copyright:: Copyright 2018-2018, Chef Software Inc.
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

module ChefHelpers
  module Internal
    class << self

      # @api private
      def env
        ENV
      end

      # @api private
      def env_path
        env['PATH']
      end

      # @api private
      def getnode
        return node if respond_to?(:node)
        run_context&.node if respond_to?(:run_context)
      end
    end
  end
end
