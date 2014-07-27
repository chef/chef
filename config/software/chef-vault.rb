#
# Copyright 2012-2014 Chef Software, Inc.
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

name "chef-vault"
default_version "v2.2.1"

source git: "git://github.com/Nordstrom/chef-vault.git"

relative_path "chef-vault"

if windows?
  dependency "ruby-windows"
  dependency "ruby-windows-devkit"
  dependency "chef-windows"
else
  dependency "ruby"
  dependency "rubygems"
  dependency "chef"
end

build do
  env = with_standard_compiler_flags(with_embedded_path)

  bundle "install", env: env

  gem "build chef-vault.gemspec", env: env

  gem "install chef-vault-*.gem" \
      " --no-ri --no-rdoc", env: env
end
