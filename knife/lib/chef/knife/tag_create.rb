#
# Contributed by: Ryan Davis (<ryand-ruby@zenspider.com>)
# Contributed by: Daniel DeLeo (<dan@chef.io>)
# Contributed by: Nuo Yan (<nuo@chef.io>)
# Copyright © 2008-2025 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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
    class TagCreate < Knife

      deps do
        require "chef/node" unless defined?(Chef::Node)
      end

      banner "knife tag create NODE TAG ..."

      def run
        name = @name_args[0]
        tags = @name_args[1..]

        if name.nil? || tags.nil? || tags.empty?
          show_usage
          ui.fatal("You must specify a node name and at least one tag.")
          exit 1
        end

        node = Chef::Node.load name
        tags.each do |tag|
          (node.tags << tag).uniq!
        end
        node.save
        ui.info("Created tags #{tags.join(", ")} for node #{name}.")
      end
    end
  end
end
