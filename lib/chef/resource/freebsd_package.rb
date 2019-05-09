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

require_relative "package"
require_relative "../provider/package/freebsd/port"
require_relative "../provider/package/freebsd/pkgng"
require_relative "../mixin/shell_out"

class Chef
  class Resource
    class FreebsdPackage < Chef::Resource::Package
      include Chef::Mixin::ShellOut

      resource_name :freebsd_package
      provides :package, platform: "freebsd"

      description "Use the freebsd_package resource to manage packages for the FreeBSD platform."

      # make sure we assign the appropriate underlying providers based on what
      # package managers exist on this FreeBSD system or the source of the package
      #
      # @return [void]
      def after_created
        assign_provider
      end

      private

      def assign_provider
        @provider = if source.to_s =~ /^ports$/i
                      Chef::Provider::Package::Freebsd::Port
                    else
                      Chef::Provider::Package::Freebsd::Pkgng
                    end
      end
    end
  end
end
