#
# Author:: Bryan McLellan (btm@loftninjas.org)
# Copyright:: Copyright 2009-2016, Bryan McLellan
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

require "spec_helper"

describe Chef::Provider::Cron do
  describe "when with special time string" do
    before do
      @node = Chef::Node.new
      @events = Chef::EventDispatch::Dispatcher.new
      @run_context = Chef::RunContext.new(@node, {}, @events)

      @new_resource = Chef::Resource::Cron.new("cronhole some stuff", @run_context)
      @new_resource.user "root"
      @new_resource.minute "30"
      @new_resource.command "/bin/true"
      @new_resource.time :reboot
      @provider = Chef::Provider::Cron.new(@new_resource, @run_context)
    end

    context "with a matching entry in the user's crontab" do
      before :each do
        allow(@provider).to receive(:read_crontab).and_return(<<-CRONTAB)
0 2 * * * /some/other/command

# Chef Name: cronhole some stuff
@reboot /bin/true param1 param2
# Chef Name: something else
2 * 1 * * /bin/false

# Another comment
CRONTAB
      end

      it "should set cron_exists" do
        @provider.load_current_resource
        expect(@provider.cron_exists).to eq(true)
        expect(@provider.cron_empty).to eq(false)
      end

      it "should pull the details out of the cron line" do
        cron = @provider.load_current_resource
        expect(cron.time).to eq(:reboot)
        expect(cron.command).to eq("/bin/true param1 param2")
      end

      it "should pull env vars out" do
        allow(@provider).to receive(:read_crontab).and_return(<<-CRONTAB)
0 2 * * * /some/other/command

# Chef Name: cronhole some stuff
MAILTO=foo@example.com
SHELL=/bin/foosh
PATH=/bin:/foo
HOME=/home/foo
@reboot /bin/true param1 param2
# Chef Name: something else
2 * 1 * * /bin/false

# Another comment
CRONTAB
        cron = @provider.load_current_resource
        expect(cron.mailto).to eq("foo@example.com")
        expect(cron.shell).to eq("/bin/foosh")
        expect(cron.path).to eq("/bin:/foo")
        expect(cron.home).to eq("/home/foo")
        expect(cron.time).to eq(:reboot)
        expect(cron.command).to eq("/bin/true param1 param2")
      end

      it "should parse and load generic and standard environment variables from cron entry" do
        allow(@provider).to receive(:read_crontab).and_return(<<-CRONTAB)
# Chef Name: cronhole some stuff
MAILTO=warn@example.com
TEST=lol
FLAG=1
@reboot /bin/true
CRONTAB
        cron = @provider.load_current_resource

        expect(cron.mailto).to eq("warn@example.com")
        expect(cron.environment).to eq({ "TEST" => "lol", "FLAG" => "1" })
      end

      it "should not break with variables that match the cron resource internals" do
        allow(@provider).to receive(:read_crontab).and_return(<<-CRONTAB)
# Chef Name: cronhole some stuff
MINUTE=40
REBOOT=midnight
TEST=lol
ENVIRONMENT=production
@reboot /bin/true
CRONTAB
        cron = @provider.load_current_resource

        expect(cron.time).to eq(:reboot)
        expect(cron.environment).to eq({ "MINUTE" => "40", "REBOOT" => "midnight", "TEST" => "lol", "ENVIRONMENT" => "production" })
      end

      it "should report the match" do
        expect(Chef::Log).to receive(:debug).with("Found cron '#{@new_resource.name}'")
        @provider.load_current_resource
      end

      describe "action_create" do
        before :each do
          allow(@provider).to receive(:write_crontab)
          allow(@provider).to receive(:read_crontab).and_return(nil)
        end

        context "when there is no existing crontab" do
          before :each do
            @provider.cron_exists = false
            @provider.cron_empty = true
          end

          it "should create a crontab with the entry" do
            expect(@provider).to receive(:write_crontab).with(<<-ENDCRON)
# Chef Name: cronhole some stuff
@reboot /bin/true
            ENDCRON
            @provider.run_action(:create)
          end
        end
      end
    end
  end

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
        allow(@provider).to receive(:read_crontab).and_return(nil)
      end

      it "should set cron_empty" do
        @provider.load_current_resource
        expect(@provider.cron_empty).to eq(true)
        expect(@provider.cron_exists).to eq(false)
      end

      it "should report an empty crontab" do
        expect(Chef::Log).to receive(:debug).with("Cron empty for '#{@new_resource.user}'")
        @provider.load_current_resource
      end
    end

    context "with no matching entry in the user's crontab" do
      before :each do
        allow(@provider).to receive(:read_crontab).and_return(<<-CRONTAB)
