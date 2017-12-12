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

require "chef/mixin/which"
require "chef/mixin/shell_out"
require "chef/provider/package/yum/version"
require "timeout"

class Chef
  class Provider
    class Package
      class Yum < Chef::Provider::Package
        class PythonHelper
          include Singleton
          include Chef::Mixin::Which
          include Chef::Mixin::ShellOut

          attr_accessor :stdin
          attr_accessor :stdout
          attr_accessor :stderr
          attr_accessor :inpipe
          attr_accessor :outpipe
          attr_accessor :wait_thr

          YUM_HELPER = ::File.expand_path(::File.join(::File.dirname(__FILE__), "yum_helper.py")).freeze

          def yum_command
            @yum_command ||= which("python", "python2", "python2.7") do |f|
              shell_out("#{f} -c 'import yum'").exitstatus == 0
            end + " #{YUM_HELPER}"
          end

          def start
            ENV["PYTHONUNBUFFERED"] = "1"
            @inpipe, inpipe_write = IO.pipe
            outpipe_read, @outpipe = IO.pipe
            @stdin, @stdout, @stderr, @wait_thr = Open3.popen3("#{yum_command} #{outpipe_read.fileno} #{inpipe_write.fileno}", outpipe_read.fileno => outpipe_read, inpipe_write.fileno => inpipe_write, close_others: false)
            outpipe_read.close
            inpipe_write.close
          end

          def reap
            unless wait_thr.nil?
              Process.kill("INT", wait_thr.pid) rescue nil
              begin
                Timeout.timeout(3) do
                  wait_thr.value # this calls waitpid()
                end
              rescue Timeout::Error
                Process.kill("KILL", wait_thr.pid) rescue nil
              end
              stdin.close unless stdin.nil?
              stdout.close unless stdout.nil?
              stderr.close unless stderr.nil?
              inpipe.close unless inpipe.nil?
              outpipe.close unless outpipe.nil?
            end
          end

          def check
            start if stdin.nil?
          end

          def compare_versions(version1, version2)
            query("versioncompare", { "versions" => [version1, version2] }).to_i
          end

          def install_only_packages(name)
            query_output = query("installonlypkgs", { "package" => name })
            if query_output == "False"
              return false
            elsif query_output == "True"
              return true
            end
          end

          def options_params(options)
            options.each_with_object({}) do |opt, h|
              if opt =~ /--enablerepo=(.+)/
                $1.split(",").each do |repo|
                  h["enablerepos"] ||= []
                  h["enablerepos"].push(repo)
                end
              end
              if opt =~ /--disablerepo=(.+)/
                $1.split(",").each do |repo|
                  h["disablerepos"] ||= []
                  h["disablerepos"].push(repo)
                end
              end
            end
          end

          # @returns Array<Version>
          def package_query(action, provides, version = nil, arch = nil, options = nil)
            parameters = { "provides" => provides, "version" => version, "arch" => arch }
            repo_opts = options_params(options || {})
            parameters.merge!(repo_opts)
            query_output = query(action, parameters)
            version = parse_response(query_output.lines.last)
            Chef::Log.debug "parsed #{version} from python helper"
            # XXX: for now we restart after every query with an enablerepo/disablerepo to clean the helpers internal state
            restart unless repo_opts.empty?
            version
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

          def query(action, parameters)
            with_helper do
              json = build_query(action, parameters)
              Chef::Log.debug "sending '#{json}' to python helper"
              outpipe.syswrite json + "\n"
              output = inpipe.sysread(4096).chomp
              Chef::Log.debug "got '#{output}' from python helper"
              return output
            end
          end

          def build_query(action, parameters)
            hash = { "action" => action }
            parameters.each do |param_name, param_value|
              hash[param_name] = param_value unless param_value.nil?
            end

            # Special handling for certain action / param combos
            if [:whatinstalled, :whatavailable].include?(action)
              add_version(hash, parameters["version"]) unless parameters["version"].nil?
            end

            FFI_Yajl::Encoder.encode(hash)
          end

          def parse_response(output)
            array = output.split.map { |x| x == "nil" ? nil : x }
            array.each_slice(3).map { |x| Version.new(*x) }.first
          end

          def drain_fds
            output = ""
            fds, = IO.select([stderr, stdout, inpipe], nil, nil, 0)
            unless fds.nil?
              fds.each do |fd|
                output += fd.sysread(4096) rescue ""
              end
            end
            output
          rescue => e
            output
          end

          def with_helper
            max_retries ||= 5
            ret = nil
            Timeout.timeout(600) do
              check
              ret = yield
            end
            output = drain_fds
            unless output.empty?
              Chef::Log.debug "discarding output on stderr/stdout from python helper: #{output}"
            end
            ret
          rescue EOFError, Errno::EPIPE, Timeout::Error, Errno::ESRCH => e
            output = drain_fds
            if ( max_retries -= 1 ) > 0
              unless output.empty?
                Chef::Log.debug "discarding output on stderr/stdout from python helper: #{output}"
              end
              restart
              retry
            else
              raise e if output.empty?
              raise "yum-helper.py had stderr/stdout output:\n\n#{output}"
            end
          end
        end
      end
    end
  end
end
