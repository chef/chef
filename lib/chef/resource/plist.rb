#
# Copyright:: Copyright 2017-2020, Microsoft Corporation
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
require_relative "../resource"
autoload :Plist, "plist"

class Chef
  class Resource

    class PlistResource < Chef::Resource # we name this PlistResource to avoid confusion with Plist from the plist gem
      unified_mode true

      provides :plist

      description "Use the **plist** resource to set config values in plist files on macOS systems."
      introduced "16.0"
      examples <<~DOC
        **Show hidden files in finder**:

        ```ruby
        plist 'show hidden files' do
          path '/Users/vagrant/Library/Preferences/com.apple.finder.plist'
          entry 'AppleShowAllFiles'
          value true
        end
        ```
      DOC

      property :path, String, name_property: true,
        description: "The path on disk to the plist file."

      property :entry, String
      property :value, [TrueClass, FalseClass, String, Integer, Float, Hash]
      property :encoding, String, default: "binary"

      property :owner, String, default: "root",
        description: "The owner of the plist file."

      property :group, String, default: "wheel",
        description: "The group of the plist file."

      property :mode, [String, Integer],
        description: "The file mode of the plist file. Ex: '644'"

      PLISTBUDDY_EXECUTABLE = "/usr/libexec/PlistBuddy".freeze
      DEFAULTS_EXECUTABLE = "/usr/bin/defaults".freeze
      PLUTIL_EXECUTABLE = "/usr/bin/plutil".freeze
      PLUTIL_FORMAT_MAP = { "us-ascii" => "xml1",
                             "text/xml" => "xml1",
                             "utf-8" => "xml1",
                             "binary" => "binary1" }.freeze

      load_current_value do |new_resource|
        current_value_does_not_exist! unless ::File.exist? new_resource.path
        entry new_resource.entry if entry_in_plist? new_resource.entry, new_resource.path

        setting = setting_from_plist new_resource.entry, new_resource.path
        value convert_to_data_type_from_string(setting[:key_type], setting[:key_value])

        file_type_cmd = shell_out "/usr/bin/file", "--brief", "--mime-encoding", "--preserve-date", new_resource.path
        encoding file_type_cmd.stdout.chomp

        file_owner_cmd = shell_out("/usr/bin/stat", "-f", "%Su", new_resource.path)
        owner file_owner_cmd.stdout.chomp

        file_group_cmd = shell_out("/usr/bin/stat", "-f", "%Sg", new_resource.path)
        group file_group_cmd.stdout.chomp
      end

      action :set, description: "Set a value in a plist file." do
        converge_if_changed :path do
          converge_by "create new plist: '#{new_resource.path}'" do
            file new_resource.path do
              content {}.to_plist
              owner new_resource.owner
              group new_resource.group
              mode new_resource.mode if property_is_set?(:mode)
            end
          end
        end

        plist_file_name = ::File.basename(new_resource.path)

        converge_if_changed :entry do
          converge_by "add entry \"#{new_resource.entry}\" to #{plist_file_name}" do
            shell_out!(plistbuddy_command(:add, new_resource.entry, new_resource.path, new_resource.value))
          end
        end

        converge_if_changed :value do
          converge_by "#{plist_file_name}: set #{new_resource.entry} to #{new_resource.value}" do
            shell_out!(plistbuddy_command(:set, new_resource.entry, new_resource.path, new_resource.value))
          end
        end

        converge_if_changed :encoding do
          converge_by "change format" do
            unless PLUTIL_FORMAT_MAP.key?(new_resource.encoding)
              Chef::Application.fatal!(
                "Option encoding must be equal to one of: #{PLUTIL_FORMAT_MAP.keys}!  You passed \"#{new_resource.encoding}\"."
              )
            end
            shell_out!(PLUTIL_EXECUTABLE, "-convert", PLUTIL_FORMAT_MAP[new_resource.encoding], new_resource.path)
          end
        end

        converge_if_changed :owner do
          converge_by "update owner to #{new_resource.owner}" do
            file new_resource.path do
              owner new_resource.owner
            end
          end
        end

        converge_if_changed :group do
          converge_by "update group to #{new_resource.group}" do
            file new_resource.path do
              group new_resource.group
            end
          end
        end
      end

      ### Question: Should I refactor these methods into an action_class?
      ### Answer: NO
      ### Why: We need them in both the action and in load_current_value. If you put them in the
      ###      action class then they're only in the Provider class and are not available to load_current_value

      def convert_to_data_type_from_string(type, value)
        case type
        when "boolean"
          # Since we've determined this is a boolean data type, we can assume that:
          # If the value as an int is 1, return true
          # If the value as an int is 0 (not 1), return false
          value.to_i == 1
        when "integer"
          value.to_i
        when "float"
          value.to_f
        when "string", "dictionary"
          value
        when nil
          ""
        else
          raise "Unknown or unsupported data type: #{type.class}"
        end
      end

      def type_to_commandline_string(value)
        case value
        when Array
          "array"
        when Integer
          "integer"
        when FalseClass, TrueClass
          "bool"
        when Hash
          "dict"
        when String
          "string"
        when Float
          "float"
        else
          raise "Unknown or unsupported data type: #{value} of #{value.class}"
        end
      end

      def entry_in_plist?(entry, path)
        print_entry = plistbuddy_command :print, entry, path
        cmd = shell_out print_entry
        cmd.exitstatus == 0
      end

      def plistbuddy_command(subcommand, entry, path, value = nil)
        sep = " "
        arg = case subcommand.to_s
              when "add"
                type_to_commandline_string(value)
              when "set"
                if value.is_a?(Hash)
                  sep = ":"
                  value.map { |k, v| "#{k} #{v}" }
                else
                  value
                end
              else
                ""
              end
        entry_with_arg = ["\"#{entry}\"", arg].join(sep).strip
        subcommand = "#{subcommand.capitalize} :#{entry_with_arg}"
        [PLISTBUDDY_EXECUTABLE, "-c", "\'#{subcommand}\'", "\"#{path}\""].join(" ")
      end

      def setting_from_plist(entry, path)
        defaults_read_type_output = shell_out(DEFAULTS_EXECUTABLE, "read-type", path, entry).stdout
        data_type = defaults_read_type_output.split.last

        if value.class == Hash
          plutil_output = shell_out(PLUTIL_EXECUTABLE, "-extract", entry, "xml1", "-o", "-", path).stdout.chomp
          { key_type: data_type, key_value: ::Plist.parse_xml(plutil_output) }
        else
          defaults_read_output = shell_out(DEFAULTS_EXECUTABLE, "read", path, entry).stdout
          { key_type: data_type, key_value: defaults_read_output.strip }
        end
      end
    end
  end
end
