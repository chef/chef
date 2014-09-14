#
# Copyright:: Copyright (c) 2013 Opscode, Inc.
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

name "opscode-pushy-client"

default_version "master"

source git: "git://github.com/opscode/opscode-pushy-client"

relative_path "opscode-pushy-client"

dependency "bundler"
dependency "appbundler"
dependency "chef"
dependency "openssl-customization"

if windows?
  dependency "libzmq-windows"
else
  dependency "libzmq"
end

build do
  env = with_standard_compiler_flags(with_embedded_path)

  zmq_lib_dir = if windows?
                  "#{install_dir}/embedded/bin"
                else
                  "#{install_dir}/embedded/lib"
                end

  # Install the ZMQ gem separately so the native extenstion
  # compiles correctly.
  gem "install zmq" \
      " --no-ri --no-rdoc" \
      " --verbose" \
      " --" \
      " --with-zmq-dir=#{install_dir}/embedded" \
      " --with-zmq-lib=#{zmq_lib_dir}", env: env

  bundle "install", env: env
  gem "build opscode-pushy-client.gemspec", env: env
  gem "install opscode-pushy-client*.gem" \
      " --no-ri --no-rdoc" \
      " --verbose", env: env
end
