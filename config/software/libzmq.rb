#
# Copyright 2012-2014 Chef Software, Inc.
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
name "libzmq"
default_version "v2.1.11"

dependency "autoconf"
dependency "automake"
dependency "libtool"
dependency "libuuid"

source git: "git://github.com/zeromq/zeromq2-x.git"

relative_path "zeromq2-x"

build do
  env = with_standard_compiler_flags(with_embedded_path)
  env['CXXFLAGS'] = "-L#{install_dir}/embedded/lib -I#{install_dir}/embedded/include"

  command "./autogen.sh", env: env
  command "./configure --prefix=#{install_dir}/embedded", env: env

  make "-j #{workers}", env: env
  make "-j #{workers} install", env: env
end
