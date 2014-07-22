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

name "chefdk"
default_version "master"

source :git => "git://github.com/opscode/chef-dk"

relative_path "chef-dk"

if platform == 'windows'
  dependency "chef-windows"
else
  dependency "chef"
end

dependency "libffi" if debian?
dependency "test-kitchen"
dependency "appbundler"
dependency "berkshelf"
dependency "ohai"
dependency "chef-vault"

build do
  env = {
    # rubocop pulls in nokogiri 1.5.11, so needs PKG_CONFIG_PATH and
    # NOKOGIRI_USE_SYSTEM_LIBRARIES until rubocop stops doing that
    "PKG_CONFIG_PATH" => "#{install_dir}/embedded/lib/pkgconfig",
    "NOKOGIRI_USE_SYSTEM_LIBRARIES" => "true",
  }
  env = with_embedded_path(env)

  def appbundle(app_path, bin_path)
    gemfile = File.join(app_path, "Gemfile.lock")
    env = with_embedded_path.merge("BUNDLE_GEMFILE" => gemfile)
    command("#{install_dir}/embedded/bin/appbundler '#{app_path}' '#{bin_path}'", env: env)
  end

  bundle "install", env: env
  rake "build", env: env

  gem "install pkg/chef-dk*.gem" \
      " --no-document" \
      " --verbose", env: env

  auxiliary_gems = {}
  auxiliary_gems['foodcritic']      = '3.0.3'
  auxiliary_gems['chefspec']        = '3.4.0'
  auxiliary_gems['rubocop']         = '0.18.1'
  auxiliary_gems['knife-spork']     = '1.3.2'
  auxiliary_gems['kitchen-vagrant'] = '0.15.0'
  # Strainer build is hosed on windows
  # auxiliary_gems['strainer'] = '3.3.0'

  # Perform multiple gem installs to better isolate/debug failures
  auxiliary_gems.each do |name, version|
    gem "install #{name}" \
        " --version '#{version}'" \
        " --bindir '#{install_dir}/bin'" \
        " --no-document" \
        " --verbose", env: env
  end

  mkdir("#{install_dir}/embedded/apps")

  appbundler_apps = %w[chef berkshelf test-kitchen chef-dk chef-vault ohai]
  appbundler_apps.each do |app_name|
    copy("#{source_dir}/#{app_name}", "#{install_dir}/embedded/apps/")
    delete("#{install_dir}/embedded/apps/#{app_name}/.git")
    appbundle("#{install_dir}/embedded/apps/#{app_name}", "#{install_dir}/bin")
  end
end
