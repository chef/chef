#
# Author:: Bryan McLellan (btm@loftninjas.org)
# Author:: Tyler Cloke (<tyler@opscode.com>)
# Copyright:: Copyright (c) 2009 Bryan McLellan
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

describe Chef::Resource::Cron do

  before(:each) do
    @resource = Chef::Resource::Cron.new("cronify")
  end  

  it "should create a new Chef::Resource::Cron" do
    @resource.should be_a_kind_of(Chef::Resource)
    @resource.should be_a_kind_of(Chef::Resource::Cron)
  end
  
  it "should have a name" do
    @resource.name.should eql("cronify")
  end
  
  it "should have a default action of 'create'" do
    @resource.action.should eql(:create)
  end
  
  it "should accept create or delete for action" do
    lambda { @resource.action :create }.should_not raise_error(ArgumentError)
    lambda { @resource.action :delete }.should_not raise_error(ArgumentError)
    lambda { @resource.action :lolcat }.should raise_error(ArgumentError)
  end

  it "should allow you to set a command" do
    @resource.command "/bin/true"
    @resource.command.should eql("/bin/true")
  end

  it "should allow you to set a user" do
    @resource.user "daemon"
    @resource.user.should eql("daemon")
  end

  it "should allow you to specify the minute" do
    @resource.minute "30"
    @resource.minute.should eql("30")
  end

  it "should allow you to specify the hour" do
    @resource.hour "6"
    @resource.hour.should eql("6")
  end
    
  it "should allow you to specify the day" do
    @resource.day "10"
    @resource.day.should eql("10")
  end

  it "should allow you to specify the month" do
    @resource.month "10"
    @resource.month.should eql("10")
  end

  it "should allow you to specify the weekday" do
    @resource.weekday "2"
    @resource.weekday.should eql("2")
  end

  it "should allow you to specify the mailto variable" do
    @resource.mailto "test@example.com"
    @resource.mailto.should eql("test@example.com")
  end

  it "should allow you to specify the path" do
    @resource.path "/usr/bin:/usr/sbin"
    @resource.path.should eql("/usr/bin:/usr/sbin")
  end

  it "should allow you to specify the home directory" do
    @resource.home "/root"
    @resource.home.should eql("/root")
  end

  it "should allow you to specify the shell to run the command with" do
    @resource.shell "/bin/zsh"
    @resource.shell.should eql("/bin/zsh")
  end

  it "should allow you to specify environment variables hash" do
    env = {"TEST" => "LOL"}
    @resource.environment env
    @resource.environment.should eql(env)
  end

  it "should allow * for all time and date values" do
    [ "minute", "hour", "day", "month", "weekday" ].each do |x|
      @resource.send(x, "*").should eql("*")
    end
  end
  
  it "should allow ranges for all time and date values" do
    [ "minute", "hour", "day", "month", "weekday" ].each do |x|
      @resource.send(x, "1-2,5").should eql("1-2,5")
    end
  end

  it "should have a default value of * for all time and date values" do
    [ "minute", "hour", "day", "month", "weekday" ].each do |x|
      @resource.send(x).should eql("*")
    end
  end

  it "should have a default value of root for the user" do
    @resource.user.should eql("root")
  end

  it "should reject any minute over 59" do
    lambda { @resource.minute "60" }.should raise_error(RangeError)
  end
  
  it "should reject any hour over 23" do
    lambda { @resource.hour "24" }.should raise_error(RangeError)
  end
  
  it "should reject any day over 31" do
    lambda { @resource.day "32" }.should raise_error(RangeError)
  end
  
  it "should reject any month over 12" do
    lambda { @resource.month "13" }.should raise_error(RangeError)
  end
  
  it "should reject any weekday over 7" do
    lambda { @resource.weekday "8" }.should raise_error(RangeError)
  end
  
  it "should convert integer schedule values to a string" do
    [ "minute", "hour", "day", "month", "weekday" ].each do |x|
      @resource.send(x, 5).should eql("5")
    end
  end
  
  describe "when it has a time (minute, hour, day, month, weeekend) and user" do
    before do 
      @resource.command("tackle")
      @resource.minute("1")
      @resource.hour("2")
      @resource.day("3")
      @resource.month("4")
      @resource.weekday("5")
      @resource.user("root")
    end

    it "describes the state" do
      state = @resource.state
      state[:minute].should == "1"
      state[:hour].should == "2"
      state[:day].should == "3"
      state[:month].should == "4"
      state[:weekday].should == "5"
      state[:user].should == "root"
    end

    it "returns the command as its identity" do
      @resource.identity.should == "tackle"
    end
  end
end
