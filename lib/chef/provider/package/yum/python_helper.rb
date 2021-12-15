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

require_relative "../../../mixin/which"
require_relative "../../../mixin/shell_out"
require_relative "version"
require "singleton" unless defined?(Singleton)
require "timeout" unless defined?(Timeout)

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
            @yum_command ||= begin
              cmd = which("platform-python", "python", "python2", "python2.7", extra_path: "/usr/libexec") do |f|
                shell_out("#{f} -c 'import yum'").exitstatus == 0
              end
              raise Chef::Exceptions::Package, "cannot find yum libraries, you may need to use dnf_package" unless cmd

              "#{cmd} #{YUM_HELPER}"
            end
          end

          def start
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
              @stdin = @stdout = @stderr = @inpipe = @outpipe = @wait_thr = nil
            end
          end

          def check
            start if stdin.nil?
          end

          def close_rpmdb
            query("close_rpmdb", {})
          end

          def compare_versions(version1, version2)
            query("versioncompare", { "versions" => [version1, version2] }).to_i
          end

          def install_only_packages(name)
            query_output = query("installonlypkgs", { "package" => name })
            if query_output == "False"
              false
            elsif query_output == "True"
              true
            end
          end

          def options_params(options)
            options.each_with_object({}) do |opt, h|
              if opt =~ /--enablerepo=(.+)/
                $1.split(",").each do |repo|
                  h["repos"] ||= []
                  h["repos"].push( { "enable" => repo } )
                end
              end
              if opt =~ /--disablerepo=(.+)/
                $1.split(",").each do |repo|
                  h["repos"] ||= []
                  h["repos"].push( { "disable" => repo } )
                end
              end
            end
          end

          def is_arch?(arch)
            # cspell:disable-next
            arches = %w{alpha alphaev4 alphaev45 alphaev5 alphaev56 alphaev6 alphaev67 alphaev68 alphaev7 alphapca56 amd64 armv5tejl armv5tel armv6l armv7l athlon geode i386 i486 i586 i686 ia32e ia64 noarch ppc ppc64 ppc64iseries ppc64pseries s390 s390x sh3 sh4 sh4a sparc sparc64 sparc64v sparcv8 sparcv9 sparcv9v x86_64}
            arches.include?(arch)
          end

          # We have a provides line with an epoch in it and yum cannot parse that, so we
          # need to deconstruct the args.  This doesn't support splats which is why we
          # only do it for this particularly narrow use case.
          #
          # name-epoch:version
          # name-epoch:version.arch
          # name-epoch:version-release
          # name-epoch:version-release.arch
          #
          # @api private
          def deconstruct_args(provides)
            raise "provides must have an epoch in the version to deconstruct" unless provides =~ /^(\S+)-(\d+):(\S+)/

            name = $1
            epoch = $2
            other = $3
            ret = { "provides" => name, "epoch" => epoch }
            maybe_arch = other.rpartition(".").last
            arch = if is_arch?(maybe_arch)
                     other.delete_suffix!(".#{maybe_arch}")
                     maybe_arch
                   end
            ret.merge!({ "arch" => arch }) if arch
            (version, _, release) = other.rpartition("-")
            if version.empty?
              ret.merge!({ "version" => release }) # yeah, rpartition is just weird
            else
              ret.merge!({ "version" => version, "release" => release })
            end
          end

          # In the default case for the yum provider we now do terrible things with ruby
          # to concatenate all the properties together to form a single string to feed to
          # the python which favors using returnPackages/searchProvides over the
          # searchNevra API.  That means that these two different ways of constructing the
          # resource are now perfectly identical:
          #
          # yum_package "zabbix-agent-4.0.15-1.fc31.x86_64"
          #
          # yum_package "zabbix-agent" do
          #   version "4.0.15-1.fc31"
          #   arch "x86_64"
          # end
          #
          # This function handles turning the second form into the first form.
          #
          # In the case where the epoch is given in the version and we do not have any glob
          # patterns that is handled by going the other way and calling deconstruct_args due
          # to the yum libraries not supporting that calling pattern other than by searchNevra.
          #
          # NOTE: This is an ugly hack and should NOT be considered an endorsement of this approach
          # towards any kind of features or bugfixes in the DNF provider.  I'm doing this
          # because YUM is sunsetting at this point and its very difficult to fight with the
          # libraries on the python side of things.
          #
          # @api private
          def combine_args(provides, version, arch)
            provides = provides.dup
            maybe_arch = provides.rpartition(".").last
            if is_arch?(maybe_arch)
              arch = maybe_arch
              provides.delete_suffix!(".#{arch}")
            end
            provides = "#{provides}-#{version}" if version
            provides = "#{provides}.#{arch}" if arch
            # yum (on rhel7) can't handle an epoch in provides, but
            # deconstructing the args can't handle dealing with globs
            if provides =~ /-\d+:/ && provides !~ /[\*\?]/
              deconstruct_args(provides)
            else
              { "provides" => provides }
            end
          end

          # @return Array<Version>
          # NB: "options" here is the yum_package options hash and is deliberately not **opts
          def package_query(action, provides, version: nil, arch: nil, options: {})
            parameters = combine_args(provides, version, arch)
            repo_opts = options_params(options || {})
            parameters.merge!(repo_opts)
            # XXX: for now we close the rpmdb before and after every query with an enablerepo/disablerepo to clean the helpers internal state
            close_rpmdb unless repo_opts.empty?
            query_output = query(action, parameters)
            version = parse_response(query_output.lines.last)
            Chef::Log.trace "parsed #{version} from python helper"
            close_rpmdb unless repo_opts.empty?
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
              Chef::Log.trace "sending '#{json}' to python helper"
              outpipe.puts json
              outpipe.flush
              output = inpipe.readline.chomp
              Chef::Log.trace "got '#{output}' from python helper"
              output
            end
          end

          def build_query(action, parameters)
            hash = { "action" => action }
            parameters.each do |param_name, param_value|
              hash[param_name] = param_value unless param_value.nil?
            end

            # Special handling for certain action / param combos
            # if %i{whatinstalled whatavailable}.include?(action)
            #  add_version(hash, parameters["version"]) unless parameters["version"].nil?
            # end

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
              Chef::Log.trace "discarding output on stderr/stdout from python helper: #{output}"
            end
            ret
          rescue => e
            output = drain_fds
            restart
            if ( max_retries -= 1 ) > 0 && !ENV["YUM_HELPER_NO_RETRIES"]
              unless output.empty?
                Chef::Log.trace "discarding output on stderr/stdout from python helper: #{output}"
              end
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
