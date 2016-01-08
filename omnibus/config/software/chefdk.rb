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

name "chefdk"
default_version "master"

source git: "git://github.com/chef/chef-dk.git"

relative_path "chef-dk"

if windows?
  dependency "ruby-windows"
  dependency "ruby-windows-devkit"
else
  dependency "libffi" if debian?
  dependency "ruby"
end

dependency "rubygems"
dependency "bundler"
dependency "appbundler"
dependency "chef"
dependency "berkshelf"
dependency "chef-vault"
dependency "foodcritic"
dependency "ohai"
dependency "inspec"
dependency "rubocop"
dependency "test-kitchen"
dependency "kitchen-inspec"
dependency "kitchen-vagrant"
# This is a TK dependency but isn't declared in that software definition
# because it is an optional dependency but we want to give it to ChefDK users
dependency "winrm-transport"
dependency "openssl-customization"
dependency "knife-windows"
dependency "knife-spork"
dependency "fauxhai"
dependency "chefspec"

dependency "chefdk-env-customization" if windows?

build do
  env = with_standard_compiler_flags(with_embedded_path).merge(
    # Rubocop pulls in nokogiri 1.5.11, so needs PKG_CONFIG_PATH and
    # NOKOGIRI_USE_SYSTEM_LIBRARIES until rubocop stops doing that
    "PKG_CONFIG_PATH" => "#{install_dir}/embedded/lib/pkgconfig",
    "NOKOGIRI_USE_SYSTEM_LIBRARIES" => "true",
  )

  bundle "install", env: env
  gem "build chef-dk.gemspec", env: env
  gem "install chef-dk*.gem" \
      " --no-ri --no-rdoc" \
      " --verbose", env: env

  appbundle 'berkshelf'
  appbundle 'chefdk'
  appbundle 'chef-vault'
  appbundle 'foodcritic'
  appbundle 'rubocop'
  appbundle 'test-kitchen'
end
