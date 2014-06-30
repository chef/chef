#
# Copyright:: Copyright (c) 2012-2014 Chef Software, Inc.
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

name "chef-init"
default_version "master"

source :git => "https://github.com/opscode/chef-init"

relative_path "chef-init"

dependency "runit"
dependency "chef"

env = with_embedded_path()
env = with_standard_compiler_flags(env)

build do
  bundle "install", :env => env
  rake "build", :env => env
  gem ["install pkg/chef-init*.gem -n #{install_dir}/bin",
    "--no-rdoc --no-ri"].join(" "), :env => env
end
