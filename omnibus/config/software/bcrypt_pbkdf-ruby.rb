#
# Copyright:: 2020 Chef Software, Inc.
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

name "bcrypt_pbkdf-ruby"
default_version "master"
relative_path "bcrypt_pbkdf"

source git: "https://github.com/mfazekas/bcrypt_pbkdf-ruby.git"

license "MIT"
license_file "COPYING"

dependency "ruby"

build do
  env = with_embedded_path

  bundle "install", env: env
  bundle "exec rake gem", env: env

  delete "pkg/*java*"

  gem "install pkg/bcrypt_pbkdf-*.gem" \
      " --no-document", env: env
end
