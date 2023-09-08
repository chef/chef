#
# Copyright 2023 Chef Software, Inc.
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
# expeditor/ignore: deprecated 2021-04

name "test_libarchive"
default_version "main"
relative_path "test_libarchive"

source git: "https://github.com/stringsn88keys/test_libarchive.git"

license "MIT"
license_file "LICENSE"

dependency "libarchive"

build do
  env = with_embedded_path

  make env: env if aix?
end
