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

name "ruby-windows"

version "1.9.3-p286"

relative_path "ruby-#{version}-i386-mingw32"

source :url => "http://rubyforge.org/frs/download.php/76528/ruby-#{version}-i386-mingw32.7z",
       :md5 => "8ba0d2203590dbf8e9d59d9d731c05d0"

build do
  command "robocopy . #{install_dir}\\embedded\\ /MIR"
end
