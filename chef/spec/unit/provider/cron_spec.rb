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
    before :each do
      @status = mock("Status", :exitstatus => 0)
      @stdout = StringIO.new
      @stdin = StringIO.new
      @stderr = StringIO.new
      @pid = 2342
    end

    context "with no crontab for the user" do
      before :each do
        @status = mock("Status", :exitstatus => 1)
        @provider.stub!(:popen4).and_return(@status)
      end

      it "should set cron_empty" do
        @provider.load_current_resource
        @provider.cron_empty.should == true
        @provider.cron_exists.should == false
      end

      it "should report an empty crontab" do
        Chef::Log.should_receive(:debug).with("Cron empty for '#{@new_resource.user}'")
        @provider.load_current_resource
      end
    end

    context "with no matching entry in the user's crontab" do
      before :each do
        @stdout = StringIO.new(<<-CRONTAB)
0 2 * * * /some/other/command

# Chef Name: something else
* 5 * * * /bin/true

# Another comment
CRONTAB
        @provider.stub!(:popen4).and_yield(@pid, @stdin, @stdout, @stderr).and_return(@status)
      end

      it "should not set cron_exists or cron_empty" do
        @provider.load_current_resource
        @provider.cron_exists.should == false
        @provider.cron_empty.should == false
      end

      it "should report no entry found" do
        Chef::Log.should_receive(:debug).with("Cron '#{@new_resource.name}' not found")
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

    context "with a matching entry in the user's crontab" do
      before :each do
        @stdout = StringIO.new(<<-CRONTAB)
0 2 * * * /some/other/command

# Chef Name: cronhole some stuff
* 5 * 1 * /bin/true param1 param2
# Chef Name: something else
2 * 1 * * /bin/false

# Another comment
CRONTAB
        @provider.stub!(:popen4).and_yield(@pid, @stdin, @stdout, @stderr).and_return(@status)
      end

      it "should set cron_exists" do
        @provider.load_current_resource
        @provider.cron_exists.should == true
        @provider.cron_empty.should == false
      end

      it "should pull the details out of the cron line" do
        cron = @provider.load_current_resource
        cron.minute.should == '*'
        cron.hour.should == '5'
        cron.day.should == '*'
        cron.month.should == '1'
        cron.weekday.should == '*'
        cron.command.should == '/bin/true param1 param2'
      end

      it "should report the match" do
        Chef::Log.should_receive(:debug).with("Found cron '#{@new_resource.name}'")
        @provider.load_current_resource
      end

      it "should parse and load generic and standard environment variables from cron entry" do
        @stdout = StringIO.new(<<-CRONTAB)
# Chef Name: cronhole some stuff
MAILTO=warn@example.com
TEST=lol
FLAG=1
* 5 * * * /bin/true
CRONTAB
        @provider.stub!(:popen4).and_yield(@pid, @stdin, @stdout, @stderr).and_return(@status)
        resource = @provider.load_current_resource

        resource.mailto.should == "warn@example.com"
        resource.environment.should == {"TEST" => "lol", "FLAG" => "1"}
      end
    end
  end

  describe "compare_crontab" do
    before :each do
      @current_resource = Chef::Resource::Cron.new("cronhole some stuff")
      @current_resource.user "root"
      @current_resource.minute "30"
      @current_resource.command "/bin/true"
      @provider.current_resource = @current_resource
    end

    [:minute, :hour, :day, :month, :weekday, :command, :mailto, :path, :shell, :home].each do |attribute|
      it "should return true if #{attribute} doesn't match" do
        @new_resource.send(attribute, "something_else")
        @provider.compare_cron.should eql(true)
      end
    end

    it "should return true if environment doesn't match" do
      @new_resource.environment "FOO" => "something_else"
      @provider.compare_cron.should eql(true)
    end

    it "should return false if the objects are identical" do
      @provider.compare_cron.should == false
    end
  end

  describe "action_create" do
    before :each do
      @status = mock("Status", :exitstatus => 0)
      @stdout = StringIO.new
      @stdin = StringIO.new
      @stderr = StringIO.new
      @pid = 2342
    end

    context "when there is no existing crontab" do
      before :each do
        @provider.cron_exists = false
        @provider.cron_empty = true
        @provider.stub!(:popen4).with("crontab -u #{@new_resource.user} -", :waitlast => true).and_yield(@pid, @stdin, @stdout, @stderr).and_return(@status)
      end

      it "should create a crontab with the entry" do
        @provider.action_create
        @stdin.string.should == <<-ENDCRON
