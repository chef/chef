#
# Author:: Adam Edwards (<adamed@chef.io>)
#
# Copyright:: Copyright 2014-2016, Chef Software, Inc.
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

require "chef/util/powershell/cmdlet"

class Chef::Util::DSC
  class ConfigurationGenerator
    def initialize(node, config_directory)
      @node = node
      @config_directory = config_directory
    end

    def configuration_document_from_script_code(code, configuration_flags, imports, shellout_flags)
      Chef::Log.debug("DSC: DSC code:\n '#{code}'")
      generated_script_path = write_document_generation_script(code, "chef_dsc", imports)
      begin
        configuration_document_from_script_path(generated_script_path, "chef_dsc", configuration_flags, shellout_flags)
      ensure
        ::FileUtils.rm(generated_script_path)
      end
    end

    def configuration_document_from_script_path(script_path, configuration_name, configuration_flags, shellout_flags)
      validate_configuration_name!(configuration_name)

      document_generation_cmdlet = Chef::Util::Powershell::Cmdlet.new(
        @node,
        configuration_document_generation_code(script_path, configuration_name))

      merged_configuration_flags = get_merged_configuration_flags!(configuration_flags, configuration_name)

      document_generation_cmdlet.run!(merged_configuration_flags, shellout_flags)
      configuration_document_location = find_configuration_document(configuration_name)

      if ! configuration_document_location
        raise "No DSC configuration for '#{configuration_name}' was generated from supplied DSC script"
      end

      configuration_document = get_configuration_document(configuration_document_location)
      ::FileUtils.rm_rf(configuration_document_location)
      configuration_document
    end

    protected

    # From PowerShell error help for the Configuration language element:
    #   Standard names may only contain letters (a-z, A-Z), numbers (0-9), and underscore (_).
    #   The name may not be null or empty, and should start with a letter.
    def validate_configuration_name!(configuration_name)
      if !!(configuration_name =~ /\A[A-Za-z]+[_a-zA-Z0-9]*\Z/) == false
        raise ArgumentError, 'Configuration `#{configuration_name}` is not a valid PowerShell cmdlet name'
      end
    end

    def get_merged_configuration_flags!(configuration_flags, configuration_name)
      merged_configuration_flags = { :outputpath => configuration_document_directory(configuration_name) }
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
      <<-EOF
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
            "Import-DscResource -ModuleName #{resource_module} -Name #{resources.join(',')}"
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
      ::File.open(document_path, "rb") do |file|
        file.read
      end
    end
  end
end
