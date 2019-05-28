#
# Author:: Nuo Yan (<nuo@chef.io>)
# Author:: Tim Hinderliter (<tim@chef.io>)
# Copyright:: Copyright 2010-2019, Chef Software Inc.
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
require_relative "supermarket_share"
require_relative "../dist"

class Chef
  class Knife
    class CookbookSiteShare < Knife::SupermarketShare

      # Handle the subclassing (knife doesn't do this :()
      dependency_loaders.concat(superclass.dependency_loaders)

      banner "knife cookbook site share COOKBOOK [CATEGORY] (options)"
      category "deprecated"

      def run
        Chef::Log.warn("knife cookbook site share has been deprecated in favor of knife supermarket share. In #{Chef::Dist::PRODUCT} 16 (April 2020) this will result in an error!")
        super
      end

    end
  end
end
