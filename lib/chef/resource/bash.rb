#
# Author:: Adam Jacob (<adam@chef.io>)
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

require_relative "script"

class Chef
  class Resource
    class Bash < Chef::Resource::Script

      provides :bash, target_mode: true
      target_mode support: :full

      description "Use the **bash** resource to execute scripts using the Bash interpreter. This resource may also use any of the actions and properties that are available to the **execute** resource. Commands that are executed with this resource are (by their nature) not idempotent, as they are typically unique to the environment in which they are run. Use `not_if` and `only_if` to guard this resource for idempotence."
      examples <<~'DOC'
      **Compile an application**

      ```ruby
      bash 'install_something' do
        user 'root'
        cwd '/tmp'
        code <<-EOH
          wget http://www.example.com/tarball.tar.gz
          tar -zxf tarball.tar.gz
          cd tarball
          ./configure
          make
          make install
        EOH
      end
      ```

      **Using escape characters in a string of code**

      In the following example, the `find` command uses an escape character (`\`). Use a second escape character (`\\`) to preserve the escape character in the code string:

      ```ruby
      bash 'delete some archives ' do
        code <<-EOH
          find ./ -name "*.tar.Z" -mtime +180 -exec rm -f {} \\;
        EOH
        ignore_failure true
      end
      ```

      **Install a file from a remote location**

      The following is an example of how to install the foo123 module for Nginx. This module adds shell-style functionality to an Nginx configuration file and does the following:

        - Declares three variables
        - Gets the Nginx file from a remote location
        - Installs the file using Bash to the path specified by the `src_filepath` variable

      ```ruby
      src_filename = "foo123-nginx-module-v#{node['nginx']['foo123']['version']}.tar.gz"
      src_filepath = "#{Chef::Config['file_cache_path']}/#{src_filename}"
      extract_path = "#{Chef::Config['file_cache_path']}/nginx_foo123_module/#{node['nginx']['foo123']['checksum']}"

      remote_file 'src_filepath' do
        source node['nginx']['foo123']['url']
        checksum node['nginx']['foo123']['checksum']
        owner 'root'
        group 'root'
        mode '0755'
      end

      bash 'extract_module' do
        cwd ::File.dirname(src_filepath)
        code <<-EOH
          mkdir -p #{extract_path}
          tar xzf #{src_filename} -C #{extract_path}
          mv #{extract_path}/*/* #{extract_path}/
        EOH
        not_if { ::File.exist?(extract_path) }
      end
      ```

      **Install an application from git**

      ```ruby
      git "#{Chef::Config[:file_cache_path]}/ruby-build" do
        repository 'git://github.com/rbenv/ruby-build.git'
        revision 'master'
        action :sync
      end

      bash 'install_ruby_build' do
        cwd "#{Chef::Config[:file_cache_path]}/ruby-build"
        user 'rbenv'
        group 'rbenv'
        code <<-EOH
          ./install.sh
        EOH
        environment 'PREFIX' => '/usr/local'
      end
      ```

      **Using Attributes in Bash Code**

      The following recipe shows how an attributes file can be used to store certain settings. An attributes file is located in the `attributes/`` directory in the same cookbook as the recipe which calls the attributes file. In this example, the attributes file specifies certain settings for Python that are then used across all nodes against which this recipe will run.

      Python packages have versions, installation directories, URLs, and checksum files. An attributes file that exists to support this type of recipe would include settings like the following:

      ```ruby
      default['python']['version'] = '2.7.1'

      if python['install_method'] == 'package'
        default['python']['prefix_dir'] = '/usr'
      else
        default['python']['prefix_dir'] = '/usr/local'
      end

      default['python']['url'] = 'http://www.python.org/ftp/python'
      default['python']['checksum'] = '80e387...85fd61'
      ```

      and then the methods in the recipe may refer to these values. A recipe that is used to install Python will need to do the following:

        - Identify each package to be installed (implied in this example, not shown)
        - Define variables for the package `version` and the `install_path`
        - Get the package from a remote location, but only if the package does not already exist on the target system
        - Use the **bash** resource to install the package on the node, but only when the package is not already installed

      ```ruby
      version = node['python']['version']
      install_path = "#{node['python']['prefix_dir']}/lib/python#{version.split(/(^\d+\.\d+)/)[1]}"

      remote_file "#{Chef::Config[:file_cache_path]}/Python-#{version}.tar.bz2" do
        source "#{node['python']['url']}/#{version}/Python-#{version}.tar.bz2"
        checksum node['python']['checksum']
        mode '0755'
        not_if { ::File.exist?(install_path) }
      end

      bash 'build-and-install-python' do
        cwd Chef::Config[:file_cache_path]
        code <<-EOF
          tar -jxvf Python-#{version}.tar.bz2
          (cd Python-#{version} && ./configure #{configure_options})
          (cd Python-#{version} && make && make install)
        EOF
        not_if { ::File.exist?(install_path) }
      end
      ```
      DOC

      def initialize(name, run_context = nil)
        super
        @interpreter = "bash"
      end

    end
  end
end
