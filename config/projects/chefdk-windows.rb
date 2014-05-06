#
# Copyright:: Copyright (c) 2012 Opscode, Inc.
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

name "chefdk-windows"
maintainer "Opscode, Inc."
homepage "http://www.opscode.com"

# NOTE: Ruby DevKit fundamentally CANNOT be installed into "Program Files"
#       Native gems will use gcc which will barf on files with spaces,
#       which is only fixable if everyone in the world fixes their Makefiles
install_path    "c:\\opscode\\chefdk"
build_version   Omnibus::BuildVersion.new.semver
build_iteration 1

package_name    "chef-dk"

override :berkshelf, version: "3.0.0.beta6"
override :bundler,   version: "1.5.2"
override :nokogiri,  version: "1.6.1"

dependency "preparation"
dependency "ruby-windows"
dependency "libyaml-windows"
dependency "ruby-windows-devkit"
dependency "chef-windows"
dependency "chefdk"
