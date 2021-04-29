#
# Copyright:: Copyright (c) Chef Software Inc.
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

require "knife_spec_helper"
require "chef/org"

describe Chef::Knife::OrgUserAdd do
  context "with --admin" do
    subject(:knife) { Chef::Knife::OrgUserAdd.new }
    let(:org) { double("Chef::Org") }

    it "adds the user to admins and billing-admins groups" do
      allow(Chef::Org).to receive(:new).and_return(org)

      knife.config[:admin] = true
      knife.name_args = %w{testorg testuser}

      expect(org).to receive(:associate_user).with("testuser")
      expect(org).to receive(:add_user_to_group).with("admins", "testuser")
      expect(org).to receive(:add_user_to_group).with("billing-admins", "testuser")

      knife.run
    end
  end
end
