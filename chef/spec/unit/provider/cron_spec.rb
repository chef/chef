#
# Author:: Bryan McLellan (btm@loftninjas.org)
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

require File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "spec_helper"))

describe Chef::Provider::Cron, "initialize" do
  before(:each) do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource", :null_object => true)
  end

  it "should return a Chef::Provider::Cron object" do
    provider = Chef::Provider::Cron.new(@node, @new_resource)
    provider.should be_a_kind_of(Chef::Provider::Cron)
  end

end

describe Chef::Provider::Cron, "load_current_resource" do
  before(:each) do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::Cron",
      :null_object => true,
      :user => "root",
      :name => "foo[bar] (baz)",
      :minute => "30",
      :command => "/bin/true"
    )
    @current_resource = mock("Chef::Resource::Cron",
      :null_object => true,
      :name => "foo[bar] (baz)",
      :minute => "30",
      :command => "/bin/true"
    )
    @provider = Chef::Provider::Cron.new(@node, @new_resource)
  end

  it "should report if it can't find the cron entry" do
    @status = mock("Status", :exitstatus => 0)
    @provider.stub!(:popen4).and_return(@status)
    Chef::Log.should_receive(:debug).with("Cron '#{@new_resource.name}' not found")
    @provider.load_current_resource
  end

  it "should report an empty crontab" do
    @status = mock("Status", :exitstatus => 1)
    @provider.stub!(:popen4).and_return(@status)
    Chef::Log.should_receive(:debug).with("Cron empty for '#{@new_resource.user}'")
    @provider.load_current_resource
  end

  it "should report finding a match if the entry exists" do
    @status = mock("Status", :exitstatus => 0)
    @stdin = mock("STDIN", :null_object => true)
    @stdout = mock("STDOUT", :null_object => true)    
    @stderr = mock("STDERR", :null_object => true)
    @pid = mock("PID", :null_object => true)
    @stdout.stub!(:each_line).and_yield("# Chef Name: foo[bar] (baz)\n").and_yield("* 5 * * * /bin/true\n")
    @provider.stub!(:popen4).and_yield(@pid, @stdin, @stdout, @stderr).and_return(@status)
    Chef::Log.should_receive(:debug).with("Found cron '#{@new_resource.name}'")
    @provider.load_current_resource
  end
        
  it "should not fail if there's an existing cron with a numerical argument" do
    @status = mock("Status", :exitstatus => 0)
    @stdin = mock("STDIN", :null_object => true)
    @stdout = mock("STDOUT", :null_object => true)    
    @stderr = mock("STDERR", :null_object => true)
    @pid = mock("PID", :null_object => true)
    @stdout.stub!(:each).and_yield("# Chef Name: foo[bar] (baz)\n").
      and_yield("21 */4 * * * some_prog 1234567\n")
    @provider.stub!(:popen4).and_yield(@pid, @stdin, @stdout, @stderr).and_return(@status)
    lambda {
      @provider.load_current_resource
    }.should_not raise_error
  end
end

describe Chef::Provider::Cron, "compare_cron" do
  before(:each) do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::Cron",
      :null_object => true,
      :user => "root",
      :name => "foo[bar] (baz)",
      :minute => "30",
      :hour => "2",
      :day => "30",
      :month => "5",
      :weekday => "3",
      :command => "/bin/true",
      :mailto => "test@example.com",
      :path => "/usr/bin:/bin",
      :shell => "/bin/zsh",
      :home => "/home/thom"
    )
    @current_resource = mock("Chef::Resource::Cron",
      :null_object => true,
      :user => "root",
      :name => "foo[bar] (baz)",
      :minute => "30",
      :hour => "2",
      :day => "30",
      :month => "5",
      :weekday => "3",
      :command => "/bin/true",
      :mailto => "test@example.com",
      :path => "/usr/bin:/bin",
      :shell => "/bin/zsh",
      :home => "/home/thom"
    )
    @provider = Chef::Provider::Cron.new(@node, @new_resource)
    @provider.current_resource = @current_resource
  end

  %w{ minute hour day month weekday command mailto path shell home }.each do |attribute|
    it "should return true if #{attribute} doesn't match" do 
      @new_resource.should_receive(attribute).exactly(2).times.and_return(true)
      @current_resource.should_receive(attribute).once.and_return(false)
      @provider.compare_cron.should eql(true)
    end
  end

  it "should return false if the objects are identical" do
    @provider.compare_cron.should eql(false)
  end