# Chef Name: cronhole some stuff
30 * * * * /bin/true
        ENDCRON
      end

      it "should include env variables that are set" do
        @new_resource.mailto 'foo@example.com'
        @new_resource.path '/usr/bin:/my/custom/path'
        @new_resource.shell '/bin/foosh'
        @new_resource.home '/home/foo'
        @new_resource.environment "TEST" => "LOL"
        @provider.action_create
        @stdin.string.should == <<-ENDCRON
# Chef Name: cronhole some stuff
MAILTO=foo@example.com
PATH=/usr/bin:/my/custom/path
SHELL=/bin/foosh
HOME=/home/foo
TEST=LOL
30 * * * * /bin/true
        ENDCRON
      end

      it "should mark the resource as updated" do
        @provider.action_create
        @new_resource.should be_updated_by_last_action
      end

      it "should log the action" do
        Chef::Log.should_receive(:info).with("cron[cronhole some stuff] added crontab entry")
        @provider.action_create
      end
    end

    context "when there is a crontab with no matching section" do
      before :each do
        @provider.cron_exists = false
        @stdout = StringIO.new(<<-CRONTAB)
0 2 * * * /some/other/command

# Chef Name: something else
2 * 1 * * /bin/false

# Another comment
        CRONTAB
        @provider.stub!(:popen4).with("crontab -l -u #{@new_resource.user}").and_yield(@pid, StringIO.new, @stdout, StringIO.new).and_return(@status)
        @provider.stub!(:popen4).with("crontab -u #{@new_resource.user} -", :waitlast => true).and_yield(@pid, @stdin, StringIO.new, StringIO.new).and_return(@status)
      end

      it "should add the entry to the crontab" do
        @provider.action_create
        @stdin.string.should == <<-ENDCRON
0 2 * * * /some/other/command

# Chef Name: something else
2 * 1 * * /bin/false

# Another comment
# Chef Name: cronhole some stuff
30 * * * * /bin/true
        ENDCRON
      end

      it "should include env variables that are set" do
        @new_resource.mailto 'foo@example.com'
        @new_resource.path '/usr/bin:/my/custom/path'
        @new_resource.shell '/bin/foosh'
        @new_resource.home '/home/foo'
        @new_resource.environment "TEST" => "LOL"
        @provider.action_create
        @stdin.string.should == <<-ENDCRON
0 2 * * * /some/other/command

# Chef Name: something else
2 * 1 * * /bin/false

# Another comment
# Chef Name: cronhole some stuff
MAILTO=foo@example.com
PATH=/usr/bin:/my/custom/path
SHELL=/bin/foosh
HOME=/home/foo
TEST=LOL
30 * * * * /bin/true
        ENDCRON
      end

      it "should mark the resource as updated" do
        @provider.action_create
        @new_resource.should be_updated_by_last_action
      end

      it "should log the action" do
        Chef::Log.should_receive(:info).with("cron[cronhole some stuff] added crontab entry")
        @provider.action_create
      end
    end

    context "when there is a crontab with a matching but different section" do
      before :each do
        @provider.cron_exists = true
        @provider.stub!(:compare_cron).and_return(true)
        @stdout = StringIO.new(<<-CRONTAB)
0 2 * * * /some/other/command

# Chef Name: cronhole some stuff
30 * * 3 * /bin/true
# Chef Name: something else
2 * 1 * * /bin/false

# Another comment
        CRONTAB
        @provider.stub!(:popen4).with("crontab -l -u #{@new_resource.user}").and_yield(@pid, StringIO.new, @stdout, StringIO.new).and_return(@status)
        @provider.stub!(:popen4).with("crontab -u #{@new_resource.user} -", :waitlast => true).and_yield(@pid, @stdin, StringIO.new, StringIO.new).and_return(@status)
      end

      it "should update the crontab entry" do
        @provider.action_create
        @stdin.string.should == <<-ENDCRON
