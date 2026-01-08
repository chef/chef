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

describe "windows_task provider", :windows_only do
  let(:new_resource) { Chef::Resource::WindowsTask.new("sample_task", run_context) }
  let(:current_resource) { Chef::Resource::WindowsTask.new }

  let(:run_context) do
    Chef::RunContext.new(Chef::Node.new, {}, Chef::EventDispatch::Dispatcher.new)
  end

  let(:provider) do
    new_resource.provider_for_action(:create)
  end

  describe "#load_current_resource" do
    it "returns a current_resource" do
      expect(provider.load_current_resource).to be_kind_of(Chef::Resource::WindowsTask)
    end
  end

  describe "#set_command_and_arguments" do
    it "sets the command arguments if command has arguments passed in it" do
      new_resource.command = "chef-client -W"
      provider.send(:set_command_and_arguments)
      expect(new_resource.command).to eq("chef-client")
      expect(new_resource.command_arguments).to eq("-W")
    end
  end

  describe "#set_start_day_and_time" do
    it "sets the curret date and time start_day and start_time if nothing is provided by user" do
      new_resource.start_day = nil
      new_resource.start_time = nil
      provider.send(:set_start_day_and_time)
      expect(new_resource.start_day).not_to be_nil
      expect(new_resource.start_time).not_to be_nil
    end

    it "does not set start_day and start_time if given by user" do
      new_resource.start_day = "12/02/2017"
      new_resource.start_time = "17:30"
      provider.send(:set_start_day_and_time)
      expect(new_resource.start_day).to eq("12/02/2017")
      expect(new_resource.start_time).to eq("17:30")
    end
  end

  describe "#trigger" do
    it "returns the trigger values in hash format" do
      new_resource.start_day "12/02/2017"
      new_resource.start_time "17:30"
      new_resource.frequency  :minute
      new_resource.frequency_modifier 15
      new_resource.random_delay 60
      result = {
        start_year: 2017,
        start_month: 12,
        start_day: 2,
        start_hour: 17,
        start_minute: 30,
        end_month: 0,
        end_day: 0,
        end_year: 0,
        trigger_type: 1,
        type: { once: nil },
        random_minutes_interval: 60,
        minutes_interval: 15,
        run_on_last_day_of_month: false,
        run_on_last_week_of_month: false,

      }
      expect(provider.send(:trigger)).to eq(result)
    end
  end

  describe "#convert_hours_in_minutes" do
    it "converts given hours in minutes" do
      expect(provider.send(:convert_hours_in_minutes, 5)).to eq(300)
    end
  end

  describe "#trigger_type" do
    it "returns 1 if frequency :once" do
      new_resource.frequency :once
      expect(provider.send(:trigger_type)).to eq(1)
    end

    it "returns 2 if frequency :daily" do
      new_resource.frequency :daily
      expect(provider.send(:trigger_type)).to eq(2)
    end

    it "returns 3 if frequency :weekly" do
      new_resource.frequency :weekly
      expect(provider.send(:trigger_type)).to eq(3)
    end

    it "returns 4 if frequency :monthly" do
      new_resource.frequency :monthly
      expect(provider.send(:trigger_type)).to eq(4)
    end

    it "returns 5 if frequency :monthly and frequency_modifier is 'first, second'" do
      new_resource.frequency :monthly
      new_resource.frequency_modifier "first, second"
      expect(provider.send(:trigger_type)).to eq(5)
    end

    it "returns 6 if frequency :on_idle" do
      new_resource.frequency :on_idle
      expect(provider.send(:trigger_type)).to eq(6)
    end

    it "returns 8 if frequency :onstart" do
      new_resource.frequency :onstart
      expect(provider.send(:trigger_type)).to eq(8)
    end

    it "returns 9 if frequency :on_logon" do
      new_resource.frequency :on_logon
      expect(provider.send(:trigger_type)).to eq(9)
    end
  end

  describe "#type" do
    it "returns type hash when frequency :once" do
      new_resource.frequency :once
      new_resource.frequency_modifier 2
      result = provider.send(:type)
      expect(result).to include(:once)
      expect(result).to eq({ once: nil })
    end

    it "returns type hash when frequency :daily" do
      new_resource.frequency :daily
      new_resource.frequency_modifier 2
      result = provider.send(:type)
      expect(result).to include(:days_interval)
      expect(result).to eq({ days_interval: 2 })
    end

    it "returns type hash when frequency :weekly" do
      new_resource.start_day "01/02/2018"
      new_resource.frequency :weekly
      new_resource.frequency_modifier 2
      result = provider.send(:type)
      expect(result).to include(:weeks_interval)
      expect(result).to include(:days_of_week)
      expect(result).to eq({ weeks_interval: 2, days_of_week: 4 })
    end

    it "returns type hash when frequency :monthly" do
      new_resource.frequency :monthly
      result = provider.send(:type)
      expect(result).to include(:months)
      expect(result).to include(:days)
      expect(result).to eq({ months: 4095, days: 1 })
    end

    it "returns type hash when frequency :monthly with frequency_modifier 'first, second, third'" do
      new_resource.start_day "01/02/2018"
      new_resource.frequency :monthly
      new_resource.frequency_modifier "First, Second, third"
      result = provider.send(:type)
      expect(result).to include(:months)
      expect(result).to include(:days_of_week)
      expect(result).to include(:weeks_of_month)
      expect(result).to eq({ months: 4095, days_of_week: 4, weeks_of_month: 7 })
    end

    it "returns type hash when frequency :on_idle" do
      new_resource.frequency :on_idle
      result = provider.send(:type)
      expect(result).to eq(nil)
    end

    it "returns type hash when frequency :onstart" do
      new_resource.frequency :onstart
      result = provider.send(:type)
      expect(result).to eq(nil)
    end

    it "returns type hash when frequency :on_logon" do
      new_resource.frequency :on_logon
      result = provider.send(:type)
      expect(result).to eq(nil)
    end
  end

  describe "#weeks_of_month" do
    it "returns the binary value 1 if frequency_modifier is set as 'first'" do
      new_resource.frequency_modifier "first"
      expect(provider.send(:weeks_of_month)).to eq(1)
    end

    it "returns the binary value 2 if frequency_modifier is set as 'second'" do
      new_resource.frequency_modifier "second"
      expect(provider.send(:weeks_of_month)).to eq(2)
    end

    it "returns the binary value 4 if frequency_modifier is set as 'third'" do
      new_resource.frequency_modifier "third"
      expect(provider.send(:weeks_of_month)).to eq(4)
    end

    it "returns the binary value 8 if frequency_modifier is set as 'fourth'" do
      new_resource.frequency_modifier "fourth"
      expect(provider.send(:weeks_of_month)).to eq(8)
    end

    it "returns the binary value 16 if frequency_modifier is set as 'last'" do
      new_resource.frequency_modifier "last"
      expect(provider.send(:weeks_of_month)).to eq(nil)
    end
  end

  describe "#weeks_of_month" do
    it "returns the binary value 1 if frequency_modifier is set as 'first'" do
      new_resource.frequency_modifier "first"
      expect(provider.send(:weeks_of_month)).to eq(1)
    end

    it "returns the binary value 2 if frequency_modifier is set as 'second'" do
      new_resource.frequency_modifier "second"
      expect(provider.send(:weeks_of_month)).to eq(2)
    end

    it "returns the binary value 4 if frequency_modifier is set as 'third'" do
      new_resource.frequency_modifier "third"
      expect(provider.send(:weeks_of_month)).to eq(4)
    end

    it "returns the binary value 8 if frequency_modifier is set as 'fourth'" do
      new_resource.frequency_modifier "fourth"
      expect(provider.send(:weeks_of_month)).to eq(8)
    end

    it "returns the binary value 16 if frequency_modifier is set as 'last'" do
      new_resource.frequency_modifier "last"
      expect(provider.send(:weeks_of_month)).to eq(nil)
    end

    it "returns the binary value 15 if frequency_modifier is set as 'first, second, third, fourth'" do
      new_resource.frequency_modifier "first, second, third, fourth"
      expect(provider.send(:weeks_of_month)).to eq(15)
    end
  end

  # REF: https://msdn.microsoft.com/en-us/library/windows/desktop/aa382063(v=vs.85).aspx
  describe "#days_of_month" do
    it "returns the binary value 1 if day is set as string 1" do
      new_resource.day "1"
      expect(provider.send(:days_of_month)).to eq(1)
    end

    it "returns the binary value 1 if day is set as integer 1" do
      new_resource.day 1
      expect(provider.send(:days_of_month)).to eq(1)
    end

    it "returns the binary value 2 if day is set as 2" do
      new_resource.day "2"
      expect(provider.send(:days_of_month)).to eq(2)
    end

    it "returns the binary value 1073741824 if day is set as 31" do
      new_resource.day "31"
      expect(provider.send(:days_of_month)).to eq(1073741824)
    end

    it "returns the binary value 131072 if day is set as 18" do
      new_resource.day "18"
      expect(provider.send(:days_of_month)).to eq(131072)
    end
  end

  # Ref : https://msdn.microsoft.com/en-us/library/windows/desktop/aa380729(v=vs.85).aspx
  describe "#days_of_week" do
    it "returns the binary value 2 if day is set as 'Mon'" do
      new_resource.day "Mon"
      expect(provider.send(:days_of_week)).to eq(2)
    end

    it "returns the binary value 4 if day is set as 'Tue'" do
      new_resource.day "Tue"
      expect(provider.send(:days_of_week)).to eq(4)
    end

    it "returns the binary value 8 if day is set as 'Wed'" do
      new_resource.day "Wed"
      expect(provider.send(:days_of_week)).to eq(8)
    end

    it "returns the binary value 16 if day is set as 'Thu'" do
      new_resource.day "Thu"
      expect(provider.send(:days_of_week)).to eq(16)
    end

    it "returns the binary value 32 if day is set as 'Fri'" do
      new_resource.day "Fri"
      expect(provider.send(:days_of_week)).to eq(32)
    end

    it "returns the binary value 64 if day is set as 'Sat'" do
      new_resource.day "Sat"
      expect(provider.send(:days_of_week)).to eq(64)
    end

    it "returns the binary value 1 if day is set as 'Sun'" do
      new_resource.day "Sun"
      expect(provider.send(:days_of_week)).to eq(1)
    end

    it "returns the binary value 127 if day is set as 'Mon, tue, wed, thu, fri, sat, sun'" do
      new_resource.day "Mon, tue, wed, thu, fri, sat, sun"
      expect(provider.send(:days_of_week)).to eq(127)
    end
  end

  # REf: https://msdn.microsoft.com/en-us/library/windows/desktop/aa382064(v=vs.85).aspx
  describe "#monts_of_year" do
    it "returns the binary value 1 if day is set as 'Jan'" do
      new_resource.months "Jan"
      expect(provider.send(:months_of_year)).to eq(1)
    end

    it "returns the binary value 2 if day is set as 'Feb'" do
      new_resource.months "Feb"
      expect(provider.send(:months_of_year)).to eq(2)
    end

    it "returns the binary value 4 if day is set as 'Mar'" do
      new_resource.months "Mar"
      expect(provider.send(:months_of_year)).to eq(4)
    end

    it "returns the binary value 8 if day is set as 'Apr'" do
      new_resource.months "Apr"
      expect(provider.send(:months_of_year)).to eq(8)
    end

    it "returns the binary value 16 if day is set as 'May'" do
      new_resource.months "May"
      expect(provider.send(:months_of_year)).to eq(16)
    end

    it "returns the binary value 32 if day is set as 'Jun'" do
      new_resource.months "Jun"
      expect(provider.send(:months_of_year)).to eq(32)
    end

    it "returns the binary value 64 if day is set as 'Jul'" do
      new_resource.months "Jul"
      expect(provider.send(:months_of_year)).to eq(64)
    end

    it "returns the binary value 128 if day is set as 'Aug'" do
      new_resource.months "Aug"
      expect(provider.send(:months_of_year)).to eq(128)
    end

    it "returns the binary value 256 if day is set as 'Sep'" do
      new_resource.months "Sep"
      expect(provider.send(:months_of_year)).to eq(256)
    end

    it "returns the binary value 512 if day is set as 'Oct'" do
      new_resource.months "Oct"
      expect(provider.send(:months_of_year)).to eq(512)
    end

    it "returns the binary value 1024 if day is set as 'Nov'" do
      new_resource.months "Nov"
      expect(provider.send(:months_of_year)).to eq(1024)
    end

    it "returns the binary value 2048 if day is set as 'Dec'" do
      new_resource.months "Dec"
      expect(provider.send(:months_of_year)).to eq(2048)
    end

    it "returns the binary value 4095 if day is set as 'jan, Feb, mar, apr, may, jun, jul, aug, sep, oct, nov, dec'" do
      new_resource.months "jan, Feb, mar, apr, may, jun, jul, aug, sep, oct, nov, dec"
      expect(provider.send(:months_of_year)).to eq(4095)
    end
  end

  describe "#run_level" do
    it "return binary value 1 for run_level highest" do
      new_resource.run_level :highest
      expect(provider.send(:run_level)).to be(1)
    end

    it "return binary value 1 for run_level limited" do
      new_resource.run_level :limited
      expect(provider.send(:run_level)).to be(0)
    end
  end

  describe "#logon_type" do
    it "return logon_type bindary value as 5 as if password is nil" do
      new_resource.password = nil
      expect(provider.send(:logon_type)).to be(5)
    end

    it "return logon_type bindary value as 1 as if password is not nil" do
      new_resource.user = "Administrator"
      new_resource.password = "abc"
      expect(provider.send(:logon_type)).to be(1)
    end
  end

  describe "#get_day" do
    it "return day if date is provided" do
      expect(provider.send(:get_day, "01/02/2018")).to eq("TUE")
    end
  end
end
