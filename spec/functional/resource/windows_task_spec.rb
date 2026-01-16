#
# Author:: Nimisha Sharad (<nimisha.sharad@msystechnologies.com>)
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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
require "chef-utils/dist"

describe Chef::Resource::WindowsTask, :windows_only do
  # resource.task.application_name will default to task_name unless resource.command is set
  let(:task_name) { "chef-client-functional-test" }
  let(:new_resource) { Chef::Resource::WindowsTask.new(task_name, run_context) }
  let(:windows_task_provider) do
    new_resource.provider_for_action(:create)
  end

  let(:run_context) do
    Chef::RunContext.new(Chef::Node.new, {}, Chef::EventDispatch::Dispatcher.new)
  end

  describe "action :create" do
    after { delete_task }
    context "when command is with arguments" do
      subject do
        new_resource = Chef::Resource::WindowsTask.new(task_name, run_context)
        new_resource.execution_time_limit = 259200 / 60 # converting "PT72H" into minutes and passing here since win32-taskscheduler accepts this
        # Make sure MM/DD/YYYY is accepted

        new_resource.start_day "09/20/2017"
        new_resource.frequency :hourly
        new_resource
      end

      context "With Arguments" do
        it "creates scheduled task and sets command arguments" do
          subject.command "#{ChefUtils::Dist::Infra::CLIENT} -W"
          call_for_create_action
          # loading current resource again to check new task is creted and it matches task parameters
          current_resource = call_for_load_current_resource
          expect(current_resource.exists).to eq(true)
          expect(current_resource.task.application_name).to eq(ChefUtils::Dist::Infra::CLIENT)
          expect(current_resource.task.parameters).to eq("-W")
        end

        it "does not converge the resource if it is already converged" do
          subject.command "#{ChefUtils::Dist::Infra::CLIENT} -W"
          subject.run_action(:create)
          subject.command "#{ChefUtils::Dist::Infra::CLIENT} -W"
          subject.run_action(:create)
          expect(subject).not_to be_updated_by_last_action
        end

        it "creates scheduled task and sets command arguments when arguments inclusive single quotes" do
          subject.command "#{ChefUtils::Dist::Infra::CLIENT} -W -L 'C:\\chef\\chef-ad-join.log'"
          call_for_create_action
          # loading current resource again to check new task is creted and it matches task parameters
          current_resource = call_for_load_current_resource
          expect(current_resource.exists).to eq(true)
          expect(current_resource.task.application_name).to eq(ChefUtils::Dist::Infra::CLIENT)
          expect(current_resource.task.parameters).to eq("-W -L 'C:\\chef\\chef-ad-join.log'")
        end

        it "does not converge the resource if it is already converged" do
          subject.command "#{ChefUtils::Dist::Infra::CLIENT} -W -L 'C:\\chef\\chef-ad-join.log'"
          subject.run_action(:create)
          subject.command "#{ChefUtils::Dist::Infra::CLIENT} -W -L 'C:\\chef\\chef-ad-join.log'"
          subject.run_action(:create)
          expect(subject).not_to be_updated_by_last_action
        end

        it "creates scheduled task and sets command arguments with spaces in command" do
          subject.command '"C:\\Program Files\\example\\program.exe" -arg1 --arg2'
          call_for_create_action
          current_resource = call_for_load_current_resource
          expect(current_resource.exists).to eq(true)
          expect(current_resource.task.application_name).to eq('"C:\\Program Files\\example\\program.exe"')
          expect(current_resource.task.parameters).to eq("-arg1 --arg2")
        end

        it "does not converge the resource if it is already converged" do
          subject.command '"C:\\Program Files\\example\\program.exe" -arg1 --arg2'
          subject.run_action(:create)
          subject.command '"C:\\Program Files\\example\\program.exe" -arg1 --arg2'
          subject.run_action(:create)
          expect(subject).not_to be_updated_by_last_action
        end

        it "creates scheduled task and sets command arguments with spaces in arguments" do
          subject.command 'powershell.exe -file "C:\\Program Files\\app\\script.ps1"'
          call_for_create_action
          current_resource = call_for_load_current_resource
          expect(current_resource.exists).to eq(true)
          expect(current_resource.task.application_name).to eq("powershell.exe")
          expect(current_resource.task.parameters).to eq('-file "C:\\Program Files\\app\\script.ps1"')
        end

        it "does not converge the resource if it is already converged" do
          subject.command 'powershell.exe -file "C:\\Program Files\\app\\script.ps1"'
          subject.run_action(:create)
          subject.command 'powershell.exe -file "C:\\Program Files\\app\\script.ps1"'
          subject.run_action(:create)
          expect(subject).not_to be_updated_by_last_action
        end

        it "creates scheduled task and sets command arguments" do
          subject.command "ping http://www.google.com"
          call_for_create_action
          # loading current resource again to check new task is creted and it matches task parameters
          current_resource = call_for_load_current_resource
          expect(current_resource.exists).to eq(true)
          expect(current_resource.task.application_name).to eq("ping")
          expect(current_resource.task.parameters).to eq("http://www.google.com")
        end

        it "does not converge the resource if it is already converged" do
          subject.command "ping http://www.google.com"
          subject.run_action(:create)
          subject.command "ping http://www.google.com"
          subject.run_action(:create)
          expect(subject).not_to be_updated_by_last_action
        end
      end

      context "Without Arguments" do
        it "creates scheduled task and sets command arguments" do
          subject.command ChefUtils::Dist::Infra::CLIENT
          call_for_create_action
          # loading current resource again to check new task is creted and it matches task parameters
          current_resource = call_for_load_current_resource
          expect(current_resource.exists).to eq(true)
          expect(current_resource.task.application_name).to eq(ChefUtils::Dist::Infra::CLIENT)
          expect(current_resource.task.parameters).to be_empty
        end

        it "does not converge the resource if it is already converged" do
          subject.command ChefUtils::Dist::Infra::CLIENT
          subject.run_action(:create)
          subject.command ChefUtils::Dist::Infra::CLIENT
          subject.run_action(:create)
          expect(subject).not_to be_updated_by_last_action
        end
      end

      it "creates scheduled task and Re-sets command arguments" do
        subject.command 'powershell.exe -file "C:\\Program Files\\app\\script.ps1"'
        subject.run_action(:create)
        current_resource = call_for_load_current_resource
        expect(current_resource.task.application_name).to eq("powershell.exe")
        expect(current_resource.task.parameters).to eq('-file "C:\\Program Files\\app\\script.ps1"')

        subject.command "powershell.exe"
        subject.run_action(:create)
        current_resource = call_for_load_current_resource
        expect(current_resource.task.application_name).to eq("powershell.exe")
        expect(current_resource.task.parameters).to be_empty
        expect(subject).to be_updated_by_last_action
      end
    end

    context "when description is passed" do
      subject do
        new_resource = Chef::Resource::WindowsTask.new(task_name, run_context)
        new_resource.execution_time_limit = 259200 / 60 # converting "PT72H" into minutes and passing here since win32-taskscheduler accepts this
        new_resource.command task_name
        # Make sure MM/DD/YYYY is accepted
        new_resource.start_day "09/20/2017"
        new_resource.frequency :hourly
        new_resource
      end

      let(:some_description) { "this is test description" }

      it "create the task and sets its description" do
        subject.description some_description
        call_for_create_action
        # loading current resource again to check new task is creted and it matches task parameters
        current_resource = call_for_load_current_resource
        expect(current_resource.exists).to eq(true)
        expect(current_resource.task.description).to eq(some_description)
      end

      it "does not converge the resource if it is already converged" do
        subject.description some_description
        subject.run_action(:create)
        subject.description some_description
        subject.run_action(:create)
        expect(subject).not_to be_updated_by_last_action
      end

      it "updates task with new description if task already exist" do
        subject.description some_description
        subject.run_action(:create)
        subject.description "test description"
        subject.run_action(:create)
        expect(subject).to be_updated_by_last_action
      end
    end

    context "when frequency_modifier are not passed" do
      subject do
        new_resource = Chef::Resource::WindowsTask.new(task_name, run_context)
        new_resource.command task_name
        new_resource.execution_time_limit = 259200 / 60 # converting "PT72H" into minutes and passing here since win32-taskscheduler accepts this
        # Make sure MM/DD/YYYY is accepted
        new_resource.start_day "09/20/2017"
        new_resource.frequency :hourly
        new_resource
      end

      it "creates a scheduled task to run every 1 hr starting on 09/20/2017" do
        call_for_create_action
        # loading current resource again to check new task is creted and it matches task parameters
        current_resource = call_for_load_current_resource
        expect(current_resource.exists).to eq(true)
        expect(current_resource.task.application_name).to eq(task_name)
        trigger_details = current_resource.task.trigger(0)
        expect(trigger_details[:start_year]).to eq("2017")
        expect(trigger_details[:start_month]).to eq("09")
        expect(trigger_details[:start_day]).to eq("20")
        expect(trigger_details[:minutes_interval]).to eq(60)
        expect(trigger_details[:trigger_type]).to eq(1)
      end

      it "does not converge the resource if it is already converged" do
        subject.run_action(:create)
        subject.run_action(:create)
        expect(subject).not_to be_updated_by_last_action
      end
    end

    context "frequency :minute" do
      subject do
        new_resource = Chef::Resource::WindowsTask.new(task_name, run_context)
        new_resource.command task_name
        new_resource.run_level :highest
        new_resource.frequency :minute
        new_resource.frequency_modifier 15
        new_resource.execution_time_limit = 259200 / 60 # converting "PT72H" into minutes and passing here since win32-taskscheduler accepts this
        new_resource
      end

      it "creates a scheduled task that runs after every 15 minutes" do
        call_for_create_action
        # loading current resource again to check new task is creted and it matches task parameters
        current_resource = call_for_load_current_resource
        expect(current_resource.exists).to eq(true)
        trigger_details = current_resource.task.trigger(0)
        expect(current_resource.task.application_name).to eq(task_name)
        expect(trigger_details[:minutes_interval]).to eq(15)
        expect(trigger_details[:trigger_type]).to eq(1)
        expect(current_resource.task.principals[:run_level]).to eq(1)
      end

      it "does not converge the resource if it is already converged" do
        subject.run_action(:create)
        subject.run_action(:create)
        expect(subject).not_to be_updated_by_last_action
      end

      it "updates a scheduled task when frequency_modifier updated to 20" do
        subject.run_action(:create)
        current_resource = call_for_load_current_resource
        trigger_details = current_resource.task.trigger(0)
        expect(trigger_details[:minutes_interval]).to eq(15)
        subject.frequency_modifier 20
        subject.run_action(:create)
        expect(subject).to be_updated_by_last_action
        # #loading current resource again to check new task is creted and it matches task parameters
        current_resource = call_for_load_current_resource
        expect(current_resource.exists).to eq(true)
        trigger_details = current_resource.task.trigger(0)
        expect(current_resource.task.application_name).to eq(task_name)
        expect(trigger_details[:minutes_interval]).to eq(20)
        expect(trigger_details[:trigger_type]).to eq(1)
        expect(current_resource.task.principals[:run_level]).to eq(1)
      end
    end

    context "frequency :hourly" do
      subject do
        new_resource = Chef::Resource::WindowsTask.new(task_name, run_context)
        new_resource.command task_name
        new_resource.run_level :highest
        new_resource.frequency :hourly
        new_resource.frequency_modifier 3
        new_resource.execution_time_limit = 259200 / 60 # converting "PT72H" into minutes and passing here since win32-taskscheduler accepts this
        new_resource
      end

      it "creates a scheduled task that runs after every 3 hrs" do
        call_for_create_action
        # loading current resource again to check new task is creted and it matches task parameters
        current_resource = call_for_load_current_resource
        expect(current_resource.exists).to eq(true)
        trigger_details = current_resource.task.trigger(0)
        expect(current_resource.task.application_name).to eq(task_name)
        expect(trigger_details[:minutes_interval]).to eq(180)
        expect(trigger_details[:trigger_type]).to eq(1)
      end

      it "does not converge the resource if it is already converged" do
        subject.run_action(:create)
        subject.run_action(:create)
        expect(subject).not_to be_updated_by_last_action
      end

      it "updates a scheduled task to run every 5 hrs when frequency modifier updated to 5" do
        subject.run_action(:create)
        current_resource = call_for_load_current_resource
        trigger_details = current_resource.task.trigger(0)
        expect(trigger_details[:minutes_interval]).to eq(180)
        # updating frequency modifier to 5 from 3
        subject.frequency_modifier 5
        subject.run_action(:create)
        expect(subject).to be_updated_by_last_action
        current_resource = call_for_load_current_resource
        expect(current_resource.exists).to eq(true)
        trigger_details = current_resource.task.trigger(0)
        expect(current_resource.task.application_name).to eq(task_name)
        expect(trigger_details[:minutes_interval]).to eq(300)
        expect(trigger_details[:trigger_type]).to eq(1)
      end
    end

    context "frequency :daily" do
      subject do
        new_resource = Chef::Resource::WindowsTask.new(task_name, run_context)
        new_resource.command task_name
        new_resource.run_level :highest
        new_resource.frequency :daily
        new_resource.execution_time_limit = 259200 / 60 # converting "PT72H" into minutes and passing here since win32-taskscheduler accepts this
        new_resource
      end

      it "creates a scheduled task to run daily" do
        call_for_create_action
        # loading current resource again to check new task is creted and it matches task parameters
        current_resource = call_for_load_current_resource
        expect(current_resource.exists).to eq(true)
        trigger_details = current_resource.task.trigger(0)
        expect(current_resource.task.application_name).to eq(task_name)
        expect(trigger_details[:trigger_type]).to eq(2)
        expect(current_resource.task.principals[:run_level]).to eq(1)
        expect(trigger_details[:type][:days_interval]).to eq(1)
      end

      it "does not converge the resource if it is already converged" do
        subject.run_action(:create)
        subject.run_action(:create)
        expect(subject).not_to be_updated_by_last_action
      end
    end

    describe "frequency :monthly" do
      subject do
        new_resource = Chef::Resource::WindowsTask.new(task_name, run_context)
        new_resource.command task_name
        new_resource.run_level :highest
        new_resource.frequency :monthly
        new_resource.execution_time_limit = 259200 / 60 # converting "PT72H" into minutes and passing here since win32-taskscheduler accepts this
        new_resource
      end

      context "with start_day and start_time" do
        before do
          subject.start_day "02/12/2018"
          subject.start_time "05:15"
        end

        it "if day property is not set creates a scheduled task to run monthly on first day of the month" do
          call_for_create_action
          # loading current resource again to check new task is creted and it matches task parameters
          current_resource = call_for_load_current_resource
          expect(current_resource.exists).to eq(true)
          trigger_details = current_resource.task.trigger(0)
          expect(current_resource.task.application_name).to eq(task_name)
          expect(trigger_details[:trigger_type]).to eq(4)
          expect(current_resource.task.principals[:run_level]).to eq(1)
          expect(trigger_details[:type][:days]).to eq(1)
          expect(trigger_details[:type][:months]).to eq(4095)
        end

        it "does not converge the resource if it is already converged" do
          subject.run_action(:create)
          subject.run_action(:create)
          expect(subject).not_to be_updated_by_last_action
        end

        it "creates a scheduled task to run monthly on first, second and third day of the month" do
          subject.day "1, 2, 3"
          call_for_create_action
          # loading current resource again to check new task is created and it matches task parameters
          current_resource = call_for_load_current_resource
          expect(current_resource.exists).to eq(true)
          trigger_details = current_resource.task.trigger(0)
          expect(current_resource.task.application_name).to eq(task_name)
          expect(trigger_details[:trigger_type]).to eq(4)
          expect(current_resource.task.principals[:run_level]).to eq(1)
          expect(trigger_details[:type][:days]).to eq(7)
          expect(trigger_details[:type][:months]).to eq(4095)
        end

        it "does not converge the resource if it is already converged" do
          subject.day "1, 2, 3"
          subject.run_action(:create)
          subject.run_action(:create)
          expect(subject).not_to be_updated_by_last_action
        end

        it "creates a scheduled task to run monthly on 1, 2, 3, 4, 8, 20, 21, 15, 28, 31 day of the month" do
          subject.day "1, 2, 3, 4, 8, 20, 21, 15, 28, 31"
          call_for_create_action
          # loading current resource again to check new task is created and it matches task parameters
          current_resource = call_for_load_current_resource
          expect(current_resource.exists).to eq(true)
          trigger_details = current_resource.task.trigger(0)
          expect(current_resource.task.application_name).to eq(task_name)
          expect(trigger_details[:trigger_type]).to eq(4)
          expect(current_resource.task.principals[:run_level]).to eq(1)
          expect(trigger_details[:type][:days]).to eq(1209548943) # TODO:: windows_task_provider.send(:days_of_month)
          expect(trigger_details[:type][:months]).to eq(4095) # windows_task_provider.send(:months_of_year)
        end

        it "does not converge the resource if it is already converged" do
          subject.day "1, 2, 3, 4, 8, 20, 21, 15, 28, 31"
          subject.run_action(:create)
          subject.run_action(:create)
          expect(subject).not_to be_updated_by_last_action
        end

        it "creates a scheduled task to run monthly on Jan, Feb, Apr, Dec on 1st 2nd 3rd 4th 8th and 20th day of these months" do
          subject.day "1, 2, 3, 4, 8, 20, 21, 30"
          subject.months "Jan, Feb, May, Sep, Dec"
          call_for_create_action
          # loading current resource again to check new task is created and it matches task parameters
          current_resource = call_for_load_current_resource
          expect(current_resource.exists).to eq(true)
          trigger_details = current_resource.task.trigger(0)
          expect(current_resource.task.application_name).to eq(task_name)
          expect(trigger_details[:trigger_type]).to eq(4)
          expect(current_resource.task.principals[:run_level]).to eq(1)
          expect(trigger_details[:type][:days]).to eq(538443919) # TODO:windows_task_provider.send(:days_of_month)
          expect(trigger_details[:type][:months]).to eq(2323) # windows_task_provider.send(:months_of_year)
        end

        it "does not converge the resource if it is already converged" do
          subject.day "1, 2, 3, 4, 8, 20, 21, 30"
          subject.months "Jan, Feb, May, Sep, Dec"
          subject.run_action(:create)
          subject.run_action(:create)
          expect(subject).not_to be_updated_by_last_action
        end

        it "creates a scheduled task to run monthly by giving day option with frequency_modifier" do
          subject.frequency_modifier "First"
          subject.day "Mon, Fri, Sun"
          call_for_create_action
          # loading current resource again to check new task is created and it matches task parameters
          current_resource = call_for_load_current_resource
          expect(current_resource.exists).to eq(true)
          trigger_details = current_resource.task.trigger(0)
          expect(current_resource.task.application_name).to eq(task_name)
          expect(trigger_details[:trigger_type]).to eq(5)
          expect(current_resource.task.principals[:run_level]).to eq(1)
          expect(trigger_details[:type][:days_of_week]).to eq(35)
          expect(trigger_details[:type][:weeks_of_month]).to eq(1)
          expect(trigger_details[:type][:months]).to eq(4095) # windows_task_provider.send(:months_of_year)
        end

        it "does not converge the resource if it is already converged" do
          subject.frequency_modifier "First"
          subject.day "Mon, Fri, Sun"
          subject.run_action(:create)
          subject.run_action(:create)
          expect(subject).not_to be_updated_by_last_action
        end
      end

      context "with frequency_modifier" do
        subject do
          new_resource = Chef::Resource::WindowsTask.new(task_name, run_context)
          new_resource.command task_name
          new_resource.run_level :highest
          new_resource.frequency :monthly
          new_resource.execution_time_limit = 259200 / 60 # converting "PT72H" into minutes and passing here since win32-taskscheduler accepts this
          new_resource
        end

        it "raises argument error if frequency_modifier is 'first, second' and day is not provided." do
          subject.frequency_modifier "first, second"
          expect { subject.after_created }.to raise_error("Please select day on which you want to run the task e.g. 'Mon, Tue'. Multiple values must be separated by comma.")
        end

        it "raises argument error if months is passed along with frequency_modifier" do
          subject.frequency_modifier 3
          subject.months "Jan, Mar"
          expect { subject.after_created }.to raise_error("For frequency :monthly either use property months or frequency_modifier to set months.")
        end

        it "not raises any Argument error if frequency_modifier set as 'first, second, third' and day is provided" do
          subject.frequency_modifier "first, second, third"
          subject.day "Mon, Fri"
          expect { subject.after_created }.not_to raise_error
        end

        it "not raises any Argument error if frequency_modifier 2 " do
          subject.frequency_modifier 2
          subject.day "Mon, Sun"
          expect { subject.after_created }.not_to raise_error
        end

        it "raises argument error if frequency_modifier > 12" do
          subject.frequency_modifier 13
          expect { subject.after_created }.to raise_error("frequency_modifier value 13 is invalid. Valid values for :monthly frequency are 1 - 12, 'FIRST', 'SECOND', 'THIRD', 'FOURTH', 'LAST'.")
        end

        it "raises argument error if frequency_modifier < 1" do
          subject.frequency_modifier 0
          expect { subject.after_created }.to raise_error("frequency_modifier value 0 is invalid. Valid values for :monthly frequency are 1 - 12, 'FIRST', 'SECOND', 'THIRD', 'FOURTH', 'LAST'.")
        end

        it "creates scheduled task to run task monthly on Monday and Friday of first, second and third week of month" do
          subject.frequency_modifier "first, second, third"
          subject.day "Mon, Fri"
          expect { subject.after_created }.not_to raise_error
          call_for_create_action
          current_resource = call_for_load_current_resource
          expect(current_resource.exists).to eq(true)
          trigger_details = current_resource.task.trigger(0)
          expect(current_resource.task.application_name).to eq(task_name)
          expect(trigger_details[:trigger_type]).to eq(5)
          expect(trigger_details[:type][:months]).to eq(4095)
          expect(trigger_details[:type][:weeks_of_month]).to eq(7)
          expect(trigger_details[:type][:days_of_week]).to eq(34)
        end

        it "does not converge the resource if it is already converged" do
          subject.frequency_modifier "first, second, third"
          subject.day "Mon, Fri"
          subject.run_action(:create)
          subject.run_action(:create)
          expect(subject).not_to be_updated_by_last_action
        end

        it "creates scheduled task to run task monthly on every 6 months when frequency_modifier is 6 and to run on 1st and 2nd day of month" do
          subject.frequency_modifier 6
          subject.day "1, 2"
          expect { subject.after_created }.not_to raise_error
          call_for_create_action
          current_resource = call_for_load_current_resource
          expect(current_resource.exists).to eq(true)
          trigger_details = current_resource.task.trigger(0)
          expect(current_resource.task.application_name).to eq(task_name)
          expect(trigger_details[:trigger_type]).to eq(4)
          expect(trigger_details[:type][:months]).to eq(2080)
          expect(trigger_details[:type][:days]).to eq(3)
        end

        it "does not converge the resource if it is already converged" do
          subject.frequency_modifier 6
          subject.day "1, 2"
          subject.run_action(:create)
          subject.run_action(:create)
          expect(subject).not_to be_updated_by_last_action
        end
      end

      context "when day is set as last or lastday for frequency :monthly" do
        subject do
          new_resource = Chef::Resource::WindowsTask.new(task_name, run_context)
          new_resource.command task_name
          new_resource.run_level :highest
          new_resource.frequency :monthly
          new_resource.execution_time_limit = 259200 / 60 # converting "PT72H" into minutes and passing here since win32-taskscheduler accepts this
          new_resource
        end

        it "creates scheduled task to run monthly to run last day of the month" do
          subject.day "last"
          expect { subject.after_created }.not_to raise_error
          call_for_create_action
          current_resource = call_for_load_current_resource
          expect(current_resource.exists).to eq(true)
          trigger_details = current_resource.task.trigger(0)
          expect(current_resource.task.application_name).to eq(task_name)
          expect(trigger_details[:trigger_type]).to eq(4)
          expect(trigger_details[:type][:months]).to eq(4095)
          expect(trigger_details[:type][:days]).to eq(0)
          expect(trigger_details[:run_on_last_day_of_month]).to eq(true)
        end

        it "does not converge the resource if it is already converged" do
          subject.day "last"
          subject.run_action(:create)
          subject.run_action(:create)
          expect(subject).not_to be_updated_by_last_action
        end

        it "day property set as 'lastday' creates scheduled task to run monthly to run last day of the month" do
          subject.day "lastday"
          expect { subject.after_created }.not_to raise_error
          call_for_create_action
          current_resource = call_for_load_current_resource
          expect(current_resource.exists).to eq(true)
          trigger_details = current_resource.task.trigger(0)
          expect(current_resource.task.application_name).to eq(task_name)
          expect(trigger_details[:trigger_type]).to eq(4)
          expect(trigger_details[:type][:months]).to eq(4095)
          expect(trigger_details[:type][:days]).to eq(0)
          expect(trigger_details[:run_on_last_day_of_month]).to eq(true)
        end

        it "does not converge the resource if it is already converged" do
          subject.day "lastday"
          subject.run_action(:create)
          subject.run_action(:create)
          expect(subject).not_to be_updated_by_last_action
        end
      end

      context "when frequency_modifier is set as last for frequency :monthly" do
        it "creates scheduled task to run monthly on last week of the month" do
          subject.frequency_modifier "last"
          subject.day "Mon, Fri"
          expect { subject.after_created }.not_to raise_error
          call_for_create_action
          current_resource = call_for_load_current_resource
          expect(current_resource.exists).to eq(true)
          trigger_details = current_resource.task.trigger(0)
          expect(current_resource.task.application_name).to eq(task_name)
          expect(trigger_details[:trigger_type]).to eq(5)
          expect(trigger_details[:type][:months]).to eq(4095)
          expect(trigger_details[:type][:days_of_week]).to eq(34)
          expect(trigger_details[:run_on_last_week_of_month]).to eq(true)
        end

        it "does not converge the resource if it is already converged" do
          subject.frequency_modifier "last"
          subject.day "Mon, Fri"
          subject.run_action(:create)
          subject.run_action(:create)
          expect(subject).not_to be_updated_by_last_action
        end
      end

      context "when wild card (*) set as months" do
        it "creates the scheduled task to run on 1st day of the all months" do
          subject.months "*"
          expect { subject.after_created }.not_to raise_error
          call_for_create_action
          current_resource = call_for_load_current_resource
          expect(current_resource.exists).to eq(true)
          trigger_details = current_resource.task.trigger(0)
          expect(current_resource.task.application_name).to eq(task_name)
          expect(trigger_details[:trigger_type]).to eq(4)
          expect(trigger_details[:type][:months]).to eq(4095)
          expect(trigger_details[:type][:days]).to eq(1)
        end

        it "does not converge the resource if it is already converged" do
          subject.months "*"
          subject.run_action(:create)
          subject.run_action(:create)
          expect(subject).not_to be_updated_by_last_action
        end
      end

      context "when wild card (*) set as day" do
        it "raises argument error" do
          subject.day "*"
          expect { subject.after_created }.to raise_error("day wild card (*) is only valid with frequency :weekly")
        end
      end

      context "Pass either start day or start time by passing day compulsory or only pass frequency_modifier" do
        subject do
          new_resource = Chef::Resource::WindowsTask.new(task_name, run_context)
          new_resource.command task_name
          new_resource.run_level :highest
          new_resource.frequency :monthly
          new_resource.execution_time_limit = 259200 / 60 # converting "PT72H" into minutes and passing here since win32-taskscheduler accepts this
          new_resource
        end

        it "creates a scheduled task to run monthly on second day of the month" do
          subject.day "2"
          subject.start_day "03/07/2018"
          call_for_create_action
          # loading current resource again to check new task is creted and it matches task parameters
          current_resource = call_for_load_current_resource
          expect(current_resource.exists).to eq(true)
          trigger_details = current_resource.task.trigger(0)
          expect(current_resource.task.application_name).to eq(task_name)
          expect(trigger_details[:trigger_type]).to eq(4)
          expect(current_resource.task.principals[:run_level]).to eq(1)
          expect(trigger_details[:type][:days]).to eq(2)
          expect(trigger_details[:type][:months]).to eq(4095)
        end

        it "does not converge the resource if it is already converged" do
          subject.day "2"
          subject.start_day "03/07/2018"
          subject.run_action(:create)
          subject.run_action(:create)
          expect(subject).not_to be_updated_by_last_action
        end

        it "creates a scheduled task to run monthly on first, second and third day of the month" do
          subject.day "1,2,3"
          call_for_create_action
          # loading current resource again to check new task is creted and it matches task parameters
          current_resource = call_for_load_current_resource
          expect(current_resource.exists).to eq(true)
          trigger_details = current_resource.task.trigger(0)
          expect(current_resource.task.application_name).to eq(task_name)
          expect(trigger_details[:trigger_type]).to eq(4)
          expect(current_resource.task.principals[:run_level]).to eq(1)
          expect(trigger_details[:type][:days]).to eq(7)
          expect(trigger_details[:type][:months]).to eq(4095)
        end

        it "does not converge the resource if it is already converged" do
          subject.day "1,2,3"
          subject.run_action(:create)
          subject.run_action(:create)
          expect(subject).not_to be_updated_by_last_action
        end

        it "creates a scheduled task to run monthly on each wednesday of the month" do
          subject.frequency_modifier "1"
          call_for_create_action
          # loading current resource again to check new task is creted and it matches task parameters
          current_resource = call_for_load_current_resource
          expect(current_resource.exists).to eq(true)
          trigger_details = current_resource.task.trigger(0)
          expect(current_resource.task.application_name).to eq(task_name)
          expect(trigger_details[:trigger_type]).to eq(4)
          expect(current_resource.task.principals[:run_level]).to eq(1)
          expect(trigger_details[:type][:days]).to eq(1)
          expect(trigger_details[:type][:months]).to eq(4095) # windows_task_provider.send(:months_of_year)
        end

        it "does not converge the resource if it is already converged" do
          subject.frequency_modifier "2"
          subject.run_action(:create)
          subject.run_action(:create)
          expect(subject).not_to be_updated_by_last_action
        end

        it "creates a scheduled task to run monthly on each wednesday of the month" do
          subject.frequency_modifier "2"
          subject.months = nil
          call_for_create_action
          # loading current resource again to check new task is creted and it matches task parameters
          current_resource = call_for_load_current_resource
          expect(current_resource.exists).to eq(true)
          trigger_details = current_resource.task.trigger(0)
          # loading current resource
          expect(current_resource.task.application_name).to eq(task_name)
          expect(trigger_details[:trigger_type]).to eq(4)
          expect(current_resource.task.principals[:run_level]).to eq(1)
          expect(trigger_details[:type][:days]).to eq(1)
          expect(trigger_details[:type][:months]).to eq(2730) # windows_task_provider.send(:months_of_year)
        end

        it "does not converge the resource if it is already converged" do
          subject.frequency_modifier "2"
          subject.months = nil
          subject.run_action(:create)
          subject.run_action(:create)
          expect(subject).not_to be_updated_by_last_action
        end
      end
    end

    ## ToDO: Add functional specs to handle frequency monthly with frequency modifier set as 1-12
    context "frequency :once" do
      subject do
        new_resource = Chef::Resource::WindowsTask.new(task_name, run_context)
        new_resource.command task_name
        new_resource.run_level :highest
        new_resource.frequency :once
        new_resource.execution_time_limit = 259200 / 60 # converting "PT72H" into minutes and passing here since win32-taskscheduler accepts this
        new_resource
      end

      context "when start_time is not provided" do
        it "raises argument error" do
          expect { subject.after_created }.to raise_error("`start_time` needs to be provided with `frequency :once`")
        end
      end

      context "when start_time is provided" do
        it "creates the scheduled task to run once at 5pm" do
          subject.start_time "17:00"
          call_for_create_action
          # loading current resource again to check new task is creted and it matches task parameters
          current_resource = call_for_load_current_resource
          expect(current_resource.exists).to eq(true)
          trigger_details = current_resource.task.trigger(0)
          expect(current_resource.task.application_name).to eq(task_name)
          expect(trigger_details[:trigger_type]).to eq(1)
          expect(current_resource.task.principals[:run_level]).to eq(1)
          expect("#{trigger_details[:start_hour]}:#{trigger_details[:start_minute]}" ).to eq(subject.start_time)
        end

        it "does not converge the resource if it is already converged" do
          subject.start_time "17:00"
          subject.run_action(:create)
          subject.run_action(:create)
          expect(subject).not_to be_updated_by_last_action
        end
      end
    end

    context "frequency :weekly" do
      subject do
        new_resource = Chef::Resource::WindowsTask.new(task_name, run_context)
        new_resource.command task_name
        new_resource.run_level :highest
        new_resource.frequency :weekly
        new_resource.execution_time_limit = 259200 / 60 # converting "PT72H" into minutes and passing here since win32-taskscheduler accepts this
        new_resource
      end

      it "creates the scheduled task to run weekly" do
        call_for_create_action
        # loading current resource again to check new task is creted and it matches task parameters
        current_resource = call_for_load_current_resource
        expect(current_resource.exists).to eq(true)
        trigger_details = current_resource.task.trigger(0)
        expect(current_resource.task.application_name).to eq(task_name)
        expect(current_resource.task.principals[:run_level]).to eq(1)
        expect(trigger_details[:trigger_type]).to eq(3)
        expect(trigger_details[:type][:weeks_interval]).to eq(1)
      end

      it "does not converge the resource if it is already converged" do
        subject.run_action(:create)
        subject.run_action(:create)
        expect(subject).not_to be_updated_by_last_action
      end

      context "when wild card (*) is set as day" do
        it "creates hte scheduled task for all days of week" do
          subject.day "*"
          call_for_create_action
          # loading current resource again to check new task is creted and it matches task parameters
          current_resource = call_for_load_current_resource
          expect(current_resource.exists).to eq(true)
          trigger_details = current_resource.task.trigger(0)
          expect(current_resource.task.application_name).to eq(task_name)
          expect(current_resource.task.principals[:run_level]).to eq(1)
          expect(trigger_details[:trigger_type]).to eq(3)
          expect(trigger_details[:type][:weeks_interval]).to eq(1)
          expect(trigger_details[:type][:days_of_week]).to eq(127)
        end

        it "does not converge the resource if it is already converged" do
          subject.day "*"
          subject.run_action(:create)
          subject.run_action(:create)
          expect(subject).not_to be_updated_by_last_action
        end
      end

      context "when days are provided" do
        it "creates the scheduled task to run on particular days" do
          subject.day "Mon, Fri"
          subject.frequency_modifier 2
          call_for_create_action
          # loading current resource again to check new task is creted and it matches task parameters
          current_resource = call_for_load_current_resource
          expect(current_resource.exists).to eq(true)
          trigger_details = current_resource.task.trigger(0)
          expect(current_resource.task.application_name).to eq(task_name)
          expect(current_resource.task.principals[:run_level]).to eq(1)
          expect(trigger_details[:trigger_type]).to eq(3)
          expect(trigger_details[:type][:weeks_interval]).to eq(2)
          expect(trigger_details[:type][:days_of_week]).to eq(34)
        end

        it "updates the scheduled task to run on if frequency_modifier is updated" do
          subject.day "sun"
          subject.frequency_modifier 2
          subject.run_action(:create)
          current_resource = call_for_load_current_resource
          trigger_details = current_resource.task.trigger(0)
          expect(trigger_details[:type][:weeks_interval]).to eq(2)
          expect(trigger_details[:type][:days_of_week]).to eq(1)
          subject.day "Mon, Sun"
          subject.frequency_modifier 3
          # call for update
          subject.run_action(:create)
          expect(subject).to be_updated_by_last_action
          current_resource = call_for_load_current_resource
          expect(current_resource.exists).to eq(true)
          trigger_details = current_resource.task.trigger(0)
          expect(current_resource.task.application_name).to eq(task_name)
          expect(current_resource.task.principals[:run_level]).to eq(1)
          expect(trigger_details[:trigger_type]).to eq(3)
          expect(trigger_details[:type][:weeks_interval]).to eq(3)
          expect(trigger_details[:type][:days_of_week]).to eq(3)
        end

        it "does not converge the resource if it is already converged" do
          subject.day "Mon, Fri"
          subject.frequency_modifier 3
          subject.run_action(:create)
          subject.run_action(:create)
          expect(subject).not_to be_updated_by_last_action
        end
      end

      context "when day property set as last" do
        it "raises argument error" do
          subject.day "last"
          expect { subject.after_created }.to raise_error("day values 1-31 or last is only valid with frequency :monthly")
        end
      end

      context "when invalid day is passed" do
        it "raises error" do
          subject.day "abc"
          expect { subject.after_created }.to raise_error("day property invalid. Only valid values are: MON, TUE, WED, THU, FRI, SAT, SUN, *. Multiple values must be separated by a comma.")
        end
      end

      context "when months are passed" do
        it "raises error that months are supported only when frequency=:monthly" do
          subject.months "Jan"
          expect { subject.after_created }.to raise_error("months property is only valid for tasks that run monthly")
        end
      end

      context "when start_day is not set" do
        it "does not converge the resource if it is already converged" do
          subject.run_action(:create)
          subject.run_action(:create)
          expect(subject).not_to be_updated_by_last_action
        end

        it "updates the day if start_day is not provided and user updates day property" do
          skip "Unable to run this test case since start_day is current system date which can be different each time so can't verify the dynamic values"
          subject.run_action(:create)
          current_resource = call_for_load_current_resource
          expect(current_resource.exists).to eq(true)
          trigger_details = current_resource.task.trigger(0)
          expect(trigger_details[:type][:days_of_week]).to eq(8)
          subject.day "Sat"
          subject.run_action(:create)
          # #loading current resource again to check new task is creted and it matches task parameters
          current_resource = call_for_load_current_resource
          expect(current_resource.exists).to eq(true)
          trigger_details = current_resource.task.trigger(0)
          expect(current_resource.task.application_name).to eq(task_name)
          expect(current_resource.task.principals[:run_level]).to eq(1)
          expect(trigger_details[:trigger_type]).to eq(3)
          expect(trigger_details[:type][:weeks_interval]).to eq(1)
          expect(trigger_details[:type][:days_of_week]).to eq(64)
        end
      end
    end

    context "frequency :onstart" do
      subject do
        new_resource = Chef::Resource::WindowsTask.new(task_name, run_context)
        new_resource.command task_name
        new_resource.run_level :highest
        new_resource.frequency :onstart
        new_resource.execution_time_limit = 259200 / 60 # converting "PT72H" into minutes and passing here since win32-taskscheduler accepts this
        new_resource
      end

      it "creates the scheduled task to run at system start up" do
        call_for_create_action
        # loading current resource again to check new task is creted and it matches task parameters
        current_resource = call_for_load_current_resource
        expect(current_resource.exists).to eq(true)
        trigger_details = current_resource.task.trigger(0)
        expect(current_resource.task.application_name).to eq(task_name)
        expect(current_resource.task.principals[:run_level]).to eq(1)
        expect(trigger_details[:trigger_type]).to eq(8)
      end

      it "does not converge the resource if it is already converged" do
        subject.run_action(:create)
        subject.run_action(:create)
        expect(subject).not_to be_updated_by_last_action
      end

      context "when start_day and start_time is set" do
        it "creates task to activate on '09/10/2018' at '15:00' when start_day = '09/10/2018' and start_time = '15:00' provided" do
          subject.start_day "09/10/2018"
          subject.start_time "15:00"
          call_for_create_action
          # loading current resource again to check new task is creted and it matches task parameters
          current_resource = call_for_load_current_resource
          expect(current_resource.exists).to eq(true)
          trigger_details = current_resource.task.trigger(0)
          expect(current_resource.task.application_name).to eq(task_name)
          expect(trigger_details[:trigger_type]).to eq(8)
          expect(trigger_details[:start_year]).to eq("2018")
          expect(trigger_details[:start_month]).to eq("09")
          expect(trigger_details[:start_day]).to eq("10")
          expect(trigger_details[:start_hour]).to eq("15")
          expect(trigger_details[:start_minute]).to eq("00")
        end
      end
    end

    context "frequency :on_logon" do
      subject do
        new_resource = Chef::Resource::WindowsTask.new(task_name, run_context)
        new_resource.command task_name
        new_resource.run_level :highest
        new_resource.frequency :on_logon
        new_resource.execution_time_limit = 259200 / 60 # converting "PT72H" into minutes and passing here since win32-taskscheduler accepts this
        new_resource
      end

      it "creates the scheduled task to on logon" do
        call_for_create_action
        # loading current resource again to check new task is creted and it matches task parameters
        current_resource = call_for_load_current_resource
        expect(current_resource.exists).to eq(true)
        trigger_details = current_resource.task.trigger(0)
        expect(current_resource.task.application_name).to eq(task_name)
        expect(current_resource.task.principals[:run_level]).to eq(1)
        expect(trigger_details[:trigger_type]).to eq(9)
      end

      it "does not converge the resource if it is already converged" do
        subject.run_action(:create)
        subject.run_action(:create)
        expect(subject).not_to be_updated_by_last_action
      end

      context "when start_day and start_time is set" do
        it "creates task to activate on '09/10/2018' at '15:00' when start_day = '09/10/2018' and start_time = '15:00' provided" do
          subject.start_day "09/10/2018"
          subject.start_time "15:00"
          call_for_create_action
          # loading current resource again to check new task is creted and it matches task parameters
          current_resource = call_for_load_current_resource
          expect(current_resource.exists).to eq(true)
          trigger_details = current_resource.task.trigger(0)
          expect(current_resource.task.application_name).to eq(task_name)
          expect(trigger_details[:trigger_type]).to eq(9)
          expect(trigger_details[:start_year]).to eq("2018")
          expect(trigger_details[:start_month]).to eq("09")
          expect(trigger_details[:start_day]).to eq("10")
          expect(trigger_details[:start_hour]).to eq("15")
          expect(trigger_details[:start_minute]).to eq("00")
        end
      end
    end

    context "frequency :on_idle" do
      subject do
        new_resource = Chef::Resource::WindowsTask.new(task_name, run_context)
        new_resource.command task_name
        new_resource.run_level :highest
        new_resource.frequency :on_idle
        new_resource.execution_time_limit = 259200 / 60 # converting "PT72H" into minutes and passing here since win32-taskscheduler accepts this
        new_resource
      end

      context "when idle_time is not passed" do
        it "raises error" do
          expect { subject.after_created }.to raise_error("idle_time value should be set for :on_idle frequency.")
        end
      end

      context "when idle_time is passed" do
        it "creates the scheduled task to run when system is idle" do
          subject.idle_time 20
          call_for_create_action
          # loading current resource again to check new task is creted and it matches task parameters
          current_resource = call_for_load_current_resource
          expect(current_resource.exists).to eq(true)
          trigger_details = current_resource.task.trigger(0)
          expect(current_resource.task.application_name).to eq(task_name)
          expect(current_resource.task.principals[:run_level]).to eq(1)
          expect(trigger_details[:trigger_type]).to eq(6)
          expect(current_resource.task.settings[:idle_settings][:idle_duration]).to eq("PT20M")
          expect(current_resource.task.settings[:run_only_if_idle]).to eq(true)
        end

        it "does not converge the resource if it is already converged" do
          subject.idle_time 20
          subject.run_action(:create)
          subject.run_action(:create)
          expect(subject).not_to be_updated_by_last_action
        end
      end

      context "when start_day and start_time is set" do
        it "creates task to activate on '09/10/2018' at '15:00' when start_day = '09/10/2018' and start_time = '15:00' provided" do
          subject.idle_time 20
          subject.start_day "09/10/2018"
          subject.start_time "15:00"
          call_for_create_action
          # loading current resource again to check new task is creted and it matches task parameters
          current_resource = call_for_load_current_resource
          expect(current_resource.exists).to eq(true)
          trigger_details = current_resource.task.trigger(0)
          expect(current_resource.task.application_name).to eq(task_name)
          expect(trigger_details[:trigger_type]).to eq(6)
          expect(trigger_details[:start_year]).to eq("2018")
          expect(trigger_details[:start_month]).to eq("09")
          expect(trigger_details[:start_day]).to eq("10")
          expect(trigger_details[:start_hour]).to eq("15")
          expect(trigger_details[:start_minute]).to eq("00")
        end
      end
    end

    context "when random_delay is passed" do
      subject do
        new_resource = Chef::Resource::WindowsTask.new(task_name, run_context)
        new_resource.command task_name
        new_resource.run_level :highest
        new_resource.execution_time_limit = 259200 / 60 # converting "PT72H" into minutes and passing here since win32-taskscheduler accepts this
        new_resource
      end

      it "sets the random_delay for frequency :minute" do
        subject.frequency :minute
        subject.random_delay "20"
        call_for_create_action
        # loading current resource again to check new task is creted and it matches task parameters
        current_resource = call_for_load_current_resource
        expect(current_resource.exists).to eq(true)
        trigger_details = current_resource.task.trigger(0)
        expect(current_resource.task.application_name).to eq(task_name)
        expect(current_resource.task.principals[:run_level]).to eq(1)
        expect(trigger_details[:trigger_type]).to eq(1)
        expect(trigger_details[:random_minutes_interval]).to eq(20)
      end

      it "does not converge the resource if it is already converged" do
        subject.frequency :minute
        subject.random_delay "20"
        subject.run_action(:create)
        subject.run_action(:create)
        expect(subject).not_to be_updated_by_last_action
      end

      it "raises error if invalid random_delay is passed" do
        subject.frequency :minute
        subject.random_delay "abc"
        expect { subject.after_created }.to raise_error("Invalid value passed for `random_delay`. Please pass seconds as an Integer (e.g. 60) or a String with numeric values only (e.g. '60').")
      end

      it "raises error if random_delay is passed with frequency on_idle" do
        subject.frequency :on_idle
        subject.random_delay "20"
        expect { subject.after_created }.to raise_error("`random_delay` property is supported only for frequency :once, :minute, :hourly, :daily, :weekly and :monthly")
      end
    end

    context "when battery options are passed" do
      subject do
        new_resource = Chef::Resource::WindowsTask.new(task_name, run_context)
        new_resource.command task_name
        new_resource.run_level :highest
        new_resource.execution_time_limit = 259200 / 60 # converting "PT72H" into minutes and passing here since win32-taskscheduler accepts this
        new_resource
      end

      it "sets the default if options are not provided" do
        subject.frequency :minute
        call_for_create_action
        # loading current resource again to check new task is created and it matches task parameters
        current_resource = call_for_load_current_resource
        expect(current_resource.exists).to eq(true)
        expect(current_resource.stop_if_going_on_batteries).to eql(false)
        expect(current_resource.disallow_start_if_on_batteries).to eql(false)
      end

      it "sets disallow_start_if_on_batteries to true" do
        subject.frequency :minute
        subject.disallow_start_if_on_batteries true
        call_for_create_action
        # loading current resource again to check new task is created and it matches task parameters
        current_resource = call_for_load_current_resource
        expect(current_resource.exists).to eq(true)
        expect(current_resource.task.settings[:disallow_start_if_on_batteries]).to eql(true)
      end

      it "sets disallow_start_if_on_batteries to false" do
        subject.frequency :minute
        subject.disallow_start_if_on_batteries false
        call_for_create_action
        # loading current resource again to check new task is created and it matches task parameters
        current_resource = call_for_load_current_resource
        expect(current_resource.exists).to eq(true)
        expect(current_resource.task.settings[:disallow_start_if_on_batteries]).to eql(false)
      end

      it "sets stop_if_going_on_batteries to true" do
        subject.frequency :minute
        subject.stop_if_going_on_batteries true
        call_for_create_action
        # loading current resource again to check new task is creted and it matches task parameters
        current_resource = call_for_load_current_resource
        expect(current_resource.exists).to eq(true)
        expect(current_resource.task.settings[:stop_if_going_on_batteries]).to eql(true)
      end

      it "sets stop_if_going_on_batteries to false" do
        subject.frequency :minute
        subject.stop_if_going_on_batteries false
        call_for_create_action
        # loading current resource again to check new task is created and it matches task parameters
        current_resource = call_for_load_current_resource
        expect(current_resource.exists).to eq(true)
        expect(current_resource.task.settings[:stop_if_going_on_batteries]).to eql(false)
      end

      it "sets the default if options are nil" do
        subject.frequency :minute
        subject.stop_if_going_on_batteries nil
        subject.disallow_start_if_on_batteries nil
        call_for_create_action
        # loading current resource again to check new task is created and it matches task parameters
        current_resource = call_for_load_current_resource
        expect(current_resource.exists).to eq(true)
        expect(current_resource.task.settings[:stop_if_going_on_batteries]).to eql(false)
        expect(current_resource.task.settings[:disallow_start_if_on_batteries]).to eql(false)
      end

      it "does not converge the resource if it is already converged" do
        subject.frequency :minute
        subject.stop_if_going_on_batteries true
        subject.disallow_start_if_on_batteries false
        subject.run_action(:create)
        subject.frequency :minute
        subject.stop_if_going_on_batteries true
        subject.disallow_start_if_on_batteries false
        subject.run_action(:create)
        expect(subject).not_to be_updated_by_last_action
      end
    end

    context "frequency :none" do
      subject do
        new_resource = Chef::Resource::WindowsTask.new(task_name, run_context)
        new_resource.command task_name
        new_resource.run_level :highest
        new_resource.frequency :none
        new_resource.execution_time_limit = 259200 / 60 # converting "PT72H" into minutes and passing here since win32-taskscheduler accepts this
        new_resource
      end

      it "creates the scheduled task to run on demand only" do
        call_for_create_action
        # loading current resource again to check new task is creted and it matches task parameters
        current_resource = call_for_load_current_resource
        expect(current_resource.exists).to eq(true)

        expect(current_resource.task.application_name).to eq(task_name)
        expect(current_resource.task.principals[:run_level]).to eq(1)
        expect(current_resource.task.trigger_count).to eq(0)
      end

      it "does not converge the resource if it is already converged" do
        subject.run_action(:create)
        subject.run_action(:create)
        expect(subject).not_to be_updated_by_last_action
      end
    end

    context "when start_when_available is passed" do
      subject do
        new_resource = Chef::Resource::WindowsTask.new(task_name, run_context)
        new_resource.command task_name
        new_resource.run_level :highest
        new_resource.execution_time_limit = 259200 / 60 # converting "PT72H" into minutes and passing here since win32-taskscheduler accepts this
        new_resource
      end

      it "sets start_when_available to true" do
        subject.frequency :minute
        subject.start_when_available true
        call_for_create_action
        # loading current resource again to check new task is creted and it matches task parameters
        current_resource = call_for_load_current_resource
        expect(current_resource.exists).to eq(true)
        expect(current_resource.task.settings[:start_when_available]).to eql(true)
      end

      it "sets start_when_available to false" do
        subject.frequency :minute
        subject.start_when_available false
        call_for_create_action
        # loading current resource again to check new task is created and it matches task parameters
        current_resource = call_for_load_current_resource
        expect(current_resource.exists).to eq(true)
        expect(current_resource.task.settings[:start_when_available]).to eql(false)
      end

      it "sets the default if start_when_available is nil" do
        subject.frequency :minute
        subject.start_when_available nil
        call_for_create_action
        # loading current resource again to check new task is created and it matches task parameters
        current_resource = call_for_load_current_resource
        expect(current_resource.exists).to eq(true)
        expect(current_resource.task.settings[:start_when_available]).to eql(false)
      end

      it "does not converge the resource if it is already converged" do
        subject.frequency :minute
        subject.start_when_available true
        subject.run_action(:create)
        subject.frequency :minute
        subject.start_when_available true
        subject.disallow_start_if_on_batteries false
        subject.run_action(:create)
        expect(subject).not_to be_updated_by_last_action
      end
    end
  end

  context "task_name with parent folder" do
    describe "task_name with path '\\foo\\chef-client-functional-test' " do
      let(:task_name) { "\\foo\\chef-client-functional-test" }
      after { delete_task }
      subject do
        new_resource = Chef::Resource::WindowsTask.new(task_name, run_context)
        new_resource.command task_name
        new_resource.run_level :highest
        new_resource.frequency :once
        new_resource.execution_time_limit = 259200 / 60 # converting "PT72H" into minutes and passing here since win32-taskscheduler accepts this
        new_resource
      end

      it "creates the scheduled task with task name 'chef-client-functional-test' inside path '\\foo'" do
        call_for_create_action
        current_resource = call_for_load_current_resource
        expect(current_resource.exists).to eq(true)
        expect(current_resource.task.application_name).to eq(task_name)
      end

      it "does not converge the resource if it is already converged" do
        subject.run_action(:create)
        subject.run_action(:create)
        expect(subject).not_to be_updated_by_last_action
      end
    end

    describe "task_name with path '\\foo\\bar\\chef-client-functional-test' " do
      let(:task_name) { "\\foo\\bar\\chef-client-functional-test" }
      after { delete_task }
      subject do
        new_resource = Chef::Resource::WindowsTask.new(task_name, run_context)
        new_resource.command task_name
        new_resource.run_level :highest
        new_resource.frequency :once
        new_resource.execution_time_limit = 259200 / 60 # converting "PT72H" into minutes and passing here since win32-taskscheduler accepts this
        new_resource
      end

      it "creates the scheduled task with task with name 'chef-client-functional-test' inside path '\\foo\\bar' " do
        call_for_create_action
        current_resource = call_for_load_current_resource
        expect(current_resource.exists).to eq(true)
        expect(current_resource.task.application_name).to eq(task_name)
      end

      it "does not converge the resource if it is already converged" do
        subject.run_action(:create)
        subject.run_action(:create)
        expect(subject).not_to be_updated_by_last_action
      end
    end
  end

  describe "priority" do
    after { delete_task }
    subject do
      new_resource = Chef::Resource::WindowsTask.new(task_name, run_context)
      new_resource.command task_name
      new_resource.frequency :once
      new_resource.execution_time_limit = 259200 / 60 # converting "PT72H" into minutes and passing here since win32-taskscheduler accepts this
      new_resource
    end

    it "default sets to 7" do
      call_for_create_action
      current_resource = call_for_load_current_resource
      expect(current_resource.task.priority).to eq("below_normal_7")
    end

    it "0 sets priority level to critical" do
      subject.priority = 0
      call_for_create_action
      current_resource = call_for_load_current_resource
      expect(current_resource.task.priority).to eq("critical")
    end

    it "2 sets priority level to highest" do
      subject.priority = 1
      call_for_create_action
      current_resource = call_for_load_current_resource
      expect(current_resource.task.priority).to eq("highest")
    end

    it "2 sets priority level to above_normal" do
      subject.priority = 2
      call_for_create_action
      current_resource = call_for_load_current_resource
      expect(current_resource.task.priority).to eq("above_normal_2")
    end

    it "3 sets priority level to above_normal" do
      subject.priority = 3
      call_for_create_action
      current_resource = call_for_load_current_resource
      expect(current_resource.task.priority).to eq("above_normal_3")
    end

    it "4 sets priority level to normal" do
      subject.priority = 4
      call_for_create_action
      current_resource = call_for_load_current_resource
      expect(current_resource.task.priority).to eq("normal_4")
    end

    it "5 sets priority level to normal" do
      subject.priority = 5
      call_for_create_action
      current_resource = call_for_load_current_resource
      expect(current_resource.task.priority).to eq("normal_5")
    end

    it "6 sets priority level to normal" do
      subject.priority = 6
      call_for_create_action
      current_resource = call_for_load_current_resource
      expect(current_resource.task.priority).to eq("normal_6")
    end

    it "7 sets priority level to below_normal" do
      subject.priority = 7
      call_for_create_action
      current_resource = call_for_load_current_resource
      expect(current_resource.task.priority).to eq("below_normal_7")
    end

    it "8 sets priority level to below_normal" do
      subject.priority = 8
      call_for_create_action
      current_resource = call_for_load_current_resource
      expect(current_resource.task.priority).to eq("below_normal_8")
    end

    it "9 sets priority level to lowest" do
      subject.priority = 9
      call_for_create_action
      current_resource = call_for_load_current_resource
      expect(current_resource.task.priority).to eq("lowest")
    end

    it "10 sets priority level to idle" do
      subject.priority = 10
      call_for_create_action
      current_resource = call_for_load_current_resource
      expect(current_resource.task.priority).to eq("idle")
    end

    it "is idempotent" do
      subject.priority 8
      subject.run_action(:create)
      subject.run_action(:create)
      expect(subject).not_to be_updated_by_last_action
    end

  end

  describe "Examples of idempotent checks for each frequency" do
    after { delete_task }
    context "For frequency :once" do
      subject do
        new_resource = Chef::Resource::WindowsTask.new(task_name, run_context)
        new_resource.command task_name
        new_resource.run_level :highest
        new_resource.frequency :once
        new_resource.start_time "17:00"
        new_resource.execution_time_limit = 259200 / 60 # converting "PT72H" into minutes and passing here since win32-taskscheduler accepts this
        new_resource
      end

      it "create task by adding frequency_modifier as 1" do
        subject.frequency_modifier 1
        subject.run_action(:create)
        subject.run_action(:create)
        expect(subject).not_to be_updated_by_last_action
      end

      it "create task by adding frequency_modifier as 5" do
        subject.frequency_modifier 5
        subject.run_action(:create)
        subject.run_action(:create)
        expect(subject).not_to be_updated_by_last_action
      end
    end

    context "For frequency :none" do
      subject do
        new_resource = Chef::Resource::WindowsTask.new(task_name, run_context)
        new_resource.command task_name
        new_resource.run_level :highest
        new_resource.execution_time_limit = 259200 / 60 # converting "PT72H" into minutes and passing here since win32-taskscheduler accepts this
        new_resource.frequency :none
        new_resource
      end

      it "create task by adding frequency_modifier as 1" do
        subject.frequency_modifier 1
        subject.run_action(:create)
        subject.run_action(:create)
        expect(subject).not_to be_updated_by_last_action
      end

      it "create task by adding frequency_modifier as 5" do
        subject.frequency_modifier 5
        subject.run_action(:create)
        subject.run_action(:create)
        expect(subject).not_to be_updated_by_last_action
      end
    end

    context "For frequency :weekly" do
      subject do
        new_resource = Chef::Resource::WindowsTask.new(task_name, run_context)
        new_resource.command task_name
        new_resource.run_level :highest
        new_resource.frequency :weekly
        new_resource.execution_time_limit = 259200 / 60 # converting "PT72H" into minutes and passing here since win32-taskscheduler accepts this
        new_resource
      end

      it "create task by adding start_day" do
        subject.start_day "12/28/2018"
        subject.run_action(:create)
        subject.run_action(:create)
        expect(subject).not_to be_updated_by_last_action
      end

      it "create task by adding frequency_modifier and random_delay" do
        subject.frequency_modifier 3
        subject.random_delay "60"
        subject.run_action(:create)
        subject.run_action(:create)
        expect(subject).not_to be_updated_by_last_action
      end
    end

    context "For frequency :monthly" do
      subject do
        new_resource = Chef::Resource::WindowsTask.new(task_name, run_context)
        new_resource.command task_name
        new_resource.run_level :highest
        new_resource.frequency :once
        new_resource.start_time "17:00"
        new_resource.execution_time_limit = 259200 / 60 # converting "PT72H" into minutes and passing here since win32-taskscheduler accepts this
        new_resource
      end

      it "create task by adding frequency_modifier as 1" do
        subject.frequency_modifier 1
        subject.run_action(:create)
        subject.run_action(:create)
        expect(subject).not_to be_updated_by_last_action
      end

      it "create task by adding frequency_modifier as 5" do
        subject.frequency_modifier 5
        subject.run_action(:create)
        subject.run_action(:create)
        expect(subject).not_to be_updated_by_last_action
      end
    end

    context "For frequency :hourly" do
      subject do
        new_resource = Chef::Resource::WindowsTask.new(task_name, run_context)
        new_resource.command task_name
        new_resource.run_level :highest
        new_resource.frequency :hourly
        new_resource.frequency_modifier 5
        new_resource.random_delay "2400"
        new_resource.execution_time_limit = 259200 / 60 # converting "PT72H" into minutes and passing here since win32-taskscheduler accepts this
        new_resource
      end

      it "create task by adding frequency_modifier and random_delay" do
        subject.run_action(:create)
        subject.run_action(:create)
        expect(subject).not_to be_updated_by_last_action
      end
    end

    context "For frequency :daily" do
      subject do
        new_resource = Chef::Resource::WindowsTask.new(task_name, run_context)
        new_resource.command task_name
        new_resource.run_level :highest
        new_resource.frequency :daily
        new_resource.frequency_modifier 2
        new_resource.random_delay "2400"
        new_resource.execution_time_limit = 259200 / 60 # converting "PT72H" into minutes and passing here since win32-taskscheduler accepts this
        new_resource
      end

      it "create task by adding frequency_modifier and random_delay" do
        subject.run_action(:create)
        subject.run_action(:create)
        expect(subject).not_to be_updated_by_last_action
      end
    end

    context "For frequency :on_logon" do
      subject do
        new_resource = Chef::Resource::WindowsTask.new(task_name, run_context)
        new_resource.command task_name
        new_resource.frequency :on_logon
        new_resource.execution_time_limit = 259200 / 60 # converting "PT72H" into minutes and passing here since win32-taskscheduler accepts this
        new_resource
      end

      it "create task by adding frequency_modifier and random_delay" do
        subject.run_action(:create)
        subject.run_action(:create)
        expect(subject).not_to be_updated_by_last_action
      end

      it "create task by adding frequency_modifier as 5" do
        subject.frequency_modifier 5
        subject.run_action(:create)
        subject.run_action(:create)
        expect(subject).not_to be_updated_by_last_action
      end
    end

    context "For frequency :onstart" do
      subject do
        new_resource = Chef::Resource::WindowsTask.new(task_name, run_context)
        new_resource.command task_name
        new_resource.run_level :highest
        new_resource.frequency :onstart
        new_resource.frequency_modifier 20
        new_resource.execution_time_limit = 259200 / 60 # converting "PT72H" into minutes and passing here since win32-taskscheduler accepts this
        new_resource
      end

      it "create task by adding frequency_modifier as 20" do
        subject.run_action(:create)
        subject.run_action(:create)
        expect(subject).not_to be_updated_by_last_action
      end
    end
  end

  describe "#after_created" do
    subject do
      new_resource = Chef::Resource::WindowsTask.new(task_name, run_context)
      new_resource.command task_name
      new_resource.run_level :highest
      new_resource.execution_time_limit = 259200 / 60 # converting "PT72H" into minutes and passing here since win32-taskscheduler accepts this
      new_resource
    end

    context "when start_day is passed with frequency :onstart" do
      it "does not raises error" do
        subject.frequency :onstart
        subject.start_day "09/20/2017"
        expect { subject.after_created }.not_to raise_error
      end
    end

    context "when a non system user is passed without password" do
      it "raises error" do
        subject.user "USER"
        subject.frequency :onstart
        expect { subject.after_created }.to raise_error(%q{Please provide a password or check if this task needs to be interactive! Valid passwordless users are: 'SYSTEM', 'NT AUTHORITY\SYSTEM', 'LOCAL SERVICE', 'NT AUTHORITY\LOCAL SERVICE', 'NETWORK SERVICE', 'NT AUTHORITY\NETWORK SERVICE', 'ADMINISTRATORS', 'BUILTIN\ADMINISTRATORS', 'USERS', 'BUILTIN\USERS', 'GUESTS', 'BUILTIN\GUESTS'})
      end
      it "does not raises error when task is interactive" do
        subject.user "USER"
        subject.frequency :onstart
        subject.interactive_enabled true
        expect { subject.after_created }.not_to raise_error
      end
    end

    context "when a system user is passed without password" do
      it "does not raises error" do
        subject.user "ADMINISTRATORS"
        subject.frequency :onstart
        expect { subject.after_created }.not_to raise_error
      end
      it "does not raises error when task is interactive" do
        subject.user "ADMINISTRATORS"
        subject.frequency :onstart
        subject.interactive_enabled true
        expect { subject.after_created }.not_to raise_error
      end
    end

    context "when a non system user is passed with password" do
      it "does not raises error" do
        subject.user "USER"
        subject.password "XXXX"
        subject.frequency :onstart
        expect { subject.after_created }.not_to raise_error
      end
      it "does not raises error when task is interactive" do
        subject.user "USER"
        subject.password "XXXX"
        subject.frequency :onstart
        subject.interactive_enabled true
        expect { subject.after_created }.not_to raise_error
      end
    end

    context "when a system user is passed with password" do
      it "raises error" do
        subject.user "ADMINISTRATORS"
        subject.password "XXXX"
        subject.frequency :onstart
        expect { subject.after_created }.to raise_error("Password is not required for system users.")
      end
      it "raises error when task is interactive" do
        subject.user "ADMINISTRATORS"
        subject.password "XXXX"
        subject.frequency :onstart
        subject.interactive_enabled true
        expect { subject.after_created }.to raise_error("Password is not required for system users.")
      end
    end

    context "when frequency_modifier > 1439 is passed for frequency=:minute" do
      it "raises error" do
        subject.frequency_modifier 1450
        subject.frequency :minute
        expect { subject.after_created }.to raise_error("frequency_modifier value 1450 is invalid. Valid values for :minute frequency are 1 - 1439.")
      end
    end

    context "when frequency_modifier > 23 is passed for frequency=:minute" do
      it "raises error" do
        subject.frequency_modifier 24
        subject.frequency :hourly
        expect { subject.after_created }.to raise_error("frequency_modifier value 24 is invalid. Valid values for :hourly frequency are 1 - 23.")
      end
    end

    context "when frequency_modifier > 23 is passed for frequency=:minute" do
      it "raises error" do
        subject.frequency_modifier 366
        subject.frequency :daily
        expect { subject.after_created }.to raise_error("frequency_modifier value 366 is invalid. Valid values for :daily frequency are 1 - 365.")
      end
    end

    context "when frequency_modifier > 52 is passed for frequency=:minute" do
      it "raises error" do
        subject.frequency_modifier 53
        subject.frequency :weekly
        expect { subject.after_created }.to raise_error("frequency_modifier value 53 is invalid. Valid values for :weekly frequency are 1 - 52.")
      end
    end

    context "when invalid frequency_modifier is passed for :monthly frequency" do
      it "raises error" do
        subject.frequency :monthly
        subject.frequency_modifier "13"
        expect { subject.after_created }.to raise_error("frequency_modifier value 13 is invalid. Valid values for :monthly frequency are 1 - 12, 'FIRST', 'SECOND', 'THIRD', 'FOURTH', 'LAST'.")
      end
    end

    context "when invalid frequency_modifier is passed for :monthly frequency" do
      it "raises error" do
        subject.frequency :monthly
        subject.frequency_modifier "xyz"
        expect { subject.after_created }.to raise_error("frequency_modifier value xyz is invalid. Valid values for :monthly frequency are 1 - 12, 'FIRST', 'SECOND', 'THIRD', 'FOURTH', 'LAST'.")
      end
    end

    context "when invalid months are passed" do
      it "raises error" do
        subject.months "xyz"
        subject.frequency :monthly
        expect { subject.after_created }.to raise_error("months property invalid. Only valid values are: JAN, FEB, MAR, APR, MAY, JUN, JUL, AUG, SEP, OCT, NOV, DEC, *. Multiple values must be separated by a comma.")
      end
    end

    context "when idle_time > 999 is passed" do
      it "raises error" do
        subject.idle_time 1000
        subject.frequency :on_idle
        expect { subject.after_created }.to raise_error("idle_time value 1000 is invalid. Valid values for :on_idle frequency are 1 - 999.")
      end
    end

    context "when idle_time is passed for frequency=:monthly" do
      it "raises error" do
        subject.idle_time 300
        subject.frequency :monthly
        expect { subject.after_created }.to raise_error("idle_time property is only valid for tasks that run on_idle")
      end
    end
  end

  describe "action :delete" do
    subject do
      new_resource = Chef::Resource::WindowsTask.new(task_name, run_context)
      new_resource.command task_name
      new_resource.execution_time_limit = 259200 / 60 # converting "PT72H" into minutes and passing here since win32-taskscheduler accepts this
      new_resource.frequency :hourly
      new_resource
    end

    it "does not converge the resource if it is already converged" do
      subject.run_action(:create)
      subject.run_action(:delete)
      subject.run_action(:delete)
      expect(subject).not_to be_updated_by_last_action
    end

    it "does not converge the resource if it is already converged" do
      subject.run_action(:create)
      subject.run_action(:delete)
      subject.run_action(:delete)
      expect(subject).not_to be_updated_by_last_action
    end
  end

  describe "action :run" do
    after { delete_task }

    subject do
      new_resource = Chef::Resource::WindowsTask.new(task_name, run_context)
      new_resource.command "dir"
      new_resource.run_level :highest
      new_resource.execution_time_limit = 259200 / 60 # converting "PT72H" into minutes and passing here since
      new_resource.frequency :hourly
      new_resource
    end

    it "runs the existing task" do
      subject.run_action(:create)
      subject.run_action(:run)
      current_resource = call_for_load_current_resource
      expect(current_resource.task.status).to eq("queued").or eq("running").or eq("ready") # queued or can be running
    end
  end

  describe "action :end", :volatile do
    after { delete_task }

    subject do
      new_resource = Chef::Resource::WindowsTask.new(task_name, run_context)
      new_resource.command "dir"
      new_resource.run_level :highest
      new_resource.execution_time_limit = 259200 / 60 # converting "PT72H" into minutes and passing here since
      new_resource
    end

    it "ends the running task" do
      subject.run_action(:create)
      subject.run_action(:run)
      subject.run_action(:end)
      current_resource = call_for_load_current_resource
      expect(current_resource.task.status).to eq("queued").or eq("ready") # queued or can be ready
    end
  end

  describe "action :enable" do
    let(:task_name) { "chef-client-functional-test-enable" }
    after { delete_task }

    subject do
      new_resource = Chef::Resource::WindowsTask.new(task_name, run_context)
      new_resource.command task_name
      new_resource.execution_time_limit = 259200 / 60 # converting "PT72H" into minutes and passing here since
      new_resource.frequency :hourly
      new_resource
    end

    it "enables the disabled task" do
      subject.run_action(:create)
      subject.run_action(:disable)
      current_resource = call_for_load_current_resource
      expect(current_resource.task.status).to eq("not scheduled")
      subject.run_action(:enable)
      current_resource = call_for_load_current_resource
      expect(current_resource.task.status).to eq("ready")
    end
  end

  describe "action :disable" do
    let(:task_name) { "chef-client-functional-test-disable" }
    after { delete_task }

    subject do
      new_resource = Chef::Resource::WindowsTask.new(task_name, run_context)
      new_resource.command task_name
      new_resource.execution_time_limit = 259200 / 60 # converting "PT72H" into minutes and passing here since
      new_resource.frequency :hourly
      new_resource
    end

    it "disables the task" do
      subject.run_action(:create)
      subject.run_action(:disable)
      current_resource = call_for_load_current_resource
      expect(current_resource.task.status).to eq("not scheduled")
    end
  end

  describe "action :change" do
    after { delete_task }
    subject do
      new_resource = Chef::Resource::WindowsTask.new(task_name, run_context)
      new_resource.command task_name
      new_resource.execution_time_limit = 259200 / 60 # converting "PT72H" into minutes and passing here since
      new_resource.frequency :hourly
      new_resource
    end

    it "call action_create since change action is alias for create" do
      subject.run_action(:change)
      expect(subject).to be_updated_by_last_action
    end
  end

  def delete_task
    task_to_delete = Chef::Resource::WindowsTask.new(task_name, run_context)
    task_to_delete.run_action(:delete)
  end

  def call_for_create_action
    current_resource = call_for_load_current_resource
    expect(current_resource.exists).to eq(false)
    subject.run_action(:create)
    expect(subject).to be_updated_by_last_action
  end

  def call_for_load_current_resource
    windows_task_provider.send(:load_current_resource)
  end
end
