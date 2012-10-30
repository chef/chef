#
# Author:: Seth Chisamore (<schisamo@opscode.com>)
# Copyright:: Copyright (c) 2011 Opscode, Inc.
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

describe Chef::Resource::File do
  include_context Chef::Resource::File

  let(:file_base) { "file_spec" }
  let(:expected_content) { "Don't fear the ruby." }

  def create_resource
    events = Chef::EventDispatch::Dispatcher.new
    node = Chef::Node.new
    run_context = Chef::RunContext.new(node, {}, events)
    resource = Chef::Resource::File.new(path, run_context)
    resource.content(expected_content)
    resource
  end

  let!(:resource) do
    create_resource
  end

  it_behaves_like "a file resource"

  context "when the target file does not exist" do
    it "it creates the file when the :touch action is run" do
      resource.run_action(:touch)
      File.should exist(path)
    end
  end

  context "when the target file has the correct content" do
    before(:each) do
      File.open(path, "w") { |f| f.print expected_content }
    end

    it "updates the mtime/atime of the file when the :touch action is run" do
      expected_mtime = File.stat(path).mtime
      expected_atime = File.stat(path).atime
      sleep 1
      resource.run_action(:touch)
      File.stat(path).mtime.should > expected_mtime
      File.stat(path).atime.should > expected_atime
    end

    it "does not change the content when :touch action is run" do
      expected_checksum = sha256_checksum(path)
      resource.run_action(:touch)
      sha256_checksum(path).should == expected_checksum
    end
  end
end
