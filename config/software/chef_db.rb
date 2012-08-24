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

name "chef_db"
version "mm/OC-3211"

dependencies ["postgresql", "rsync"]

# TODO: use the public git:// uri once this repo is public
source :git => "git://github.com/opscode/chef_db.git"

relative_path "chef_db"

build do
  command "mkdir -p #{install_dir}/embedded/service/chef_db"
  command "#{install_dir}/embedded/bin/rsync -a --delete --exclude=.git/*** --exclude=.gitignore ./ #{install_dir}/embedded/service/chef_db/"
end
