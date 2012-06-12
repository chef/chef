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
              "runit",
              "nginx",
              "omnibus-ctl"]

version case project.name
        when "chef-server"
          ENV["CHEF_SERVER_GIT_REV"] || "0.10.8"
        else
          "0.10.8"
        end

source :git => "gie://github.com/opscode/chef"

relative_path "chef"

always_build true

build do
  #####################################################################
  #
  # nasty nasty nasty hack for setting artifact version
  #
  #####################################################################
  #
  # since omnibus-ruby is not architected to intentionally let the
  # software definitions define the #build_version and
  # #build_iteration of the package artifact, we're going to implement
  # a temporary hack here that lets us do so. this type of use case
  # will become a feature of omnibus-ruby in the future, but in order
  # to get things shipped, we'll hack it up here.
  #
  # <3 Stephen
  #
  #####################################################################
  block do
    project = self.project
    if %w{chef chef-server}.include? project.name
      git_cmd = "git describe --tags"
      src_dir = self.project_dir
      shell = Mixlib::ShellOut.new(git_cmd,
                                   :cwd => src_dir)
      shell.run_command
      shell.error!
      build_version = shell.stdout.chomp

      project.build_version build_version
      project.build_iteration 1
    end
  end

  rake "gem"

  gem ["install chef-server/pkg/chef-server*.gem",
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
   command "#{install_dir}/embedded/bin/rsync --delete -a #{File.expand_path("files/chef-server-cookbooks", Omnibus.root)}/ #{install_dir}/embedded/cookbooks/"

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
