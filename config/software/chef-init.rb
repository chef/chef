#
# Copyright:: Copyright (c) 2012-2014 Chef Software, Inc.
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

name "chef-init"

dependency "runit"

build do
  block do
    open("#{install_dir}/bin/chef-init", "w") do |file|
      file.print <<-EOH
#!/bin/bash
#
# Copyright:: Copyright (c) 2012-2014 Chef Software, Inc.
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

export PATH=#{install_dir}/bin:#{install_dir}/embedded/bin:/usr/local/bin:/usr/local/sbin:/bin:/sbin:/usr/bin:/usr/sbin


run_chef=true
exec_cmd="runsvdir -p #{install_dir}/service 'log: #{ "." * 395 }'"

while [[ $# > 1 ]]
for i in "$@"
do
  case $i in 
    --onboot) 
      run_chef=true
      shift
      ;;
    --no-chef-onboot)
      run_chef=false
      shift
      ;;
    --with-exec=*)
      exec_cmd="${i#*=}"
      shift
      ;;
    *)
      shift
      ;;
  esac
done

if [ "$run_chef" = true ]; then
  if [ -f /chef/zero.rb ]; then
    chef-client -z -c /chef/zero.rb -j /chef/first-boot.json
  fi

  if [ -f /chef/client.rb ]; then
    chef-client -c /chef/client.rb -j /chef/first-boot.json
  fi
fi

eval "exec env - PATH=$PATH $exec_cmd"
      EOH
    end
  end

  command "chmod 755 #{install_dir}/bin/chef-init"
end