0 2 * * * /some/other/command

# Chef Name: something else
* 5 * * * /bin/true

# Another comment
CRONTAB
      end

      it "should not set cron_exists or cron_empty" do
        @provider.load_current_resource
        expect(@provider.cron_exists).to eq(false)
        expect(@provider.cron_empty).to eq(false)
      end

      it "should report no entry found" do
        expect(Chef::Log).to receive(:debug).with("Cron '#{@new_resource.name}' not found")
        @provider.load_current_resource
      end

      it "should not fail if there's an existing cron with a numerical argument" do
        allow(@provider).to receive(:read_crontab).and_return(<<-CRONTAB)
# Chef Name: foo[bar] (baz)
21 */4 * * * some_prog 1234567
CRONTAB
        expect do
          @provider.load_current_resource
        end.not_to raise_error
      end
    end

    context "with a matching entry in the user's crontab" do
      before :each do
        allow(@provider).to receive(:read_crontab).and_return(<<-CRONTAB)
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
        expect(@provider.cron_exists).to eq(true)
        expect(@provider.cron_empty).to eq(false)
      end

      it "should pull the details out of the cron line" do
        cron = @provider.load_current_resource
        expect(cron.minute).to eq("*")
        expect(cron.hour).to eq("5")
        expect(cron.day).to eq("*")
        expect(cron.month).to eq("1")
        expect(cron.weekday).to eq("*")
        expect(cron.time).to eq(nil)
        expect(cron.command).to eq("/bin/true param1 param2")
      end

      it "should pull env vars out" do
        allow(@provider).to receive(:read_crontab).and_return(<<-CRONTAB)
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
        expect(cron.mailto).to eq("foo@example.com")
        expect(cron.shell).to eq("/bin/foosh")
        expect(cron.path).to eq("/bin:/foo")
        expect(cron.home).to eq("/home/foo")
        expect(cron.minute).to eq("*")
        expect(cron.hour).to eq("5")
        expect(cron.day).to eq("*")
        expect(cron.month).to eq("1")
        expect(cron.weekday).to eq("*")
        expect(cron.time).to eq(nil)
        expect(cron.command).to eq("/bin/true param1 param2")
      end

      it "should parse and load generic and standard environment variables from cron entry" do
        allow(@provider).to receive(:read_crontab).and_return(<<-CRONTAB)
# Chef Name: cronhole some stuff
MAILTO=warn@example.com
TEST=lol
FLAG=1
* 5 * * * /bin/true
CRONTAB
        cron = @provider.load_current_resource

        expect(cron.mailto).to eq("warn@example.com")
        expect(cron.environment).to eq({ "TEST" => "lol", "FLAG" => "1" })
      end

      it "should not break with variabels that match the cron resource internals" do
        allow(@provider).to receive(:read_crontab).and_return(<<-CRONTAB)
# Chef Name: cronhole some stuff
MINUTE=40
HOUR=midnight
TEST=lol
ENVIRONMENT=production
* 5 * * * /bin/true
CRONTAB
        cron = @provider.load_current_resource

        expect(cron.minute).to eq("*")
        expect(cron.hour).to eq("5")
        expect(cron.environment).to eq({ "MINUTE" => "40", "HOUR" => "midnight", "TEST" => "lol", "ENVIRONMENT" => "production" })
      end

      it "should report the match" do
        expect(Chef::Log).to receive(:debug).with("Found cron '#{@new_resource.name}'")
        @provider.load_current_resource
      end
    end

    context "with a matching entry in the user's crontab using month names and weekday names (#CHEF-3178)" do
      before :each do
        allow(@provider).to receive(:read_crontab).and_return(<<-CRONTAB)
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
        expect(@provider.cron_exists).to eq(true)
        expect(@provider.cron_empty).to eq(false)
      end

      it "should pull the details out of the cron line" do
        cron = @provider.load_current_resource
        expect(cron.minute).to eq("*")
        expect(cron.hour).to eq("5")
        expect(cron.day).to eq("*")
        expect(cron.month).to eq("Jan")
        expect(cron.weekday).to eq("Mon")
        expect(cron.command).to eq("/bin/true param1 param2")
      end

      it "should report the match" do
        expect(Chef::Log).to receive(:debug).with("Found cron '#{@new_resource.name}'")
        @provider.load_current_resource
      end
    end

    context "with a matching entry without a crontab line" do
      it "should set cron_exists and leave current_resource values at defaults" do
        allow(@provider).to receive(:read_crontab).and_return(<<-CRONTAB)
