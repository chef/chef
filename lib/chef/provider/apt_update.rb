#
# Author:: Thom May (<thom@chef.io>)
# Copyright:: Copyright (c) 2016-2017, Chef Software Inc.
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

require "chef/provider"
require "chef/provider/noop"
require "chef/mixin/which"

class Chef
  class Provider
    class AptUpdate < Chef::Provider
      extend Chef::Mixin::Which

      provides :apt_update do
        which("apt-get")
      end

      APT_CONF_DIR = "/etc/apt/apt.conf.d"
      STAMP_DIR = "/var/lib/apt/periodic"

      def load_current_resource
      end

      action :periodic do
        if !apt_up_to_date?
          converge_by "update new lists of packages" do
            do_update
          end
        end
      end

      action :update do
        converge_by "force update new lists of packages" do
          do_update
        end
      end

      private

      # Determines whether we need to run `apt-get update`
      #
      # @return [Boolean]
      def apt_up_to_date?
        ::File.exist?("#{STAMP_DIR}/update-success-stamp") &&
          ::File.mtime("#{STAMP_DIR}/update-success-stamp") > Time.now - new_resource.frequency
      end

      def do_update
        [STAMP_DIR, APT_CONF_DIR].each do |d|
          declare_resource(:directory, d) do
            recursive true
          end
        end

        declare_resource(:file, "#{APT_CONF_DIR}/15update-stamp") do
          content "APT::Update::Post-Invoke-Success {\"touch #{STAMP_DIR}/update-success-stamp 2>/dev/null || true\";};\n"
          action :create_if_missing
        end

        declare_resource(:execute, "apt-get -q update")
      end

    end
  end
end

Chef::Provider::Noop.provides :apt_update
