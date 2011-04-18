#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Christopher Walters (<cw@opscode.com>)
# Author:: Tim Hinderliter (<tim@opscode.com>)
# Copyright:: Copyright (c) 2008, 2010 Opscode, Inc.
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

require 'chef/cookbook/file_system_file_vendor'
require 'chef/cookbook_uploader'
require 'chef/cookbook_loader'

def compare_manifests(manifest1, manifest2)
  Chef::CookbookVersion::COOKBOOK_SEGMENTS.each do |segment|
    next unless manifest1[segment]
    manifest2.should have_key(segment)

    manifest2_records_by_path = manifest2[segment].inject({}) {|memo,manifest2_record| memo[manifest2_record[:path]] = manifest2_record; memo}
    manifest1[segment].each do |manifest1_record|
      path = manifest1_record[:path]

      manifest2_records_by_path.should have_key(path)
      manifest1_record.should == manifest2_records_by_path[path]
    end
  end
end

Before do
  FileUtils.mkdir "#{datadir}/cookbooks_not_uploaded_at_feature_start/testcookbook_invalid_empty" unless File.exist?("#{datadir}/cookbooks_not_uploaded_at_feature_start/testcookbook_invalid_empty")
  extra_cookbook_repo = File.join(datadir, "cookbooks_not_uploaded_at_feature_start")
  Chef::Cookbook::FileVendor.on_create {|manifest| Chef::Cookbook::FileSystemFileVendor.new(manifest, extra_cookbook_repo) }
  @cookbook_loader_not_uploaded_at_feature_start = Chef::CookbookLoader.new(extra_cookbook_repo)
end

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

Given "I upload the cookbook" do
  cookbook_name, recipe_name = recipe.split('::')
  shell_out!("#{KNIFE_CMD} cookbook upload -c #{KNIFE_CONFIG} -a -o #{INTEGRATION_COOKBOOKS}")
end

Given "I have uploaded a frozen cookbook named '$cookbook_name' at version '$cookbook_version'" do |name, version|
  shell_out!("#{KNIFE_CMD} cookbook upload #{name} -c #{KNIFE_CONFIG} -o #{EXTRA_COOKBOOKS} --freeze --force")
end

Given /^I delete the cookbook's on disk checksum files$/ do
  #pp :checksums => @last_uploaded_cookbook.checksums.keys
  #pending # express the regexp above with the code you wish you had
  @last_uploaded_cookbook.checksums.keys.each do |file_checksum|
    file_location_in_checksum_repo = File.join(datadir, 'repo', 'checksums', file_checksum[0...2], file_checksum)
    #pp :expected_cksum_path => {file_checksum => file_location_in_checksum_repo}
    #puts "deleting checksum file #{file_location_in_checksum_repo}"
    FileUtils.rm(file_location_in_checksum_repo)
  end
end

When /^I run the task to generate cookbook metadata for '(.+)'$/ do |cb|
  self.cookbook = cb
  When('I run the task to generate cookbook metadata')
end

When /^I run the task to generate cookbook metadata$/ do
  to_run = "#{KNIFE_CMD} cookbook metadata"
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
# Cookbook upload/download-specific steps
#####

When "I upload a cookbook named '$name' at version '$version'" do |name, version|


  call_as_admin do
    cookbook = @cookbook_loader_not_uploaded_at_feature_start[name]
    uploader = Chef::CookbookUploader.new(cookbook, [EXTRA_COOKBOOKS], :rest => rest)
    begin
      uploader.upload_cookbook
    rescue Exception => e
      @exception = e
    end
  end
end

When /^I create a versioned cookbook(?: named '(.*?)')?(?: versioned '(.*?)')? with '(.*?)'$/ do |request_name, request_version, cookbook_name|
  cookbook = @cookbook_loader_not_uploaded_at_feature_start[cookbook_name]
  raise ArgumentError, "no such cookbook in cookbooks_not_uploaded_at_feature_start: #{cookbook_name}" unless cookbook

  begin
    self.api_response = rest.put_rest("/cookbooks/#{request_name}/#{request_version}", cookbook)
    self.inflated_response = api_response
  rescue => e
    self.exception = e
  end
end

