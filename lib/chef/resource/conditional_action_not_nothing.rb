#
# Author:: Xabier de Zuazo (<xabier@onddo.com>)
# Copyright:: Copyright (c) 2013 Onddo Labs, SL.
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
  class Resource
    class ConditionalActionNotNothing

      attr_reader :current_action

      def initialize(current_action)
        @current_action = current_action
      end

      def continue?
        # @positivity == not_if
        @current_action != :nothing
      end

      def short_description
        description
      end

      def description
        "action :nothing"
      end

      def to_text
        "not_if { action == :nothing }"
      end

    end
  end
end
