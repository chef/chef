#
# Author:: Jay Mundrawala (<jdm@chef.io>)
# Copyright:: Copyright 2015-2016, Chef Software
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

require "spec_helper"

describe Chef::Provider::RemoteFile::NetworkFile do

  let(:source) { "\\\\foohost\\fooshare\\Foo.tar.gz" }

  let(:new_resource) { Chef::Resource::RemoteFile.new("network file (new_resource)") }
  let(:current_resource) { Chef::Resource::RemoteFile.new("network file (current_resource)") }
  subject(:fetcher) { Chef::Provider::RemoteFile::NetworkFile.new(source, new_resource, current_resource) }

  describe "when fetching the object" do

    let(:tempfile) { double("Tempfile", :path => "/tmp/foo/bar/Foo.tar.gz", :close => nil) }
    let(:chef_tempfile) { double("Chef::FileContentManagement::Tempfile", :tempfile => tempfile) }

    it "stages the local file to a temporary file" do
      expect(Chef::FileContentManagement::Tempfile).to receive(:new).with(new_resource).and_return(chef_tempfile)
      expect(::FileUtils).to receive(:cp).with(source, tempfile.path)
      expect(tempfile).to receive(:close)

      result = fetcher.fetch
      expect(result).to eq(tempfile)
    end

  end

end
