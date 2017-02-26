#
# Author:: Adam Jacob (<adam@chef.io>)
# Author:: Tyler Cloke (<tyler@chef.io>)
# Copyright:: Copyright 2008-2017, Chef Software Inc.
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

require "chef/resource/execute"
require "chef/provider/script"

class Chef
  class Resource
    class Script < Chef::Resource::Execute
      identity_attr :name

      def initialize(name, run_context = nil)
        super
        @command = nil
        @default_guard_interpreter = :default
      end

      # FIXME: remove this and use an execute sub-resource instead of inheriting from Execute
      def command(arg = nil)
        unless arg.nil?
          raise Chef::Exceptions::Script, "Do not use the command attribute on a #{resource_name} resource, use the 'code' attribute instead."
        end
        super
      end

      property :code, String, required: true
      property :interpreter, String
      property :flags, String

    end
  end
end
