#
# Copyright:: Copyright 2016-2017, Chef Software Inc.
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

require_relative "../../../mixin/which"
require_relative "../../../mixin/shell_out"
require_relative "version"
require "timeout" unless defined?(Timeout)

class Chef
  class Provider
    class Package
      class Dnf < Chef::Provider::Package
        class PythonHelper
          include Singleton
          include Chef::Mixin::Which
          include Chef::Mixin::ShellOut

          attr_accessor :stdin
          attr_accessor :stdout
          attr_accessor :stderr
          attr_accessor :wait_thr

          DNF_HELPER = ::File.expand_path(::File.join(::File.dirname(__FILE__), "dnf_helper.py")).freeze

          def dnf_command
            # platform-python is used for system tools on RHEL 8 and is installed under /usr/libexec
            @dnf_command ||= which("platform-python", "python", "python3", "python2", "python2.7", extra_path: "/usr/libexec") do |f|
              shell_out("#{f} -c 'import dnf'").exitstatus == 0
            end + " #{DNF_HELPER}"
          end

          def start
            ENV["PYTHONUNBUFFERED"] = "1"
            @stdin, @stdout, @stderr, @wait_thr = Open3.popen3(dnf_command)
          end

          def reap
            unless wait_thr.nil?
              Process.kill("KILL", wait_thr.pid) rescue nil
              stdin.close unless stdin.nil?
              stdout.close unless stdout.nil?
              stderr.close unless stderr.nil?
              wait_thr.value # this calls waitpit()
            end
          end

          def check
            start if stdin.nil?
          end

          def compare_versions(version1, version2)
            with_helper do
              json = build_version_query("versioncompare", [version1, version2])
              Chef::Log.trace "sending '#{json}' to python helper"
              stdin.syswrite json + "\n"
              stdout.sysread(4096).chomp.to_i
            end
          end

          # @return Array<Version>
          def query(action, provides, version = nil, arch = nil)
            with_helper do
              json = build_query(action, provides, version, arch)
              Chef::Log.trace "sending '#{json}' to python helper"
              stdin.syswrite json + "\n"
              output = stdout.sysread(4096).chomp
              Chef::Log.trace "got '#{output}' from python helper"
              version = parse_response(output)
              Chef::Log.trace "parsed #{version} from python helper"
              version
            end
          end

          def restart
            reap
            start
          end

          private

          # i couldn't figure out how to decompose an evr on the python side, it seems reasonably
          # painless to do it in ruby (generally massaging nevras in the ruby side is HIGHLY
          # discouraged -- this is an "every rule has an exception" exception -- any additional
          # functionality should probably trigger moving this regexp logic into python)
          def add_version(hash, version)
            epoch = nil
            if version =~ /(\S+):(\S+)/
              epoch = $1
              version = $2
            end
            if version =~ /(\S+)-(\S+)/
              version = $1
              release = $2
            end
            hash["epoch"] = epoch unless epoch.nil?
            hash["release"] = release unless release.nil?
            hash["version"] = version
          end

          def build_query(action, provides, version, arch)
            hash = { "action" => action }
            hash["provides"] = provides
            add_version(hash, version) unless version.nil?
            hash["arch" ] = arch unless arch.nil?
            FFI_Yajl::Encoder.encode(hash)
          end

          def build_version_query(action, versions)
            hash = { "action" => action }
            hash["versions"] = versions
            FFI_Yajl::Encoder.encode(hash)
          end

          def parse_response(output)
            array = output.split.map { |x| x == "nil" ? nil : x }
            array.each_slice(3).map { |x| Version.new(*x) }.first
          end

          def drain_stderr
            output = ""
            output += stderr.sysread(4096).chomp until IO.select([stderr], nil, nil, 0).nil?
            output
          rescue
            # we must rescue EOFError, and we don't much care about errors on stderr anyway
            output
          end

          def with_helper
            max_retries ||= 5
            ret = nil
            Timeout.timeout(600) do
              check
              ret = yield
            end
            output = drain_stderr
            unless output.empty?
              Chef::Log.trace "discarding output on stderr from python helper: #{output}"
            end
            ret
          rescue EOFError, Errno::EPIPE, Timeout::Error, Errno::ESRCH => e
            output = drain_stderr
            if ( max_retries -= 1 ) > 0
              unless output.empty?
                Chef::Log.trace "discarding output on stderr from python helper: #{output}"
              end
              restart
              retry
            else
              raise e if output.empty?
              raise "dnf-helper.py had stderr output:\n\n#{output}"
            end
          end
        end
      end
    end
  end
end
