#
# Author:: Tyler Cloke (<tyler@chef.io>)
# Copyright:: Copyright (c) Chef Software Inc.
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

require "chef/key" unless defined?(Chef::Key)

class Chef
  class Knife
    # Service class for UserKeyDelete and ClientKeyDelete, used to delete keys.
    # Implements common functionality of knife [user | org client] key delete.
    #
    # @author Tyler Cloke
    #
    # @attr_accessor [Hash] cli input, see UserKeyDelete and ClientKeyDelete for what could populate it
    class KeyDelete
      def initialize(name, actor, actor_field_name, ui)
        @name = name
        @actor = actor
        @actor_field_name = actor_field_name
        @ui = ui
      end

      def confirm!
        @ui.confirm("Do you really want to delete the key named #{@name} for the #{@actor_field_name} named #{@actor}")
      end

      def print_destroyed
        @ui.info("Deleted key named #{@name} for the #{@actor_field_name} named #{@actor}")
      end

      def run
        key = Chef::Key.new(@actor, @actor_field_name)
        key.name(@name)
        confirm!
        key.destroy
        print_destroyed
      end

    end
  end
end