# The argument handling in the above step defn isn't working for me, so dup city.
# :/
When "I create a cookbook named '$cookbook_name' with only the metadata file" do |cookbook_name|
  cookbook = @cookbook_loader_not_uploaded_at_feature_start[cookbook_name.to_sym]
  raise ArgumentError, "no such cookbook in cookbooks_not_uploaded_at_feature_start: #{cookbook_name}" unless cookbook

  begin
    self.api_response = rest.put_rest("/cookbooks/#{cookbook_name}/1.0.0", cookbook)
    self.inflated_response = api_response
  rescue => e
    Chef::Log.debug("Caught exception #{e} from HTTP request")
    self.exception = e
  end
end

When /^I create a sandbox named '(.+)' for cookbook '([^\']+)'(?: minus files '(.+)')?$/ do |sandbox_name, cookbook_name, filenames_to_exclude|
  cookbook = @cookbook_loader_not_uploaded_at_feature_start[cookbook_name]
  raise ArgumentError, "no such cookbook in cookbooks_not_uploaded_at_feature_start: #{cookbook_name}" unless cookbook

  if filenames_to_exclude
    filenames_to_exclude = filenames_to_exclude.split(",").inject({}) { |memo, filename| memo[filename] = 1; memo }
  else
    filenames_to_exclude = Hash.new
  end

  # add all the checksums from the given cookbook into the sandbox.
  checksums = Hash.new
  Chef::CookbookVersion::COOKBOOK_SEGMENTS.each do |segment|
    next unless cookbook.manifest[segment]
    cookbook.manifest[segment].each do |manifest_record|
      # include the checksum, unless it was included in the filenames to exclude
      checksums[manifest_record[:checksum]] = nil unless filenames_to_exclude.has_key?(manifest_record[:path])
    end
  end

  sandbox = {
    :checksums => checksums
  }

  begin
    self.api_response = self.inflated_response = nil
    self.exception = nil

    self.inflated_response = rest.post_rest('/sandboxes', sandbox)
    self.sandbox_url = self.inflated_response['uri']

    @stash['sandbox_response'] = self.inflated_response
  rescue
    Chef::Log.debug("Caught exception in sandbox create (POST) request: #{$!.message}: #{$!.backtrace.join("\n")}")
    self.exception = $!
  end
end

Then /^I upload a file named '(.+)' from cookbook '(.+)' to the sandbox/ do |path, cookbook_name|
  cookbook = @cookbook_loader_not_uploaded_at_feature_start[cookbook_name]
  raise ArgumentError, "no such cookbook in cookbooks_not_uploaded_at_feature_start: #{cookbook_name}" unless cookbook

  if path =~ /([^\/]+)\/(.+)/
    segment, path_no_segment = $1, $2
  else
    segment = :root_files
    path_no_segment = path
  end
  if cookbook.manifest[segment]
    manifest_record = cookbook.manifest[segment].find {|manifest_record| manifest_record[:path] == path }
  end
  raise ArgumentError, "no such file in cookbooks_not_uploaded_at_feature_start/#{cookbook_name}: #{path}" unless manifest_record

  full_path = File.join(datadir, "cookbooks_not_uploaded_at_feature_start", cookbook_name, path)

  begin
    url = @stash['sandbox_response']['checksums'][manifest_record[:checksum]]['url']
    upload_to_sandbox(full_path, manifest_record[:checksum], url)
  rescue
    Chef::Log.debug("Caught exception in cookbook/sandbox checksum upload (PUT) request: #{$!.message}: #{$!.backtrace.join("\n")}")
    self.exception = $!
  end
end

