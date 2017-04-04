#
# Author:: Nimisha Sharad (<nimisha.sharad@msystechnologies.com>)
# Copyright:: Copyright 2008-2016, Chef Software, Inc.
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

describe Chef::Provider::WindowsTask do
  let(:new_resource) { Chef::Resource::WindowsTask.new("sample_task") }

  let(:provider) do
    node = Chef::Node.new
    events = Chef::EventDispatch::Dispatcher.new
    run_context = Chef::RunContext.new(node, {}, events)
    Chef::Provider::WindowsTask.new(new_resource, run_context)
  end

  let(:task_hash) do
    {
      :"" => "",
      :Folder => "\\",
      :HostName => "NIMISHA-PC",
      :TaskName => "\\sample_task",
      :NextRunTime => "3/30/2017 2:42:00 PM",
      :Status => "Ready",
      :LogonMode => "Interactive/Background",
      :LastRunTime => "3/30/2017 2:27:00 PM",
      :LastResult => "1",
      :Author => "Administrator",
      :TaskToRun => "chef-client",
      :StartIn => "N/A",
      :Comment => "N/A",
      :ScheduledTaskState => "Enabled",
      :IdleTime => "Disabled",
      :PowerManagement => "Stop On Battery Mode, No Start On Batteries",
      :RunAsUser => "SYSTEM",
      :DeleteTaskIfNotRescheduled => "Enabled",
      :StopTaskIfRunsXHoursandXMins => "72:00:00",
      :Schedule => "Scheduling data is not available in this format.",
      :ScheduleType => "One Time Only, Minute",
      :StartTime => "1:12:00 PM",
      :StartDate => "3/30/2017",
      :EndDate => "N/A",
      :Days => "N/A",
      :Months => "N/A",
      :"Repeat:Every" => "0 Hour(s), 15 Minute(s)",
      :"Repeat:Until:Time" => "None",
      :"Repeat:Until:Duration" => "Disabled",
      :"Repeat:StopIfStillRunning" => "Disabled",
      :run_level => "HighestAvailable",
      :repetition_interval => "PT15M",
      :execution_time_limit => "PT72H",
    }
  end

  let(:task_xml) do
    "<?xml version=\"1.0\" encoding=\"UTF-16\"?>\r\r\n<Task version=\"1.2\" xmlns=\"http://schemas.microsoft.com/windows/2004/02/mit/task\">\r\r\n  <RegistrationInfo>\r\r\n    <Date>2017-03-31T15:34:44</Date>\r\r\n    <Author>Administrator</Author>\r\r\n  </RegistrationInfo>\r\r\n<Triggers>\r\r\n    <TimeTrigger>\r\r\n      <Repetition>\r\r\n        <Interval>PT15M</Interval>\r\r\n        <StopAtDurationEnd>false</StopAtDurationEnd>\r\r\n      </Repetition>\r\r\n      <StartBoundary>2017-03-31T15:34:00</StartBoundary>\r\r\n      <Enabled>true</Enabled>\r\r\n    </TimeTrigger>\r\r\n  </Triggers>\r\r\n  <Principals>\r\r\n    <Principal id=\"Author\">\r\r\n      <RunLevel>HighestAvailable</RunLevel>\r\r\n      <UserId>S-1-5-18</UserId>\r\r\n    </Principal>\r\r\n  </Principals>\r\r\n  <Settings>\r\r\n    <MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy>\r\r\n    <DisallowStartIfOnBatteries>true</DisallowStartIfOnBatteries>\r\r\n    <StopIfGoingOnBatteries>true</StopIfGoingOnBatteries>\r\r\n    <AllowHardTerminate>true</AllowHardTerminate>\r\r\n    <StartWhenAvailable>false</StartWhenAvailable>\r\r\n    <RunOnlyIfNetworkAvailable>false</RunOnlyIfNetworkAvailable>\r\r\n    <IdleSettings>\r\r\n      <Duration>PT10M</Duration>\r\r\n<WaitTimeout>PT1H</WaitTimeout>\r\r\n      <StopOnIdleEnd>true</StopOnIdleEnd>\r\r\n      <RestartOnIdle>false</RestartOnIdle>\r\r\n    </IdleSettings>\r\r\n    <AllowStartOnDemand>true</AllowStartOnDemand>\r\r\n    <Enabled>true</Enabled>\r\r\n    <Hidden>false</Hidden>\r\r\n<RunOnlyIfIdle>false</RunOnlyIfIdle>\r\r\n    <WakeToRun>false</WakeToRun>\r\r\n    <ExecutionTimeLimit>PT72H</ExecutionTimeLimit>\r\r\n<Priority>7</Priority>\r\r\n  </Settings>\r\r\n  <Actions Context=\"Author\">\r\r\n    <Exec>\r\r\n      <Command>chef-client</Command>\r\r\n    </Exec>\r\r\n  </Actions>\r\r\n</Task>"
  end

  describe "#load_current_resource" do
    it "returns a current_resource" do
      allow(provider).to receive(:load_task_hash)
      expect(provider.load_current_resource).to be_kind_of(Chef::Resource::WindowsTask)
    end

    context "if the given task name already exists" do
      before do
        allow(provider).to receive(:load_task_hash).and_return({ :TaskName => "\\sample_task" })
      end

      it "calls set_current_resource" do
        expect(provider).to receive(:set_current_resource)
        provider.load_current_resource
      end
    end

    it "sets the attributes of current_resource" do
      allow(provider).to receive(:load_task_hash).and_return(task_hash)
      current_resource = provider.load_current_resource
      expect(current_resource.exists).to be(true)
      expect(current_resource.command).to eq("chef-client")
      expect(current_resource.user).to eq("SYSTEM")
      expect(current_resource.run_level).to eq(:highest)
      expect(current_resource.frequency).to eq(:minute)
      expect(current_resource.frequency_modifier).to eq(15)
      expect(current_resource.execution_time_limit).to eq("PT72H")
      expect(current_resource.enabled).to be(true)
    end
  end

  describe "#action_create" do
    it "doesn't create the same task if it's already existing" do
      allow(provider).to receive(:load_task_hash).and_return(task_hash)
      provider.load_current_resource
      allow(provider).to receive(:task_need_update?).and_return(false)
      provider.run_action(:create)
      expect(new_resource).not_to be_updated_by_last_action
    end

    context "when task is not existing" do
      before do
        allow(provider).to receive(:load_task_hash)
        provider.load_current_resource
      end

      it "creates the task if it's not already existing" do
        allow(provider).to receive(:task_need_update?).and_return(true)
        expect(provider).to receive(:run_schtasks).with("CREATE", { "F" => "", "SC" => :hourly, "MO" => 1, "TR" => nil, "RU" => "SYSTEM" })
        provider.run_action(:create)
        expect(new_resource).to be_updated_by_last_action
      end

      it "updates the task XML if random_delay is provided" do
        new_resource.random_delay "20"
        allow(provider).to receive(:task_need_update?).and_return(true)
        expect(provider).to receive(:run_schtasks).with("CREATE", { "F" => "", "SC" => :hourly, "MO" => 1, "TR" => nil, "RU" => "SYSTEM" })
        expect(provider).to receive(:update_task_xml)
        provider.run_action(:create)
        expect(new_resource).to be_updated_by_last_action
      end

      it "updates the task XML if execution_time_limit is provided" do
        new_resource.execution_time_limit "20"
        allow(provider).to receive(:task_need_update?).and_return(true)
        expect(provider).to receive(:run_schtasks).with("CREATE", { "F" => "", "SC" => :hourly, "MO" => 1, "TR" => nil, "RU" => "SYSTEM" })
        expect(provider).to receive(:update_task_xml)
        provider.run_action(:create)
        expect(new_resource).to be_updated_by_last_action
      end
    end
  end

  describe "#action_run" do
    it "does nothing if the task doesn't exist" do
      allow(provider).to receive(:load_task_hash)
      provider.load_current_resource
      provider.run_action(:run)
      expect(new_resource).not_to be_updated_by_last_action
    end

    context "when the task exists" do
      it "does nothing if the task is already running" do
        task_hash[:Status] = "Running"
        allow(provider).to receive(:load_task_hash).and_return(task_hash)
        provider.load_current_resource
        provider.run_action(:run)
        expect(new_resource).not_to be_updated_by_last_action
      end

      it "runs the task" do
        allow(provider).to receive(:load_task_hash).and_return(task_hash)
        provider.load_current_resource
        expect(provider).to receive(:run_schtasks).with("RUN")
        provider.run_action(:run)
        expect(new_resource).to be_updated_by_last_action
      end
    end
  end

  describe "#action_delete" do
    it "deletes the task if it exists" do
      allow(provider).to receive(:load_task_hash).and_return(task_hash)
      provider.load_current_resource
      expect(provider).to receive(:run_schtasks).with("DELETE", { "F" => "" })
      provider.run_action(:delete)
      expect(new_resource).to be_updated_by_last_action
    end

    it "does nothing if the task doesn't exist" do
      allow(provider).to receive(:load_task_hash)
      provider.load_current_resource
      provider.run_action(:delete)
      expect(new_resource).not_to be_updated_by_last_action
    end
  end

  describe "#action_end" do
    it "does nothing if the task doesn't exist" do
      allow(provider).to receive(:load_task_hash)
      provider.load_current_resource
      provider.run_action(:end)
      expect(new_resource).not_to be_updated_by_last_action
    end

    context "when the task exists" do
      it "does nothing if the task is not running" do
        allow(provider).to receive(:load_task_hash).and_return(task_hash)
        provider.load_current_resource
        provider.run_action(:end)
        expect(new_resource).not_to be_updated_by_last_action
      end

      it "ends the task if it's running" do
        task_hash[:Status] = "Running"
        allow(provider).to receive(:load_task_hash).and_return(task_hash)
        provider.load_current_resource
        expect(provider).to receive(:run_schtasks).with("END")
        provider.run_action(:end)
        expect(new_resource).to be_updated_by_last_action
      end
    end
  end

  describe "#action_enable" do
    it "raises error if the task doesn't exist" do
      allow(provider).to receive(:load_task_hash)
      provider.load_current_resource
      expect { provider.run_action(:enable) }.to raise_error(Errno::ENOENT)
    end

    context "when the task exists" do
      it "does nothing if the task is already enabled" do
        allow(provider).to receive(:load_task_hash).and_return(task_hash)
        provider.load_current_resource
        provider.run_action(:enable)
        expect(new_resource).not_to be_updated_by_last_action
      end

      it "enables the task if it exists" do
        task_hash[:ScheduledTaskState] = "Disabled"
        allow(provider).to receive(:load_task_hash).and_return(task_hash)
        provider.load_current_resource
        expect(provider).to receive(:run_schtasks).with("CHANGE", { "ENABLE" => "" })
        provider.run_action(:enable)
        expect(new_resource).to be_updated_by_last_action
      end
    end
  end

  describe "#action_disable" do
    it "does nothing if the task doesn't exist" do
      allow(provider).to receive(:load_task_hash)
      provider.load_current_resource
      provider.run_action(:disable)
      expect(new_resource).not_to be_updated_by_last_action
    end

    context "when the task exists" do
      it "disables the task if it's enabled" do
        allow(provider).to receive(:load_task_hash).and_return(task_hash)
        provider.load_current_resource
        expect(provider).to receive(:run_schtasks).with("CHANGE", { "DISABLE" => "" })
        provider.run_action(:disable)
        expect(new_resource).to be_updated_by_last_action
      end

      it "does nothing if the task is already disabled" do
        task_hash[:ScheduledTaskState] = "Disabled"
        allow(provider).to receive(:load_task_hash).and_return(task_hash)
        provider.load_current_resource
        provider.run_action(:disable)
        expect(new_resource).not_to be_updated_by_last_action
      end
    end
  end

  describe "#run_schtasks" do
    before do
      @task_action = "CREATE"
      @options = { "F" => "", "SC" => :minute, "MO" => 15, "TR" => "chef-client", "RU" => "SYSTEM", "RL" => "HIGHEST" }
      @cmd = "schtasks /CREATE /TN \"sample_task\" /F /SC \"minute\" /MO \"15\" /TR \"chef-client\" /RU \"SYSTEM\" /RL \"HIGHEST\" "
    end

    it "forms the command properly from the given options" do
      expect(provider).to receive(:shell_out!).with(@cmd, { :returns => [0] })
      provider.send(:run_schtasks, @task_action, @options)
    end
  end

  describe "#task_need_update?" do
    context "when task doesn't exist" do
      before do
        allow(provider).to receive(:load_task_hash)
        provider.load_current_resource
      end

      it "returns true" do
        new_resource.command "chef-client"
        expect(provider.send(:task_need_update?)).to be(true)
      end
    end

    context "when the task exists" do
      before do
        allow(provider).to receive(:load_task_hash).and_return(task_hash)
        provider.load_current_resource

        new_resource.command "chef-client"
        new_resource.run_level :highest
        new_resource.frequency :minute
        new_resource.frequency_modifier 15
        new_resource.user "SYSTEM"
        new_resource.execution_time_limit "PT72H"
      end

      context "when no attributes are modified" do
        it "returns false" do
          expect(provider.send(:task_need_update?)).to be(false)
        end
      end

      context "when frequency_modifier is updated" do
        it "returns true" do
          new_resource.frequency_modifier 25
          expect(provider.send(:task_need_update?)).to be(true)
        end
      end

      context "when months are updated" do
        it "returns true" do
          new_resource.months "JAN"
          expect(provider.send(:task_need_update?)).to be(true)
        end
      end
    end
  end

  describe "#update_task_xml" do
    before do
      new_resource.command "chef-client"
      new_resource.run_level :highest
      new_resource.frequency :minute
      new_resource.frequency_modifier 15
      new_resource.user "SYSTEM"
      new_resource.random_delay "20"
    end

    it "does nothing if the task doesn't exist" do
      task_xml = double("xml", :exitstatus => 1)
      allow(provider).to receive(:powershell_out).and_return(task_xml)
      output = provider.send(:update_task_xml, ["random_delay"])
      expect(output).to be(nil)
    end

    it "updates the task XML if random_delay is passed" do
      shell_out_obj = double("xml", :exitstatus => 0, :stdout => task_xml)
      allow(provider).to receive(:powershell_out).and_return(shell_out_obj)
      expect(::File).to receive(:join)
      expect(::File).to receive(:open)
      expect(::File).to receive(:delete)
      expect(provider).to receive(:run_schtasks).twice
      output = provider.send(:update_task_xml, ["random_delay"])
    end
  end

  describe "#load_task_hash" do
    it "returns false if the task doesn't exist" do
      allow(provider).to receive_message_chain(:powershell_out, :stdout, :force_encoding).and_return("")
      allow(provider).to receive(:load_task_xml)
      expect(provider.send(:load_task_hash, "chef-client")).to be(false)
    end

    it "returns task hash if the task exists" do
      powershell_output = "\r\nFolder: \\\r\nHostName:                             NIMISHA-PC\r\nTaskName:                             \\chef-client\r\n"
      task_h = { :"" => "", :Folder => "\\", :HostName => "NIMISHA-PC", :TaskName => "\\chef-client" }
      allow(provider).to receive_message_chain(:powershell_out, :stdout, :force_encoding).and_return(powershell_output)
      allow(provider).to receive(:load_task_xml).with("chef-client")
      expect(provider.send(:load_task_hash, "chef-client")).to eq(task_h)
    end
  end

  describe "#frequency_modifier_allowed" do
    it "returns true for frequency :hourly" do
      new_resource.frequency :hourly
      expect(provider.send(:frequency_modifier_allowed)).to be(true)
    end

    it "returns true for frequency :monthly if frequency_modifier is THIRD" do
      new_resource.frequency :monthly
      new_resource.frequency_modifier "THIRD"
      expect(provider.send(:frequency_modifier_allowed)).to be(true)
    end

    it "returns false for frequency :once" do
      new_resource.frequency :once
      expect(provider.send(:frequency_modifier_allowed)).to be(false)
    end
  end
end
