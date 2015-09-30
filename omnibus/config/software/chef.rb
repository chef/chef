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
name "chef"
default_version "master"

source git: "git://github.com/chef/chef"

relative_path "chef"

if windows?
  dependency "ruby-windows"
  dependency "openssl-windows"
  dependency "ruby-windows-devkit"
  dependency "ruby-windows-devkit-bash"
  dependency "cacerts"
else
  dependency "ruby"
  dependency "libffi"
end

dependency "rubygems"
dependency "bundler"
dependency "ohai"
dependency "appbundler"

build do
  env = with_standard_compiler_flags(with_embedded_path)

  if windows?
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
      copy "#{install_dir}/embedded/mingw/bin/#{to}", "#{install_dir}/bin/#{target}"
    end

    bundle "install --without server docgen", env: env

    # Install components that live inside Chef's git repo. For now this is just
    # 'chef-config'
    bundle "exec rake install_components", env: env

    gem "build chef-{windows,x86-mingw32}.gemspec", env: env

    gem "install chef*mingw32.gem" \
        " --no-ri --no-rdoc" \
        " --verbose", env: env

    block "Build Event Log Dll" do
      Dir.chdir software.project_dir do
        rake = windows_safe_path("#{install_dir}/embedded/bin/rake")
        `#{rake} -rdevkit build_eventlog"` if File.exist? "#{software.project_dir}/ext/win32-eventlog"
      end
    end
  else

    # install the whole bundle first
    bundle "install --without server docgen", env: env

    # Install components that live inside Chef's git repo. For now this is just
    # 'chef-config'
    bundle "exec rake install_components", env: env

    gem "build chef.gemspec", env: env

    # Don't use -n #{install_dir}/bin. Appbundler will take care of them later
    gem "install chef*.gem " \
        " --no-ri --no-rdoc", env: env

  end

  auxiliary_gems = {}
  auxiliary_gems['ruby-shadow'] = '>= 0.0.0' unless aix? || windows?

  auxiliary_gems.each do |name, version|
    gem "install #{name}" \
        " --version '#{version}'" \
        " --no-ri --no-rdoc" \
        " --verbose", env: env
  end

  appbundle 'chef'
  appbundle 'ohai'

  # Clean up
  delete "#{install_dir}/embedded/docs"
  delete "#{install_dir}/embedded/share/man"
  delete "#{install_dir}/embedded/share/doc"
  delete "#{install_dir}/embedded/share/gtk-doc"
  delete "#{install_dir}/embedded/ssl/man"
  delete "#{install_dir}/embedded/man"
  delete "#{install_dir}/embedded/info"
end
