# Author:: Prajakta Purohit (<prajakta@chef.io>)
# Author:: Lamont Granquist (<lamont@chef.io>)
#
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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

require_relative "../resource"
require_relative "../digester"
require "chef-utils/dist" unless defined?(ChefUtils::Dist)

class Chef
  class Resource
    class RegistryKey < Chef::Resource

      provides(:registry_key) { true }

      description "Use the **registry_key** resource to create and delete registry keys in Microsoft Windows. Note: 64-bit versions of Microsoft Windows have a 32-bit compatibility layer in the registry that reflects and redirects certain keys (and their values) into specific locations (or logical views) of the registry hive.\n\n#{ChefUtils::Dist::Infra::PRODUCT} can access any reflected or redirected registry key. The machine architecture of the system on which #{ChefUtils::Dist::Infra::PRODUCT} is running is used as the default (non-redirected) location. Access to the SysWow64 location is redirected must be specified. Typically, this is only necessary to ensure compatibility with 32-bit applications that are running on a 64-bit operating system.\n\nFor more information, see: [Registry Reflection](https://docs.microsoft.com/en-us/windows/win32/winprog64/registry-reflection)."
      examples <<~'DOC'
      **Create a registry key**

      ```ruby
      registry_key 'HKEY_LOCAL_MACHINE\\path-to-key\\Policies\\System' do
        values [{
          name: 'EnableLUA',
          type: :dword,
          data: 0
        }]
        action :create
      end
      ```

      **Create a registry key with binary data: "\x01\x02\x03"**:

      ```ruby
      registry_key 'HKEY_CURRENT_USER\ChefTest' do
        values [{
          :name => "test",
          :type => :binary,
          :data => [0, 1, 2].map(&:chr).join
        }]

        action :create
      end
      ```

      **Create 32-bit key in redirected wow6432 tree**

      In 64-bit versions of Microsoft Windows, HKEY_LOCAL_MACHINE\SOFTWARE\Example is a re-directed key. In the following examples, because HKEY_LOCAL_MACHINE\SOFTWARE\Example is a 32-bit key, the output will be “Found 32-bit key” if they are run on a version of Microsoft Windows that is 64-bit:

      ```ruby
      registry_key 'HKEY_LOCAL_MACHINE\SOFTWARE\Example' do
        architecture :i386
        recursive true
        action :create
      end
      ```

      **Set proxy settings to be the same as those used by #{ChefUtils::Dist::Infra::PRODUCT}**

      ```ruby
      proxy = URI.parse(Chef::Config[:http_proxy])
      registry_key 'HKCU\Software\Microsoft\path\to\key\Internet Settings' do
        values [{name: 'ProxyEnable', type: :reg_dword, data: 1},
                {name: 'ProxyServer', data: "#{proxy.host}:#{proxy.port}"},
                {name: 'ProxyOverride', type: :reg_string, data: <local>},
               ]
        action :create
      end
      ```

      **Set the name of a registry key to "(Default)"**

      ```ruby
      registry_key 'Set (Default) value' do
        key 'HKLM\Software\Test\Key\Path'
        values [
          {name: '', type: :string, data: 'test'},
        ]
        action :create
      end
      ```

      **Delete a registry key value**

      ```ruby
      registry_key 'HKEY_LOCAL_MACHINE\SOFTWARE\path\to\key\AU' do
        values [{
          name: 'NoAutoRebootWithLoggedOnUsers',
          type: :dword,
          data: ''
          }]
        action :delete
      end
      ```

      Note: If data: is not specified, you get an error: Missing data key in RegistryKey values hash

      **Delete a registry key and its subkeys, recursively**

      ```ruby
      registry_key 'HKCU\SOFTWARE\Policies\path\to\key\Themes' do
        recursive true
        action :delete_key
      end
      ```

      Note: Be careful when using the :delete_key action with the recursive attribute. This will delete the registry key, all of its values and all of the names, types, and data associated with them. This cannot be undone by #{ChefUtils::Dist::Infra::PRODUCT}.
      DOC

      default_action :create
      allowed_actions :create, :create_if_missing, :delete, :delete_key

      VALID_VALUE_HASH_KEYS = %i{name type data}.freeze

      property :key, String, name_property: true
      property :values, [Hash, Array],
        default: [],
        coerce: proc { |v|
          @unscrubbed_values =
            case v
            when Hash
              [ Mash.new(v).symbolize_keys ]
            when Array
              v.map { |value| Mash.new(value).symbolize_keys }
            else
              raise ArgumentError, "Bad type for RegistryKey resource, use Hash or Array"
            end
          scrub_values(@unscrubbed_values)
        },
        callbacks: {
        "Missing name key in RegistryKey values hash" => lambda { |v| v.all? { |value| value.key?(:name) } },
        "Bad key in RegistryKey values hash. Should be one of: #{VALID_VALUE_HASH_KEYS}" => lambda do |v|
          v.all? do |value|
            value.keys.all? { |key| VALID_VALUE_HASH_KEYS.include?(key) }
          end
        end,
        "Type of name should be a string" => lambda { |v| v.all? { |value| value[:name].is_a?(String) } },
        "Type of type should be a symbol" => lambda { |v| v.all? { |value| value[:type] ? value[:type].is_a?(Symbol) : true } },
      }
      property :recursive, [TrueClass, FalseClass], default: false
      property :architecture, Symbol, default: :machine, equal_to: %i{machine x86_64 i386}

      # Some registry key data types may not be safely reported as json.
      # Example (CHEF-5323):
      #
      # registry_key 'HKEY_CURRENT_USER\\ChefTest2014' do
      #   values [{
      #     :name => "ValueWithBadData",
      #     :type => :binary,
      #     :data => 255.chr * 1
      #   }]
      #   action :create
      # end
      #
      # will raise Encoding::UndefinedConversionError: "\xFF" from ASCII-8BIT to UTF-8.
      #
      # To avoid sending data that cannot be nicely converted for json, we have
      # the values method return "safe" data if the data type is "unsafe". Known "unsafe"
      # data types are :binary, :dword, :dword-big-endian, and :qword. If other
      # criteria generate data that cannot reliably be sent as json, add that criteria
      # to the needs_checksum? method. When unsafe data is detected, the values method
      # returns an md5 checksum of the listed data.
      #
      # :unscrubbed_values returns the values exactly as provided in the resource (i.e.,
      # data is not checksummed, regardless of the data type/"unsafe" criteria).
      #
      # Future:
      # If we have conflicts with other resources reporting json incompatible state, we
      # may want to extend the state_attrs API with the ability to rename POST'd attrs.
      #
      # See lib/chef/resource_reporter.rb for more information.
      def unscrubbed_values
        @unscrubbed_values ||= []
      end

      private

      def scrub_values(values)
        scrubbed = []
        values.each do |value|
          scrubbed_value = value.dup
          if needs_checksum?(scrubbed_value)
            data_io = StringIO.new(scrubbed_value[:data].to_s)
            scrubbed_value[:data] = Chef::Digester.instance.generate_checksum(data_io)
          end
          scrubbed << scrubbed_value
        end
        scrubbed
      end

      # Some data types may raise errors when sent as json. Returns true if this
      # value's data may need to be converted to a checksum.
      def needs_checksum?(value)
        unsafe_types = %i{binary dword dword_big_endian qword}
        unsafe_types.include?(value[:type])
      end

    end
  end
end
