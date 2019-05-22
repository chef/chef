#
# Author:: S.Cavallo (<smcavallo@hotmail.com>)
# Copyright:: Copyright 2016-2018, Chef Software Inc.
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

require_relative "../package"
require_relative "../../resource/snap_package"
require_relative "../../mixin/shell_out"
require "socket" unless defined?(Socket)
require "json"

class Chef
  class Provider
    class Package
      class Snap < Chef::Provider::Package
        allow_nils
        use_multipackage_api
        use_package_name_for_source

        provides :snap_package

        def load_current_resource
          @current_resource = Chef::Resource::SnapPackage.new(new_resource.name)
          current_resource.package_name(new_resource.package_name)
          current_resource.version(get_current_versions)

          current_resource
        end

        def define_resource_requirements
          requirements.assert(:install, :upgrade, :remove, :purge) do |a|
            a.assertion { !new_resource.source || ::File.exist?(new_resource.source) }
            a.failure_message Chef::Exceptions::Package, "Package #{new_resource.package_name} not found: #{new_resource.source}"
            a.whyrun "assuming #{new_resource.source} would have previously been created"
          end

          super
        end

        def candidate_version
          package_name_array.each_with_index.map do |pkg, i|
            available_version(i)
          end
        end

        def get_current_versions
          package_name_array.each_with_index.map do |pkg, i|
            installed_version(i)
          end
        end

        def install_package(names, versions)
          if new_resource.source
            install_snap_from_source(names, new_resource.source)
          else
            resolved_names = names.each_with_index.map { |name, i| available_version(i).to_s unless name.nil? }
            install_snaps(resolved_names)
          end
        end

        def upgrade_package(names, versions)
          if new_resource.source
            install_snap_from_source(names, new_resource.source)
          else
            resolved_names = names.each_with_index.map { |name, i| available_version(i).to_s unless name.nil? }
            update_snaps(resolved_names)
          end
        end

        def remove_package(names, versions)
          resolved_names = names.each_with_index.map { |name, i| installed_version(i).to_s unless name.nil? }
          uninstall_snaps(resolved_names)
        end

        alias purge_package remove_package

        private

        # @return Array<Version>
        def available_version(index)
          @available_version ||= []

          @available_version[index] ||= if new_resource.source
                                          get_snap_version_from_source(new_resource.source)
                                        else
                                          get_latest_package_version(package_name_array[index], new_resource.channel)
                                        end

          @available_version[index]
        end

        # @return [Array<Version>]
        def installed_version(index)
          @installed_version ||= []
          @installed_version[index] ||= get_installed_package_version_by_name(package_name_array[index])
          @installed_version[index]
        end

        def safe_version_array
          if new_resource.version.is_a?(Array)
            new_resource.version
          elsif new_resource.version.nil?
            package_name_array.map { nil }
          else
            [new_resource.version]
          end
        end

        # ToDo: Support authentication
        # ToDo: Support private snap repos
        # https://github.com/snapcore/snapd/wiki/REST-API

        # ToDo: Would prefer to use net/http over socket
        def call_snap_api(method, uri, post_data = nil?)
          request = "#{method} #{uri} HTTP/1.0\r\n" +
            "Accept: application/json\r\n" +
            "Content-Type: application/json\r\n"
          if method == "POST"
            request.concat("Content-Length: #{post_data.bytesize}\r\n\r\n#{post_data}")
          end
          request.concat("\r\n")
          # While it is expected to allow clients to connect using HTTPS over a TCP socket,
          # at this point only a UNIX socket is supported. The socket is /run/snapd.socket
          # Note - UNIXSocket is not defined on windows systems
          if defined?(::UNIXSocket)
            UNIXSocket.open("/run/snapd.socket") do |socket|
              # Send request, read the response, split the response and parse the body
              socket.print(request)
              response = socket.read
              headers, body = response.split("\r\n\r\n", 2)
              JSON.parse(body)
            end
          end
        end

        def get_change_id(id)
          call_snap_api("GET", "/v2/changes/#{id}")
        end

        def get_id_from_async_response(response)
          if response["type"] == "error"
            raise "status: #{response["status"]}, kind: #{response["result"]["kind"]}, message: #{response["result"]["message"]}"
          end
          response["change"]
        end

        def wait_for_completion(id)
          n = 0
          waiting = true
          while waiting
            result = get_change_id(id)
            puts "STATUS: #{result["result"]["status"]}"
            case result["result"]["status"]
            when "Do", "Doing", "Undoing", "Undo"
              # Continue
            when "Abort"
              raise result
            when "Hold", "Error"
              raise result
            when "Done"
              waiting = false
            else
              # How to handle unknown status
            end
            n += 1
            raise "Snap operating timed out after #{n} seconds." if n == 300
            sleep(1)
          end
        end

        def snapctl(*args)
          shell_out!("snap", *args)
        end

        def get_snap_version_from_source(path)
          body = {
              "context-id" => "get_snap_version_from_source_#{path}",
              "args" => ["info", path,],
          }.to_json

          # json = call_snap_api('POST', '/v2/snapctl', body)
          response = snapctl(["info", path])
          Chef::Log.trace(response)
          response.error!
          get_version_from_stdout(response.stdout)
        end

        def get_version_from_stdout(stdout)
          stdout.match(/version: (\S+)/)[1]
        end

        def install_snap_from_source(name, path)
          # json = call_snap_api('POST', '/v2/snapctl', body)
          response = snapctl(["install", path])
          Chef::Log.trace(response)
          response.error!
        end

        def install_snaps(snap_names)
          response = post_snaps(snap_names, "install", new_resource.channel, new_resource.options)
          id = get_id_from_async_response(response)
          wait_for_completion(id)
        end

        def update_snaps(snap_names)
          response = post_snaps(snap_names, "refresh", new_resource.channel, new_resource.options)
          id = get_id_from_async_response(response)
          wait_for_completion(id)
        end

        def uninstall_snaps(snap_names)
          response = post_snaps(snap_names, "remove", new_resource.channel, new_resource.options)
          id = get_id_from_async_response(response)
          wait_for_completion(id)
        end

        # Constructs the multipart/form-data required to sideload packages
        # https://github.com/snapcore/snapd/wiki/REST-API#sideload-request
        #
        #   @param snap_name [String] An array of snap package names to install
        #   @param action [String] The action. Valid: install or try
        #   @param options [Hash] Misc configuration Options
        #   @param path [String] Path to the package on disk
        #   @param content_length [Integer] byte size of the snap file
        def generate_multipart_form_data(snap_name, action, options, path, content_length)
          snap_options = options.map do |k, v|
            <<~SNAP_OPTION
              Content-Disposition: form-data; name="#{k}"

              #{v}
              --#{snap_name}
            SNAP_OPTION
          end

          multipart_form_data = <<~SNAP_S
            Host:
            Content-Type: multipart/form-data; boundary=#{snap_name}
            Content-Length: #{content_length}

            --#{snap_name}
            Content-Disposition: form-data; name="action"

            #{action}
            --#{snap_name}
            #{snap_options.join("\n").chomp}
            Content-Disposition: form-data; name="snap"; filename="#{path}"

            <#{content_length} bytes of snap file data>
            --#{snap_name}
          SNAP_S
          multipart_form_data
        end

        # Constructs json to post for snap changes
        #
        #   @param snap_names [Array] An array of snap package names to install
        #   @param action [String] The action.  install, refresh, remove, revert, enable, disable or switch
        #   @param channel [String] The release channel.  Ex. stable
        #   @param options [Hash] Misc configuration Options
        #   @param revision [String] A revision/version
        def generate_snap_json(snap_names, action, channel, options, revision = nil)
          request = {
              "action" => action,
              "snaps" => snap_names,
          }
          if %w{install refresh switch}.include?(action)
            request["channel"] = channel
          end

          # No defensive handling of params
          # Snap will throw the proper exception if called improperly
          # And we can provide that exception to the end user
          request["classic"] = true if options["classic"]
          request["devmode"] = true if options["devmode"]
          request["jailmode"] = true if options["jailmode"]
          request["revision"] = revision unless revision.nil?
          request["ignore_validation"] = true if options["ignore-validation"]
          request
        end

        # Post to the snap api to update snaps
        #
        #   @param snap_names [Array] An array of snap package names to install
        #   @param action [String] The action.  install, refresh, remove, revert, enable, disable or switch
        #   @param channel [String] The release channel.  Ex. stable
        #   @param options [Hash] Misc configuration Options
        #   @param revision [String] A revision/version
        def post_snaps(snap_names, action, channel, options, revision = nil)
          json = generate_snap_json(snap_names, action, channel, options, revision = nil)
          call_snap_api("POST", "/v2/snaps", json)
        end

        def get_latest_package_version(name, channel)
          json = call_snap_api("GET", "/v2/find?name=#{name}")
          if json["status-code"] != 200
            raise Chef::Exceptions::Package, json["result"], caller
          end

          # Return the version matching the channel
          json["result"][0]["channels"]["latest/#{channel}"]["version"]
        end

        def get_installed_packages
          json = call_snap_api("GET", "/v2/snaps")
          # We only allow 200 or 404s
          unless [200, 404].include? json["status-code"]
            raise Chef::Exceptions::Package, json["result"], caller
          end
          json["result"]
        end

        def get_installed_package_version_by_name(name)
          result = get_installed_package_by_name(name)
          # Return nil if not installed
          if result["status-code"] == 404
            nil
          else
            result["version"]
          end
        end

        def get_installed_package_by_name(name)
          json = call_snap_api("GET", "/v2/snaps/#{name}")
          # We only allow 200 or 404s
          unless [200, 404].include? json["status-code"]
            raise Chef::Exceptions::Package, json["result"], caller
          end
          json["result"]
        end

        def get_installed_package_conf(name)
          json = call_snap_api("GET", "/v2/snaps/#{name}/conf")
          json["result"]
        end

        def set_installed_package_conf(name, value)
          response = call_snap_api("PUT", "/v2/snaps/#{name}/conf", value)
          id = get_id_from_async_response(response)
          wait_for_completion(id)
        end

      end
    end
  end
end
