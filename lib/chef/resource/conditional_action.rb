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
    class ConditionalAction

      # We only create these via the `not_if` or `only_if` constructors, and
      # not the default constructor
      class << self
        private :new
      end

      def self.not_if(current_action, required_action)
        new(:not_if, current_action, required_action)
      end

      def self.only_if(current_action, required_action)
        new(:only_if, current_action, required_action)
      end

      attr_reader :positivity
      attr_reader :required_action
      attr_reader :current_action

      def initialize(positivity, current_action, required_action)
        @positivity = positivity
        @current_action = current_action
        @required_action = required_action
      end

      def continue?
        case @positivity
        when :only_if
          evaluate
        when :not_if
          !evaluate
        else
          raise "Cannot evaluate resource conditional of type #{@positivity}"
        end
      end

      def evaluate
        @required_action == @current_action
      end

      def short_description
        description
      end

      def description
        case @positivity
        when :only_if
          "action not being #{@required_action.inspect}"
        when :not_if
          "action #{@required_action.inspect}"
        else
          raise "Cannot describe resource conditional of type #{@positivity}"
        end
      end

      def to_text
        "#{@positivity} { action == #{@required_action.inspect} }"
      end

    end
  end
end
