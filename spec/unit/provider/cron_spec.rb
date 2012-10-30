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

require 'spec_helper'

describe Chef::Provider::Cron do
  before do
    @node = Chef::Node.new
    @events = Chef::EventDispatch::Dispatcher.new
    @run_context = Chef::RunContext.new(@node, {}, @events)
    @new_resource = Chef::Resource::Cron.new("cronhole some stuff", @run_context)
    @new_resource.user "root"
    @new_resource.minute "30"
    @new_resource.command "/bin/true"

    @provider = Chef::Provider::Cron.new(@new_resource, @run_context)
  end

  describe "when examining the current system state" do
    context "with no crontab for the user" do
      before :each do
        @provider.stub!(:read_crontab).and_return(nil)
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
        @provider.stub!(:read_crontab).and_return(<<-CRONTAB)
0 2 * * * /some/other/command

# Chef Name: something else
* 5 * * * /bin/true

# Another comment
CRONTAB
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
        @provider.stub!(:read_crontab).and_return(<<-CRONTAB)
# Chef Name: foo[bar] (baz)
21 */4 * * * some_prog 1234567
CRONTAB
        lambda {
          @provider.load_current_resource
        }.should_not raise_error
      end
    end

    context "with a matching entry in the user's crontab" do
      before :each do
        @provider.stub!(:read_crontab).and_return(<<-CRONTAB)
0 2 * * * /some/other/command

# Chef Name: cronhole some stuff
* 5 * 1 * /bin/true param1 param2
# Chef Name: something else
2 * 1 * * /bin/false

# Another comment
CRONTAB
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

      it "should pull env vars out" do
        @provider.stub!(:read_crontab).and_return(<<-CRONTAB)
0 2 * * * /some/other/command

# Chef Name: cronhole some stuff
MAILTO=foo@example.com
SHELL=/bin/foosh
PATH=/bin:/foo
HOME=/home/foo
* 5 * 1 * /bin/true param1 param2
# Chef Name: something else
2 * 1 * * /bin/false

# Another comment
CRONTAB
        cron = @provider.load_current_resource
        cron.mailto.should == 'foo@example.com'
        cron.shell.should == '/bin/foosh'
        cron.path.should == '/bin:/foo'
        cron.home.should == '/home/foo'
        cron.minute.should == '*'
        cron.hour.should == '5'
        cron.day.should == '*'
        cron.month.should == '1'
        cron.weekday.should == '*'
        cron.command.should == '/bin/true param1 param2'
      end

      it "should parse and load generic and standard environment variables from cron entry" do
        @provider.stub!(:read_crontab).and_return(<<-CRONTAB)
# Chef Name: cronhole some stuff
MAILTO=warn@example.com
TEST=lol
FLAG=1
* 5 * * * /bin/true
CRONTAB
        cron = @provider.load_current_resource

        cron.mailto.should == "warn@example.com"
        cron.environment.should == {"TEST" => "lol", "FLAG" => "1"}
      end

      it "should not break with variabels that match the cron resource internals" do
        @provider.stub!(:read_crontab).and_return(<<-CRONTAB)
# Chef Name: cronhole some stuff
MINUTE=40
HOUR=midnight
TEST=lol
ENVIRONMENT=production
* 5 * * * /bin/true
CRONTAB
        cron = @provider.load_current_resource

        cron.minute.should == '*'
        cron.hour.should == '5'
        cron.environment.should == {"MINUTE" => "40", "HOUR" => "midnight", "TEST" => "lol", "ENVIRONMENT" => "production"}
      end

      it "should report the match" do
        Chef::Log.should_receive(:debug).with("Found cron '#{@new_resource.name}'")
        @provider.load_current_resource
      end
    end

    context "with a matching entry in the user's crontab using month names and weekday names (#CHEF-3178)" do
      before :each do
        @provider.stub!(:read_crontab).and_return(<<-CRONTAB)
0 2 * * * /some/other/command
      
# Chef Name: cronhole some stuff
* 5 * Jan Mon /bin/true param1 param2
# Chef Name: something else
2 * 1 * * /bin/false

# Another comment
CRONTAB
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
        cron.month.should == 'Jan'
        cron.weekday.should == 'Mon'
        cron.command.should == '/bin/true param1 param2'
      end

      it "should report the match" do
        Chef::Log.should_receive(:debug).with("Found cron '#{@new_resource.name}'")
        @provider.load_current_resource
      end
    end

    context "with a matching entry without a crontab line" do
      it "should set cron_exists and leave current_resource values at defaults" do
        @provider.stub!(:read_crontab).and_return(<<-CRONTAB)
0 2 * * * /some/other/command

