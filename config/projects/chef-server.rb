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

name "chef-server"
maintainer "Opscode, Inc."
homepage "http://www.opscode.com"

replaces        "chef-server"
install_path    "/opt/chef-server"
build_version   Omnibus::BuildVersion.new.semver
build_iteration 1

# creates required build directories
dependency "preparation"

# global
dependency "chef-gem" # for embedded chef-solo
dependency "chef-server-cookbooks" # used by chef-server-ctl reconfigure
dependency "chef-server-scripts" # assorted scripts used by installed instance
dependency "chef-server-ctl" # additional project-specific chef-server-ctl subcommands
dependency "nginx" # load balacning
dependency "runit"
dependency "unicorn" # serves up Rack apps (chef-server-webui)

# the backend
dependency "postgresql"
dependency "rabbitmq"
dependency "chef-solr"
dependency "chef-expander"
dependency "bookshelf" # S3 API compatible object store

# the front-end services
dependency "erchef" # the actual Chef Server REST API
dependency "chef-server-webui"

# integration testing
dependency "chef-pedant" # test ALL THE THINGS!

# version manifest file
dependency "version-manifest"

exclude "\.git*"
exclude "bundler\/git"
