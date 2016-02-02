#
# Author:: Vasiliy Tolstov (<v.tolstov@selfip.ru>)
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

require "chef/resource/package"
require "chef/provider/package/paludis"

class Chef
  class Resource
    class PaludisPackage < Chef::Resource::Package
      resource_name :paludis_package
      provides :paludis_package, os: "linux"

      allowed_actions :install, :remove, :upgrade

      property :timeout, default: 3600
    end
  end
end
