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

# We use the version in util-linux, and only build the libuuid subdirectory
name "libuuid"
default_version "2.21"

dependency "autoconf"
dependency "automake"

source :url => "ftp://ftp.kernel.org/pub/linux/utils/util-linux/v2.21/util-linux-2.21.tar.gz",
       :md5 => "4222aa8c2a1b78889e959a4722f1881a"

relative_path "util-linux-2.21"

build do
  env = {
    "LDFLAGS" => "-L#{install_dir}/embedded/lib -I#{install_dir}/embedded/include",
    "CFLAGS" => "-L#{install_dir}/embedded/lib -I#{install_dir}/embedded/include",
    "LD_RUN_PATH" => "#{install_dir}/embedded/lib"
  }
  command(["./configure",
           "--prefix=#{install_dir}/embedded",
           ].join(" "),
          :env => env)
  command "cd libuuid && make -j #{max_build_jobs}", :env => {"LD_RUN_PATH" => "#{install_dir}/embedded/bin"}
  command "cd libuuid && make install", :env => {"LD_RUN_PATH" => "#{install_dir}/embedded/bin"}
end
