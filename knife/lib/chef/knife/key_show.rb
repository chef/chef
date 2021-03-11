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
require "chef/json_compat" unless defined?(Chef::JSONCompat)
require "chef/exceptions" unless defined?(Chef::Exceptions)

class Chef
  class Knife
    # Service class for UserKeyShow and ClientKeyShow, used to show keys.
    # Implements common functionality of knife [user | org client] key show.
    #
    # @author Tyler Cloke
    #
    # @attr_accessor [Hash] cli input, see UserKeyShow and ClientKeyShow for what could populate it
    class KeyShow

      attr_accessor :config

      def initialize(name, actor, load_method, ui)
        @name = name
        @actor = actor
        @load_method = load_method
        @ui = ui
      end

      def display_output(key)
        @ui.output(@ui.format_for_display(key))
      end

      def run
        key = Chef::Key.send(@load_method, @actor, @name)
        key.public_key(key.public_key.strip)
        display_output(key)
      end
    end
  end
end
