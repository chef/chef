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

require "chef/resource"

class Chef
  class Resource
    # Use the osx_profile resource to manage configuration profiles (.mobileconfig files)
    # on the macOS platform. The osx_profile resource installs profiles by using
    # the uuidgen library to generate a unique ProfileUUID, and then using the
    # profiles command to install the profile on the system.
    #
    # @since 12.7
    class OsxProfile < Chef::Resource
      provides :osx_profile, os: "darwin"
      provides :osx_config_profile, os: "darwin"

      identity_attr :profile_name

      default_action :install
      allowed_actions :install, :remove

      property :profile_name, String, name_property: true
      property :profile, [ String, Hash ]
      property :identifier, String
      property :path, String
    end
  end
end
