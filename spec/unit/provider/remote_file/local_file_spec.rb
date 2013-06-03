#
# Author:: Jesse Campbell (<hikeit@gmail.com>)
# Copyright:: Copyright (c) 2013 Jesse Campbell
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

require 'spec_helper'

describe Chef::Provider::RemoteFile::LocalFile do

  let(:uri) { URI.parse("file:///nyan_cat.png") }

  let(:new_resource) { Chef::Resource::RemoteFile.new("local file backend test (new_resource)") }
  let(:current_resource) { Chef::Resource::RemoteFile.new("local file backend test (current_resource)") }
  subject(:fetcher) { Chef::Provider::RemoteFile::LocalFile.new(uri, new_resource, current_resource) }

  context "when first created" do

    it "stores the uri it is passed" do
      fetcher.uri.should == uri
    end

    it "stores the new_resource" do
      fetcher.new_resource.should == new_resource
    end

  end

  describe "when fetching the object" do

    let(:tempfile) { mock("Tempfile", :path => "/tmp/foo/bar/nyan.png") }
    let(:chef_tempfile) { mock("Chef::FileContentManagement::Tempfile", :tempfile => tempfile) }

    before do
      current_resource.source("file:///nyan_cat.png")
    end

    it "stages the local file to a temporary file" do
      Chef::FileContentManagement::Tempfile.should_receive(:new).with(new_resource).and_return(chef_tempfile)
      ::FileUtils.should_receive(:cp).with(uri.path, tempfile.path)

      result = fetcher.fetch
      result.should == tempfile
    end

  end

end