0 2 * * * /some/other/command

# Chef Name: cronhole some stuff
30 * * * * /bin/true
# Chef Name: something else
2 * 1 * * /bin/false

# Another comment
        ENDCRON
      end

      it "should include env variables that are set" do
        @new_resource.mailto 'foo@example.com'
        @new_resource.path '/usr/bin:/my/custom/path'
        @new_resource.shell '/bin/foosh'
        @new_resource.home '/home/foo'
        @new_resource.environment "TEST" => "LOL"
        @provider.action_create
        @stdin.string.should == <<-ENDCRON
0 2 * * * /some/other/command

# Chef Name: cronhole some stuff
MAILTO=foo@example.com
PATH=/usr/bin:/my/custom/path
SHELL=/bin/foosh
HOME=/home/foo
TEST=LOL
30 * * * * /bin/true
# Chef Name: something else
2 * 1 * * /bin/false

# Another comment
        ENDCRON
      end

      it "should mark the resource as updated" do
        @provider.action_create
        @new_resource.should be_updated_by_last_action
      end

      it "should log the action" do
        Chef::Log.should_receive(:info).with("cron[cronhole some stuff] updated crontab entry")
        @provider.action_create
      end
    end

    context "when there is a crontab with a matching and identical section" do
      before :each do
        @provider.cron_exists = true
        @provider.stub!(:compare_cron).and_return(false)
      end

      it "should not update the crontab" do
        @provider.should_not_receive(:popen4)
        @provider.action_create
      end

      it "should not mark the resource as updated" do
        @provider.action_create
        @new_resource.should_not be_updated_by_last_action
      end

      it "should log nothing changed" do
        Chef::Log.should_receive(:debug).with("Skipping existing cron entry '#{@new_resource.name}'")
        @provider.action_create
      end
    end
  end

  describe "action_delete" do

    context "when the user's crontab has no matching section" do
      before :each do
        @provider.cron_exists = false
      end

      it "should do nothing" do
        @provider.should_not_receive(:popen4)
        Chef::Log.should_not_receive(:info)
        @provider.action_delete
      end

      it "should not mark the resource as updated" do
        @provider.action_delete
        @new_resource.should_not be_updated_by_last_action
      end
    end

    context "when the user has a crontab with a matching section" do
      before :each do
        @provider.cron_exists = true
        @status = mock("Status", :exitstatus => 0)
        @stdout = StringIO.new(<<-CRONTAB)
0 2 * * * /some/other/command

# Chef Name: cronhole some stuff
30 * * 3 * /bin/true
# Chef Name: something else
2 * 1 * * /bin/false

# Another comment
        CRONTAB
        @stdin = StringIO.new
        @provider.stub!(:popen4).with("crontab -l -u #{@new_resource.user}").and_yield(@pid, StringIO.new, @stdout, StringIO.new).and_return(@status)
        @provider.stub!(:popen4).with("crontab -u #{@new_resource.user} -", :waitlast => true).and_yield(@pid, @stdin, StringIO.new, StringIO.new).and_return(@status)
      end

      it "should remove the entry" do
        @provider.action_delete
        @stdin.string.should == <<-ENDCRON
0 2 * * * /some/other/command

# Chef Name: something else
2 * 1 * * /bin/false

# Another comment
        ENDCRON
      end

      it "should remove any env vars with the entry" do
        @stdout.string = <<-CRONTAB
0 2 * * * /some/other/command

# Chef Name: cronhole some stuff
MAILTO=foo@example.com
FOO=test
30 * * 3 * /bin/true
# Chef Name: something else
2 * 1 * * /bin/false

# Another comment
        CRONTAB
        @provider.action_delete
        @stdin.string.should == <<-ENDCRON
0 2 * * * /some/other/command

# Chef Name: something else
2 * 1 * * /bin/false

# Another comment
        ENDCRON
      end

      it "should mark the resource as updated" do
        @provider.action_delete
        @new_resource.should be_updated_by_last_action
      end

      it "should log the action" do
        Chef::Log.should_receive(:info).with("#{@new_resource} deleted crontab entry")
        @provider.action_delete
      end
    end
  end
end
