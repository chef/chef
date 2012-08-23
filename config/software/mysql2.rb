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

#
# Enable MySQL support by adding the following to '/etc/chef-server/chef-server.rb':
#
#   postgresql['enable'] = false
#   mysql['enable'] = true
#   mysql['destructive_migrate'] = true
#
# Then run 'chef-server-ctl reconfigure'
#

name "mysql2"
versions_to_install = [ "0.3.6", "0.3.7" ]
version versions_to_install.join("-")

dependencies ["ruby", "bundler"]

build do
  gem "install rake-compiler"
  command "mkdir -p #{install_dir}/embedded/service/gem/ruby/1.9.1/cache"
  versions_to_install.each do |ver|
    gem "fetch mysql2 --version #{ver}", :cwd => "#{install_dir}/embedded/service/gem/ruby/1.9.1/cache"
  end
end