end


describe Chef::Provider::Cron, "action_create" do
  before(:each) do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::Cron",
      :null_object => true,
      :name => "foo[bar] (baz)",
      :minute => "30",
      :hour => "*",
      :day => "*",
      :month => "*",
      :weekday => "*",
      :mailto => nil,
      :path => nil,
      :shell => nil,
      :home => nil,
      :command => "/bin/true"
    )
    @current_resource = mock("Chef::Resource::Cron",
      :null_object => true,
      :name => "foo[bar] (baz)",
      :minute => "*",
      :hour => "5",
      :day => "*",
      :month => "*",
      :weekday => "*",
      :mailto => nil,
      :path => nil,
      :shell => nil,
      :home => nil,
      :command => "/bin/true"
    )
    @provider = Chef::Provider::Cron.new(@node, @new_resource)
  end

  it "should add the cron entry if cron exists" do
    @status = mock("Status", :exitstatus => 0)
    @stdin = mock("STDIN", :null_object => true)
    @stdout = mock("STDOUT", :null_object => true)    
    @stderr = mock("STDERR", :null_object => true)
    @pid = mock("PID", :null_object => true)
    @stdout.stub!(:each_line).and_yield("# Chef Name: bar\n").
      and_yield("* 10 * * * /bin/false\n")
    @provider.stub!(:popen4).and_yield(@pid, @stdin, @stdout, @stderr).and_return(@status)
    Chef::Log.should_receive(:info).with("Added cron '#{@new_resource.name}'")
    @provider.action_create
  end

  it "should create the cron entry even if cron is empty" do
    @status = mock("Status", :exitstatus => 0)
    @stdin = mock("STDIN", :null_object => true)
    @stdout = mock("STDOUT", :null_object => true)    
    @stderr = mock("STDERR", :null_object => true)
    @pid = mock("PID", :null_object => true)
    @stdout.stub!(:each_line).and_yield("# Chef Name: bar\n").
      and_yield("* 10 * * * /bin/false\n").
      and_yield("# Chef Name: foo[bar] (baz)\n").
      and_yield("* 5 * * * /bin/true\n")
    @provider.cron_empty=true
    @provider.stub!(:popen4).and_yield(@pid, @stdin, @stdout, @stderr).and_return(@status)
    Chef::Log.should_receive(:info).with("Added cron '#{@new_resource.name}'")
    @provider.action_create
  end

  it "should update the cron entry if it exists and has changed" do
    @provider.current_resource = @current_resource
    @status = mock("Status", :exitstatus => 0)
    @stdin = mock("STDIN", :null_object => true)
    @stdout = mock("STDOUT", :null_object => true)    
    @stderr = mock("STDERR", :null_object => true)
    @pid = mock("PID", :null_object => true)
    @stdout.stub!(:each_line).and_yield("# Chef Name: bar\n").
      and_yield("* 10 * * * /bin/false\n").
      and_yield("# Chef Name: foo[bar] (baz)\n").
      and_yield("* 5 * * * /bin/true\n")
    @provider.cron_exists=true
    @provider.stub!(:popen4).and_yield(@pid, @stdin, @stdout, @stderr).and_return(@status)
    Chef::Log.should_receive(:info).with("Updated cron '#{@new_resource.name}'")
    @provider.should_receive(:compare_cron).once.and_return(true)
    @provider.action_create
  end

  it "should not update the cron entry if it exists and has not changed" do
    @status = mock("Status", :exitstatus => 0)
    @stdin = mock("STDIN", :null_object => true)
    @stdout = mock("STDOUT", :null_object => true)    
    @stderr = mock("STDERR", :null_object => true)
    @pid = mock("PID", :null_object => true)
    @stdout.stub!(:each_line).and_yield("# Chef Name: bar\n").
      and_yield("* 10 * * * /bin/false\n").
      and_yield("# Chef Name: foo[bar] (baz)\n").
      and_yield("30 * * * * /bin/true\n")
    @provider.stub!(:popen4).and_yield(@pid, @stdin, @stdout, @stderr).and_return(@status)
    Chef::Log.should_not_receive(:info).with("Updated cron '#{@new_resource.name}'")
    Chef::Log.should_receive(:debug).with("Skipping existing cron entry '#{@new_resource.name}'")
    @provider.should_receive(:compare_cron).once.and_return(false)
    @provider.cron_exists = true
    @provider.action_create
  end

  it "should update the cron entry if it exists and has changed environment variables" do
    @provider.current_resource = @current_resource
    @status = mock("Status", :exitstatus => 0)
    @stdin = mock("STDIN", :null_object => true)
    @stdout = mock("STDOUT", :null_object => true)    
    @stderr = mock("STDERR", :null_object => true)
    @pid = mock("PID", :null_object => true)
    @stdout.stub!(:each_line).and_yield("# Chef Name: bar\n").
      and_yield("* 10 * * * /bin/false\n").
      and_yield("# Chef Name: foo[bar] (baz)\n").
      and_yield("MAILTO=warn@example.com\n").
      and_yield("30 * * * * /bin/true\n")
    @provider.stub!(:popen4).and_yield(@pid, @stdin, @stdout, @stderr).and_return(@status)
    Chef::Log.should_receive(:info).with("Updated cron '#{@new_resource.name}'")
    @provider.cron_exists = true
    @provider.should_receive(:compare_cron).once.and_return(true)
    @provider.action_create
  end

  it "should update the cron entry if it exists and has no environment variables" do
    resource = mock("Chef::Resource::Cron",
      :null_object => true,
      :name => "foo[bar] (baz)",
      :minute => "30",
      :hour => "*",
      :day => "*",
      :month => "*",
      :weekday => "*",
      :mailto => "test@example.com",
      :path => nil,
      :shell => nil,
      :home => nil,
      :command => "/bin/true"
    )
    provider = Chef::Provider::Cron.new(@node, resource)
    provider.current_resource = @current_resource

    @status = mock("Status", :exitstatus => 0)
    @stdin = mock("STDIN", :null_object => true)
    @stdout = mock("STDOUT", :null_object => true)    
    @stderr = mock("STDERR", :null_object => true)
    @pid = mock("PID", :null_object => true)
    @stdout.stub!(:each_line).and_yield("# Chef Name: bar\n").
      and_yield("* 10 * * * /bin/false\n").
      and_yield("# Chef Name: foo[bar] (baz)\n").
      and_yield("30 * * * * /bin/true\n")
    provider.stub!(:popen4).and_yield(@pid, @stdin, @stdout, @stderr).and_return(@status)
    Chef::Log.should_receive(:info).with("Updated cron '#{@new_resource.name}'")
    provider.cron_exists = true
    provider.should_receive(:compare_cron).once.and_return(true)
    provider.action_create
  end
