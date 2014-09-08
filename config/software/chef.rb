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

dependency "ruby"
dependency "rubygems"
dependency "libffi"
dependency "bundler"
dependency "appbundler"

default_version "master"

source :git => "git://github.com/opscode/chef"

relative_path "chef"

build do
  env = with_standard_compiler_flags(with_embedded_path)

  def appbundle(app_path, bin_path)
    gemfile = File.join(app_path, "Gemfile.lock")
    env = with_embedded_path.merge("BUNDLE_GEMFILE" => gemfile)
    command("#{install_dir}/embedded/bin/appbundler '#{app_path}' '#{bin_path}'", env: env)
  end

  block do
    if File.exist?("#{project_dir}/chef")
      # We are on Chef 10 and need to adjust the relative path. In Chef 10, the
      # Chef Client and Chef Server were in the same repo (like Rails), but in
      # Chef 11, the server has been moved to its own project.
      software.relative_path('chef/chef')
    end
  end

  # install the whole bundle first
  bundle "install --without server docgen", env: env
  rake "gem", env: env

  # Delete the windows gem
  command "rm -f pkg/chef-*-x86-mingw32.gem"

  # Don't use -n #{install_dir}/bin. Appbundler will take care of them later
  gem "install pkg/chef-*.gem " \
      " --no-ri --no-rdoc", env: env

  auxiliary_gems = {}
  auxiliary_gems['ruby-shadow'] = '>= 0.0.0' unless Ohai['platform'] == 'aix'

  auxiliary_gems.each do |name, version|
    gem "install #{name}" \
        " --version '#{version}'" \
        " --no-ri --no-rdoc" \
        " --verbose", env: env
  end

  # Appbundler is run by the main software in a project. If we are building chef
  # for chefdk skip appbundler. chefdk will take care of this
  unless project.name == "chefdk"
    mkdir("#{install_dir}/embedded/apps")

    appbundler_apps = %w[chef]
    appbundler_apps.each do |app_name|
      copy("#{source_dir}/#{app_name}", "#{install_dir}/embedded/apps/")
      delete("#{install_dir}/embedded/apps/#{app_name}/.git")
      appbundle("#{install_dir}/embedded/apps/#{app_name}", "#{install_dir}/bin")
    end
  end

  # Clean up
  delete("#{install_dir}/embedded/docs")
  delete("#{install_dir}/embedded/share/man")
  delete("#{install_dir}/embedded/share/doc")
  delete("#{install_dir}/embedded/share/gtk-doc")
  delete("#{install_dir}/embedded/ssl/man")
  delete("#{install_dir}/embedded/man")
  delete("#{install_dir}/embedded/info")
end
