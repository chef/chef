#
# Copyright:: Copyright 2018, Chef Software, Inc.
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

describe Chef::Resource::CronD do
  let(:resource) { Chef::Resource::CronD.new("cronify") }

  it "has a default action of [:create]" do
    expect(resource.action).to eql([:create])
  end

  it "accepts create or delete for action" do
    expect { resource.action :create }.not_to raise_error
    expect { resource.action :delete }.not_to raise_error
    expect { resource.action :lolcat }.to raise_error(ArgumentError)
  end

  it "the cron_name property is the name_property" do
    expect(resource.cron_name).to eql("cronify")
  end

  context "#validate_dow" do
    it "it accepts a string day" do
      expect(Chef::Resource::CronD.validate_dow("mon")).to be true
    end

    it "it accepts an integer day" do
      expect(Chef::Resource::CronD.validate_dow(0)).to be true
    end

    it "it accepts the string of *" do
      expect(Chef::Resource::CronD.validate_dow("*")).to be true
    end

    it "returns false for an out of range integer" do
      expect(Chef::Resource::CronD.validate_dow(8)).to be false
    end

    it "returns false for an invalid string" do
      expect(Chef::Resource::CronD.validate_dow("monday")).to be false
    end
  end

  context "#validate_month" do
    it "it accepts a string month" do
      expect(Chef::Resource::CronD.validate_month("feb")).to be true
    end

    it "it accepts an integer month" do
      expect(Chef::Resource::CronD.validate_month(2)).to be true
    end

    it "it accepts the string of *" do
      expect(Chef::Resource::CronD.validate_month("*")).to be true
    end

    it "returns false for an out of range integer" do
      expect(Chef::Resource::CronD.validate_month(13)).to be false
    end

    it "returns false for an invalid string" do
      expect(Chef::Resource::CronD.validate_month("janurary")).to be false
    end
  end

  context "#validate_numeric" do
    it "returns true if the value is in the allowed range" do
      expect(Chef::Resource::CronD.validate_numeric(5, 1, 100)).to be true
    end

    it "returns false if the value is out of the allowed range" do
      expect(Chef::Resource::CronD.validate_numeric(-1, 1, 100)).to be false
    end
  end
end