end

describe Chef::Provider::Cron, "action_delete" do
  before(:each) do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::Cron",
      :null_object => true,
      :name => "foo[bar] (baz)",
      :minute => "30",
      :command => "/bin/true"
    )
    @current_resource = mock("Chef::Resource::Cron",
      :null_object => true,
      :name => "foo[bar] (baz)",
      :minute => "30",
      :command => "/bin/true"
    )
    @provider = Chef::Provider::Cron.new(@node, @new_resource)

  end

  it "should delete the cron entry if it exists" do
    @status = mock("Status", :exitstatus => 0)
    @stdin = mock("STDIN", :null_object => true)
    @stdout = mock("STDOUT", :null_object => true)    
    @stderr = mock("STDERR", :null_object => true)
    @pid = mock("PID", :null_object => true)
    @stdout.stub!(:each_line).and_yield("# Chef Name: bar\n").
      and_yield("* 10 * * * /bin/false\n").
      and_yield("# Chef Name: foo[bar] (baz)\n").
      and_yield("* 30 * * * /bin/true\n")
    @provider.cron_exists=true
    @provider.stub!(:popen4).and_yield(@pid, @stdin, @stdout, @stderr).and_return(@status)
    Chef::Log.should_receive(:debug).with("Deleted cron '#{@new_resource.name}'")
    @provider.action_delete

  end

  it "should not delete the cron entry if it does not exist" do
    @status = mock("Status", :exitstatus => 0)
    @stdin = mock("STDIN", :null_object => true)
    @stdout = mock("STDOUT", :null_object => true)    
    @stderr = mock("STDERR", :null_object => true)
    @pid = mock("PID", :null_object => true)
    @stdout.stub!(:each_line).and_yield("# Chef Name: bar").
      and_yield("* 10 * * * /bin/false")
    @provider.stub!(:popen4).and_yield(@pid, @stdin, @stdout, @stderr).and_return(@status)
    Chef::Log.should_not_receive(:debug).with("Deleted cron '#{@new_resource.name}'")
    @provider.action_delete
  end
end

