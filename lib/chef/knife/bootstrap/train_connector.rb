# Copyright:: Copyright (c) 2019 Chef Software Inc.
#
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

require "train"
require "tempfile"
require "uri"

class Chef
  class Knife
    class Bootstrap < Knife
      class TrainConnector
        SSH_CONFIG_OVERRIDE_KEYS = [:user, :port, :proxy].freeze

        MKTEMP_WIN_COMMAND = <<~EOM.freeze
          $parent = [System.IO.Path]::GetTempPath();
          [string] $name = [System.Guid]::NewGuid();
          $tmp = New-Item -ItemType Directory -Path;
          (Join-Path $parent $name);
          $tmp.FullName
        EOM

        MKTEMP_NIX_COMMAND = "bash -c 'd=$(mktemp -d ${TMPDIR:-/tmp}/chef_XXXXXX); echo $d'".freeze

        def initialize(host_url, default_transport, opts)

          uri_opts = opts_from_uri(host_url)
          uri_opts[:backend] ||= @default_transport
          @transport_type = uri_opts[:backend]

          # opts in the URI will override user-provided options
          @config = transport_config(host_url, opts.merge(uri_opts))

          Train.validate_backend(@config)
          @train = Train.create(@transport_type, @config)
        end

        # Because creating a valid train connection for testing is a two-step process in which
        # we need to connect before mocking config,
        # we expose test_instance as a way for tests to create actual instances
        # but ensure that they don't connect to any back end.
        def self.test_instance(url, protocol: "ssh",
                               family: "unknown", name: "unknown",
                               release: "unknown", arch: "x86_64",
                               opts: {})
          # Specifying sudo: false ensures that attempted operations
          # don't fail because the mock platform doesn't support sudo
          tc = TrainConnector.new(url, protocol, { sudo: false }.merge(opts))

          # Don't pull in the platform-specific mixins automatically during connect
          # Otherwise, it will raise since it can't resolve the OS without the mock.
          tc.connect!
          # We need to provide this mock before invoking mix_in_target_platform,
          # otherwise it will fail with an unknown OS (since we don't have a real connection).
          tc.backend.mock_os(
            family: family,
            name: name,
            release: release,
            arch: arch
          )
          tc

        end

        def connect!
          # Force connection to establish:
          backend.wait_until_ready
          true
        end

        def hostname
          @config[:host]
        end

        def password_auth?
          @config.key? :password
        end

        # True if we're connected to a linux host
        def linux?
          backend.platform.linux?
        end

        # True if we're connected to a unix host.
        # NOTE: this is always true
        # for a linux host because train classifies
        # linux as a unix
        def unix?
          backend.platform.unix?
        end

        # True if we're connected to a windows host
        def windows?
          backend.platform.windows?
        end

        def winrm?
          @transport_type == "winrm"
        end

        def ssh?
          @transport_type == "ssh"
        end

        # Creates a temporary directory on the remote host if it
        # hasn't already. Caches directory location.
        #
        # Returns the path.
        def temp_dir
          cmd = windows? ? MKTEMP_WIN_COMMAND : MKTEMP_NIX_COMMAND
          @tmpdir ||= begin
                        res = run_command!(cmd)
                        dir = res.stdout.chomp.strip
                        unless windows?
                          run_command!("chown #{@config[:user]} '#{dir}'")
                        end
                        dir
                      end
        end

        def upload_file!(local_path, remote_path)
          backend.upload(local_path, remote_path)
        end

        def upload_file_content!(content, remote_path)
          t = Tempfile.new("chef-content")
          t << content
          t.close
          upload_file!(t.path, remote_path)
        ensure
          t.close
          t.unlink
        end

        def del_file!(path)
          if windows?
            run_command!("If (Test-Path \"#{path}\") { Remove-Item -Force -Path \"#{path}\" }")
          else
            run_command!("rm -f \"#{path}\"")
          end
        end

        # normalizes path across OS's
        def normalize_path(path)
          path.tr("\\", "/")
        end

        def run_command(command, &data_handler)
          backend.run_command(command, &data_handler)
        end

        def run_command!(command, &data_handler)
          result = run_command(command, &data_handler)
          if result.exit_status != 0
            raise RemoteExecutionFailed.new(hostname, command, result)
          end
          result
        end

        # Should be private, but we use them for test validation/mocking
        def train
          @train
        end
        def backend
          @train.connection
        end

        private

        # For a given url and set of options, create a config
        # hash suitable for passing into train.
        def transport_config(host_url, opts_in)
          opts = { target: host_url,
                   sudo: opts_in[:sudo] === false ? false : true,
                   # TODO - we should be always encoding password
                   www_form_encoded_password: true,
                   key_files: opts_in[:key_files],
                   non_interactive: true, # Prevent password prompts
                   transport_retries: 2,
                   transport_retry_sleep: 1,
                   logger: opts_in[:logger],
                   backend: @transport_type }

          # Base opts are those provided by the caller directly
          opts.merge!(opts_from_caller(opts, opts_in))

          # WinRM has some additional computed options
          opts.merge!(opts_inferred_from_winrm(opts, opts_in))

          # Now that everything is populated, fill in anything left
          # from user ssh config that may be present
          opts.merge!(missing_opts_from_ssh_config(opts, opts_in))

          Train.target_config(opts)
        end

        # Some winrm options are inferred based on other options.
        # Return a hash of winrm options based on configuration already built.
        def opts_inferred_from_winrm(config, opts_in)
          return {} unless winrm?
          opts_out = {}

          if opts_in[:ssl]
            opts_out[:ssl] = true
            opts_out[:self_signed] = opts_in[:self_signed] || false
          end

          # See note here: https://github.com/mwrock/WinRM#example
          if %w{ssl plaintext}.include?(opts_in[:winrm_auth_method])
            opts_out[:winrm_disable_sspi] = true
          end
          opts_out
        end

        # Returns a hash containing valid options for the current
        # transport protocol that are not already present in config
        def opts_from_caller(config, opts_in)
          # Train.options gives us the supported config options for the
          # backend provider (ssh, winrm). We'll use that
          # to filter out options that don't belong
          # to the transport type we're using.
          valid_opts = Train.options(config[:backend])
          opts_in.select do |key, _v|
            valid_opts.key?(key) &&
              !config.key?(key) end
        end

        # Extract any of username/password/host/port/transport
        # that are in the URI and return them as a config has
        def opts_from_uri(uri)
          # Train.unpack_target_from_uri only works for complete URIs in
          # form of proto://[user[:pass]@]host[:port]/
          # So we'll add the protocol prefix if it's not supplied.
          uri_to_check = if URI.regexp.match(uri)
                           uri
                         else
                           "#{@transport_type}://#{uri}"
                         end

          Train.unpack_target_from_uri(uri_to_check)
        end

        # This returns a hash that consists of settings
        # populated from SSH configuration that are not already present
        # in the configuration passed in.
        # This is necessary because train will default these values
        # itself - causing SSH config data to be ignored
        def missing_opts_from_ssh_config(config, opts_in)
          return {} unless ssh?
          host_cfg = ssh_config_for_host(config[:host])
          opts_out = {}
          opts_in.each do |key, _value|
            if SSH_CONFIG_OVERRIDE_KEYS.include?(key) && !config.key?(key)
              opts_out[key] = host_cfg[key]
            end
          end
          opts_out
        end

        # Having this as a method makes it easier to mock
        # SSH Config for testing.
        def ssh_config_for_host(host)
          require "net/ssh"
          Net::SSH::Config.for(host)
        end
      end

      class RemoteExecutionFailed < StandardError
        attr_reader :exit_status, :command, :hostname, :stdout, :stderr
        def initialize(hostname, command, result)
          @hostname = hostname
          @exit_status = result.exit_status
          @stderr = result.stderr
          @stdout = result.stdout
        end
      end

    end
  end
end
