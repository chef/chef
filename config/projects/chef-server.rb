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

replaces        "chef-server"
install_path    "/opt/chef-server"
build_version   Omnibus::BuildVersion.new.semver
build_iteration "1"

deps = []

# Hacky but allows us to set the embedded chef version that is installed.
# Once omnibus-ruby supports proper software definition version overrides
# (either externally or at the project level) this can go away.
ENV['CHEF_GIT_REV'] ||= "master"

# global
deps << "chef" # for embedded chef-solo
deps << "preparation" # creates required build directories
deps << "chef-server-cookbooks" # used by chef-server-ctl reconfigure
deps << "chef-server-scripts" # assorted scripts used by installed instance
deps << "chef-server-ctl" # additional project-specific chef-server-ctl subcommands
deps << "nginx" # load balacning
deps << "runit"
deps << "unicorn" # serves up Rack apps (chef-server-webui)

# the backend
deps << "postgresql"
deps << "rabbitmq"
deps << "chef-solr"
deps << "chef-expander"
deps << "bookshelf" # S3 API compatible object store

# the front-end services
deps << "erchef" # the actual Chef Server REST API
deps << "chef-server-webui"

# integration testing
deps << "chef-pedant" # test ALL THE THINGS!

# version manifest file
deps << "version-manifest"

dependencies deps

exclude "\.git*"
exclude "bundler\/git"
