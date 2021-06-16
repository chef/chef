#
# Author:: Steven Danna (<steve@chef.io>)
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

Chef::Knife::UserDelete.load_deps

describe Chef::Knife::UserDelete do
  subject(:knife) { Chef::Knife::UserDelete.new }

  let(:non_admin_member_org) { Chef::Org.new("non-admin-member") }
  let(:solo_admin_member_org) { Chef::Org.new("solo-admin-member") }
  let(:shared_admin_member_org) { Chef::Org.new("shared-admin-member") }

  let(:removable_orgs) { [non_admin_member_org, shared_admin_member_org] }
  let(:non_removable_orgs) { [solo_admin_member_org] }

  let(:admin_memberships) { [ removable_orgs, non_removable_orgs ] }
  let(:username) { "test_user" }

  let(:rest) { double("Chef::ServerAPI") }
  let(:orgs) { [non_admin_member_org, solo_admin_member_org, shared_admin_member_org] }
  let(:knife) { Chef::Knife::UserDelete.new }

  let(:orgs_data) do
    [{ "organization" => { "name" => "non-admin-member" } },
     { "organization" => { "name" => "solo-admin-member" } },
     { "organization" => { "name" => "shared-admin-member" } },
  ]
  end

  before(:each) do
    allow(Chef::ServerAPI).to receive(:new).and_return(rest)
    knife.name_args << username
    knife.config[:yes] = true
  end

  context "when invoked" do
    before do
      allow(knife).to receive(:admin_group_memberships).and_return(admin_memberships)
    end

    context "with --no-disassociate-user" do
      before(:each) do
        knife.config[:no_disassociate_user] = true
      end

      it "should bypass all checks and go directly to user deletion" do
        expect(knife).to receive(:delete_user).with(username)
        knife.run
      end
    end

    context "without --no-disassociate-user" do
      before do
        allow(knife).to receive(:org_memberships).and_return(orgs)
      end

      context "and with --remove-from-admin-groups" do
        let(:non_removable_orgs) { [ solo_admin_member_org ] }
        before(:each) do
          knife.config[:remove_from_admin_groups] = true
        end

        context "when an associated user the only organization admin" do
          let(:non_removable_orgs) { [ solo_admin_member_org ] }

          it "refuses to proceed with because the user is the only admin" do
            expect(knife).to receive(:error_exit_cant_remove_admin_membership!).and_call_original
            expect { knife.run }.to raise_error SystemExit
          end
        end

        context "when an associated user is one of many organization admins" do
          let(:non_removable_orgs) { [] }

          it "should remove the user from the group, the org, and then and delete the user" do
            expect(knife).to receive(:disassociate_user)
            expect(knife).to receive(:remove_from_admin_groups)
            expect(knife).to receive(:delete_user)
            expect(knife).to receive(:error_exit_cant_remove_admin_membership!).exactly(0).times
            expect(knife).to receive(:error_exit_admin_group_member!).exactly(0).times
            knife.run
          end

        end
      end

      context "and without --remove-from-admin-groups" do
        before(:each) do
          knife.config[:remove_from_admin_groups] = false
        end

        context "when an associated user is in admins group" do
          let(:removable_orgs) { [ shared_admin_member_org ] }
          let(:non_removable_orgs) { [ ] }
          it "refuses to proceed with because the user is an admin" do
            # Default setup
            expect(knife).to receive(:error_exit_admin_group_member!).and_call_original
            expect { knife.run }.to raise_error SystemExit
          end
        end
      end

    end
  end

  context "#admin_group_memberships" do
    before do
      expect(non_admin_member_org).to receive(:user_member_of_group?).and_return false

      expect(solo_admin_member_org).to receive(:user_member_of_group?).and_return true
      expect(solo_admin_member_org).to receive(:actor_delete_would_leave_admins_empty?).and_return true

      expect(shared_admin_member_org).to receive(:user_member_of_group?).and_return true
      expect(shared_admin_member_org).to receive(:actor_delete_would_leave_admins_empty?).and_return false

    end

    it "returns an array of organizations in which the user is an admin, and an array of orgs which block removal" do
      expect(knife.admin_group_memberships(orgs, username)).to eq [ [solo_admin_member_org, shared_admin_member_org], [solo_admin_member_org]]
    end
  end

  context "#delete_user" do
    it "attempts to delete the user from the system via DELETE to the /users endpoint" do
      expect(rest).to receive(:delete).with("users/#{username}")
      knife.delete_user(username)
    end
  end

  context "#disassociate_user" do
    it "attempts to remove dissociate the user from each org" do
      removable_orgs.each { |org| expect(org).to receive(:dissociate_user).with(username) }
      knife.disassociate_user(removable_orgs, username)
    end
  end

  context "#remove_from_admin_groups" do
    it "attempts to remove the given user from the organizations' groups" do
      removable_orgs.each { |org| expect(org).to receive(:remove_user_from_group).with("admins", username) }
      knife.remove_from_admin_groups(removable_orgs, username)
    end
  end

  context "#org_memberships" do
    it "should make a REST request to return the list of organizations that the user is a member of" do
      expect(rest).to receive(:get).with("users/test_user/organizations").and_return orgs_data
      result = knife.org_memberships(username)
      result.each_with_index do |v, x|
        expect(v.to_hash).to eq(orgs[x].to_hash)
      end
    end
  end
end
