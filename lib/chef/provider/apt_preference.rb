#
# Author:: Tim Smith (<tsmith@chef.io>)
# Copyright:: Copyright (c) 2016 Chef Software, Inc.
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
require "chef/dsl/declare_resource"
require "chef/mixin/which"
require "chef/provider/noop"
require "chef/log"

class Chef
  class Provider
    class AptPreference < Chef::Provider
      use_inline_resources

      extend Chef::Mixin::Which

      provides :apt_preference do
        which("apt-get")
      end

      def whyrun_supported?
        true
      end

      def load_current_resource
      end

      action :add do
        preference = build_pref(
          new_resource.glob || new_resource.package_name,
          new_resource.pin,
          new_resource.pin_priority
        )

        declare_resource(:directory, "/etc/apt/preferences.d") do
          owner "root"
          group "root"
          mode "0755"
          recursive true
          action :create
        end

        name = safe_name(new_resource.name)

        declare_resource(:file, "/etc/apt/preferences.d/#{new_resource.name}.pref") do
          action :delete
          if ::File.exist?("/etc/apt/preferences.d/#{new_resource.name}.pref")
            Chef::Log.warn "Replacing #{new_resource.name}.pref with #{name}.pref in /etc/apt/preferences.d/"
          end
          only_if { name != new_resource.name }
        end

        declare_resource(:file, "/etc/apt/preferences.d/#{new_resource.name}") do
          action :delete
          if ::File.exist?("/etc/apt/preferences.d/#{new_resource.name}")
            Chef::Log.warn "Replacing #{new_resource.name} with #{new_resource.name}.pref in /etc/apt/preferences.d/"
          end
        end

        declare_resource(:file, "/etc/apt/preferences.d/#{name}.pref") do
          owner "root"
          group "root"
          mode "0644"
          content preference
          action :create
        end
      end

      action :delete do
        name = safe_name(new_resource.name)
        if ::File.exist?("/etc/apt/preferences.d/#{name}.pref")
          Chef::Log.info "Un-pinning #{name} from /etc/apt/preferences.d/"
          declare_resource(:file, "/etc/apt/preferences.d/#{name}.pref") do
            action :delete
          end
        end
      end
    end

    # Build preferences.d file contents
    def build_pref(package_name, pin, pin_priority)
      "Package: #{package_name}\nPin: #{pin}\nPin-Priority: #{pin_priority}\n"
    end

    def safe_name(name)
      name.tr(".", "_").gsub("*", "wildcard")
    end
  end
end

Chef::Provider::Noop.provides :apt_preference
