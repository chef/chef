#
# Author:: Christopher Webber (<cwebber@chef.io>)
# Copyright:: Copyright (c) 2014 Chef Software, Inc.
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
require "chef/knife/cookbook_site_show"

class Chef
  class Knife
    class SupermarketShow < Knife::CookbookSiteShow
      # Handle the subclassing (knife doesn't do this :()
      dependency_loaders.concat(superclass.dependency_loaders)
      options.merge!(superclass.options)

      banner "knife supermarket show COOKBOOK [VERSION] (options)"
      category "supermarket"
    end
  end
end
