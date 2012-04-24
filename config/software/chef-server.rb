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
version Omnibus::BuildVersion.version_tag

dependencies ["ruby",
              "rubygems",
              "yajl",
              "bundler",
              "gecode",
              "libxml2",
              "libxslt",
              "curl",
              "couchdb",
              "rabbitmq",
              "jre",
              "unicorn",
              "rsync",
              "omnibus-ctl"]

build do
  gem ["install chef-server",
       "-v #{version}",
       "-n #{install_dir}/bin",
       "--no-rdoc --no-ri"].join(" ")

  # clean up
  ["docs",
   "share/man",
   "share/doc",
   "share/gtk-doc",
   "ssl/man",
   "man",
   "info"].each do |dir|
     command "rm -rf #{install_dir}/embedded/#{dir}"
   end

   command "mkdir -p #{install_dir}/embedded/cookbooks"
   command "#{install_dir}/embedded/bin/rsync --delete -a #{File.expand_path("files/private-chef-cookbooks", Omnibus.root)}/ #{install_dir}/embedded/cookbooks/"

   block do
     open("#{install_dir}/bin/chef-server-ctl", "w") do |file|
       file.print <<-EOH
#!/bin/bash
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

#{install_dir}/embedded/bin/omnibus-ctl chef-server #{install_dir}/embedded/service/omnibus-ctl $1 $2
       EOH
     end
   end

   command "chmod 755 #{install_dir}/bin/chef-server-ctl"

end