0 2 * * * /some/other/command

# Chef Name: cronhole some stuff
CRONTAB
        cron = @provider.load_current_resource
        expect(@provider.cron_exists).to eq(true)
        expect(cron.minute).to eq("*")
        expect(cron.hour).to eq("*")
        expect(cron.day).to eq("*")
        expect(cron.month).to eq("*")
        expect(cron.weekday).to eq("*")
        expect(cron.time).to eq(nil)
        expect(cron.command).to eq(nil)
      end

      it "should not pick up a commented out crontab line" do
        allow(@provider).to receive(:read_crontab).and_return(<<-CRONTAB)
0 2 * * * /some/other/command

# Chef Name: cronhole some stuff
#* 5 * 1 * /bin/true param1 param2
CRONTAB
        cron = @provider.load_current_resource
        expect(@provider.cron_exists).to eq(true)
        expect(cron.minute).to eq("*")
        expect(cron.hour).to eq("*")
        expect(cron.day).to eq("*")
        expect(cron.month).to eq("*")
        expect(cron.weekday).to eq("*")
        expect(cron.time).to eq(nil)
        expect(cron.command).to eq(nil)
      end

      it "should not pick up a later crontab entry" do
        allow(@provider).to receive(:read_crontab).and_return(<<-CRONTAB)
0 2 * * * /some/other/command

# Chef Name: cronhole some stuff
#* 5 * 1 * /bin/true param1 param2
# Chef Name: something else
2 * 1 * * /bin/false

# Another comment
CRONTAB
        cron = @provider.load_current_resource
        expect(@provider.cron_exists).to eq(true)
        expect(cron.minute).to eq("*")
        expect(cron.hour).to eq("*")
        expect(cron.day).to eq("*")
        expect(cron.month).to eq("*")
        expect(cron.weekday).to eq("*")
        expect(cron.time).to eq(nil)
        expect(cron.command).to eq(nil)
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
        expect(@provider.cron_different?).to eql(true)
      end
    end

    it "should return true if special time string doesn't match" do
      @new_resource.send(:time, :reboot)
      expect(@provider.cron_different?).to eql(true)
    end

    it "should return true if environment doesn't match" do
      @new_resource.environment "FOO" => "something_else"
      expect(@provider.cron_different?).to eql(true)
    end

    it "should return true if mailto doesn't match" do
      @current_resource.mailto "foo@bar.com"
      @new_resource.mailto(nil)
      expect(@provider.cron_different?).to eql(true)
    end

    it "should return false if the objects are identical" do
      expect(@provider.cron_different?).to eq(false)
    end
  end

  describe "action_create" do
    before :each do
      allow(@provider).to receive(:write_crontab)
      allow(@provider).to receive(:read_crontab).and_return(nil)
    end

    context "when there is no existing crontab" do
      before :each do
        @provider.cron_exists = false
        @provider.cron_empty = true
      end

      it "should create a crontab with the entry" do
        expect(@provider).to receive(:write_crontab).with(<<-ENDCRON)
# Chef Name: cronhole some stuff
30 * * * * /bin/true
        ENDCRON
        @provider.run_action(:create)
      end

      it "should include env variables that are set" do
        @new_resource.mailto "foo@example.com"
        @new_resource.path "/usr/bin:/my/custom/path"
        @new_resource.shell "/bin/foosh"
        @new_resource.home "/home/foo"
        @new_resource.environment "TEST" => "LOL"
        expect(@provider).to receive(:write_crontab).with(<<-ENDCRON)
