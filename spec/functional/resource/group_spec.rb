require 'spec_helper'

describe "Chef provider for group", :requires_root do
	# Order the tests for proper cleanup and execution
	RSpec.configure do |config|
		config.order_groups_and_examples do |list|
			list.sort_by { |item| item.description }
		end
	end

	def get_user_provider(username)
		usr = Chef::Resource::User.new("#{username}", @run_context)
		usr.password("S0mePassword!")
		userProviderClass = Chef::Platform.find_provider(@ohai[:platform], @ohai[:version], usr)
		usr_provider = userProviderClass.new(usr, @run_context)
	end

	def create_user(username)
		get_user_provider(username).run_action(:create)
	end

	def remove_user(username)
		get_user_provider(username).run_action(:remove)
	end

	before do
		# Load ohai only once
		@ohai = Ohai::System.new
		@ohai.all_plugins
		@node = Chef::Node.new
		@events = Chef::EventDispatch::Dispatcher.new
		@run_context = Chef::RunContext.new(@node, {}, @events)
		@new_grp = Chef::Resource::Group.new("chef-test-group", @run_context)
		@groupProviderClass = Chef::Platform.find_provider(@ohai[:platform], @ohai[:version], @new_grp)
		@grp_provider = @groupProviderClass.new(@new_grp, @run_context)
	end

	context "group create action" do
		
		it " - should create a group" do
			@grp_provider.load_current_resource
			@grp_provider.group_exists.should be_false
			@grp_provider.run_action(:create)
			@grp_provider = @groupProviderClass.new(@new_grp, @run_context)
			@grp_provider.load_current_resource
			@grp_provider.group_exists.should be_true
		end

		context "group name with 256 characters", :windows_only do
			before(:each) do
				grp_name = "theoldmanwalkingdownthestreetalwayshadagoodsmileonhisfacetheoldmanwalkingdownthestreetalwayshadagoodsmileonhisfacetheoldmanwalkingdownthestreetalwayshadagoodsmileonhisfacetheoldmanwalkingdownthestreetalwayshadagoodsmileonhisfacetheoldmanwalkingdownthestree"
				@new_grp = Chef::Resource::Group.new(grp_name, @run_context)
				@groupProviderClass = Chef::Platform.find_provider(@ohai[:platform], @ohai[:version], @new_grp)
				@grp_provider = @groupProviderClass.new(@new_grp, @run_context)
			end
			after do
				@grp_provider.run_action(:remove)
			end
			it " - should create a group" do
				@grp_provider.load_current_resource
				@grp_provider.group_exists.should be_false
				@grp_provider.run_action(:create)
				@grp_provider = @groupProviderClass.new(@new_grp, @run_context)
				@grp_provider.group_exists.should be_true
			end
		end

		context "group name with more than 256 characters", :windows_only do
			before(:each) do
				grp_name = "theoldmanwalkingdownthestreetalwayshadagoodsmileonhisfacetheoldmanwalkingdownthestreetalwayshadagoodsmileonhisfacetheoldmanwalkingdownthestreetalwayshadagoodsmileonhisfacetheoldmanwalkingdownthestreetalwayshadagoodsmileonhisfacetheoldmanwalkingdownthestreeQQQQQQQQQQQQQQQQQ"
				@new_grp = Chef::Resource::Group.new(grp_name, @run_context)
				@groupProviderClass = Chef::Platform.find_provider(@ohai[:platform], @ohai[:version], @new_grp)
				@grp_provider = @groupProviderClass.new(@new_grp, @run_context)
			end
			after do
				@grp_provider.run_action(:remove)
			end
			it " - should not create a group" do
				expect {@grp_provider.run_action(:create)}.to raise_error
			end
		end

		context "add user to group" do
			after do
				remove_user("NotSoFunctional")
			end
			it " - should add a user to the group" do
				create_user("NotSoFunctional")
				@new_grp.members("NotSoFunctional")
				@new_grp.append(true)
				@groupProviderClass = Chef::Platform.find_provider(@ohai[:platform], @ohai[:version], @new_grp)
				@grp_provider = @groupProviderClass.new(@new_grp, @run_context)
				@grp_provider.run_action(:modify)
				@grp_provider = @groupProviderClass.new(@new_grp, @run_context)
				@grp_provider.load_current_resource
				@grp_provider.new_resource.members.length > 0
			end
		end

		context "add non existent user to group" do
			it " - should not update the members" do
				@new_grp.members("NotAUser")
				@new_grp.append(true)
				@groupProviderClass = Chef::Platform.find_provider(@ohai[:platform], @ohai[:version], @new_grp)
				@grp_provider = @groupProviderClass.new(@new_grp, @run_context)
				expect {@grp_provider.run_action(:modify)}.to raise_error
			end
		end

		context "change gid of the group" do
			before(:each) do
				@new_grp.gid("1234567890")
				@groupProviderClass = Chef::Platform.find_provider(@ohai[:platform], @ohai[:version], @new_grp)
				@grp_provider = @groupProviderClass.new(@new_grp, @run_context)	
			end
			it " - should change gid of the group" do
				@grp_provider.run_action(:manage)
				@grp_provider.load_current_resource
				@grp_provider.group_exists.should be_true
				@grp_provider.compare_group.should be_true
			end
		end

		context "group remove action" do
			it "should remove the group" do
				@grp_provider.load_current_resource
				@grp_provider.group_exists.should be_true
				@grp_provider.run_action(:remove)
				@grp_provider.load_current_resource
				@grp_provider.group_exists.should be_false
			end
		end

	end	
end
