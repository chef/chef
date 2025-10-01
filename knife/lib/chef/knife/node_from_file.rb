#
# Author:: Adam Jacob (<adam@chef.io>)
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

require_relative "../knife"

class Chef
  class Knife
    class NodeFromFile < Knife

      deps do
        require "chef/node" unless defined?(Chef::Node)
        require "chef/json_compat" unless defined?(Chef::JSONCompat)
        require_relative "core/object_loader"
      end

      banner "knife node from file FILE (options)"

      def loader
        @loader ||= Knife::Core::ObjectLoader.new(Chef::Node, ui)
      end

      def run
        @name_args.each do |arg|
          updated = loader.load_from("nodes", arg)

          updated.save

          output(format_for_display(updated)) if config[:print_after]

          ui.info("Updated Node #{updated.name}")
        end
      end

    end
  end
end
