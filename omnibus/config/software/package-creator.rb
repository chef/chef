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

name "package-creator"
description "Downloads Chef Infra Client packages to be used as payload"
default_version "1.0.0"

license :project_license
skip_transitive_dependency_licensing true

build do
  block "Download and unwrap architecture specific packages" do
    system "../creator/create_universal_pkg.sh"
    system "mkdir -p #{install_dir}"
    system "cp ./stage/* #{install_dir}"
  end
end