# Shortcut for uploading a whole cookbook based on data in the
# cookbooks_not_uploaded_at_feature_start directory
Then /I fully upload a sandboxed cookbook (force-)?named '([^\']+)' versioned '([^\']+)' with '(.+)'/ do |forced, request_name, request_version, cookbook_name|
  @last_uploaded_cookbook = cookbook = @cookbook_loader_not_uploaded_at_feature_start[cookbook_name]
  raise ArgumentError, "no such cookbook in cookbooks_not_uploaded_at_feature_start: #{cookbook_name}" unless cookbook

  # If they said 'force-named', we will reach into the cookbook and change its
  # name. This is to get around the fact that CookbookLoader uses the
  # directory name as the cookbook name. This is super awesome right here.
  if forced == "force-"
    # If the paths contain the name of the old cookbook name, change it to the
    # new cookbook name.
    Chef::CookbookVersion::COOKBOOK_SEGMENTS.each do |segment|
      next unless cookbook.manifest[segment]
      cookbook.manifest[segment].each do |manifest_record|
        if manifest_record[:path] =~ /^(.+)\/#{cookbook.name}\/(.+)$/
          manifest_record[:path] = "#{$1}/#{request_name}/#{$2}"
        end
      end
    end
    cookbook.name = request_name
    cookbook.manifest[:cookbook_name] = request_name
    cookbook.manifest[:name] = "#{cookbook.manifest[:cookbook_name]}-#{cookbook.manifest[:version]}"
  end

  When "I create a sandbox named 'sandbox1' for cookbook '#{cookbook_name}'"
  Then "the inflated responses key 'uri' should match '^http://.+/sandboxes/[^\/]+$'"

  Chef::CookbookVersion::COOKBOOK_SEGMENTS.each do |segment|
    next unless cookbook.manifest[segment]
    cookbook.manifest[segment].each do |manifest_record|
      full_path = File.join(datadir, "cookbooks_not_uploaded_at_feature_start", cookbook_name, manifest_record[:path])

      begin
        csum_entry = @stash['sandbox_response']['checksums'][manifest_record[:checksum]]
        next unless csum_entry['url']
        url = @stash['sandbox_response']['checksums'][manifest_record[:checksum]]['url']
        upload_to_sandbox(full_path, manifest_record[:checksum], url)
      rescue
        Chef::Log.debug("Caught exception in cookbook/sandbox checksum upload (PUT) request: #{$!.message}: #{$!.backtrace.join("\n")}")
        self.exception = $!
      end
      Then "the response code should be '200'"
    end
  end

  When "I commit the sandbox"
  Then "I should not get an exception"
  When "I create a versioned cookbook named '#{request_name}' versioned '#{request_version}' with '#{cookbook_name}'"
  Then "I should not get an exception"
end

When /I download the cookbook manifest for '(.+)' version '(.+)'$/ do |cookbook_name, cookbook_version|
  self.api_response = self.inflated_response = self.exception = nil

  When "I 'GET' to the path '/cookbooks/#{cookbook_name}/#{cookbook_version}'"
  @downloaded_cookbook = self.inflated_response
end

Then /the downloaded cookbook manifest contents should match '(.+)'$/ do |cookbook_name|
  expected_cookbook = @cookbook_loader_not_uploaded_at_feature_start[cookbook_name]
  raise ArgumentError, "no such cookbook in cookbooks_not_uploaded_at_feature_start: #{cookbook_name}" unless expected_cookbook

  downloaded_cookbook_manifest = Mash.new(@downloaded_cookbook.manifest)
  downloaded_cookbook_manifest.delete("uri")

  # remove the uri's from the manifest records
  Chef::CookbookVersion::COOKBOOK_SEGMENTS.each do |segment|
    next unless downloaded_cookbook_manifest[segment]
    downloaded_cookbook_manifest[segment].each do |downloaded_manifest_record|
      downloaded_manifest_record.delete("url")
    end
  end

  # ensure that each file expected (from the cookbook on disk) was downloaded,
  # and then do the opposite.
  begin
    compare_manifests(expected_cookbook.manifest, downloaded_cookbook_manifest)
    compare_manifests(downloaded_cookbook_manifest, expected_cookbook.manifest)
  rescue
    pp({:expected_cookbook_manifest => expected_cookbook.manifest})
    pp({:downloaded_cookbook_manifest => downloaded_cookbook_manifest})

    raise
  end
end

When /I download the file '([^\']+)' from the downloaded cookbook manifest/ do |path|
  raise "no @downloaded_cookbook" unless @downloaded_cookbook

  # TODO: timh, 2010-5-26: Cookbook really should have a "get me a file by its
  # path" method.
  if path =~ /^([^\/]+)\/(.+)$/
    segment, path_in_segment = $1, $2
  else
    segment = :root_files
    path_in_segment = path
  end

  raise "no such file #{path}" unless @downloaded_cookbook.manifest[segment]
  found_manifest_record = @downloaded_cookbook.manifest[segment].find {|manifest_record| manifest_record[:path] == path}
  raise "no such file #{path}" unless found_manifest_record

  begin
    cookbook_name = @downloaded_cookbook.name
    cookbook_version = @downloaded_cookbook.version

    checksum = found_manifest_record[:checksum]

    self.api_response = nil
    self.inflated_response = nil
    self.exception = nil

    url = found_manifest_record[:url]
    downloaded_cookbook_file = rest.get_rest(url, true)
    @downloaded_cookbook_file_contents = IO.read(downloaded_cookbook_file.path)
  rescue
    self.exception = $!
  end
