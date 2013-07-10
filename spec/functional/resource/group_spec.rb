require 'spec_helper'
require 'chef/mixin/shell_out'

describe Chef::Resource::Group, :requires_root_or_running_windows	  do
  include Chef::Mixin::ShellOut

  OHAI_SYSTEM = Ohai::System.new
  OHAI_SYSTEM.require_plugin("os")
  OHAI_SYSTEM.require_plugin("platform")

	# Order the tests for proper cleanup and execution
	RSpec.configure do |config|
		config.order_groups_and_examples do |list|
			list.sort_by { |item| item.description }
		end
	end

  let(:events) do
    Chef::EventDispatch::Dispatcher.new
  end

  let(:node) do
    n = Chef::Node.new
    n.consume_external_attrs(OHAI_SYSTEM.data.dup, {})
    n
  end

  let(:run_context) do
    Chef::RunContext.new(node, {}, events)
  end

  let(:user_resource) do
  	r = Chef::Resource::User.new("test-user-resource", run_context)
  	r
  end

	let(:create_user) do
		user_resource.run_action(:create)
	end

	let(:remove_user) do
		user_resource.run_action(:remove)
	end

	def provider(resource)
		provider = resource.provider_for_action(resource.action)
		provider.load_current_resource
		provider
	end

	def resource_should_exist(resource)
		provider(resource).group_exists.should be_true
	end

	def resource_should_not_exist(resource)
		provider(resource).group_exists.should be_false
	end


	before do
		@grp_resource = Chef::Resource::Group.new("chef-test-group", run_context)
	end

	context "group create action" do

		it " - should create a group" do
			@grp_resource.run_action(:create)
			resource_should_exist(@grp_resource)
		end

		context "group name with 256 characters", :windows_only do
			before(:each) do
				grp_name = "theoldmanwalkingdownthestreetalwayshadagoodsmileonhisfacetheoldmanwalkingdownthestreetalwayshadagoodsmileonhisfacetheoldmanwalkingdownthestreetalwayshadagoodsmileonhisfacetheoldmanwalkingdownthestreetalwayshadagoodsmileonhisfacetheoldmanwalkingdownthestree"
				@new_grp = Chef::Resource::Group.new(grp_name, run_context)
			end
			after do
				@new_grp.run_action(:remove)
			end
			it " - should create a group" do
				@new_grp.run_action(:create)
				resource_should_exist(@new_grp)
			end
		end

		context "group name with more than 256 characters", :windows_only do
			before(:each) do
				grp_name = "theoldmanwalkingdownthestreetalwayshadagoodsmileonhisfacetheoldmanwalkingdownthestreetalwayshadagoodsmileonhisfacetheoldmanwalkingdownthestreetalwayshadagoodsmileonhisfacetheoldmanwalkingdownthestreetalwayshadagoodsmileonhisfacetheoldmanwalkingdownthestreeQQQQQQQQQQQQQQQQQ"
				@new_grp = Chef::Resource::Group.new(grp_name, run_context)
			end
			it " - should not create a group" do
				@new_grp.run_action(:create)
				resource_should_not_exist(@new_grp)
			end
		end

		context "add user to group" do
			after do
				remove_user
			end
			it " - should add a user to the group" do
				create_user
				@grp_resource.members(user_resource.username)
				@grp_resource.append(true)
				@grp_resource.run_action(:modify)
				@grp_resource.members.length > 0
			end
		end

		context "add non existent user to group" do
			it " - should not update the members" do
				@grp_resource.members("NotAUser")
				@grp_resource.append(true)
				expect {@grp_resource.run_action(:modify)}.to raise_error
			end
		end

		context "change gid of the group", :windows_only do
			before(:each) do
				@grp_resource.gid("1234567890")
			end
			it " - should change gid of the group" do
				@grp_resource.run_action(:manage)
				@grp_resource.gid.should == "1234567890"
			end
		end

		context "group remove action" do
			it "should remove the group" do
				@grp_resource.run_action(:remove)
				resource_should_not_exist(@grp_resource)
			end
		end
	end
end