# Chef Name: cronhole some stuff
CRONTAB
        cron = @provider.load_current_resource
        @provider.cron_exists.should == true
        cron.minute.should == '*'
        cron.hour.should == '*'
        cron.day.should == '*'
        cron.month.should == '*'
        cron.weekday.should == '*'
        cron.command.should == nil
      end

      it "should not pick up a commented out crontab line" do
        @provider.stub!(:read_crontab).and_return(<<-CRONTAB)
0 2 * * * /some/other/command

# Chef Name: cronhole some stuff
#* 5 * 1 * /bin/true param1 param2
CRONTAB
        cron = @provider.load_current_resource
        @provider.cron_exists.should == true
        cron.minute.should == '*'
        cron.hour.should == '*'
        cron.day.should == '*'
        cron.month.should == '*'
        cron.weekday.should == '*'
        cron.command.should == nil
      end

      it "should not pick up a later crontab entry" do
        @provider.stub!(:read_crontab).and_return(<<-CRONTAB)
0 2 * * * /some/other/command

# Chef Name: cronhole some stuff
#* 5 * 1 * /bin/true param1 param2
# Chef Name: something else
2 * 1 * * /bin/false

# Another comment
CRONTAB
        cron = @provider.load_current_resource
        @provider.cron_exists.should == true
        cron.minute.should == '*'
        cron.hour.should == '*'
        cron.day.should == '*'
        cron.month.should == '*'
        cron.weekday.should == '*'
        cron.command.should == nil
      end
    end
  end

  describe "cron_different?" do
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
        @provider.cron_different?.should eql(true)
      end
    end

    it "should return true if environment doesn't match" do
      @new_resource.environment "FOO" => "something_else"
      @provider.cron_different?.should eql(true)
    end

    it "should return false if the objects are identical" do
      @provider.cron_different?.should == false
    end
  end

  describe "action_create" do
    before :each do
      @provider.stub!(:write_crontab)
      @provider.stub!(:read_crontab).and_return(nil)
    end

    context "when there is no existing crontab" do
      before :each do
        @provider.cron_exists = false
        @provider.cron_empty = true
      end

      it "should create a crontab with the entry" do
        @provider.should_receive(:write_crontab).with(<<-ENDCRON)
# Chef Name: cronhole some stuff
30 * * * * /bin/true
        ENDCRON
        @provider.run_action(:create)
      end

      it "should include env variables that are set" do
        @new_resource.mailto 'foo@example.com'
        @new_resource.path '/usr/bin:/my/custom/path'
        @new_resource.shell '/bin/foosh'
        @new_resource.home '/home/foo'
        @new_resource.environment "TEST" => "LOL"
        @provider.should_receive(:write_crontab).with(<<-ENDCRON)
# Chef Name: cronhole some stuff
MAILTO=foo@example.com
PATH=/usr/bin:/my/custom/path
SHELL=/bin/foosh
HOME=/home/foo
TEST=LOL
30 * * * * /bin/true
        ENDCRON
        @provider.run_action(:create)
      end

      it "should mark the resource as updated" do
        @provider.run_action(:create)
        @new_resource.should be_updated_by_last_action
      end

      it "should log the action" do
        Chef::Log.should_receive(:info).with("cron[cronhole some stuff] added crontab entry")
        @provider.run_action(:create)
      end
    end

    context "when there is a crontab with no matching section" do
      before :each do
        @provider.cron_exists = false
        @provider.stub!(:read_crontab).and_return(<<-CRONTAB)
0 2 * * * /some/other/command

# Chef Name: something else
2 * 1 * * /bin/false

# Another comment
        CRONTAB
      end

      it "should add the entry to the crontab" do
        @provider.should_receive(:write_crontab).with(<<-ENDCRON)
0 2 * * * /some/other/command

# Chef Name: something else
2 * 1 * * /bin/false

# Another comment
# Chef Name: cronhole some stuff
30 * * * * /bin/true
        ENDCRON
        @provider.run_action(:create)
      end

      it "should include env variables that are set" do
        @new_resource.mailto 'foo@example.com'
        @new_resource.path '/usr/bin:/my/custom/path'
        @new_resource.shell '/bin/foosh'
        @new_resource.home '/home/foo'
        @new_resource.environment "TEST" => "LOL"
        @provider.should_receive(:write_crontab).with(<<-ENDCRON)
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
        @provider.run_action(:create)
      end

      it "should mark the resource as updated" do
        @provider.run_action(:create)
        @new_resource.should be_updated_by_last_action
      end

      it "should log the action" do
        Chef::Log.should_receive(:info).with("cron[cronhole some stuff] added crontab entry")
        @provider.run_action(:create)
      end
    end

    context "when there is a crontab with a matching but different section" do
      before :each do
        @provider.cron_exists = true
        @provider.stub!(:cron_different?).and_return(true)
        @provider.stub!(:read_crontab).and_return(<<-CRONTAB)
