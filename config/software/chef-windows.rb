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

name "chef-windows"

dependency "ruby-windows" #includes rubygems
dependency "libyaml-windows"
dependency "openssl-windows"
dependency "ruby-windows-devkit"
dependency "bundler"
dependency "cacerts"

default_version "master"

source :git => "git://github.com/opscode/chef"

relative_path "chef"

always_build (self.project.name == "chef-windows")

build do
  block do
    if File.exist?("#{project_dir}/chef")
      # We are on Chef 10 and need to adjust the relative path. In Chef 10, the
      # Chef Client and Chef Server were in the same repo (like Rails), but in
      # Chef 11, the server has been moved to its own project.
      software.relative_path('chef/chef')
    end
  end

  # Normally we would symlink the required unix tools.
  # However with the introduction of git-cache to speed up omnibus builds,
  # we can't do that anymore since git on windows doesn't support symlinks.
  # https://groups.google.com/forum/#!topic/msysgit/arTTH5GmHRk
  # Therefore we copy the tools to the necessary places.
  # We need tar for 'knife cookbook site install' to function correctly
  {
    'tar.exe'          => 'bsdtar.exe',
    'libarchive-2.dll' => 'libarchive-2.dll',
    'libexpat-1.dll'   => 'libexpat-1.dll',
    'liblzma-1.dll'    => 'liblzma-1.dll',
    'libbz2-2.dll'     => 'libbz2-2.dll',
    'libz-1.dll'       => 'libz-1.dll',
  }.each do |target, to|
    source = "#{install_dir}/embedded/mingw/bin/#{to}"
    target = "#{install_dir}/bin/#{target}"
    copy(source, target)
  end

  rake "gem"

  gem "install pkg/chef*mingw32.gem" \
      " --bindir '#{install_dir}/bin'" \
      " --no-document" \
      " --verbose"

  # Depending on which shell is being used, the path environment variable can
  # be "PATH" or "Path". If *both* are set, only one is honored.
  path_key = ENV.keys.grep(/\Apath\Z/i).first

  bundle "install", :env => { path_key => "#{install_dir}\\embedded\\bin;#{install_dir}\\embedded\\mingw\\bin;C:\\Windows\\system32;C:\\Windows;C:\\Windows\\System32\\Wbem"}
end
