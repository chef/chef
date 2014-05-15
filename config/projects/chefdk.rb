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

name       "chefdk"
friendly_name "Chef Development Kit"
maintainer "Chef Software, Inc."
homepage   "http://www.getchef.com"

install_path    "/opt/chefdk"

build_iteration 1
build_version do
  # Use chefdk to determine the build version
  source :git, from_dependency: 'chefdk'

  # Set a Rubygems style version
  output_format :git_describe
end

mac_pkg_identifier "com.getchef.pkg.chefdk"
resources_path File.join(files_path, "chefdk")

override :berkshelf, version: "master"
override :bundler,   version: "1.5.2"
override :libedit,   version: "20130712-3.1"
override :libtool,   version: "2.4.2"
override :libxml2,   version: "2.9.1"
override :libxslt,   version: "1.1.28"
override :ruby,      version: "2.1.1"
override :rubygems,  version: "2.2.1"
override :yajl,      version: "1.2.0"
override :zlib,      version: "1.2.8"

dependency "preparation"
dependency "chefdk"
dependency "rubygems-customization"
dependency "version-manifest"
