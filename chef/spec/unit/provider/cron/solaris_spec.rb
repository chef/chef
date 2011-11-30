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

require File.expand_path(File.join(File.dirname(__FILE__), "..", "..","..", "spec_helper"))

describe Chef::Provider::Cron::Solaris do
  before(:each) do
    @node = Chef::Node.new
    @run_context = Chef::RunContext.new(@node, {})
    @new_resource = Chef::Resource::Cron.new("cronhole some stuff")
    @new_resource.user "root"
    @new_resource.minute "30"
    @new_resource.command "/bin/true"

    @provider = Chef::Provider::Cron::Solaris.new(@new_resource, @run_context)
    @provider.current_resource = @current_resource
  end

  describe "when examining the current system state" do
    before do
      @status = mock("Status", :exitstatus => 0)
      @stdin = StringIO.new
      @stderr = StringIO.new
      @stdout = StringIO.new(<<-CRON)
# Chef Name: cronhole some stuff
* 5 * * * /bin/true
CRON
      @pid = 2342
    end

    it "should report if it can't find the cron entry" do
      @provider.stub!(:popen4).and_return(@status)
      Chef::Log.should_receive(:debug).with("#{@new_resource} cron '#{@new_resource.name}' not found")
      @provider.load_current_resource
    end

    it "should report an empty crontab" do
      @status = mock("Status", :exitstatus => 1)
      @provider.stub!(:popen4).and_return(@status)
      Chef::Log.should_receive(:debug).with("#{@new_resource} cron empty for '#{@new_resource.user}'")
      @provider.load_current_resource
    end

    it "should report finding a match if the entry exists" do
      @provider.stub!(:popen4).and_yield(@pid, @stdin, @stdout, @stderr).and_return(@status)
      Chef::Log.should_receive(:debug).with("#{@new_resource} found cron '#{@new_resource.name}'")
      @provider.load_current_resource
    end

    it "should not fail if there's an existing cron with a numerical argument" do
      @stdout = StringIO.new(<<-CRON)
# Chef Name: foo[bar] (baz)
21 */4 * * * some_prog 1234567
CRON
      @provider.stub!(:popen4).and_yield(@pid, @stdin, @stdout, @stderr).and_return(@status)
      lambda {
        @provider.load_current_resource
      }.should_not raise_error
    end

    it "should parse and load generic and standard environment variables from cron entry" do
      @stdout = StringIO.new(<<-CRON)
# Chef Name: cronhole some stuff
MAILTO=warn@example.com
TEST=lol
FLAG=1
* 5 * * * /bin/true
CRON
      @provider.stub!(:popen4).and_yield(@pid, @stdin, @stdout, @stderr).and_return(@status)
      resource = @provider.load_current_resource

      resource.mailto.should == "warn@example.com"
      resource.environment.should eql({"TEST" => "lol", "FLAG" => "1"})
    end
  end

  describe "when the current crontab state is known" do
    before do
      @current_resource = Chef::Resource::Cron.new("cronhole some stuff")
      @current_resource.user "root"
      @current_resource.minute "30"
      @current_resource.command "/bin/true"

      @provider.current_resource = @current_resource

      @status = mock("Status", :exitstatus => 0)
      @stdin = StringIO.new
      @stdout = StringIO.new(<<-CRON)
# Chef Name: bar
* 10 * * * /bin/false
CRON
      @stderr = StringIO.new
      @pid = 2342
    end


    describe Chef::Provider::Cron::Solaris, "compare_cron" do
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


    describe Chef::Provider::Cron::Solaris, "action_create" do
      it "should add the cron entry if cron exists" do
        @provider.stub!(:popen4).and_yield(@pid, @stdin, @stdout, @stderr).and_return(@status)
        Chef::Log.should_receive(:info).with("cron[cronhole some stuff] added crontab entry")
        @provider.action_create
      end

      it "should create the cron entry even if cron is empty" do
        @stdout = StringIO.new(<<-CRON)
# Chef Name: bar
* 10 * * * /bin/false
# Chef Name: foo[bar] (baz)
* 5 * * * /bin/true
CRON
        @provider.cron_empty=true
        @provider.stub!(:popen4).and_yield(@pid, @stdin, @stdout, @stderr).and_return(@status)
        Chef::Log.should_receive(:info).with("cron[cronhole some stuff] added crontab entry")
        @provider.action_create
      end

      it "should update the cron entry if it exists and has changed" do
        @provider.current_resource = @current_resource
        @stdout = StringIO.new(<<-CRON)
