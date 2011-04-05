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

describe Chef::Provider::Cron do
  before do
    @node = Chef::Node.new
    @run_context = Chef::RunContext.new(@node, {})
    @new_resource = Chef::Resource::Cron.new("cronhole some stuff")
    @new_resource.user "root"
    @new_resource.minute "30"
    @new_resource.command "/bin/true"

    @provider = Chef::Provider::Cron.new(@new_resource, @run_context)
    @provider.current_resource = @current_resource
  end

  describe "when examining the current system state" do
    before do
      @status = mock("Status", :exitstatus => 0)
      @stdout = StringIO.new(<<-CRONTAB)
# Chef Name: cronhole some stuff
* 5 * * * /bin/true
CRONTAB

      @stdin = StringIO.new
      @stderr = StringIO.new
      @pid = 2342
      @provider.stub!(:popen4).and_yield(@pid, @stdin, @stdout, @stderr).and_return(@status)
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
      Chef::Log.should_receive(:debug).with("Found cron '#{@new_resource.name}'")
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
  end

  describe "when the current crontab state is known" do
    before do
      @current_resource = Chef::Resource::Cron.new("cronhole some stuff")
      @current_resource.user "root"
      @current_resource.minute "30"
      @current_resource.command "/bin/true"

      @provider.current_resource = @current_resource
    end


    describe Chef::Provider::Cron, "compare_cron" do
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


    describe "when creating a new crontab entry" do
      before do
        @stdout, @stderr, @stdin = StringIO.new, StringIO.new, StringIO.new
      end
      it "should add the cron entry if cron exists" do
        @stdout = StringIO.new(<<-CRONTAB)
# Chef Name: bar
* 10 * * * /bin/false
CRONTAB
        @provider.stub!(:popen4).and_yield(@pid, @stdin, @stdout, @stderr).and_return(@status)
        Chef::Log.should_receive(:info).with("cron[cronhole some stuff] added crontab entry")
        @provider.action_create
      end

      describe "and there is existing content in the crontab" do
        before do
          @stdout = StringIO.new(<<-CRON)
# Chef Name: bar
* 10 * * * /bin/false
# Chef Name: foo[bar] (baz)
* 5 * * * /bin/true
CRON

        end

        it "should create the cron entry even if cron is empty" do
          @provider.cron_empty=true
          @provider.stub!(:popen4).and_yield(@pid, @stdin, @stdout, @stderr).and_return(@status)
          Chef::Log.should_receive(:info).with("cron[cronhole some stuff] added crontab entry")
          @provider.action_create
        end

        it "should update the cron entry if it exists and has changed" do
          @provider.current_resource = @current_resource
          @provider.cron_exists=true
          @provider.stub!(:popen4).and_yield(@pid, @stdin, @stdout, @stderr).and_return(@status)
          Chef::Log.should_receive(:info).with("cron[cronhole some stuff] updated crontab entry")
          @provider.should_receive(:compare_cron).once.and_return(true)
          @provider.action_create
        end

        it "should not update the cron entry if it exists and has not changed" do
          @stdout =StringIO.new(<<-CRON)
# Chef Name: bar
* 10 * * * /bin/false
# Chef Name: foo[bar] (baz)
30 * * * * /bin/true
CRON
          @provider.stub!(:popen4).and_yield(@pid, @stdin, @stdout, @stderr).and_return(@status)
          Chef::Log.should_not_receive(:info).with("Updated cron '#{@new_resource.name}'")
          Chef::Log.should_receive(:debug).with("Skipping existing cron entry '#{@new_resource.name}'")
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

          provider = Chef::Provider::Cron.new(resource, @run_context)
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
          provider.action_create
        end
      end
    end

    describe Chef::Provider::Cron, "action_delete" do
      before do
        @stdin = StringIO.new
      end
      it "should delete the cron entry if it exists" do
       @stdout = StringIO.new(<<-CRON)
# Chef Name: bar
* 10 * * * /bin/false
# Chef Name: foo[bar] (baz)
* 30 * * * /bin/true
CRON
        @provider.cron_exists=true
        @provider.stub!(:popen4).and_yield(@pid, @stdin, @stdout, @stderr).and_return(@status)
        Chef::Log.should_receive(:info).with("#{@new_resource} deleted crontab entry")
        @provider.action_delete

      end

      it "should not delete the cron entry if it does not exist" do
        @stdout = StringIO.new(<<-CRON)
# Chef Name: bar
* 10 * * * /bin/false
CRON
        @provider.stub!(:popen4).and_yield(@pid, @stdin, @stdout, @stderr).and_return(@status)
        Chef::Log.should_not_receive(:debug).with("Deleted cron '#{@new_resource.name}'")
        @provider.action_delete
      end
    end
  end
end
