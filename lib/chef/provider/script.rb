#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2008 Opscode, Inc.
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

require 'tempfile'
require 'chef/provider/execute'
require 'forwardable'

class Chef
  class Provider
    class Script < Chef::Provider::Execute
      extend Forwardable

      provides :bash
      provides :csh
      provides :ksh
      provides :perl
      provides :python
      provides :ruby
      provides :script

      def_delegators :@new_resource, :interpreter, :flags

      attr_accessor :code

      def initialize(new_resource, run_context)
        super
        self.code = new_resource.code
      end

      def command
        "\"#{interpreter}\" #{flags} \"#{script_file.path}\""
      end

      def load_current_resource
        super
        # @todo Chef-13: change this to an exception
        if code.nil?
          Chef::Log.warn "#{@new_resource}: No code attribute was given, resource does nothing, this behavior is deprecated and will be removed in Chef-13"
        end
      end

      def action_run
        script_file.puts(code)
        script_file.close

        set_owner_and_group

        super

        unlink_script_file
      end

      def set_owner_and_group
        # FileUtils itself implements a no-op if +user+ or +group+ are nil
        # You can prove this by running FileUtils.chown(nil,nil,'/tmp/file')
        # as an unprivileged user.
        FileUtils.chown(new_resource.user, new_resource.group, script_file.path)
      end

      def script_file
        @script_file ||= Tempfile.open("chef-script")
      end

      def unlink_script_file
        script_file && script_file.close!
      end

    end
  end
end
