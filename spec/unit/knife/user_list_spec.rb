#
# Author:: Steven Danna
# Copyright:: Copyright 2012-2016, Chef Software Inc.
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

describe Chef::Knife::UserList do
  let(:knife) { Chef::Knife::UserList.new }
  let(:stdout) { StringIO.new }

  before(:each) do
    Chef::Knife::UserList.load_deps
    allow(knife.ui).to receive(:stderr).and_return(stdout)
    allow(knife.ui).to receive(:stdout).and_return(stdout)
  end

  it "lists the users" do
    expect(Chef::UserV1).to receive(:list)
    expect(knife).to receive(:format_list_for_display)
    knife.run
  end
end
