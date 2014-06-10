#
# Copyright:: Copyright (c) 2012-2014 Chef Software, Inc.
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
dependency "chef-vault"

sep = File::PATH_SEPARATOR || ":"
path = "#{install_dir}/embedded/bin#{sep}#{ENV['PATH']}"

build do
  path_key = ENV.keys.grep(/\Apath\Z/i).first

  env = {
    # rubocop pulls in nokogiri 1.5.11, so needs PKG_CONFIG_PATH and
    # NOKOGIRI_USE_SYSTEM_LIBRARIES until rubocop stops doing that
    "PKG_CONFIG_PATH" => "#{install_dir}/embedded/lib/pkgconfig",
    "NOKOGIRI_USE_SYSTEM_LIBRARIES" => "true",
    path_key => path
  }


  def appbuilder(app_path, bin_path)
    path_key = ENV.keys.grep(/\Apath\Z/i).first
    path = path_with_embedded

    gemfile = File.join(app_path, "Gemfile.lock")
    command("#{install_dir}/embedded/bin/appbundler #{app_path} #{bin_path}",
            :env => {
      'RUBYOPT'         => nil,
      'BUNDLE_BIN_PATH' => nil,
      'BUNDLE_GEMFILE'  => gemfile,
      'GEM_PATH'        => nil,
      'GEM_HOME'        => nil,
      path_key          => path
    })
  end

  bundle "install", :env => {path_key => path}
  rake "build", :env => env.merge({path_key => path})

  gem ["install pkg/chef-dk*.gem",
      "--no-rdoc --no-ri"].join(" "), :env => env.merge({path_key => path})

  auxiliary_gems = []

  auxiliary_gems << {name: 'foodcritic',  version: '3.0.3'}
  auxiliary_gems << {name: 'chefspec',    version: '3.4.0'}
  auxiliary_gems << {name: 'rubocop',     version: '0.18.1'}
  auxiliary_gems << {name: 'knife-spork', version: '1.3.2'}
  auxiliary_gems << {name: 'kitchen-vagrant', version: '0.15.0'}
  # strainer build is hosed on windows
  # auxiliary_gems << {name: 'strainer',    version: '3.3.0'}

  # do multiple gem installs to better isolate/debug failures
  auxiliary_gems.each do |g|
    gem "install #{g[:name]} -v #{g[:version]} -n #{install_dir}/bin --no-rdoc --no-ri --verbose", :env => env
  end

  block { FileUtils.mkdir_p("#{install_dir}/embedded/apps") }

  appbundler_apps = %w[chef berkshelf test-kitchen chef-dk chef-vault]
  appbundler_apps.each do |app_name|
    block { FileUtils.cp_r("#{source_dir}/#{app_name}", "#{install_dir}/embedded/apps/") }
    block { FileUtils.rm_rf("#{install_dir}/embedded/apps/#{app_name}/.git") }
    appbuilder("#{install_dir}/embedded/apps/#{app_name}", "#{install_dir}/bin")
  end
end
