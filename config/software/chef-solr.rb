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

name "chef-solr"
version ENV["CHEF_GIT_REV"] || "master"

dependencies ["rsync", "jre"]

source :git => "git://github.com/opscode/chef"

service_dir = "#{install_dir}/embedded/service/chef-solr"

build do
  # TODO: when we upgrade solr to > 1.4.1, we should think about
  # building it from source

  command "mkdir -p #{service_dir}"

  # copy solr jetty
  command "mkdir -p #{service_dir}/jetty"
  command "#{install_dir}/embedded/bin/rsync -a chef-solr/solr/solr-jetty/ #{service_dir}/jetty/"

  # copy solr home
  command "mkdir -p #{service_dir}/home"
  command "#{install_dir}/embedded/bin/rsync -a chef-solr/solr/solr-home/ #{service_dir}/home/"
end
