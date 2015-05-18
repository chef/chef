#
# Copyright 2015 Chef Software, Inc.
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

name "delivery-cli"
default_version "master"

source git: "https://github.com/chef/delivery-cli.git"

dependency "openssl"
dependency "rust"

build do
  env = with_standard_compiler_flags(with_embedded_path)

  # The rust core libraries are dynamicaly linked
  env['LD_LIBRARY_PATH']            = "#{install_dir}/embedded/lib"
  env['DYLD_FALLBACK_LIBRARY_PATH'] = "#{install_dir}/embedded/lib:" if mac_os_x?

  command "cargo test -j #{workers}", env: env
  command "cargo build -j #{workers} --release", env: env

  mkdir "#{install_dir}/bin"
  copy "#{project_dir}/target/release/delivery", "#{install_dir}/bin/delivery"
end
