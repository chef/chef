#
# Author:: Steven Danna (<steve@chef.io>)
# Copyright:: Copyright 2011-2016 Chef Software, Inc.
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
require_relative "../mixin/root_rest"

module Opc
  class OpcOrgDelete < Chef::Knife
    category "CHEF ORGANIZATION MANAGEMENT"
    banner "knife opc org delete ORG_NAME"

    include Chef::Mixin::RootRestv0

    def run
      org_name = @name_args[0]
      ui.confirm "Do you want to delete the organization #{org_name}"
      ui.output root_rest.delete("organizations/#{org_name}")
    end
  end
end
