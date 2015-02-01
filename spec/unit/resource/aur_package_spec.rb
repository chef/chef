#
# Author:: Ryan Chipman (<rchipman@mit.edu>)
# Copyright:: Copyright (c) 2015 Ryan Chipman
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

require 'spec_helper'
require 'support/shared/unit/resource/static_provider_resolution'

describe Chef::Resource::AURPackage, "initialize" do

  static_provider_resolution(
    resource: Chef::Resource::AURPackage,
    provider: Chef::Provider::Package::AUR,
    name: :aur_package,
    action: :install,
    os: "linux",
  )

end
