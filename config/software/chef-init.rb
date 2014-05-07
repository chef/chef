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
default_version "0.1.0"

source :url => "http://smarden.org/runit/runit-2.1.1.tar.gz",
       :md5 => "8fa53ea8f71d88da9503f62793336bc3"

relative_path "admin"

working_dir = "#{project_dir}/runit-2.1.1"

build do
  # put runit where we want it, not where they tell us to
  command 'sed -i -e "s/^char\ \*varservice\ \=\"\/service\/\";$/char\ \*varservice\ \=\"' + project.install_path.gsub("/", "\\/") + '\/service\/\";/" src/sv.c', :cwd => working_dir
  # TODO: the following is not idempotent
  command "sed -i -e s:-static:: src/Makefile", :cwd => working_dir

  # build it
  command "make", :cwd => "#{working_dir}/src"
  command "make check", :cwd => "#{working_dir}/src"

  # move it
  command "mkdir -p #{install_dir}/embedded/bin"
  ["src/chpst",
   "src/runit",
   "src/runit-init",
   "src/runsv",
   "src/runsvchdir",
   "src/runsvdir",
   "src/sv",
   "src/svlogd",
   "src/utmpset"].each do |bin|
    command "cp #{bin} #{install_dir}/embedded/bin", :cwd => working_dir
  end

  # set up service directories
  block do
    ["#{install_dir}/service",
     "#{install_dir}/sv",
     "#{install_dir}/init"].each do |dir|
      FileUtils.mkdir_p(dir)
      # make sure cached builds include this dir
      FileUtils.touch(File.join(dir, '.gitkeep'))
    end
  end

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

PATH=#{install_dir}/bin:#{install_dir}/embedded/bin:/usr/local/bin:/usr/local/sbin:/bin:/sbin:/usr/bin:/usr/sbin

# Setup first run directory
mkdir -p /etc/chef/first-run
cd /etc/chef/first-run

# If the user passes a Berksfile through ENV VAR
if [ "$BERKSFILE" ]; then

  # Create berkshelf directory
  mkdir -p /etc/chef/first-run/.berkshelf
  echo -e "$BERKSHELF_PATH"

  echo -e "$BERKSFILE"

  # Save the Berksfile
  echo -e "$BERKSFILE" >> /etc/chef/first-run/Berksfile

  # Vendor the cookbooks
  exec env - PATH=$PATH BERKSHELF_PATH=/etc/chef/first-run/.berkshelf \
    berks vendor /etc/chef/first-run/cookbooks 
fi

if [ "$CHEF_RUN_LIST" ]; then
  # Execute chef-local-mode
  exec env - PATH=$PATH \
    chef-client -z -o $CHEF_RUN_LIST
fi

# Start the other services
exec env - PATH=$PATH \
  runsvdir -P #{install_dir}/service 'log: ...........................................................................................................................................................................................................................................................................................................................................................................................................'
       EOH
    end
  end

  command "chmod 755 #{install_dir}/bin/chef-init"

end
