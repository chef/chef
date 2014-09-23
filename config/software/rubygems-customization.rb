#
# Copyright:: Copyright (c) 2014 Chef Software, Inc.
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

name "rubygems-customization"

source path: "#{project.files_path}/#{name}"

if windows?
  dependency "ruby-windows"
else
  dependency "ruby"
  dependency "rubygems"
end

build do
  block "Add Rubygems customization file" do
    source_customization_file = if windows?
      "#{project_dir}/windows/operating_system.rb"
    else
      "#{project_dir}/default/operating_system.rb"
    end

    site_ruby = Bundler.with_clean_env do
      ruby = windows_safe_path("#{install_dir}/embedded/bin/ruby")
      %x|#{ruby} -rrbconfig -e "puts RbConfig::CONFIG['sitelibdir']"|.strip
    end

    if site_ruby.nil? || site_ruby.empty?
      raise "Could not determine embedded Ruby's site directory, aborting!"
    end

    destination = "#{site_ruby}/rubygems/defaults"

    FileUtils.mkdir_p destination
    FileUtils.cp source_customization_file, destination
  end
end
