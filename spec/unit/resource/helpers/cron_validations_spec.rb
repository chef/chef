#
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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

require "spec_helper"
require "chef/resource/helpers/cron_validations"

describe Chef::ResourceHelpers::CronValidations do
  context "#validate_dow" do
    it "it accepts a string day" do
      expect(Chef::ResourceHelpers::CronValidations.validate_dow("mon")).to be true
    end

    it "it accepts an integer day" do
      expect(Chef::ResourceHelpers::CronValidations.validate_dow(0)).to be true
    end

    it "it accepts the string of *" do
      expect(Chef::ResourceHelpers::CronValidations.validate_dow("*")).to be true
    end

    it "returns false for an out of range integer" do
      expect(Chef::ResourceHelpers::CronValidations.validate_dow(8)).to be false
    end

    it "it accepts the string day with full name" do
      expect(Chef::ResourceHelpers::CronValidations.validate_dow("monday")).to be true
    end

    it "returns false for an invalid string" do
      expect(Chef::ResourceHelpers::CronValidations.validate_dow("funday")).to be false
    end
  end

  context "#validate_month" do
    it "it accepts a string month" do
      expect(Chef::ResourceHelpers::CronValidations.validate_month("feb")).to be true
    end

    it "it accepts an integer month" do
      expect(Chef::ResourceHelpers::CronValidations.validate_month(2)).to be true
    end

    it "it accepts the string of *" do
      expect(Chef::ResourceHelpers::CronValidations.validate_month("*")).to be true
    end

    it "returns false for an out of range integer" do
      expect(Chef::ResourceHelpers::CronValidations.validate_month(13)).to be false
    end

    it "returns false for an invalid string (typo)" do
      expect(Chef::ResourceHelpers::CronValidations.validate_month("janurary")).to be false
    end
  end

  context "#validate_numeric" do
    it "returns true if the value is in the allowed range" do
      expect(Chef::ResourceHelpers::CronValidations.validate_numeric(5, 1, 100)).to be true
    end

    it "returns false if the value less than the allowed range" do
      expect(Chef::ResourceHelpers::CronValidations.validate_numeric(-1, 1, 100)).to be false
    end

    it "returns false if the value more than the allowed range" do
      expect(Chef::ResourceHelpers::CronValidations.validate_numeric(101, 1, 100)).to be false
    end
  end
end
