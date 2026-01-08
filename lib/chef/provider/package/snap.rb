#
# Author:: S.Cavallo (<smcavallo@hotmail.com>)
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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
require "json" unless defined?(JSON)

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
          super

          requirements.assert(:install, :upgrade, :remove, :purge) do |a|
            a.assertion { !new_resource.source || ::File.exist?(new_resource.source) }
            a.failure_message Chef::Exceptions::Package, "Package #{new_resource.package_name} not found: #{new_resource.source}"
            a.whyrun "assuming #{new_resource.source} would have previously been created"
          end

          requirements.assert(:all_actions) do |a|
            a.assertion { !new_resource.environment }
            a.failure_message Chef::Exceptions::Package, "The environment property is not supported for package resources on this platform"
          end
        end

        def candidate_version
          package_name_array.each_with_index.map do |pkg, i|
            available_version(i)
          end
        end

        def get_current_versions
          package_name_array.each_with_index.map do |pkg, i|
            installed_version(i)
          end.compact
        end

        def install_package(names, versions)
          if new_resource.source
            install_snap_from_source(names, new_resource.source)
          else
            install_snaps(names, versions)
          end
        end

        def upgrade_package(names, versions)
          if new_resource.source
            install_snap_from_source(names, new_resource.source)
          else
            if get_current_versions.empty?
              install_snaps(names, versions)
            else
              update_snaps(names)
            end
          end
        end

        def remove_package(names, versions)
          uninstall_snaps(names)
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
            pdata = post_data.to_json
            request.concat("Content-Length: #{pdata.bytesize}\r\n\r\n#{pdata}")
          end
          request.concat("\r\n")

          # while it is expected to allow clients to connect using https over
          # a tcp socket, at this point only a unix socket is supported. the
          # socket is /run/snapd.socket note - UNIXSocket is not defined on
          # windows systems
          if defined?(::UNIXSocket)
            UNIXSocket.open("/run/snapd.socket") do |socket|
              # send request, read the response, split the response and parse
              # the body
              socket.write(request)

              # WARNING!!! HERE BE DRAGONs
              #
              # So snapd doesn't return an EOF at the end of its body, so
              # doing a normal read will just hang forever.
              #
              # Well, sort of. if, after it writes everything, you then send
              # yet-another newline, it'll then send its EOF and promptly
              # disconnect closing the pipe and preventing reading. so, you
              # have to read first, and therein lies the EOF problem.
              #
              # So you can do non-blocking reads with selects, but it
              # makes every read take about 5 seconds. If, instead, we
              # read the last line char-by-char, it's about half a second.
              #
              # Reading a character at a time isn't efficient, and since we
              # know that http headers always have a blank line after them,
              # we can read lines until we find a blank line and *then* read
              # a character at a time. snap returns all the json on a single
              # line, so once you pass headers you must read a character a
              # time.
              #
              # - jaymzh

              Chef::Log.trace(
                "snap_package[#{new_resource.package_name}]: reading headers"
              )
              loop do
                response = socket.readline
                break if response.strip.empty? # finished headers
              end
              Chef::Log.trace(
                "snap_package[#{new_resource.package_name}]: past headers, " +
                "onto the body..."
              )
              result = nil
              body = ""
              socket.each_char do |c|
                body << c
                # we know we're not done if we don't have a char that
                # can end JSON
                next unless ["}", "]"].include?(c)

                begin
                  result = JSON.parse(body)
                  # if we get here, we were able to parse the json so we
                  # are done reading
                  break
                rescue JSON::ParserError
                  next
                end
              end
              result
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

            case result["result"]["status"]
            when "Do", "Doing", "Undoing", "Undo"
              # Continue
            when "Abort", "Hold", "Error"
              raise "#{result["result"]["summary"]} - #{result["result"]["status"]} - #{result["result"]["err"]}"
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
              "args" => ["info", path],
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

        def install_snaps(snap_names, versions)
          snap_names.each do |snap|
            response = post_snap(snap, "install", new_resource.channel, new_resource.options)
            id = get_id_from_async_response(response)
            wait_for_completion(id)
          end
        end

        def update_snaps(snap_names)
          response = post_snaps(snap_names, "refresh", nil, new_resource.options)
          id = get_id_from_async_response(response)
          wait_for_completion(id)
        end

        def uninstall_snaps(snap_names)
          response = post_snaps(snap_names, "remove", nil, new_resource.options)
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

          <<~SNAP_S
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
              "snaps" => Array(snap_names),
          }
          if %w{install refresh switch}.include?(action) && channel
            request["channel"] = channel
          end

          # No defensive handling of params
          # Snap will throw the proper exception if called improperly
          # And we can provide that exception to the end user
          if options
            request["classic"] = true if options.include?("classic")
            request["devmode"] = true if options.include?("devmode")
            request["jailmode"] = true if options.include?("jailmode")
            request["ignore_validation"] = true if options.include?("ignore-validation")
          end
          request["revision"] = revision unless revision.nil?
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

        def post_snap(snap_name, action, channel, options, revision = nil)
          json = generate_snap_json(snap_name, action, channel, options, revision = nil)
          json.delete("snaps")
          call_snap_api("POST", "/v2/snaps/#{snap_name}", json)
        end

        def get_latest_package_version(name, channel)
          json = call_snap_api("GET", "/v2/find?name=#{name}")
          if json["status-code"] != 200
            raise Chef::Exceptions::Package, json["result"], caller
          end

          Chef::Log.debug("snapd API response: #{json}\n")

          # If no channel is passed, use the snap's default version
          if channel.nil?
            Chef::Log.debug("Channel is nil, using default snap version: #{json["result"][0]["version"]}")
            json["result"][0]["version"]
          else
            # Before Chef 19, this resource hardcoded `latest`.
            if %w{edge beta candidate stable}.include?(channel)
              channel = "latest/#{channel}"
            end
            unless json["result"][0]["channels"][channel]
              raise Chef::Exceptions::Package, "No version of #{name} in channel #{channel}", caller
            end

            # Return the version matching the channel
            json["result"][0]["channels"][channel]["version"]
          end
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
