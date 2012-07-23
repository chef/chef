name "chef-server-scripts"

dependencies [ "rsync", "omnibus-ctl" ]

source :path => File.expand_path("files/chef-server-scripts", Omnibus.root)

build do
  command "mkdir -p #{install_dir}/embedded/bin"
  command "#{install_dir}/embedded/bin/rsync -a ./ #{install_dir}/bin/"

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
