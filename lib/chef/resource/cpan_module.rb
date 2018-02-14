#
# Copyright:: Copyright 2009-2018, Chef Software Inc.
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

require "chef/resource"

class Chef
  class Resource
    class CpanModule < Chef::Resource
      resource_name :cpan_module
      provides :cpan_module

      description "A resource for installing and uninstalling perl CPAN modules."
      introduced "14.0"

      property :module_name,
               String,
               description: "The name of the module if it's different than the name of the resource",
               name_property: true

      property :force,
               [TrueClass, FalseClass],
               description: "To force the install within cpanm",
               default: false

      property :test,
               [TrueClass, FalseClass],
               description: "To do a test install",
               default: false

      property :version,
               String,
               description: "Any version string cpanm would find acceptable"

      property :cwd,
               String,
               description: "A path to change into before running cpanm"

      property :cpanm_binary,
               String,
               description: "The path of the cpanm binary",
               default: "cpanm"

      action :install do
        description "Install the module"

        declare_resource(:execute, "CPAN :install #{new_resource.module_name}") do
          cwd current_working_dir
          command cpanm_install_cmd
          environment "HOME" => current_working_dir, "PATH" => "/usr/local/bin:/usr/bin:/bin"
          not_if { module_exists_new_enough }
        end
      end

      action :uninstall do
        description "Uninstall the module"

        declare_resource(:execute, "CPAN :uninstall #{new_resource.module_name}") do
          cwd current_working_dir
          command cpanm_uninstall_cmd
          only_if { module_exists? }
        end
      end

      action_class do
        def module_exists_new_enough
          existing_version = parse_cpan_version
          return false if existing_version.empty? # mod doesn't exist
          return true if new_resource.version.nil? # mod exists and version is unimportant
          @comparator, @pending_version = new_resource.version.split(" ", 2)
          @current_vers = Gem::Version.new(existing_version)
          @pending_vers = Gem::Version.new(@pending_version)
          @current_vers.method(@comparator).call(@pending_vers)
        end

        def parse_cpan_version
          mod_ver_cmd = Mixlib::ShellOut.new("perl -M#{new_resource.module_name} -e 'print $#{new_resource.module_name}::VERSION;' 2> /dev/null")
          mod_ver_cmd.run_command
          mod_ver = mod_ver_cmd.stdout
          return mod_ver if mod_ver.empty?
          # remove leading v and convert underscores to dots since gems parses them wrong
          mod_ver.gsub!(/v_?(\d)/, '\\1')
          mod_ver.tr!("_", ".")
          # in the event that this command outputs whatever it feels like, only keep the first vers number!
          version_match = /(^[0-9.]*)/.match(mod_ver)
          version_match[0]
        end

        def module_exists?
          !shell_out("perl", "-M", new_resource.module_name, "-e", "1").error?
        end

        def cpanm_install_cmd
          @cmd = "#{new_resource.cpanm_binary} --quiet "
          @cmd += "--force " if new_resource.force
          @cmd += "--notest " unless new_resource.test
          @cmd += new_resource.module_name
          @cmd += parsed_version
          @cmd
        end

        def cpanm_uninstall_cmd
          @cmd = "#{new_resource.cpanm_binary} "
          @cmd += "--force " if new_resource.force
          @cmd += "--uninstall "
          @cmd += new_resource.module_name
          @cmd
        end

        # a bit of a stub, could use a version parser for really consistent experience
        def parsed_version
          return "~\"#{new_resource.version}\"" if new_resource.version
          ""
        end

        def command_path
          return 'C:\\strawberry\\perl\\bin' if platform?("windows")
          "/usr/local/bin:/usr/bin:/bin"
        end

        def current_working_dir
          return new_resource.cwd if new_resource.cwd
          return "/var/root" if platform?("mac_os_x")
          return 'C:\\' if platform?("windows")
          "/root"
        end
      end
    end
  end
end
