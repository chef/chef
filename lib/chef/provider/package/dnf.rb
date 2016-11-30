# Copyright:: Copyright 2016, Chef Software, Inc.
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

require "chef/provider/package"
require "chef/resource/dnf_package"
require "chef/mixin/which"
require "timeout"

class Chef
  class Provider
    class Package
      class Dnf < Chef::Provider::Package
        extend Chef::Mixin::Which

        class Version
          attr_accessor :name
          attr_accessor :version
          attr_accessor :arch

          def initialize(name, version, arch)
            @name = name
            @version = ( version == "nil" ) ? nil : version
            @arch = ( arch == "nil" ) ? nil : arch
          end

          def to_s
            "#{name}-#{version}.#{arch}"
          end

          def version_with_arch
            "#{version}.#{arch}" unless version.nil?
          end

          def matches_name_and_arch?(other)
            other.version == version && other.arch == arch
          end
        end

        attr_accessor :python_helper

        class PythonHelper
          include Singleton
          extend Chef::Mixin::Which

          attr_accessor :stdin
          attr_accessor :stdout
          attr_accessor :stderr
          attr_accessor :wait_thr

          DNF_HELPER = ::File.expand_path(::File.join(::File.dirname(__FILE__), "dnf_helper.py")).freeze
          DNF_COMMAND = "#{which("python3")} #{DNF_HELPER}"

          def start
            ENV["PYTHONUNBUFFERED"] = "1"
            @stdin, @stdout, @stderr, @wait_thr = Open3.popen3(DNF_COMMAND)
          end

          def reap
            unless wait_thr.nil?
              Process.kill("KILL", wait_thr.pid)
              stdin.close unless stdin.nil?
              stdout.close unless stdout.nil?
              stderr.close unless stderr.nil?
              wait_thr.value
            end
          end

          def check
            start if stdin.nil?
          end

          # @returns Array<Version>
          def whatinstalled(provides, version = nil, arch = nil)
            with_helper do
              hash = { "action" => "whatinstalled" }
              hash["provides"] = provides
              hash["version"] = version unless version.nil?
              hash["arch" ] = arch unless arch.nil?
              json = FFI_Yajl::Encoder.encode(hash)
              puts json
              stdin.syswrite json + "\n"
              output = stdout.sysread(4096)
              puts output
              output.split.each_slice(3).map { |x| Version.new(*x) }.first
            end
          end

          # @returns Array<Version>
          def whatavailable(provides, version = nil, arch = nil)
            with_helper do
              hash = { "action" => "whatavailable" }
              hash["provides"] = provides
              hash["version"] = version unless version.nil?
              hash["arch" ] = arch unless arch.nil?
              json = FFI_Yajl::Encoder.encode(hash)
              puts json
              stdin.syswrite json + "\n"
              output = stdout.sysread(4096)
              puts output
              output.split.each_slice(3).map { |x| Version.new(*x) }.first
            end
          end

          def flushcache
            restart # FIXME: make flushcache work + not leak memory
          end

          def restart
            reap
            start
          end

          def with_helper
            max_retries ||= 5
            Timeout.timeout(60) do
              check
              yield
            end
          rescue EOFError, Errno::EPIPE, Timeout::Error, Errno::ESRCH => e
            raise e unless ( max_retries -= 1 ) > 0
            restart
            retry
          end
        end

        use_multipackage_api

        provides :package, platform_family: %w{rhel fedora} do
          which("dnf")
        end

        provides :dnf_package, os: "linux"

        def python_helper
          @python_helper ||= PythonHelper.instance
        end

        def load_current_resource
          @current_resource = Chef::Resource::DnfPackage.new(new_resource.name)
          current_resource.package_name(new_resource.package_name)

          current_resource.version(get_current_versions)

          current_resource
        end

        def candidate_version
          package_name_array.map do |pkg|
            available_version(pkg).version_with_arch
          end
        end

        def get_current_versions
          package_name_array.map do |pkg|
            installed_version(pkg).version_with_arch
          end
        end

        def install_package(names, versions)
          resolved_names = names.map { |name| available_version(name).to_s }
          dnf(new_resource.options, "-y install", resolved_names)
          flushcache
        end

        # dnf upgrade does not work on uninstalled packaged, while install will upgrade
        alias_method :upgrade_package, :install_package

        def remove_package(names, versions)
          resolved_names = names.map { |name| installed_version(name).to_s }
          dnf(new_resource.options, "-y remove", resolved_names)
          flushcache
        end

        alias_method :purge_package, :remove_package

        action :flush_cache do
          python_helper.flushcache
        end

        private

        # @returns Array<Version>
        def available_version(package_name)
          @available_version ||= {}
          @available_version[package_name] ||= python_helper.whatavailable(package_name, desired_name_versions[package_name], desired_name_archs[package_name])
          @available_version[package_name]
        end

        # @returns Array<Version>
        def installed_version(package_name)
          @installed_version ||= {}
          @installed_version[package_name] ||= python_helper.whatinstalled(package_name, desired_name_versions[package_name], desired_name_archs[package_name])
          @installed_version[package_name]
        end

        def flushcache
          python_helper.flushcache
        end

        def dnf(*args)
          shell_out_with_timeout!(a_to_s("dnf", *args))
        end

      end
    end
  end
end