# Chef Name: cronhole some stuff
MAILTO="foo@example.com"
PATH="/usr/bin:/my/custom/path"
SHELL="/bin/foosh"
HOME="/home/foo"
TEST=LOL
30 * * * * /bin/true
        ENDCRON
        @provider.run_action(:create)
      end

      it "should mark the resource as updated" do
        @provider.run_action(:create)
        expect(@new_resource).to be_updated_by_last_action
      end

      it "should log the action" do
        expect(Chef::Log).to receive(:info).with("cron[cronhole some stuff] added crontab entry")
        @provider.run_action(:create)
      end
    end

    context "when there is a crontab with no matching section" do
      before :each do
        @provider.cron_exists = false
        allow(@provider).to receive(:read_crontab).and_return(<<-CRONTAB)
0 2 * * * /some/other/command

# Chef Name: something else
2 * 1 * * /bin/false

# Another comment
        CRONTAB
      end

      it "should add the entry to the crontab" do
        expect(@provider).to receive(:write_crontab).with(<<-ENDCRON)
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
        @new_resource.mailto "foo@example.com"
        @new_resource.path "/usr/bin:/my/custom/path"
        @new_resource.shell "/bin/foosh"
        @new_resource.home "/home/foo"
        @new_resource.environment "TEST" => "LOL"
        expect(@provider).to receive(:write_crontab).with(<<-ENDCRON)
0 2 * * * /some/other/command

# Chef Name: something else
2 * 1 * * /bin/false

# Another comment
# Chef Name: cronhole some stuff
MAILTO="foo@example.com"
PATH="/usr/bin:/my/custom/path"
SHELL="/bin/foosh"
HOME="/home/foo"
TEST=LOL
30 * * * * /bin/true
        ENDCRON
        @provider.run_action(:create)
      end

      it "should mark the resource as updated" do
        @provider.run_action(:create)
        expect(@new_resource).to be_updated_by_last_action
      end

      it "should log the action" do
        expect(Chef::Log).to receive(:info).with("cron[cronhole some stuff] added crontab entry")
        @provider.run_action(:create)
      end
    end

    context "when there is a crontab with a matching but different section" do
      before :each do
        @provider.cron_exists = true
        allow(@provider).to receive(:cron_different?).and_return(true)
        allow(@provider).to receive(:read_crontab).and_return(<<-CRONTAB)
0 2 * * * /some/other/command

# Chef Name: cronhole some stuff
30 * * 3 * /bin/true
# Chef Name: something else
2 * 1 * * /bin/false

# Another comment
        CRONTAB
      end

      it "should update the crontab entry" do
        expect(@provider).to receive(:write_crontab).with(<<-ENDCRON)
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
        @new_resource.mailto "foo@example.com"
        @new_resource.path "/usr/bin:/my/custom/path"
        @new_resource.shell "/bin/foosh"
        @new_resource.home "/home/foo"
        @new_resource.environment "TEST" => "LOL"
        expect(@provider).to receive(:write_crontab).with(<<-ENDCRON)
0 2 * * * /some/other/command

# Chef Name: cronhole some stuff
MAILTO="foo@example.com"
PATH="/usr/bin:/my/custom/path"
SHELL="/bin/foosh"
HOME="/home/foo"
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
        expect(@new_resource).to be_updated_by_last_action
      end

      it "should log the action" do
        expect(Chef::Log).to receive(:info).with("cron[cronhole some stuff] updated crontab entry")
        @provider.run_action(:create)
      end
    end

    context "when there is a crontab with a matching section with no crontab line in it" do
      before :each do
        @provider.cron_exists = true
        allow(@provider).to receive(:cron_different?).and_return(true)
      end

      it "should add the crontab to the entry" do
        allow(@provider).to receive(:read_crontab).and_return(<<-CRONTAB)
0 2 * * * /some/other/command

# Chef Name: cronhole some stuff
        CRONTAB
        expect(@provider).to receive(:write_crontab).with(<<-ENDCRON)
0 2 * * * /some/other/command

# Chef Name: cronhole some stuff
30 * * * * /bin/true
        ENDCRON
        @provider.run_action(:create)
      end

      it "should not blat any following entries" do
        allow(@provider).to receive(:read_crontab).and_return(<<-CRONTAB)
0 2 * * * /some/other/command

# Chef Name: cronhole some stuff
#30 * * * * /bin/true
# Chef Name: something else
2 * 1 * * /bin/false

