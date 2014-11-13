#
# Authors:: AJ Christensen (<aj@opscode.com>)
#           Richard Manyanza (<liseki@nyikacraftsmen.com>)
#           Scott Bonds (<scott@ggr.com>)
# Copyright:: Copyright (c) 2008 Opscode, Inc.
# Copyright:: Copyright (c) 2014 Richard Manyanza, Scott Bonds
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

require 'chef/resource/package'
require 'chef/provider/package/openbsd'
require 'chef/mixin/shell_out'

class Chef
  class Resource
    class OpenbsdPackage < Chef::Resource::Package
      include Chef::Mixin::ShellOut

      provides :package, os: "openbsd"

      def initialize(name, run_context=nil)
        super
        @resource_name = :openbsd_package
      end

      def after_created
        assign_provider
      end

      private

      def assign_provider
        @provider = Chef::Provider::Package::Openbsd
      end

    end
  end
end

