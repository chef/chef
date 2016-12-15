#
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

require "chef/provider/package/dnf/version"
require "timeout"

class Chef
  class Provider
    class Package
      class Dnf < Chef::Provider::Package
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

          # i couldn't figure out how to decompose an evr on the python side, it seems reasonably
          # painless to do it in ruby (generally massaging nevras in the ruby side is HIGHLY
          # discouraged -- this is an "every rule has an exception" exception -- any additional
          # functionality should probably trigger moving this regexp logic into python)
          def add_version(hash, version)
            epoch = nil
            if version =~ /(\S+):(\S+)/
              epoch, version = $1, $2
            end
            if version =~ /(\S+)-(\S+)/
              version, release = $1, $2
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

          def parse_response(output)
            array = output.split.map { |x| x == "nil" ? nil : x }
            array.each_slice(3).map { |x| Version.new(*x) }.first
          end

          # @returns Array<Version>
          def query(action, provides, version = nil, arch = nil)
            with_helper do
              json = build_query(action, provides, version, arch)
              stdin.syswrite json + "\n"
              output = stdout.sysread(4096)
              version = parse_response(output)
              version
            end
          end

          def flushcache
            restart # FIXME: make flushcache work + not leak memory
          end

          def flushcache_installed
            restart # FIXME: make flushcache work + not leak memory
          end

          def restart
            reap
            start
          end

          def with_helper
            max_retries ||= 5
            Timeout.timeout(600) do
              check
              yield
            end
          rescue EOFError, Errno::EPIPE, Timeout::Error, Errno::ESRCH => e
            raise e unless ( max_retries -= 1 ) > 0
            restart
            retry
          end
        end
      end
    end
  end
end
