#
# Author:: Deepali Jagtap (<deepali.jagtap@clogeny.com>)
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
require "chef-utils/dist" unless defined?(ChefUtils::Dist)

class Chef
  class Resource
    class BffPackage < Chef::Resource::Package

      provides :bff_package, target_mode: true
      target_mode support: :full

      description "Use the **bff_package** resource to manage packages for the AIX platform using the installp utility. When a package is installed from a local file, it must be added to the node using the **remote_file** or **cookbook_file** resources."
      introduced "12.0"
      examples <<~DOC
      The **bff_package** resource is the default package provider on the AIX platform. The base **package** resource may be used, and then when the platform is AIX, #{ChefUtils::Dist::Infra::PRODUCT} will identify the correct package provider. The following examples show how to install part of the IBM XL C/C++ compiler.

      **Installing using the base package resource**

      ```ruby
      package 'xlccmp.13.1.0' do
        source '/var/tmp/IBM_XL_C_13.1.0/usr/sys/inst.images/xlccmp.13.1.0'
        action :install
      end
      ```

      **Installing using the bff_package resource**

      ```ruby
      bff_package 'xlccmp.13.1.0' do
        source '/var/tmp/IBM_XL_C_13.1.0/usr/sys/inst.images/xlccmp.13.1.0'
        action :install
      end
      ```
      DOC

      property :package_name, String,
        description: "An optional property to set the package name if it differs from the resource block's name.",
        identity: true

      property :version, String,
        description: "The version of a package to be installed or upgraded."
    end
  end
end
