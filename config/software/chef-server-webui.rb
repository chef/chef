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

name "chef-server-webui"
version "master"

dependencies ["ruby", "bundler", "libxml2", "libxslt", "curl", "rsync"]

source :git => "git://github.com/opscode/chef-server-webui"

project_dir = "#{source_dir}/#{name}/#{name}"

build do
  bundle "install --without development test --path=#{install_dir}/embedded/service/gem", :cwd => project_dir
  command "mkdir -p #{install_dir}/embedded/service/chef-server-webui"
  command "#{install_dir}/embedded/bin/rsync -a #{project_dir}/ --delete --exclude=.git/*** --exclude=.gitignore #{install_dir}/embedded/service/chef-server-webui/"
end
