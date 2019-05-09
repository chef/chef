#
# Author:: Nate Walck (<nate.walck@gmail.com>)
# Copyright:: Copyright 2015-2016, Facebook, Inc.
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

require_relative "../resource"

class Chef
  class Resource
    class OsxProfile < Chef::Resource
      resource_name :osx_profile
      provides :osx_profile
      provides :osx_config_profile

      description "Use the osx_profile resource to manage configuration profiles (.mobileconfig files) on the macOS platform. The osx_profile resource installs profiles by using the uuidgen library to generate a unique ProfileUUID, and then using the profiles command to install the profile on the system."
      introduced "12.7"

      default_action :install
      allowed_actions :install, :remove

      property :profile_name, String,
               description: "Use to specify the name of the profile, if different from the name of the resource block.",
               name_property: true, identity: true

      property :profile, [ String, Hash ],
               description: "Use to specify a profile. This may be the name of a profile contained in a cookbook or a Hash that contains the contents of the profile."

      property :identifier, String,
               description: "Use to specify the identifier for the profile, such as com.company.screensaver."

      property :path, String,
               description: "The path to write the profile to disk before loading it."
    end
  end
end
