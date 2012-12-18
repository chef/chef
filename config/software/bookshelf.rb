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

name "bookshelf"
version "92fd6d3308ad7bcdd4e7ab64c39c7678973df448"

dependencies ["erlang", "rebar", "rsync"]

source :git => "git://github.com/opscode/bookshelf.git"

relative_path "bookshelf"

env = {
  "PATH" => "#{install_dir}/embedded/bin:#{ENV["PATH"]}",
  "LD_FLAGS" => "-L#{install_dir}/embedded/lib -I#{install_dir}/embedded/include",
  "LD_RUN_PATH" => "#{install_dir}/embedded/lib"
}

build do
  command "make distclean", :env => env
  command "make rel", :env => env
  command "mkdir -p #{install_dir}/embedded/service/bookshelf"
  command "#{install_dir}/embedded/bin/rsync -a --delete ./rel/bookshelf/ #{install_dir}/embedded/service/bookshelf/"
  command "rm -rf #{install_dir}/embedded/service/bookshelf/log"
end
