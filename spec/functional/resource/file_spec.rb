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
    resource
  end

  let!(:resource) do
    r = create_resource
    r.content(expected_content)
    r
  end

  let(:resource_without_content) do
    create_resource
  end

  let(:unmanaged_content) do
    "This is file content that is not managed by chef"
  end

  let(:current_resource) do
    provider = resource.provider_for_action(resource.action)
    provider.load_current_resource
    provider.current_resource
  end

  let(:default_mode) { ((0100666 - File.umask) & 07777).to_s(8) }

  it_behaves_like "a file resource"

  it_behaves_like "a securable resource with reporting"

  describe "when running action :create without content" do
    before do
      resource_without_content.run_action(:create)
    end

    context "and the target file does not exist" do
      it "creates the file" do
        File.should exist(path)
      end

      it "is marked updated by last action" do
        resource_without_content.should be_updated_by_last_action
      end
    end
  end

  describe "when running action :touch" do
    context "and the target file does not exist" do
      before do
        resource.run_action(:touch)
      end

      it "it creates the file" do
        File.should exist(path)
      end

      it "is marked updated by last action" do
        resource.should be_updated_by_last_action
      end
    end

    context "and the target file exists and has the correct content" do
      before(:each) do
        File.open(path, "w") { |f| f.print expected_content }

        @expected_checksum = sha256_checksum(path)

        now = Time.now.to_i
        File.utime(now - 9000, now - 9000, path)
        @expected_mtime = File.stat(path).mtime

        resource.run_action(:touch)
      end

      it "updates the mtime of the file" do
        File.stat(path).mtime.should > @expected_mtime
      end

      it "does not change the content" do
        sha256_checksum(path).should == @expected_checksum
      end

      it "is marked as updated by last action" do
        resource.should be_updated_by_last_action
      end
    end
  end

end
