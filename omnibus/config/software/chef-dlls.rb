#
# Copyright:: Copyright Chef Software, Inc.
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

# This is a windows only dependency

name "chef-dlls"

skip_transitive_dependency_licensing true
license :project_license

build do
  block "Install windows powershell dlls to \\embedded\bin" do
    # Copy the chef gem's distro stuff over
    chef_gem_path = File.expand_path("../..", shellout!("#{install_dir}/embedded/bin/gem which chef").stdout.chomp)

    chef_module_dir = "#{install_dir}/embedded/bin"
    require "fileutils"
    FileUtils.cp_r "#{chef_gem_path}/chef-powershell/bin/ruby_bin_folder/AMD64/.", chef_module_dir, verbose: true
  end
end
