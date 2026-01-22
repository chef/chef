#
# Author:: S.Cavallo (<smcavallo@hotmail.com>)
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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

require_relative "package"

class Chef
  class Resource
    class SnapPackage < Chef::Resource::Package

      provides :snap_package, target_mode: true
      target_mode support: :full

      description "Use the **snap_package** resource to manage snap packages on supported Linux distributions."
      introduced "15.0"
      examples <<~DOC
      **Install a package**

      ```ruby
      snap_package 'hello'
      ```

      **Upgrade a package**

      ```ruby
      snap_package 'hello' do
        action :upgrade
      end
      ```

      **Install a package from a specific channel track**

      ```ruby
      snap_package 'firefox' do
        channel 'esr/stable'
        action :upgrade
      end
      ```

      **Install a package with classic confinement**

      ```ruby
      snap_package 'hello' do
        options 'classic'
      end
      ```
      DOC

      allowed_actions :install, :upgrade, :remove, :purge

      property :channel, [String, nil],
        description: "The desired channel. For example: `latest/stable`. `latest/beta/fix-test-062`, or `0.x/edge`. If nil, the resource will install the snap's default version. See <https://snapcraft.io/docs/channels>.",
        default: "latest/stable",
        desired_state: false
    end
  end
end