# Another comment
        CRONTAB
        expect(@provider).to receive(:write_crontab).with(<<-ENDCRON)
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
        allow(@provider).to receive(:read_crontab).and_return(<<-CRONTAB)
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
        @new_resource.mailto "foo@example.com"
        @new_resource.path "/usr/bin:/my/custom/path"
        @new_resource.shell "/bin/foosh"
        @new_resource.home "/home/foo"
        expect(@provider).to receive(:write_crontab).with(<<-ENDCRON)
0 2 * * * /some/other/command

# Chef Name: cronhole some stuff
MAILTO="foo@example.com"
PATH="/usr/bin:/my/custom/path"
SHELL="/bin/foosh"
HOME="/home/foo"
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
        allow(@provider).to receive(:cron_different?).and_return(false)
        allow(@provider).to receive(:read_crontab).and_return(<<-CRONTAB)
0 2 * * * /some/other/command

# Chef Name: cronhole some stuff
* 5 * * * /bin/true

# Another comment
CRONTAB
      end

      it "should not update the crontab" do
        expect(@provider).not_to receive(:write_crontab)
        @provider.run_action(:create)
      end

      it "should not mark the resource as updated" do
        @provider.run_action(:create)
        expect(@new_resource).not_to be_updated_by_last_action
      end

      it "should log nothing changed" do
        expect(Chef::Log).to receive(:debug).with("Found cron '#{@new_resource.name}'")
        expect(Chef::Log).to receive(:debug).with("Skipping existing cron entry '#{@new_resource.name}'")
        @provider.run_action(:create)
      end
    end
  end

  describe "action_delete" do
    before :each do
      allow(@provider).to receive(:write_crontab)
      allow(@provider).to receive(:read_crontab).and_return(nil)
    end

    context "when the user's crontab has no matching section" do
      before :each do
        @provider.cron_exists = false
      end

      it "should do nothing" do
        expect(@provider).not_to receive(:write_crontab)
        expect(Chef::Log).not_to receive(:info)
        @provider.run_action(:delete)
      end

      it "should not mark the resource as updated" do
        @provider.run_action(:delete)
        expect(@new_resource).not_to be_updated_by_last_action
      end
    end

    context "when the user has a crontab with a matching section" do
      before :each do
        @provider.cron_exists = true
        allow(@provider).to receive(:read_crontab).and_return(<<-CRONTAB)
0 2 * * * /some/other/command

# Chef Name: cronhole some stuff
30 * * 3 * /bin/true
# Chef Name: something else
2 * 1 * * /bin/false

# Another comment
        CRONTAB
      end

      it "should remove the entry" do
        expect(@provider).to receive(:write_crontab).with(<<-ENDCRON)
0 2 * * * /some/other/command

# Chef Name: something else
2 * 1 * * /bin/false

# Another comment
        ENDCRON
        @provider.run_action(:delete)
      end

      it "should remove any env vars with the entry" do
        allow(@provider).to receive(:read_crontab).and_return(<<-CRONTAB)
0 2 * * * /some/other/command

# Chef Name: cronhole some stuff
MAILTO=foo@example.com
FOO=test
30 * * 3 * /bin/true
# Chef Name: something else
2 * 1 * * /bin/false

# Another comment
        CRONTAB
        expect(@provider).to receive(:write_crontab).with(<<-ENDCRON)
0 2 * * * /some/other/command

# Chef Name: something else
2 * 1 * * /bin/false

# Another comment
        ENDCRON
        @provider.run_action(:delete)
      end

      it "should mark the resource as updated" do
        @provider.run_action(:delete)
        expect(@new_resource).to be_updated_by_last_action
      end

      it "should log the action" do
        expect(Chef::Log).to receive(:info).with("#{@new_resource} deleted crontab entry")
        @provider.run_action(:delete)
      end
    end

    context "when the crontab has a matching section with no crontab line" do
      before :each do
        @provider.cron_exists = true
      end

      it "should remove the section" do
        allow(@provider).to receive(:read_crontab).and_return(<<-CRONTAB)
0 2 * * * /some/other/command

# Chef Name: cronhole some stuff
        CRONTAB
        expect(@provider).to receive(:write_crontab).with(<<-ENDCRON)
0 2 * * * /some/other/command

        ENDCRON
        @provider.run_action(:delete)
      end

      it "should not blat following sections" do
        allow(@provider).to receive(:read_crontab).and_return(<<-CRONTAB)
