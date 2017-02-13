#
# Author:: Tyler Ball (<tball@chef.io>)
# Copyright:: Copyright 2014-2016, Chef Software Inc.
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

require "chef/exceptions"

class Chef
  module DSL
    module Audit

      # Can encompass tests in a `control` block or `describe` block
      # Adds the controls group and block (containing controls to execute) to the runner's list of pending examples
      def control_group(*args, &block)
        raise Chef::Exceptions::NoAuditsProvided unless block

        name = args[0]
        if name.nil? || name.empty?
          raise Chef::Exceptions::AuditNameMissing
        elsif run_context.audits.has_key?(name)
          raise Chef::Exceptions::AuditControlGroupDuplicate.new(name)
        end

        # This DSL will only work in the Recipe class because that exposes the cookbook_name
        cookbook_name = self.cookbook_name
        metadata = {
            cookbook_name: cookbook_name,
            cookbook_version: run_context.cookbook_collection[cookbook_name].version,
            recipe_name: recipe_name,
            line_number: block.source_location[1],
        }

        run_context.audits[name] = Struct.new(:args, :block, :metadata).new(args, block, metadata)
      end

    end
  end
end
