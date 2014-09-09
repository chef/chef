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

name "ohai"
default_version "master"

source git: "git://github.com/opscode/ohai"

if windows?
  dependency "ruby-windows"
  dependency "ruby-windows-devkit"
else
  dependency "ruby"
  dependency "libffi"
  dependency "rubygems"
end

dependency "bundler"

relative_path "ohai"

env = with_embedded_path()
env = with_standard_compiler_flags(env)

build do
  bundle "install --without development",  :env => env
  bundle "exec rake gem", :env => env

  gem "install pkg/ohai*.gem --no-rdoc --no-ri", :env => env
end
