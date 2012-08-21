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

name "chef-sql-schema"
version "osc-int"

dependencies ["ruby",
              "bundler",
              "postgresql",
              "rsync"]

# TODO: use the public git:// uri once this repo is public
source :git => "git@github.com:opscode/chef-sql-schema.git"

relative_path "chef-sql-schema"

build do
  bundle "install --without mysql --path=#{install_dir}/embedded/service/gem"
  command "mkdir -p #{install_dir}/embedded/service/chef-sql-schema"
  command "#{install_dir}/embedded/bin/rsync -a --delete --exclude=.git/*** --exclude=.gitignore ./ #{install_dir}/embedded/service/chef-sql-schema/"
end
