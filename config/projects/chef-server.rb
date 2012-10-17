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
build_version   Omnibus::BuildVersion.full
build_iteration "1"

deps = []

# global
deps << "chef-gem"
deps << "preparation"
deps << "chef-server-cookbooks"
deps << "chef-server-scripts"
deps << "chef-server-ctl"
deps << "nginx"
deps << "runit"
deps << "unicorn"

# the backend
deps << "postgresql"
deps << "mysql2"
deps << "rabbitmq"
deps << "chef-solr"
deps << "chef-expander"
deps << "bookshelf"

# the front-end services
deps << "erchef"
deps << "chef-pedant"
deps << "chef-server-webui"

# version manifest file
deps << "version-manifest"

dependencies deps

exclude "\.git*"
exclude "bundler\/git"