# Chef Name: bar
* 10 * * * /bin/false
# Chef Name: foo[bar] (baz)
* 5 * * * /bin/true
CRON
        @provider.cron_exists=true
        @provider.stub!(:popen4).and_yield(@pid, @stdin, @stdout, @stderr).and_return(@status)
        Chef::Log.should_receive(:info).with("cron[cronhole some stuff] updated crontab entry")
        @provider.should_receive(:compare_cron).once.and_return(true)
        @provider.action_create
      end

      it "should not update the cron entry if it exists and has not changed" do
        @stdout = StringIO.new(<<-CRON)
# Chef Name: bar
* 10 * * * /bin/false
# Chef Name: foo[bar] (baz)
30 * * * * /bin/true
CRON
        @provider.stub!(:popen4).and_yield(@pid, @stdin, @stdout, @stderr).and_return(@status)
        Chef::Log.should_not_receive(:info).with("#{@new_resource} updated crontab entry")
        Chef::Log.should_receive(:debug).with("#{@new_resource} skipping existing cron entry '#{@new_resource.name}'")
        @provider.should_receive(:compare_cron).once.and_return(false)
        @provider.cron_exists = true
        @provider.action_create
      end

      it "should update the cron entry if it exists and has changed environment variables" do
        @provider.current_resource = @current_resource
        @stdout = StringIO.new(<<-CRON)
# Chef Name: bar
* 10 * * * /bin/false
# Chef Name: foo[bar] (baz)
MAILTO=warn@example.com
30 * * * * /bin/true
CRON
        @provider.stub!(:popen4).and_yield(@pid, @stdin, @stdout, @stderr).and_return(@status)
        Chef::Log.should_receive(:info).with("cron[cronhole some stuff] updated crontab entry")
        @provider.cron_exists = true
        @provider.should_receive(:compare_cron).once.and_return(true)
        @provider.action_create
      end

      it "should update the cron entry if it exists and has no environment variables" do
        resource = Chef::Resource::Cron.new("lobster rage")
        resource.name "lobster rage"
        resource.minute "30"
        resource.hour "*"
        resource.day "*"
        resource.month "*"
        resource.weekday "*"
        resource.mailto "test@example.com"
        resource.path nil
        resource.shell nil
        resource.home nil
        resource.command "/bin/true"
        resource.environment "TEST"=>"LOL"

        provider = Chef::Provider::Cron::Solaris.new(resource, @run_context)
        provider.current_resource = @current_resource

        @stdout = StringIO.new(<<-CRON)
# Chef Name: lobster rage
* 10 * * * /bin/false
# Chef Name: foo[bar] (baz)
30 * * * * /bin/true
CRON
        provider.stub!(:popen4).and_yield(@pid, @stdin, @stdout, @stderr).and_return(@status)
        Chef::Log.should_receive(:info).with("cron[lobster rage] updated crontab entry")
        provider.cron_exists = true
        provider.should_receive(:compare_cron).once.and_return(true)
        provider.should_receive(:write_crontab).with(/TEST=LOL/)
        provider.action_create
      end
    end

    describe Chef::Provider::Cron::Solaris, "action_delete" do
      it "should delete the cron entry if it exists" do
        @stdout = StringIO.new(<<-C)
# Chef Name: bar
* 10 * * * /bin/false
# Chef Name: foo[bar] (baz)
* 30 * * * /bin/true
C
        @provider.cron_exists=true
        @provider.stub!(:popen4).and_yield(@pid, @stdin, @stdout, @stderr).and_return(@status)
        Chef::Log.should_receive(:info).with("cron[cronhole some stuff] deleted crontab entry")
        @provider.action_delete

      end

      it "should not delete the cron entry if it does not exist" do
        @stdout = StringIO.new(<<-C)
# Chef Name: bar
* 10 * * * /bin/false
C
        @provider.stub!(:popen4).and_yield(@pid, @stdin, @stdout, @stderr).and_return(@status)
        Chef::Log.should_not_receive(:info).with("cron[bar] deleted crontab entry")
        @provider.action_delete
      end
    end
  end
end
