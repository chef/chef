#
# Author:: Adam Jacob (<adam@chef.io>)
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

require_relative "execute"
require "forwardable" unless defined?(Forwardable)

class Chef
  class Provider
    class Script < Chef::Provider::Execute
      extend Forwardable

      provides :bash, target_mode: true
      provides :csh, target_mode: true
      provides :ksh, target_mode: true
      provides :perl, target_mode: true
      provides :python, target_mode: true
      provides :ruby, target_mode: true
      provides :script, target_mode: true

      def_delegators :new_resource, :interpreter, :flags, :code

      def command
        "\"#{interpreter}\" #{flags}"
      end

      def input
        code
      end
    end
  end
end
