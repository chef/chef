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

name "ruby-windows-devkit"

version "4.5.2-20111229-1559"

source :url => "http://cloud.github.com/downloads/oneclick/rubyinstaller/DevKit-tdm-32-#{version}-sfx.exe",
       :md5 => "4bf8f2dd1d582c8733a67027583e19a6"

dependencies ["ruby-windows"]

build do
  command "DevKit-tdm-32-#{version}-sfx.exe -y -oC:\\opscode\\chef\\embedded"
  command "echo - C:/opscode/chef/embedded > config.yml", :cwd => "C:\\opscode\\chef\\embedded"
  ruby "dk.rb install", :cwd => "C:\\opscode\\chef\\embedded"
end
