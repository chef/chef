#
# Author:: Bryan McLellan (btm@loftninjas.org)
# Author:: Toomas Pelberg (toomasp@gmx.net)
# Copyright:: Copyright (c) 2009 Bryan McLellan
# Copyright:: Copyright (c) 2010 Toomas Pelberg
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

describe Chef::Provider::Cron::Solaris do
  before do
    @node = Chef::Node.new
    @events = Chef::EventDispatch::Dispatcher.new
    @run_context = Chef::RunContext.new(@node, {}, @events)
    @new_resource = Chef::Resource::Cron.new("cronhole some stuff")
    @new_resource.user "root"
    @new_resource.minute "30"
    @new_resource.command "/bin/true"

    @provider = Chef::Provider::Cron::Solaris.new(@new_resource, @run_context)
  end

  it "should inherit from Chef::Provider:Cron" do
    @provider.should be_a(Chef::Provider::Cron)
  end

  describe "read_crontab" do
    before :each do
      @status = mock("Status", :exitstatus => 0)
      @stdout = StringIO.new(<<-CRONTAB)
0 2 * * * /some/other/command

# Chef Name: something else
* 5 * * * /bin/true

# Another comment
      CRONTAB
      @provider.stub!(:popen4).and_yield(1234, StringIO.new, @stdout, StringIO.new).and_return(@status)
    end

    it "should call crontab -l with the user" do
      @provider.should_receive(:popen4).with("crontab -l #{@new_resource.user}").and_return(@status)
      @provider.send(:read_crontab)
    end

    it "should return the contents of the crontab" do
      crontab = @provider.send(:read_crontab)
      crontab.should == <<-CRONTAB
0 2 * * * /some/other/command

# Chef Name: something else
* 5 * * * /bin/true

# Another comment
CRONTAB
    end

    it "should return nil if the user has no crontab" do
      status = mock("Status", :exitstatus => 1)
      @provider.stub!(:popen4).and_return(status)
      @provider.send(:read_crontab).should == nil
    end

    it "should raise an exception if another error occurs" do
      status = mock("Status", :exitstatus => 2)
      @provider.stub!(:popen4).and_return(status)
      lambda do
        @provider.send(:read_crontab)
      end.should raise_error(Chef::Exceptions::Cron, "Error determining state of #{@new_resource.name}, exit: 2")
    end
  end

  describe "write_crontab" do
    before :each do
      @status = mock("Status", :exitstatus => 0)
      @provider.stub!(:run_command).and_return(@status)
      @tempfile = mock("foo", :path => "/tmp/foo", :close => true, :binmode => nil)
      Tempfile.stub!(:new).and_return(@tempfile)
      @tempfile.should_receive(:flush)
      @tempfile.should_receive(:chmod).with(420)
      @tempfile.should_receive(:close!)
    end

    it "should call crontab for the user" do
      @provider.should_receive(:run_command).with(hash_including(:user => @new_resource.user))
      @tempfile.should_receive(:<<).with("Foo")
      @provider.send(:write_crontab, "Foo")
    end

    it "should call crontab with a file containing the crontab" do
      @provider.should_receive(:run_command) do |args|
        (args[:command] =~ %r{\A/usr/bin/crontab (/\S+)\z}).should be_true
        $1.should == "/tmp/foo"
        @status
      end
      @tempfile.should_receive(:<<).with("Foo\n# wibble\n wah!!")
      @provider.send(:write_crontab, "Foo\n# wibble\n wah!!")
    end

    it "should raise an exception if the command returns non-zero" do
      @tempfile.should_receive(:<<).with("Foo")
      @status.stub!(:exitstatus).and_return(1)
      lambda do
        @provider.send(:write_crontab, "Foo")
      end.should raise_error(Chef::Exceptions::Cron, "Error updating state of #{@new_resource.name}, exit: 1")
    end
  end
end
