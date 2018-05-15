#
# Author:: Nimisha Sharad (<nimisha.sharad@msystechnologies.com>)
# Copyright:: Copyright 2008-2017, Chef Software, Inc.
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

describe Chef::Resource::WindowsTask, :windows_only do
  let(:resource) { Chef::Resource::WindowsTask.new("sample_task") }

  it "sets resource name as :windows_task" do
    expect(resource.resource_name).to eql(:windows_task)
  end

  it "sets the task_name as its name" do
    expect(resource.task_name).to eql("sample_task")
  end

  it "sets the default action as :create" do
    expect(resource.action).to eql([:create])
  end

  it "sets the default user as System" do
    expect(resource.user).to eql("SYSTEM")
  end

  it "sets the default run_level as :limited" do
    expect(resource.run_level).to eql(:limited)
  end

  it "sets the default force as false" do
    expect(resource.force).to eql(false)
  end

  it "sets the default interactive_enabled as false" do
    expect(resource.interactive_enabled).to eql(false)
  end

  it "sets the default frequency_modifier as 1" do
    expect(resource.frequency_modifier).to eql(1)
  end

  context "when frequency is not provided" do
    it "raises ArgumentError to provide frequency" do
      expect { resource.after_created }.to raise_error(ArgumentError, "Frequency needs to be provided. Valid frequencies are :minute, :hourly, :daily, :weekly, :monthly, :once, :on_logon, :onstart, :on_idle, :none." )
    end
  end

  context "when user is set but password is not" do
    before do
      resource.frequency :hourly
    end
    it "raises an error if the user is a non-system user" do
      resource.user "bob"
      expect { resource.after_created }.to raise_error(ArgumentError, %q{Cannot specify a user other than the system users without specifying a password!. Valid passwordless users: 'NT AUTHORITY\SYSTEM', 'SYSTEM', 'NT AUTHORITY\LOCALSERVICE', 'NT AUTHORITY\NETWORKSERVICE', 'BUILTIN\USERS', 'USERS'})
    end

    it "does not raise an error if the user is a system user" do
      resource.user 'NT AUTHORITY\SYSTEM'
      expect { resource.after_created }.to_not raise_error
    end

    it "does not raise an error if the user is a system user even if lowercase" do
      resource.user 'nt authority\system'
      expect { resource.after_created }.to_not raise_error
    end
  end

  context "when random_delay is passed" do
    # changed this sepc since random_delay property is valid with it frequency :once
    it "not raises error if frequency is `:once`" do
      resource.frequency :once
      resource.random_delay "20"
      resource.start_time "15:00"
      expect { resource.after_created }.to_not raise_error(ArgumentError, "`random_delay` property is supported only for frequency :once, :minute, :hourly, :daily, :weekly and :monthly")
    end

    it "raises error for invalid random_delay" do
      resource.frequency :monthly
      resource.random_delay "xyz"
      expect { resource.after_created }.to raise_error(ArgumentError, "Invalid value passed for `random_delay`. Please pass seconds as an Integer (e.g. 60) or a String with numeric values only (e.g. '60').")
    end

    it "raises error for invalid random_delay which looks like an Integer" do
      resource.frequency :monthly
      resource.random_delay "5,000"
      expect { resource.after_created }.to raise_error(ArgumentError, "Invalid value passed for `random_delay`. Please pass seconds as an Integer (e.g. 60) or a String with numeric values only (e.g. '60').")
    end

    it "converts '60' seconds into integer 1 minute format" do
      resource.frequency :monthly
      resource.random_delay "60"
      resource.after_created
      expect(resource.random_delay).to eq(1)
    end

    it "converts 60 Integer into integer 1 minute format" do
      resource.frequency :monthly
      resource.random_delay 60
      resource.after_created
      expect(resource.random_delay).to eq(1)
    end

    it "raises error that random_delay is not supported" do
      expect { resource.send(:validate_random_delay, 60, :on_idle) }.to raise_error(ArgumentError, "`random_delay` property is supported only for frequency :once, :minute, :hourly, :daily, :weekly and :monthly")
    end
  end

  context "when execution_time_limit isn't specified" do
    it "sets the default value to PT72H which get converted to minute as 4320" do
      resource.frequency :hourly
      resource.after_created
      expect(resource.execution_time_limit).to eq(4320)
    end
  end

  context "when execution_time_limit is passed" do
    it "raises error for invalid execution_time_limit" do
      resource.execution_time_limit "abc"
      expect { resource.after_created }.to raise_error(ArgumentError, "Invalid value passed for `execution_time_limit`. Please pass seconds as an Integer (e.g. 60) or a String with numeric values only (e.g. '60').")
    end

    it "raises error for invalid execution_time_limit that looks like an Integer" do
      resource.execution_time_limit "5,000"
      expect { resource.after_created }.to raise_error(ArgumentError, "Invalid value passed for `execution_time_limit`. Please pass seconds as an Integer (e.g. 60) or a String with numeric values only (e.g. '60').")
    end

    it "converts seconds Integer into integer minute format" do
      resource.frequency :hourly
      resource.execution_time_limit 60
      resource.after_created
      expect(resource.execution_time_limit).to eq(1)
    end

    it "converts seconds String into integer minute format" do
      resource.frequency :hourly
      resource.execution_time_limit "60"
      resource.after_created
      expect(resource.execution_time_limit).to eq(1)
    end
  end

  context "#validate_start_time" do
    it "raises error if start_time is nil when frequency `:once`" do
      resource.frequency :once
      expect { resource.send(:validate_start_time, nil, :once) }.to raise_error(ArgumentError, "`start_time` needs to be provided with `frequency :once`")
    end

    it "raises error if start_time is given when frequency `:none`" do
      resource.frequency :none
      expect { resource.send(:validate_start_time, "12.00", :none) }.to raise_error(ArgumentError, "`start_time` property is not supported with `frequency :none`")
    end

    it "raises error if start_time is not HH:mm format" do
      resource.frequency :once
      expect { resource.send(:validate_start_time, "2:30", :once) }.to raise_error(ArgumentError, "`start_time` property must be in the HH:mm format (e.g. 6:20pm -> 18:20).")
    end

    it "does not raise error if start_time is in HH:mm format" do
      resource.frequency :once
      expect { resource.send(:validate_start_time, "12:30", :once) }.not_to raise_error
    end
  end

  context "#validate_start_day" do
    it "not to raise error if start_day is passed with invalid frequency (:onstart)" do
      expect { resource.send(:validate_start_day, "02/07/1984", :onstart) }.not_to raise_error
    end

    it "not to raise error if start_day is passed with invalid frequency (:on_idle)" do
      expect { resource.send(:validate_start_day, "02/07/1984", :on_idle) }.not_to raise_error
    end

    it "not to raise error if start_day is passed with invalid frequency (:on_logon)" do
      expect { resource.send(:validate_start_day, "02/07/1984", :on_logon) }.not_to raise_error
    end

    it "not raise error if start_day is passed with valid frequency (:weekly)" do
      expect { resource.send(:validate_start_day, "02/07/1984", :weekly) }.not_to raise_error
    end

    it "not to raise error if start_day is passed with invalid date format (DD/MM/YYYY)" do
      expect { resource.send(:validate_start_day, "28/12/2009", :weekly) }.to raise_error(ArgumentError, "`start_day` property must be in the MM/DD/YYYY format.")
    end

    it "raise error if start_day is passed with invalid date format (M/DD/YYYY)" do
      expect { resource.send(:validate_start_day, "2/07/1984", :weekly) }.to raise_error(ArgumentError, "`start_day` property must be in the MM/DD/YYYY format.")
    end

    it "raise error if start_day is passed with invalid date format (MM/D/YYYY)" do
      expect { resource.send(:validate_start_day, "02/7/1984", :weekly) }.to raise_error(ArgumentError, "`start_day` property must be in the MM/DD/YYYY format.")
    end

    it "raise error if start_day is passed with invalid date format (MM/DD/YY)" do
      expect { resource.send(:validate_start_day, "02/07/84", :weekly) }.to raise_error(ArgumentError, "`start_day` property must be in the MM/DD/YYYY format.")
    end
  end

  context "#validate_interactive_setting" do
    it "raises error when interactive_enabled is passed without password" do
      expect { resource.send(:validate_interactive_setting, true, nil) }.to raise_error("Please provide the password when attempting to set interactive/non-interactive.")
    end
  end

  context "#validate_create_frequency_modifier" do
    context "when frequency is :minute" do
      it "raises error if frequency_modifier > 1439" do
        expect { resource.send(:validate_create_frequency_modifier, :minute, 1500) }.to raise_error("frequency_modifier value 1500 is invalid. Valid values for :minute frequency are 1 - 1439.")
      end
    end

    context "when frequency is :hourly" do
      it "raises error if frequency_modifier > 23" do
        expect { resource.send(:validate_create_frequency_modifier, :hourly, 24) }.to raise_error("frequency_modifier value 24 is invalid. Valid values for :hourly frequency are 1 - 23.")
      end
    end

    context "when frequency is :daily" do
      it "raises error if frequency_modifier > 365" do
        expect { resource.send(:validate_create_frequency_modifier, :daily, 366) }.to raise_error("frequency_modifier value 366 is invalid. Valid values for :daily frequency are 1 - 365.")
      end
    end

    context "when frequency is :weekly" do
      it "raises error if frequency_modifier > 52" do
        expect { resource.send(:validate_create_frequency_modifier, :weekly, 53) }.to raise_error("frequency_modifier value 53 is invalid. Valid values for :weekly frequency are 1 - 52.")
      end
    end

    context "when frequency is :monthly" do
      it "raises error if frequency_modifier > 12" do
        expect { resource.send(:validate_create_frequency_modifier, :monthly, 14) }.to raise_error("frequency_modifier value 14 is invalid. Valid values for :monthly frequency are 1 - 12, 'FIRST', 'SECOND', 'THIRD', 'FOURTH', 'LAST'.")
      end

      it "raises error if frequency_modifier is invalid" do
        expect { resource.send(:validate_create_frequency_modifier, :monthly, "abc") }.to raise_error("frequency_modifier value abc is invalid. Valid values for :monthly frequency are 1 - 12, 'FIRST', 'SECOND', 'THIRD', 'FOURTH', 'LAST'.")
      end
    end
  end

  context "#validate_create_day" do
    it "raises error if frequency is not :weekly or :monthly" do
      expect { resource.send(:validate_create_day, "Mon", :once, 1) }.to raise_error("day property is only valid for tasks that run monthly or weekly")
    end

    it "accepts a valid single day" do
      expect { resource.send(:validate_create_day, "Mon", :weekly, 1) }.not_to raise_error
    end

    it "accepts a comma separated list of valid days" do
      expect { resource.send(:validate_create_day, "Mon, tue, THU", :weekly, 1) }.not_to raise_error
    end

    it "raises error for invalid day value" do
      expect { resource.send(:validate_create_day, "xyz", :weekly, 1) }.to raise_error(ArgumentError, "day property invalid. Only valid values are: MON, TUE, WED, THU, FRI, SAT, SUN, *. Multiple values must be separated by a comma.")
    end
  end

  context "#validate_create_months" do
    it "raises error if frequency is not :monthly" do
      expect { resource.send(:validate_create_months, "Jan", :once) }.to raise_error(ArgumentError, "months property is only valid for tasks that run monthly")
    end

    it "accepts a valid single month" do
      expect { resource.send(:validate_create_months, "Feb", :monthly) }.not_to raise_error
    end

    it "accepts a comma separated list of valid months" do
      expect { resource.send(:validate_create_months, "Jan, mar, AUG", :monthly) }.not_to raise_error
    end

    it "raises error for invalid month value" do
      expect { resource.send(:validate_create_months, "xyz", :monthly) }.to raise_error(ArgumentError, "months property invalid. Only valid values are: JAN, FEB, MAR, APR, MAY, JUN, JUL, AUG, SEP, OCT, NOV, DEC, *. Multiple values must be separated by a comma.")
    end
  end

  context "#validate_idle_time" do
    it "raises error if frequency is not :on_idle" do
      [:minute, :hourly, :daily, :weekly, :monthly, :once, :on_logon, :onstart, :none].each do |frequency|
        expect { resource.send(:validate_idle_time, 5, frequency) }.to raise_error(ArgumentError, "idle_time property is only valid for tasks that run on_idle")
      end
    end

    it "raises error if idle_time > 999" do
      expect { resource.send(:validate_idle_time, 1000, :on_idle) }.to raise_error(ArgumentError, "idle_time value 1000 is invalid. Valid values for :on_idle frequency are 1 - 999.")
    end

    it "raises error if idle_time < 0" do
      expect { resource.send(:validate_idle_time, -5, :on_idle) }.to raise_error(ArgumentError, "idle_time value -5 is invalid. Valid values for :on_idle frequency are 1 - 999.")
    end

    it "raises error if idle_time is not set" do
      expect { resource.send(:validate_idle_time, nil, :on_idle) }.to raise_error(ArgumentError, "idle_time value should be set for :on_idle frequency.")
    end

    it "does not raises error if idle_time is not set for other frequencies" do
      [:minute, :hourly, :daily, :weekly, :monthly, :once, :on_logon, :onstart, :none].each do |frequency|
        expect { resource.send(:validate_idle_time, nil, frequency) }.not_to raise_error
      end
    end
  end

  context "#sec_to_dur" do
    it "return nil when passed 0" do
      expect(resource.send(:sec_to_dur, 0)).to eql("PT0S")
    end
    it "return PT1S when passed 1" do
      expect(resource.send(:sec_to_dur, 1)).to eql("PT1S")
    end
    it "return PT86400S when passed 86400" do
      expect(resource.send(:sec_to_dur, 86400)).to eql("PT86400S")
    end
    it "return PT86401S when passed 86401" do
      expect(resource.send(:sec_to_dur, 86401)).to eql("PT86401S")
    end
    it "return PT86500S when passed 86500" do
      expect(resource.send(:sec_to_dur, 86500)).to eql("PT86500S")
    end
    it "return PT604801S when passed 604801" do
      expect(resource.send(:sec_to_dur, 604801)).to eql("PT604801S")
    end
  end
end
