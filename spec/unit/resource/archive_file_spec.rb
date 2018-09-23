#
# Author:: Vincent Aubert <vincentaubert88@gmail.com>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
#     You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require "spec_helper"

describe Chef::Resource::ArchiveFile do

  let(:resource) { Chef::Resource::ArchiveFile.new("fakey_fakerton") }

  it "has a resource name of :archive_file" do
    expect(resource.resource_name).to eql(:archive_file)
  end

  it "the path property is the name_property" do
    expect(resource.path).to eql("fakey_fakerton")
  end

  it "has a default mode of '0755'" do
    expect(resource.mode).to eql(0755)
  end
end
