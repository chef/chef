#
# Author:: Stephen Haynes (<sh@nomitor.com>)
# Copyright:: Copyright (c) 2009 OpsCode, Inc.
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

require File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "..", "spec_helper"))

describe Chef::Provider::Group::Pw, "set_options" do
  before do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::Group",
      :null_object => true,
      :group_name => "aj",
      :gid => 50,
      :members => [ "root", "aj"]
    )
    @current_resource = mock("Chef::Resource::Group",
      :null_object => true,
      :group_name => "aj",
      :gid => 50,
      :members => [ "root", "aj"]
    )
    @provider = Chef::Provider::Group::Pw.new(@node, @new_resource)
    @provider.current_resource = @current_resource    
  end
  
  field_list = {
    :gid => "-g"
  }
  
  field_list.each do |attribute, option|
    it "should check for differences in #{attribute.to_s} between the current and new resources" do
        @new_resource.should_receive(attribute)
        @current_resource.should_receive(attribute)
        @provider.set_options     
    end  
    it "should set the option for #{attribute} if the new resources #{attribute} is not null" do
      @new_resource.stub!(attribute).and_return("wowaweea")
      @provider.set_options.should eql(" #{@new_resource.group_name} #{option} '#{@new_resource.send(attribute)}'")
    end
  end
  
  it "should combine all the possible options" do
    match_string = " aj"
    field_list.sort{ |a,b| a[0] <=> b[0] }.each do |attribute, option|
      @new_resource.stub!(attribute).and_return("hola")
      match_string << " #{option} 'hola'"
    end
    @provider.set_options.should eql(match_string)
  end
end

describe Chef::Provider::Group::Pw, "create_group" do
  before do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::Group", :null_object => true)
    @provider = Chef::Provider::Group::Pw.new(@node, @new_resource)
    @provider.stub!(:run_command).and_return(true)
    @provider.stub!(:set_options).and_return(" monkey")
    @provider.stub!(:set_members_option).and_return(" -M purple")
  end
  
  it "should run pw groupadd with the return of set_options and set_members_option" do
    @provider.should_receive(:run_command).with({ :command => "pw groupadd monkey -M purple" }).and_return(true)
    @provider.create_group
  end
end

describe Chef::Provider::Group::Pw, "manage_group" do
  before do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::Group", :null_object => true)
    @provider = Chef::Provider::Group::Pw.new(@node, @new_resource)
    @provider.stub!(:run_command).and_return(true)
    @provider.stub!(:set_options).and_return(" monkey")
    @provider.stub!(:set_members_option).and_return(" -M purple")
  end
  
  it "should run pw groupmod with the return of set_options" do
    @provider.should_receive(:run_command).with({ :command => "pw groupmod monkey -M purple" }).and_return(true)
    @provider.manage_group
  end

end

describe Chef::Provider::Group::Pw, "remove_group" do
  before do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::Group", 
      :null_object => true,
      :group_name => "aj"
    )
    @provider = Chef::Provider::Group::Pw.new(@node, @new_resource)
    @provider.stub!(:run_command).and_return(true)
  end
  
  it "should run pw groupdel with the new resources group name" do
    @provider.should_receive(:run_command).with({ :command => "pw groupdel aj" }).and_return(true)
    @provider.remove_group
  end
end

describe Chef::Provider::Group::Pw, "set_members_option" do
  before do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::Group",
      :null_object => true,
      :group_name => "aj",
      :members => [ "all", "your", "base" ]
    )
    @current_resource = mock("Chef::Resource::Group",
      :null_object => true,
      :group_name => "aj",
      :members => [ "all", "your", "base" ]
    )
    @new_resource.stub!(:to_s).and_return("group[aj]")
    @provider = Chef::Provider::Group::Pw.new(@node, @new_resource)
    @provider.current_resource = @current_resource
  end
  
  describe "with an empty members array in both the new and current resource" do
    before do
      @new_resource.stub!(:members).and_return([])
      @current_resource.stub!(:members).and_return([])
    end
    
    it "should log an appropriate message" do
      Chef::Log.should_receive(:debug).with("group[aj]: not changing group members, the group has no members")
      @provider.set_members_option
    end
    
    it "should set no options" do
      @provider.set_members_option.should eql("")
    end
  end

  describe "with an empty members array in the new resource and existing members in the current resource" do
    before do
      @new_resource.stub!(:members).and_return([])
      @current_resource.stub!(:members).and_return(["all", "your", "base"])
    end
    
    it "should log an appropriate message" do
      Chef::Log.should_receive(:debug).with("group[aj]: removing group members all, your, base")
      @provider.set_members_option
    end
    
    it "should set the -d option with the members joined by ','" do
      @provider.set_members_option.should eql(" -d all,your,base")
    end      
  end
  
  describe "with supplied members array in the new resource and an empty members array in the current resource" do
    before do
      @new_resource.stub!(:members).and_return(["all", "your", "base"])
      @current_resource.stub!(:members).and_return([])
    end
    
    it "should log an appropriate debug message" do
      Chef::Log.should_receive(:debug).with("group[aj]: setting group members to all, your, base")
      @provider.set_members_option
    end
    
    it "should set the -M option with the members joined by ','" do
      @provider.set_members_option.should eql(" -M all,your,base")
    end
  end
end

describe Chef::Provider::Group::Pw, "load_current_resource" do
  before do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::Group", :null_object => true, :group_name => "aj")
    @provider = Chef::Provider::Group::Pw.new(@node, @new_resource)
    File.stub!(:exists?).and_return(false)
  end

  it "should raise an error if the required binary /usr/sbin/pw doesn't exist" do
    File.should_receive(:exists?).with("/usr/sbin/pw").and_return(false)
    lambda { @provider.load_current_resource }.should raise_error(Chef::Exception::Group)
  end
  
  it "shouldn't raise an error if /usr/sbin/pw exists" do
    File.stub!(:exists?).and_return(true)
    lambda { @provider.load_current_resource }.should_not raise_error(Chef::Exception::Group)
  end
end