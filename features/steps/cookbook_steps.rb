#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2008 Opscode, Inc.
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

Given /^a local cookbook repository$/ do 
  Dir.mkdir(File.join(tmpdir, 'cookbooks_dir'))
  Dir.mkdir(File.join(tmpdir, 'cookbooks_dir', 'cookbooks'))
  Dir.mkdir(File.join(tmpdir, 'cookbooks_dir', 'config'))
  system("cp #{datadir}/Rakefile #{tmpdir}/cookbooks_dir")
  system("cp -r #{datadir}/config/* #{tmpdir}/cookbooks_dir/config")
  system("cp -r #{datadir}/cookbooks/* #{tmpdir}/cookbooks_dir/cookbooks")
  cleanup_dirs << "#{tmpdir}/cookbooks_dir"
end

Given /^a local cookbook named '(.+)'$/ do |cb|
  Dir.mkdir(File.join(tmpdir, 'cookbooks_dir'))
  Dir.mkdir(File.join(tmpdir, 'cookbooks_dir', 'cookbooks'))
  Dir.mkdir(File.join(tmpdir, 'cookbooks_dir', 'config'))
  system("cp #{datadir}/Rakefile #{tmpdir}/cookbooks_dir")
  system("cp -r #{datadir}/config/* #{tmpdir}/cookbooks_dir/config")
  system("cp -r #{datadir}/cookbooks/#{cb} #{tmpdir}/cookbooks_dir/cookbooks")
  cleanup_dirs << "#{tmpdir}/cookbooks_dir"
end

When /^I run the rake task to generate cookbook metadata for '(.+)'$/ do |cb|
  self.cookbook = cb
  When('I run the rake task to generate cookbook metadata')
end

When /^I run the rake task to generate cookbook metadata$/ do
  to_run = "rake metadata"
  to_run += " COOKBOOK=#{cookbook}" if cookbook
  Dir.chdir(File.join(tmpdir, 'cookbooks_dir')) do
    self.status = Chef::Mixin::Command.popen4(to_run) do |p, i, o, e|
      self.stdout = o.gets(nil)
      self.stderr = o.gets(nil)
    end
  end
end
