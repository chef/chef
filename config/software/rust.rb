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

name "rust"
default_version "2015-04-29"

if mac_os_x?
  host_triple = "apple-darwin"

  version "1.0.0" do
    source md5: "45bbb4f6d4502c2af870e6a74033a707"
  end
  version "2015-04-29" do
    source md5: "33914f7ac0dab1dbc90d279dff8d8e2b"
  end
else
  host_triple = "unknown-linux-gnu"

  version "1.0.0" do
    source md5: "bf108fe44d5f05507418c00ce7a08f3e"
  end
  version "2015-04-29" do
    source md5: "47f8dbf39f2ecf8a67119551ea6dcefd"
  end
end

# Nightly versions of Rust have a slightly different URL structure and
# package name
if version =~ /\d{4}-\d{2}-\d{2}/
  source url: "https://static.rust-lang.org/dist/#{version}/rust-nightly-x86_64-#{host_triple}.tar.gz"
  relative_path "rust-nightly-x86_64-#{host_triple}"
else
  source url: "https://static.rust-lang.org/dist/rust-#{version}-x86_64-#{host_triple}.tar.gz"
  relative_path "rust-#{version}-x86_64-#{host_triple}"
end

build do
  env = with_standard_compiler_flags(with_embedded_path)

  command "./install.sh" \
          " --prefix=#{install_dir}/embedded" \
          " --components=rustc,cargo" \
          " --verbose", env: env
end
