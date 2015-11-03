#
# Copyright 2015 Chef Software, Inc.
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

name "kitchen-inspec"
default_version "master"

source git: "https://github.com/chef/kitchen-inspec.git"

if windows?
  dependency "ruby-windows"
  dependency "ruby-windows-devkit"
else
  dependency "ruby"
end

dependency "rubygems"
dependency "bundler"
dependency "test-kitchen"
dependency "inspec"

build do
  env = with_standard_compiler_flags(with_embedded_path)

  bundle "install --without development guard test", env: env

  gem "build kitchen-inspec.gemspec", env: env
  gem "install kitchen-inspec-*.gem" \
      " --no-ri --no-rdoc", env: env
end