0 2 * * * /some/other/command

# Chef Name: cronhole some stuff
30 * * 3 * /bin/true
# Chef Name: something else
2 * 1 * * /bin/false

# Another comment
        CRONTAB
      end

      it "should update the crontab entry" do
        @provider.should_receive(:write_crontab).with(<<-ENDCRON)
0 2 * * * /some/other/command

# Chef Name: cronhole some stuff
30 * * * * /bin/true
# Chef Name: something else
2 * 1 * * /bin/false

# Another comment
        ENDCRON
        @provider.run_action(:create)
      end

      it "should include env variables that are set" do
        @new_resource.mailto 'foo@example.com'
        @new_resource.path '/usr/bin:/my/custom/path'
        @new_resource.shell '/bin/foosh'
        @new_resource.home '/home/foo'
        @new_resource.environment "TEST" => "LOL"
        @provider.should_receive(:write_crontab).with(<<-ENDCRON)
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
        @provider.run_action(:create)
      end

      it "should mark the resource as updated" do
        @provider.run_action(:create)
        @new_resource.should be_updated_by_last_action
      end

      it "should log the action" do
        Chef::Log.should_receive(:info).with("cron[cronhole some stuff] updated crontab entry")
        @provider.run_action(:create)
      end
    end

    context "when there is a crontab with a matching section with no crontab line in it" do
      before :each do
        @provider.cron_exists = true
        @provider.stub!(:cron_different?).and_return(true)
      end

      it "should add the crontab to the entry" do
        @provider.stub!(:read_crontab).and_return(<<-CRONTAB)
0 2 * * * /some/other/command

# Chef Name: cronhole some stuff
        CRONTAB
        @provider.should_receive(:write_crontab).with(<<-ENDCRON)
0 2 * * * /some/other/command

# Chef Name: cronhole some stuff
30 * * * * /bin/true
        ENDCRON
        @provider.run_action(:create)
      end

      it "should not blat any following entries" do
        @provider.stub!(:read_crontab).and_return(<<-CRONTAB)
0 2 * * * /some/other/command

# Chef Name: cronhole some stuff
#30 * * * * /bin/true
# Chef Name: something else
2 * 1 * * /bin/false

# Another comment
        CRONTAB
        @provider.should_receive(:write_crontab).with(<<-ENDCRON)
0 2 * * * /some/other/command

# Chef Name: cronhole some stuff
30 * * * * /bin/true
#30 * * * * /bin/true
# Chef Name: something else
2 * 1 * * /bin/false

# Another comment
        ENDCRON
        @provider.run_action(:create)
      end

      it "should handle env vars with no crontab" do
        @provider.stub!(:read_crontab).and_return(<<-CRONTAB)
0 2 * * * /some/other/command

# Chef Name: cronhole some stuff
MAILTO=bar@example.com
PATH=/usr/bin:/my/custom/path
SHELL=/bin/barsh
HOME=/home/foo

# Chef Name: something else
2 * 1 * * /bin/false

# Another comment
        CRONTAB
        @new_resource.mailto 'foo@example.com'
        @new_resource.path '/usr/bin:/my/custom/path'
        @new_resource.shell '/bin/foosh'
        @new_resource.home '/home/foo'
        @provider.should_receive(:write_crontab).with(<<-ENDCRON)
0 2 * * * /some/other/command

# Chef Name: cronhole some stuff
MAILTO=foo@example.com
PATH=/usr/bin:/my/custom/path
SHELL=/bin/foosh
HOME=/home/foo
30 * * * * /bin/true

# Chef Name: something else
2 * 1 * * /bin/false

# Another comment
        ENDCRON
        @provider.run_action(:create)
      end
    end

    context "when there is a crontab with a matching and identical section" do
      before :each do
        @provider.cron_exists = true
        @provider.stub!(:cron_different?).and_return(false)
        @provider.stub!(:read_crontab).and_return(<<-CRONTAB)
0 2 * * * /some/other/command

# Chef Name: something else
* 5 * * * /bin/true

# Another comment
CRONTAB
      end

      it "should not update the crontab" do
        @provider.should_not_receive(:write_crontab)
        @provider.run_action(:create)
      end

      it "should not mark the resource as updated" do
        @provider.run_action(:create)
        @new_resource.should_not be_updated_by_last_action
      end

      it "should log nothing changed" do
        Chef::Log.should_receive(:debug).with("Skipping existing cron entry '#{@new_resource.name}'")
        @provider.run_action(:create)
      end
    end
  end

  describe "action_delete" do
    before :each do
      @provider.stub!(:write_crontab)
      @provider.stub!(:read_crontab).and_return(nil)
    end

    context "when the user's crontab has no matching section" do
      before :each do
        @provider.cron_exists = false
      end

      it "should do nothing" do
        @provider.should_not_receive(:write_crontab)
        Chef::Log.should_not_receive(:info)
        @provider.run_action(:delete)
      end

      it "should not mark the resource as updated" do
        @provider.run_action(:delete)
        @new_resource.should_not be_updated_by_last_action
      end
    end

    context "when the user has a crontab with a matching section" do
      before :each do
        @provider.cron_exists = true
        @provider.stub!(:read_crontab).and_return(<<-CRONTAB)
