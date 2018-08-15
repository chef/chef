#
# Author:: Tyler Cloke (tyler@chef.io)
# Copyright:: Copyright 2015-2016, Chef Software, Inc
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

require "chef/knife"
require "chef/knife/key_edit"
require "chef/knife/key_edit_base"

class Chef
  class Knife
    # Implements knife user key edit using Chef::Knife::KeyEdit
    # as a service class.
    #
    # @author Tyler Cloke
    #
    # @attr_reader [String] actor the name of the user that this key is for
    class UserKeyEdit < Knife
      include Chef::Knife::KeyEditBase

      banner "knife user key edit USER KEYNAME (options)"

      attr_reader :actor

      def initialize(argv = [])
        super(argv)
        @service_object = nil
      end

      def run
        apply_params!(@name_args)
        service_object.run
      end

      def actor_field_name
        "user"
      end

      def service_object
        @service_object ||= Chef::Knife::KeyEdit.new(@name, @actor, actor_field_name, ui, config)
      end

      def actor_missing_error
        "You must specify a user name"
      end

      def keyname_missing_error
        "You must specify a key name"
      end

      def apply_params!(params)
        @actor = params[0]
        if @actor.nil?
          show_usage
          ui.fatal(actor_missing_error)
          exit 1
        end
        @name = params[1]
        if @name.nil?
          show_usage
          ui.fatal(keyname_missing_error)
          exit 1
        end
      end
    end
  end
end
