#
# Copyright:: Copyright 2018, Chef Software Inc.
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

describe Chef::Resource::ArchiveFile do

  let(:resource) { Chef::Resource::ArchiveFile.new("foo") }

  it "has a resource name of :archive_file" do
    expect(resource.resource_name).to eql(:archive_file)
  end

  it "has a name property of path" do
    expect(resource.path).to match(/.*foo$/)
  end

  it "sets the default action as :extract" do
    expect(resource.action).to eql([:extract])
  end

  it "supports :extract action" do
    expect { resource.action :extract }.not_to raise_error
  end

  it "mode property defaults to '755'" do
    expect(resource.mode).to eql("755")
  end

  it "options property defaults to [:time]" do
    expect(resource.options).to eql([:time])
  end
end
