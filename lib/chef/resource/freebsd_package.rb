#
# Authors:: AJ Christensen (<aj@chef.io>)
#           Richard Manyanza (<liseki@nyikacraftsmen.com>)
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
# Copyright:: Copyright 2014-2016, Richard Manyanza.
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
require_relative "../provider/package/freebsd/port"
require_relative "../provider/package/freebsd/pkgng"

class Chef
  class Resource
    class FreebsdPackage < Chef::Resource::Package
      provides :freebsd_package, target_mode: true
      provides :package, platform: "freebsd", target_mode: true
      target_mode support: :full

      description "Use the **freebsd_package** resource to manage packages for the FreeBSD platform."

      allowed_actions :install, :remove

      # make sure we assign the appropriate underlying providers based on what
      # package managers exist on this FreeBSD system or the source of the package
      #
      # @return [void]
      def after_created
        assign_provider
      end

      private

      def assign_provider
        @provider = if /^ports$/i.match?(source.to_s)
                      Chef::Provider::Package::Freebsd::Port
                    else
                      Chef::Provider::Package::Freebsd::Pkgng
                    end
      end
    end
  end
end
