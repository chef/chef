#
# Author:: Adam Edwards (<adamed@chef.io>)
#
# Copyright:: Copyright (c) Chef Software Inc.
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

require_relative "../../mixin/powershell_exec"

class Chef::Util::DSC
  class ConfigurationGenerator
    include Chef::Mixin::PowershellExec

    def initialize(node, config_directory)
      @node = node
      @config_directory = config_directory
    end

    def configuration_document_from_script_code(code, configuration_flags, imports)
      Chef::Log.trace("DSC: DSC code:\n '#{code}'")
      generated_script_path = write_document_generation_script(code, "chef_dsc", imports)
      begin
        configuration_document_from_script_path(generated_script_path, "chef_dsc", configuration_flags)
      ensure
        ::FileUtils.rm(generated_script_path)
      end
    end

    def configuration_document_from_script_path(script_path, configuration_name, configuration_flags)
      validate_configuration_name!(configuration_name)

      config_generation_code = configuration_document_generation_code(script_path, configuration_name)
      switches_string = command_switches_string(get_merged_configuration_flags!(configuration_flags, configuration_name))

      powershell_exec!("#{config_generation_code} #{switches_string}")
      configuration_document_location = find_configuration_document(configuration_name)

      unless configuration_document_location
        raise "No DSC configuration for '#{configuration_name}' was generated from supplied DSC script"
      end

      configuration_document = get_configuration_document(configuration_document_location)
      ::FileUtils.rm_rf(configuration_document_location)
      configuration_document
    end

    protected

    def validate_switch_name!(switch_parameter_name)
      unless switch_parameter_name.match?(/\A[A-Za-z]+[_a-zA-Z0-9]*\Z/)
        raise ArgumentError, "`#{switch_parameter_name}` is not a valid PowerShell cmdlet switch parameter name"
      end
    end

    def escape_parameter_value(parameter_value)
      parameter_value.gsub(/(`|'|"|#)/, '`\1')
    end

    def escape_string_parameter_value(parameter_value)
      "'#{escape_parameter_value(parameter_value)}'"
    end

    def command_switches_string(switches)
      command_switches = switches.map do |switch_name, switch_value|
        if switch_name.class != Symbol
          raise ArgumentError, "Invalid type `#{switch_name} `for PowerShell switch '#{switch_name}'. The switch must be specified as a Symbol'"
        end

        validate_switch_name!(switch_name)

        switch_argument = ""
        switch_present = true

        case switch_value
        when Numeric, Float
          switch_argument = switch_value.to_s
        when FalseClass
          switch_present = false
        when TrueClass
          # nothing
        when String
          switch_argument = escape_string_parameter_value(switch_value)
        else
          raise ArgumentError, "Invalid argument type `#{switch_value.class}` specified for PowerShell switch `:#{switch_name}`. Arguments to PowerShell must be of type `String`, `Numeric`, `Float`, `FalseClass`, or `TrueClass`"
        end

        switch_present ? ["-#{switch_name.to_s.downcase}", switch_argument].join(" ").strip : ""
      end

      command_switches.join(" ")
    end

    # From PowerShell error help for the Configuration language element:
    #   Standard names may only contain letters (a-z, A-Z), numbers (0-9), and underscore (_).
    #   The name may not be null or empty, and should start with a letter.
    def validate_configuration_name!(configuration_name)
      if !!(configuration_name =~ /\A[A-Za-z]+[_a-zA-Z0-9]*\Z/) == false
        raise ArgumentError, "Configuration `#{configuration_name}` is not a valid PowerShell cmdlet name"
      end
    end

    def get_merged_configuration_flags!(configuration_flags, configuration_name)
      merged_configuration_flags = { outputpath: configuration_document_directory(configuration_name) }
      if configuration_flags
        configuration_flags.map do |switch, value|
          if merged_configuration_flags.key?(switch.to_s.downcase.to_sym)
            raise ArgumentError, "The `flags` attribute for the dsc_script resource contained a command line switch :#{switch} that is disallowed."
          end

          merged_configuration_flags[switch.to_s.downcase.to_sym] = value
        end
      end
      merged_configuration_flags
    end

    def configuration_code(code, configuration_name, imports)
      <<~EOF
        $ProgressPreference = 'SilentlyContinue';
        Configuration '#{configuration_name}'
        {
          #{generate_import_resource_statements(imports).join("  \n")}
          node 'localhost'
          {
            #{code}
          }
        }
      EOF
    end

    def generate_import_resource_statements(imports)
      if imports
        imports.map do |resource_module, resources|
          if resources.length == 0 || resources.include?("*")
            "Import-DscResource -ModuleName #{resource_module}"
          else
            "Import-DscResource -ModuleName #{resource_module} -Name #{resources.join(",")}"
          end
        end
      else
        []
      end
    end

    def configuration_document_generation_code(configuration_script, configuration_name)
      ". '#{configuration_script}';#{configuration_name}"
    end

    def write_document_generation_script(code, configuration_name, imports)
      script_path = "#{@config_directory}/chef_dsc_config.ps1"
      ::File.open(script_path, "wt") do |script|
        script.write(configuration_code(code, configuration_name, imports))
      end
      script_path
    end

    def find_configuration_document(configuration_name)
      document_directory = configuration_document_directory(configuration_name)
      document_file_name = ::Dir.entries(document_directory).find { |path| path =~ /.*.mof/ }
      ::File.join(document_directory, document_file_name) if document_file_name
    end

    def configuration_document_directory(configuration_name)
      ::File.join(@config_directory, configuration_name)
    end

    def get_configuration_document(document_path)
      ::File.open(document_path, "rb", &:read)
    end
  end
end
