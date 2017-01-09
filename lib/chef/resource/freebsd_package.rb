#
# Authors:: AJ Christensen (<aj@chef.io>)
#           Richard Manyanza (<liseki@nyikacraftsmen.com>)
# Copyright:: Copyright 2008-2016, Chef Software Inc.
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

require "chef/resource/package"
require "chef/provider/package/freebsd/port"
require "chef/provider/package/freebsd/pkg"
require "chef/provider/package/freebsd/pkgng"
require "chef/mixin/shell_out"

class Chef
  class Resource
    class FreebsdPackage < Chef::Resource::Package
      include Chef::Mixin::ShellOut

      resource_name :freebsd_package
      provides :package, platform: "freebsd"

      def after_created
        assign_provider
      end

      def supports_pkgng?
        ships_with_pkgng? || !!shell_out_compact!("make", "-V", "WITH_PKGNG", :env => nil).stdout.match(/yes/i)
      end

      private

      def ships_with_pkgng?
        # It was not until __FreeBSD_version 1000017 that pkgng became
        # the default binary package manager. See '/usr/ports/Mk/bsd.port.mk'.
        node[:os_version].to_i >= 1000017
      end

      def assign_provider
        @provider = if source.to_s =~ /^ports$/i
                      Chef::Provider::Package::Freebsd::Port
                    elsif supports_pkgng?
                      Chef::Provider::Package::Freebsd::Pkgng
                    else
                      Chef::Provider::Package::Freebsd::Pkg
                    end
      end
    end
  end
end