0 2 * * * /some/other/command

# Chef Name: cronhole some stuff
#30 * * 3 * /bin/true
# Chef Name: something else
2 * 1 * * /bin/false

# Another comment
        CRONTAB
        expect(@provider).to receive(:write_crontab).with(<<-ENDCRON)
0 2 * * * /some/other/command

#30 * * 3 * /bin/true
# Chef Name: something else
2 * 1 * * /bin/false

# Another comment
        ENDCRON
        @provider.run_action(:delete)
      end

      it "should remove any envvars with the section" do
        allow(@provider).to receive(:read_crontab).and_return(<<-CRONTAB)
0 2 * * * /some/other/command

# Chef Name: cronhole some stuff
MAILTO=foo@example.com
#30 * * 3 * /bin/true
# Chef Name: something else
2 * 1 * * /bin/false

# Another comment
        CRONTAB
        expect(@provider).to receive(:write_crontab).with(<<-ENDCRON)
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
      @stdout = <<-CRONTAB
0 2 * * * /some/other/command

# Chef Name: something else
* 5 * * * /bin/true

# Another comment
      CRONTAB
      @status = double("Status", exitstatus: 0, stdout: @stdout)
      allow(@provider).to receive(:shell_out!).and_return(@status)
    end

    it "should call crontab -l with the user" do
      expect(@provider).to receive(:shell_out!).with("crontab -l -u #{@new_resource.user}", returns: [0, 1]).and_return(@status)
      @provider.send(:read_crontab)
    end

    it "should return the contents of the crontab" do
      crontab = @provider.send(:read_crontab)
      expect(crontab).to eq <<-CRONTAB
0 2 * * * /some/other/command

# Chef Name: something else
* 5 * * * /bin/true

# Another comment
      CRONTAB
    end

    it "should return nil if the user has no crontab" do
      @status = double("Status", exitstatus: 1, stdout: "")
      allow(@provider).to receive(:shell_out!).and_return(@status)
      expect(@provider.send(:read_crontab)).to eq(nil)
    end

    it "should raise an exception if another error occurs" do
      @status = double("Status", exitstatus: 2)
      allow(@provider).to receive(:shell_out!).and_raise(Mixlib::ShellOut::ShellCommandFailed)
      expect { @provider.send(:read_crontab) }.to raise_error(Chef::Exceptions::Cron)
    end
  end

  describe "write_crontab" do
    before :each do
      @status = double("Status", exitstatus: 0)
      allow(@provider).to receive(:shell_out!).and_return(@status)
    end

    it "should call crontab for the user" do
      expect(@provider).to receive(:shell_out!).with("crontab -u #{@new_resource.user} -", input: "Foo").and_return(@status)
      @provider.send(:write_crontab, "Foo")
    end

    it "should raise an exception if the command returns non-zero" do
      @status = double("Status", exitstatus: 1)
      allow(@provider).to receive(:shell_out!).and_raise(Mixlib::ShellOut::ShellCommandFailed)
      expect do
        @provider.send(:write_crontab, "Foo")
      end.to raise_error(Chef::Exceptions::Cron)
    end
  end

  describe "weekday_in_crontab" do
    context "when weekday is symbol" do
      it "should return weekday in crontab format" do
        @new_resource.weekday :wednesday
        expect(@provider.send(:weekday_in_crontab)).to eq("3")
      end

      it "should raise an error with an unknown weekday" do
        expect { @new_resource.weekday :caturday }.to raise_error(RangeError)
      end
    end

    context "when weekday is a number in a string" do
      it "should return the string" do
        @new_resource.weekday "3"
        expect(@provider.send(:weekday_in_crontab)).to eq("3")
      end

      it "should raise an error with an out of range number" do
        expect { @new_resource.weekday "-1" }.to raise_error(RangeError)
      end
    end

    context "when weekday is string with the name of the week" do
      it "should return the string" do
        @new_resource.weekday "mon"
        expect(@provider.send(:weekday_in_crontab)).to eq("mon")
      end
    end

    context "when weekday is an integer" do
      it "should return the integer" do
        @new_resource.weekday 1
        expect(@provider.send(:weekday_in_crontab)).to eq("1")
      end

      it "should raise an error with an out of range integer" do
        expect { @new_resource.weekday 45 }.to raise_error(RangeError)
      end
    end
  end
end
