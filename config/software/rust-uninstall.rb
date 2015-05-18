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

name "rust-uninstall"
default_version "0.0.1"

dependency "rust"

build do
  env = with_standard_compiler_flags(with_embedded_path)

  # Until Omnibus has full support for build depedencies (see chef/omnibus#483)
  # we don't want to ship the Rust and Cargo in our final artifact. Luckily
  # Rust ships with a nice uninstall script which makes it easy to strip
  # everything out.
  command "#{install_dir}/embedded/lib/rustlib/uninstall.sh", env: env
end
