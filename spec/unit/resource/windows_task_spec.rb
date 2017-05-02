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

describe Chef::Resource::WindowsTask do
  let(:resource) { Chef::Resource::WindowsTask.new("sample_task") }

  it "creates a new Chef::Resource::WindowsTask" do
    expect(resource).to be_a_kind_of(Chef::Resource)
    expect(resource).to be_a_instance_of(Chef::Resource::WindowsTask)
  end

  it "sets resource name as :windows_task" do
    expect(resource.resource_name).to eql(:windows_task)
  end

  it "sets the task_name as it's name" do
    expect(resource.task_name).to eql("sample_task")
  end

  it "sets the default action as :create" do
    expect(resource.action).to eql(:create)
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

  it "sets the default frequency as :hourly" do
    expect(resource.frequency).to eql(:hourly)
  end

  context "when random_delay is passed" do
    it "raises error if frequency is `:once`" do
      resource.frequency :once
      resource.random_delay "20"
      expect { resource.after_created }.to raise_error(Chef::Exceptions::ArgumentError, "`random_delay` property is supported only for frequency :minute, :hourly, :daily, :weekly and :monthly")
    end

    it "raises error for invalid random_delay" do
      resource.frequency :monthly
      resource.random_delay "xyz"
      expect { resource.after_created }.to raise_error(Chef::Exceptions::ArgumentError, "Invalid value passed for `random_delay`. Please pass seconds as a String e.g. '60'.")
    end

    it "converts seconds into iso8601 format" do
      resource.frequency :monthly
      resource.random_delay "60"
      resource.after_created
      expect(resource.random_delay).to eq("PT60S")
    end
  end

  context "when execution_time_limit is passed" do
    it "sets the deafult value as PT72H" do
      resource.after_created
      expect(resource.execution_time_limit).to eq("PT72H")
    end

    it "raises error for invalid execution_time_limit" do
      resource.execution_time_limit "abc"
      expect { resource.after_created }.to raise_error(Chef::Exceptions::ArgumentError, "Invalid value passed for `execution_time_limit`. Please pass seconds as a String e.g. '60'.")
    end

    it "converts seconds into iso8601 format" do
      resource.execution_time_limit "60"
      resource.after_created
      expect(resource.execution_time_limit).to eq("PT60S")
    end
  end

  context "#validate_start_time" do
    it "raises error if start_time is nil" do
      expect { resource.send(:validate_start_time, nil) }.to raise_error(Chef::Exceptions::ArgumentError, "`start_time` needs to be provided with `frequency :once`")
    end
  end

  context "#validate_start_day" do
    it "raise error if start_day is passed with frequency :on_logon" do
      resource.frequency :on_logon
      expect { resource.send(:validate_start_day, "Wed", :on_logon) }.to raise_error(Chef::Exceptions::ArgumentError, "`start_day` property is not supported with frequency: on_logon")
    end
  end

  context "#validate_user_and_password" do
    context "when password is not passed" do
      it "raises error with non-system users" do
        allow(resource).to receive(:use_password?).and_return(true)
        expect { resource.send(:validate_user_and_password, "Testuser", nil) }.to raise_error("Can't specify a non-system user without a password!")
      end
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
        expect { resource.send(:validate_create_frequency_modifier, :minute, 1500) }.to raise_error("frequency_modifier value 1500 is invalid.  Valid values for :minute frequency are 1 - 1439.")
      end
    end

    context "when frequency is :hourly" do
      it "raises error if frequency_modifier > 23" do
        expect { resource.send(:validate_create_frequency_modifier, :hourly, 24) }.to raise_error("frequency_modifier value 24 is invalid.  Valid values for :hourly frequency are 1 - 23.")
      end
    end

    context "when frequency is :daily" do
      it "raises error if frequency_modifier > 365" do
        expect { resource.send(:validate_create_frequency_modifier, :daily, 366) }.to raise_error("frequency_modifier value 366 is invalid.  Valid values for :daily frequency are 1 - 365.")
      end
    end

    context "when frequency is :weekly" do
      it "raises error if frequency_modifier > 52" do
        expect { resource.send(:validate_create_frequency_modifier, :weekly, 53) }.to raise_error("frequency_modifier value 53 is invalid.  Valid values for :weekly frequency are 1 - 52.")
      end
    end

    context "when frequency is :monthly" do
      it "raises error if frequency_modifier > 12" do
        expect { resource.send(:validate_create_frequency_modifier, :monthly, 14) }.to raise_error("frequency_modifier value 14 is invalid.  Valid values for :monthly frequency are 1 - 12, 'FIRST', 'SECOND', 'THIRD', 'FOURTH', 'LAST', 'LASTDAY'.")
      end

      it "raises error if frequency_modifier is invalid" do
        expect { resource.send(:validate_create_frequency_modifier, :monthly, "abc") }.to raise_error("frequency_modifier value abc is invalid.  Valid values for :monthly frequency are 1 - 12, 'FIRST', 'SECOND', 'THIRD', 'FOURTH', 'LAST', 'LASTDAY'.")
      end
    end
  end

  context "#validate_create_day" do
    it "raises error if frequency is not :weekly or :monthly" do
      expect  { resource.send(:validate_create_day, "Mon", :once) }.to raise_error("day attribute is only valid for tasks that run monthly or weekly")
    end

    it "accepts a valid single day" do
      expect  { resource.send(:validate_create_day, "Mon", :weekly) }.not_to raise_error
    end

    it "accepts a comma separated list of valid days" do
      expect  { resource.send(:validate_create_day, "Mon, tue, THU", :weekly) }.not_to raise_error
    end

    it "raises error for invalid day value" do
      expect  { resource.send(:validate_create_day, "xyz", :weekly) }.to raise_error("day attribute invalid.  Only valid values are: MON, TUE, WED, THU, FRI, SAT, SUN and *.  Multiple values must be separated by a comma.")
    end
  end

  context "#validate_create_months" do
    it "raises error if frequency is not :monthly" do
      expect  { resource.send(:validate_create_months, "Jan", :once) }.to raise_error("months attribute is only valid for tasks that run monthly")
    end

    it "accepts a valid single month" do
      expect  { resource.send(:validate_create_months, "Feb", :monthly) }.not_to raise_error
    end

    it "accepts a comma separated list of valid months" do
      expect  { resource.send(:validate_create_months, "Jan, mar, AUG", :monthly) }.not_to raise_error
    end

    it "raises error for invalid month value" do
      expect  { resource.send(:validate_create_months, "xyz", :monthly) }.to raise_error("months attribute invalid. Only valid values are: JAN, FEB, MAR, APR, MAY, JUN, JUL, AUG, SEP, OCT, NOV, DEC and *. Multiple values must be separated by a comma.")
    end
  end

  context "#validate_idle_time" do
    it "raises error if frequency is not :on_idle" do
      expect  { resource.send(:validate_idle_time, 5, :hourly) }.to raise_error("idle_time attribute is only valid for tasks that run on_idle")
    end

    it "raises error if idle_time > 999" do
      expect  { resource.send(:validate_idle_time, 1000, :on_idle) }.to raise_error("idle_time value 1000 is invalid.  Valid values for :on_idle frequency are 1 - 999.")
    end
  end
end
