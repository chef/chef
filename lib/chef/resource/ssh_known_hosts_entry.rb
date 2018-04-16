#
# Author:: Seth Vargo (<sethvargo@gmail.com>)
#
# Copyright:: 2013-2018, Seth Vargo
# Copyright:: 2017-2018, Chef Software, Inc.
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

require "chef/resource"

class Chef
  class Resource
    class SshKnownHostsEntry < Chef::Resource
      resource_name :ssh_known_hosts_entry
      provides(:ssh_known_hosts_entry) { true }

      description "Use the ssh_known_hosts_entry resource to append an entry for the specified host in /etc/ssh/ssh_known_hosts or a user's known hosts file if specified."
      introduced "15.0"

      property :host, String, name_property: true
      property :key, String
      property :key_type, String, default: "rsa"
      property :port, Integer, default: 22
      property :timeout, Integer, default: 30
      property :mode, String, default: "0644"
      property :owner, String, default: "root"
      property :group, String, default: "root"
      property :hash_entries, [true, false], default: false
      property :file_location, String, default: "/etc/ssh/ssh_known_hosts"

      action :create do
        key =
          if new_resource.key
            hoststr = (new_resource.port != 22) ? "[#{new_resource.host}]:#{new_resource.port}" : new_resource.host
            "#{hoststr} #{type_string(new_resource.key_type)} #{new_resource.key}"
          else
            keyscan_cmd = ["ssh-keyscan", "-t#{new_resource.key_type}", "-p #{new_resource.port}"]
            keyscan_cmd << "-H" if new_resource.hash_entries
            keyscan_cmd << new_resource.host
            keyscan = shell_out!(keyscan_cmd.join(" "), timeout: new_resource.timeout)
            keyscan.stdout
          end

        key.sub!(/^#{new_resource.host}/, "[#{new_resource.host}]:#{new_resource.port}") if new_resource.port != 22

        comment = key.split("\n").first || ""

        r = with_run_context :root do
          find_resource(:template, "update ssh known hosts file #{new_resource.file_location}") do
            source "ssh_known_hosts.erb"
            path new_resource.file_location
            owner new_resource.owner
            group new_resource.group
            mode new_resource.mode
            action :nothing
            delayed_action :create
            backup false
            variables(entries: [])
          end
        end

        # messing with the run_context appears to cause issues with the cookbook_name
        r.cookbook_name = "ssh_known_hosts"

        keys = r.variables[:entries].reject(&:empty?)

        if key_exists?(keys, key, comment)
          Chef::Log.debug "Known hosts key for #{new_resource.name} already exists - skipping"
        else
          r.variables[:entries].push(key)
        end
      end

      # all this does is send an immediate run_action(:create) to the template resource
      action :flush do
        with_run_context :root do
          # if you haven't ever called ssh_known_hosts_entry before you're definitely doing it wrong so we blow up hard.
          find_resource!(:template, "update ssh known hosts file #{new_resource.file_location}").run_action(:create)
          # it is the user's responsibility to only call this *after* all the ssh_known_hosts_entry resources have been called.
          # if you call this too early in your run_list you will get a partial known_host file written to disk, and the resource
          # behavior will not be idempotent (template resources will flap and never show 0 resources updated on converged boxes).
          Chef::Log.warn "flushed ssh_known_hosts entries to file, later ssh_known_hosts_entry resources will not have been written"
        end
      end

      action_class do
        def key_exists?(keys, key, comment)
          keys.any? do |line|
            line.match(/#{Regexp.escape(comment)}|#{Regexp.escape(key)}/)
          end
        end

        def type_string(key_type)
          type_map = {
            "rsa" => "ssh-rsa",
            "dsa" => "ssh-dss",
            "ecdsa" => "ecdsa-sha2-nistp256",
            "ed25519" => "ssh-ed25519",
          }
          type_map[key_type] || key_type
        end
      end
    end
  end
end
