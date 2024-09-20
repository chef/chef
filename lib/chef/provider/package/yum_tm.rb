#
# Copyright:: Copyright (c) Chef Software Inc.
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

require_relative "yum"

class Chef
  class Provider
    class Package
      class YumTM < Chef::Provider::Package::Yum
        provides :package, platform_family: "fedora_derived", target_mode: true, agent_mode: false
        provides :yum_package, target_mode: true, agent_mode: false

        def install_package(names, versions)
          if new_resource.source
            yum(options, "-y", "install", new_resource.source)
          else
            yum(options, "-y", "install", names)
          end
          flushcache
        end

        # remove_package just uses yum commands and is Target Mode compatible
        def remove_package(names, versions)
          yum(options, "-y", "remove", names)
        end

        def get_current_versions
          package_name_array.each.map do |pkg, i|
            cmd = shell_out("rpm -q --queryformat='%{VERSION}' #{pkg}")
            cmd.exitstatus == 1 ? nil : cmd.stdout
          end
        end

        # Redirect any agent mode yum implementation calls to python helper to this class
        def python_helper
          self
        end

        def flushcache
          yum("clean", "all")
        end

        # Reuse base implementation, not the one from agent-mode yum_package
        def version_equals?(v1, v2)
          return false unless v1 && v2

          v1 == v2
        end

        # Perform package query via shell commands only
        def package_query(action, provides, arch: nil, version: nil, options: {})
          if action == :whatinstalled
            cmdline = "rpm -q --queryformat='%{VERSION} %{ARCH}' #{provides}"

            cmd = shell_out(cmdline)
            return nil if cmd.exitstatus != 0

            Chef::Provider::Package::Yum::Version.new(
              provides,
              cmd.stdout.split[0],
              cmd.stdout.split[1]
            )
          else
            logger.info("Retrieving package information from repository server (please wait)...")

            cmdline = "yum info #{provides}"
            cmdline += "-#{version} " unless version.nil?
            cmdline += " --forcearch=#{arch} " unless arch.nil?

            cmd = shell_out(cmdline)
            if cmd.exitstatus != 0
              raise Chef::Exceptions::Package, "#{new_resource.package_name} caused a repository error: #{cmd.stderr}"
            else
              Chef::Provider::Package::Yum::Version.new(
                provides,
                cmd.stdout.match(/^Version +: (.+)$/)[1],
                cmd.stdout.match(/^Architecture +: (.+)$/)[1]
              )
            end
          end
        end

        def yum_binary
          @yum_binary ||=
            begin
              yum_binary = new_resource.yum_binary if new_resource.is_a?(Chef::Resource::YumPackage)
              yum_binary ||= ::TargetIO::File.exist?("/usr/bin/yum-deprecated") ? "yum-deprecated" : "yum"
            end
        end
      end
    end
  end
end