end

Then /^the downloaded cookbook file contents should match the pattern '(.+)'$/ do |pattern|
  raise "no @downloaded_cookbook_file_contents" unless @downloaded_cookbook_file_contents

  @downloaded_cookbook_file_contents.should =~ /#{pattern}/
end

Then /^the dependencies in its metadata should be an empty hash$/ do
  inflated_response.metadata.dependencies.should == {}
end

Then /^the metadata should include a dependency on '(.+)'$/ do |key|
  inflated_response.metadata.dependencies.should have_key(key)
end

Then "the cookbook version document should be frozen" do
  inflated_response.should be_frozen_version
end

RSpec::Matchers.define :have_been_deleted do
  match do |file_name|
    ! File.exist?(file_name)
  end
  failure_message_for_should do |file_name|
    "Expected file #{file_name} to have been deleted but it was not"
  end
  failure_message_for_should_not do |player|
    "Expected file #{file_name} to not have been deleted but it was (i.e., it should exist)"
  end
  description do
    "The file should have been deleted"
  end
end

Then /^the cookbook's files should have been deleted$/ do
  #pp @last_uploaded_cookbook
  @last_uploaded_cookbook.checksums.keys.each do |file_checksum|
    file_location_in_checksum_repo = File.join(datadir, 'repo', 'checksums', file_checksum[0...2], file_checksum)
    #pp :expected_cksum_path => {file_checksum => file_location_in_checksum_repo}
    file_location_in_checksum_repo.should have_been_deleted
  end
end

RSpec::Matchers.define :have_checksum_document do |checksum|
  match do |checksum_list|
    checksum_list.include?(checksum)
  end
  failure_message_for_should do |checksum_list|
    "Expected checksum document #{checksum} to exist in couchdb but it is not in the list of existing checksums:\n#{checksum_list.sort.join("\n")}\n"
  end
  failure_message_for_should_not do |checksum_list|
    "Expected checksum document #{checksum} not to exist in couchdb but it is in the list of existing checksums:\n#{checksum_list.sort.join("\n")}\n"
  end
  description do
    "The checksum should exist"
  end
end

Then /^the cookbook's checksums should be removed from couchdb$/ do
  #pp @last_uploaded_cookbook
  all_checksum_docs = couchdb_rest_client.get_rest('/_design/checksums/_view/all')["rows"]
  checksums_in_couchdb = all_checksum_docs.map {|c| c["key"]}
  #pp :checksums_in_couchdb => checksums_in_couchdb
  @last_uploaded_cookbook.checksums.keys.each do |checksum|
    checksums_in_couchdb.should_not have_checksum_document(checksum)
  end
end

Given "I upload multiple versions of the 'version_test' cookbook" do
  When "I fully upload a sandboxed cookbook force-named 'version_test' versioned '0.1.0' with 'version_test_0.1.0'"
  When "I fully upload a sandboxed cookbook force-named 'version_test' versioned '0.1.1' with 'version_test_0.1.1'"
  When "I fully upload a sandboxed cookbook force-named 'version_test' versioned '0.2.0' with 'version_test_0.2.0'"
end

Given "I upload multiple versions of the 'version_test' cookbook that do not lexically sort correctly" do
  When "I fully upload a sandboxed cookbook force-named 'version_test' versioned '0.9.0' with 'version_test_0.9.0'"
  When "I fully upload a sandboxed cookbook force-named 'version_test' versioned '0.10.0' with 'version_test_0.10.0'"
  When "I fully upload a sandboxed cookbook force-named 'version_test' versioned '0.9.7' with 'version_test_0.9.7'"
end

Given "I upload the set of 'dep_test_*' cookbooks" do
  %w{a b c}.each do |letter|
    %w{1 2 3}.each do |number|
      When "I fully upload a sandboxed cookbook force-named 'dep_test_#{letter}' versioned '#{number}.0.0' with 'dep_test_#{letter}_#{number}.0.0'"
    end
  end
end

Then /^cookbook '(.+)' should have version '(.+)'$/ do |cookbook, version|
  Then "the inflated responses key '#{cookbook}' should exist"
  Then "the inflated responses key 'dep_test_a' should match '\"version\":\"#{version}\"' as json"
end
