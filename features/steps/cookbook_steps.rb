#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Chris Walters (<cw@opscode.com>)
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

When /^I run the task to generate cookbook metadata for '(.+)'$/ do |cb|
  self.cookbook = cb
  When('I run the task to generate cookbook metadata')
end

When /^I run the task to generate cookbook metadata$/ do
  knife_cmd = File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "chef", "bin", "knife"))
  to_run = "#{knife_cmd} cookbook metadata"
  if cookbook
    to_run += " #{cookbook}" 
  else
    to_run += " -a"
  end
  to_run += " -o #{File.join(tmpdir, 'cookbooks_dir', 'cookbooks')}"
  Dir.chdir(File.join(tmpdir, 'cookbooks_dir', 'cookbooks')) do
    self.status = Chef::Mixin::Command.popen4(to_run) do |p, i, o, e|
      self.stdout = o.gets(nil)
      self.stderr = o.gets(nil)
    end
  end
end

#####
# Cookbook tarball-specific steps
#####

require 'chef/streaming_cookbook_uploader'

Given /^a cookbook named '(.+?)' is created with '(.*?)'$/ do |cookbook, stash_key|
  params = {:name => cookbook}.merge(@stash[stash_key])
  response = Chef::StreamingCookbookUploader.post("#{Chef::Config[:chef_server_url]}/cookbooks", rest.client_name, rest.signing_key_filename, params)
  response.status.should == 201
end

When /^I delete the cached tarball for '(.*?)'$/ do |cookbook|
  path = File.join(server_tmpdir, "cookbook-tarballs", "#{cookbook}.tar.gz")
  Chef::Log.debug "Deleting #{path}"
  FileUtils.rm_f(path)
end

When /^I create a cookbook(?: named '(.*?)')? with '(.*?)'$/ do |name, stash_key|
  payload = { }
  payload[:name] = name if name
  payload.merge!(@stash[stash_key])
  url = "#{Chef::Config[:chef_server_url]}/cookbooks"
  payload[:file].rewind if payload[:file].kind_of?(File)
  response = Chef::StreamingCookbookUploader.post(url, rest.client_name, rest.signing_key_filename, payload)
  
  store_response response
end

When /^I upload '(.*?)' to cookbook '(.*?)'$/ do |stash_key, cookbook|
  payload = @stash[stash_key]
  url = "#{Chef::Config[:chef_server_url]}/cookbooks/#{cookbook}/_content"
  payload[:file].rewind if payload[:file].kind_of?(File)
  response = Chef::StreamingCookbookUploader.put(url, rest.client_name, rest.signing_key_filename, payload)
  
  store_response response
end

When /^I download the '(.*?)' cookbook$/ do |cookbook|
  When "I 'GET' the path '/cookbooks/#{cookbook}/_content'"
end

When /^I delete cookbook '(.*?)'$/ do |cookbook|
  When "I 'DELETE' the path '/cookbooks/#{cookbook}'"
end

Then /^the response should be a valid tarball$/ do
  Tempfile.open('tarball') do |tempfile|
    tempfile.write(self.response.to_s)
    tempfile.flush()
    system("tar", "tzf", tempfile.path).should == true
  end
end

Then /^the untarred response should include file '(.+)'$/ do |filepath|
  Tempfile.open('tarball') do |tempfile|
    tempfile.write(self.response.to_s)
    tempfile.flush()
    `tar tzf #{tempfile.path}`.split("\n").select{|e| e == filepath}.empty?.should == false
  end
end

def store_response(resp)
  self.response = resp
  
  STDERR.puts "store response: #{resp.inspect}, #{resp.to_s}"# if ENV['DEBUG']=='true'
  begin
    STDERR.puts resp.to_s
    self.inflated_response = JSON.parse(resp.to_s)
  rescue
    STDERR.puts "failed to convert response to JSON: #{$!.message}" if ENV['DEBUG']=='true'
  end
end