0 2 * * * /some/other/command

# Chef Name: cronhole some stuff
30 * * 3 * /bin/true
# Chef Name: something else
2 * 1 * * /bin/false

# Another comment
        CRONTAB
      end

      it "should remove the entry" do
        @provider.should_receive(:write_crontab).with(<<-ENDCRON)
0 2 * * * /some/other/command

# Chef Name: something else
2 * 1 * * /bin/false

# Another comment
        ENDCRON
        @provider.run_action(:delete)
      end

      it "should remove any env vars with the entry" do
        @provider.stub!(:read_crontab).and_return(<<-CRONTAB)
0 2 * * * /some/other/command

# Chef Name: cronhole some stuff
MAILTO=foo@example.com
FOO=test
30 * * 3 * /bin/true
# Chef Name: something else
2 * 1 * * /bin/false

# Another comment
        CRONTAB
        @provider.should_receive(:write_crontab).with(<<-ENDCRON)
0 2 * * * /some/other/command

# Chef Name: something else
2 * 1 * * /bin/false

# Another comment
        ENDCRON
        @provider.run_action(:delete)
      end

      it "should mark the resource as updated" do
        @provider.run_action(:delete)
        @new_resource.should be_updated_by_last_action
      end

      it "should log the action" do
        Chef::Log.should_receive(:info).with("#{@new_resource} deleted crontab entry")
        @provider.run_action(:delete)
      end
    end

    context "when the crontab has a matching section with no crontab line" do
      before :each do
        @provider.cron_exists = true
      end

      it "should remove the section" do
        @provider.stub!(:read_crontab).and_return(<<-CRONTAB)
0 2 * * * /some/other/command

# Chef Name: cronhole some stuff
        CRONTAB
        @provider.should_receive(:write_crontab).with(<<-ENDCRON)
0 2 * * * /some/other/command

        ENDCRON
        @provider.run_action(:delete)
      end

      it "should not blat following sections" do
        @provider.stub!(:read_crontab).and_return(<<-CRONTAB)
0 2 * * * /some/other/command

# Chef Name: cronhole some stuff
#30 * * 3 * /bin/true
# Chef Name: something else
2 * 1 * * /bin/false

# Another comment
        CRONTAB
        @provider.should_receive(:write_crontab).with(<<-ENDCRON)
0 2 * * * /some/other/command

#30 * * 3 * /bin/true
# Chef Name: something else
2 * 1 * * /bin/false

# Another comment
        ENDCRON
        @provider.run_action(:delete)
      end

      it "should remove any envvars with the section" do
        @provider.stub!(:read_crontab).and_return(<<-CRONTAB)
0 2 * * * /some/other/command

# Chef Name: cronhole some stuff
MAILTO=foo@example.com
#30 * * 3 * /bin/true
# Chef Name: something else
2 * 1 * * /bin/false

# Another comment
        CRONTAB
        @provider.should_receive(:write_crontab).with(<<-ENDCRON)
0 2 * * * /some/other/command

#30 * * 3 * /bin/true
# Chef Name: something else
2 * 1 * * /bin/false

# Another comment
        ENDCRON
        @provider.run_action(:delete)
      end
    end
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
      @provider.should_receive(:popen4).with("crontab -l -u #{@new_resource.user}").and_return(@status)
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
      @stdin = StringIO.new
      @provider.stub!(:popen4).and_yield(1234, @stdin, StringIO.new, StringIO.new).and_return(@status)
    end

    it "should call crontab for the user" do
      @provider.should_receive(:popen4).with("crontab -u #{@new_resource.user} -", :waitlast => true).and_return(@status)
      @provider.send(:write_crontab, "Foo")
    end

    it "should write the given string to the crontab command" do
      @provider.send(:write_crontab, "Foo\n# wibble\n wah!!")
      @stdin.string.should == "Foo\n# wibble\n wah!!"
    end

    it "should raise an exception if the command returns non-zero" do
      @status.stub!(:exitstatus).and_return(1)
      lambda do
        @provider.send(:write_crontab, "Foo")
      end.should raise_error(Chef::Exceptions::Cron, "Error updating state of #{@new_resource.name}, exit: 1")
    end
  end
end
