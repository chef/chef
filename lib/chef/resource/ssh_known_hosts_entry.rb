#
# Author:: Seth Vargo (<sethvargo@gmail.com>)
#
# Copyright:: 2013-2018, Seth Vargo
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

require_relative "../resource"
require "chef-utils/dist" unless defined?(ChefUtils::Dist)

class Chef
  class Resource
    class SshKnownHostsEntry < Chef::Resource
      unified_mode true

      provides :ssh_known_hosts_entry

      description "Use the **ssh_known_hosts_entry** resource to add an entry for the specified host in /etc/ssh/ssh_known_hosts or a user's known hosts file if specified."
      introduced "14.3"
      examples <<~DOC
      **Add a single entry for github.com with the key auto detected**

      ```ruby
      ssh_known_hosts_entry 'github.com'
      ```

      **Add a single entry with your own provided key**

      ```ruby
      ssh_known_hosts_entry 'github.com' do
        key 'node.example.com ssh-rsa ...'
      end
      ```
      DOC

      property :host, String,
        description: "The host to add to the known hosts file.",
        name_property: true

      property :key, String,
        description: "An optional key for the host. If not provided this will be automatically determined."

      property :key_type, String,
        description: "The type of key to store.",
        default: "rsa"

      property :port, Integer,
        description: "The server port that the ssh-keyscan command will use to gather the public key.",
        default: 22

      property :timeout, Integer,
        description: "The timeout in seconds for ssh-keyscan.",
        default: 30,
        desired_state: false

      property :mode, String,
        description: "The file mode for the ssh_known_hosts file.",
        default: "0644"

      property :owner, [String, Integer],
        description: "The file owner for the ssh_known_hosts file.",
        default: "root"

      property :group, [String, Integer],
        description: "The file group for the ssh_known_hosts file.",
        default: lazy { node["root_group"] },
        default_description: "The root user's group depending on platform."

      property :hash_entries, [TrueClass, FalseClass],
        description: "Hash the hostname and addresses in the ssh_known_hosts file for privacy.",
        default: false

      property :file_location, String,
        description: "The location of the ssh known hosts file. Change this to set a known host file for a particular user.",
        default: "/etc/ssh/ssh_known_hosts"

      action :create, description: "Create an entry in the ssh_known_hosts file." do
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
            source ::File.expand_path("support/ssh_known_hosts.erb", __dir__)
            local true
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

        keys = r.variables[:entries].reject(&:empty?)

        if key_exists?(keys, key, comment)
          Chef::Log.debug "Known hosts key for #{new_resource.host} already exists - skipping"
        else
          r.variables[:entries].push(key)
        end
      end

      # all this does is send an immediate run_action(:create) to the template resource
      action :flush, description: "Immediately flush the entries to the config file. Without this the actual writing of the file is delayed in the #{ChefUtils::Dist::Infra::PRODUCT} run so all entries can be accumulated before writing the file out." do
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
