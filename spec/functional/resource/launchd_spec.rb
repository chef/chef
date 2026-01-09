#
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

# Deploy relies heavily on symlinks, so it doesn't work on windows.
describe Chef::Resource::Launchd, :macos_only, requires_root: true do
  include RecipeDSLHelper

  before(:each) do
    shell_out("launchctl unload -wF /Library/LaunchDaemons/io.chef.testing.fake.plist")
    FileUtils.rm_f "/Library/LaunchDaemons/io.chef.testing.fake.plist"
  end

  after(:each) do
    shell_out("launchctl unload -wF /Library/LaunchDaemons/io.chef.testing.fake.plist")
    FileUtils.rm_f "/Library/LaunchDaemons/io.chef.testing.fake.plist"
  end

  context ":enable" do
    it "enables a service" do
      launchd "io.chef.testing.fake" do
        program_arguments [
          "/bin/sleep",
          "60",
        ]
        run_at_load true
        type "daemon"
        action :enable
      end.should_be_updated
      expect(File.exist?("/Library/LaunchDaemons/io.chef.testing.fake.plist")).to be true
      expect(shell_out!("launchctl list io.chef.testing.fake").stdout).to match('"PID" = \d+')
      expect(shell_out!("launchctl list io.chef.testing.fake").stdout).not_to match('"PID" = 0')
    end

    it "should be idempotent" do
      launchd "io.chef.testing.fake" do
        program_arguments [
          "/bin/sleep",
          "60",
        ]
        run_at_load true
        type "daemon"
        action :enable
      end.should_be_updated
      launchd "io.chef.testing.fake" do
        program_arguments [
          "/bin/sleep",
          "60",
        ]
        run_at_load true
        type "daemon"
        action :enable
      end.should_not_be_updated
    end
  end

  context ":create" do
    it "creates a service" do
      launchd "io.chef.testing.fake" do
        program_arguments [
          "/bin/sleep",
          "60",
        ]
        run_at_load true
        type "daemon"
        action :create
      end.should_be_updated
      expect(File.exist?("/Library/LaunchDaemons/io.chef.testing.fake.plist")).to be true
      expect(shell_out("launchctl list io.chef.testing.fake").exitstatus).not_to eql(0)
    end

    it "should be idempotent" do
      launchd "io.chef.testing.fake" do
        program_arguments [
          "/bin/sleep",
          "60",
        ]
        run_at_load true
        type "daemon"
        action :create
      end.should_be_updated
      launchd "io.chef.testing.fake" do
        program_arguments [
          "/bin/sleep",
          "60",
        ]
        run_at_load true
        type "daemon"
        action :create
      end.should_not_be_updated
    end
  end

  context ":create_if_missing" do
    it "creates a service if it is missing" do
      launchd "io.chef.testing.fake" do
        program_arguments [
          "/bin/sleep",
          "60",
        ]
        run_at_load true
        type "daemon"
        action :create_if_missing
      end.should_be_updated
      expect(File.exist?("/Library/LaunchDaemons/io.chef.testing.fake.plist")).to be true
      expect(shell_out("launchctl list io.chef.testing.fake").exitstatus).not_to eql(0)
    end
    it "is idempotent" do
      launchd "io.chef.testing.fake" do
        program_arguments [
          "/bin/sleep",
          "60",
        ]
        run_at_load true
        type "daemon"
        action :create_if_missing
      end.should_be_updated
      launchd "io.chef.testing.fake" do
        program_arguments [
          "/bin/sleep",
          "60",
        ]
        run_at_load true
        type "daemon"
        action :create_if_missing
      end.should_not_be_updated
    end
  end

  context ":delete" do
    it "deletes a service" do
      launchd "io.chef.testing.fake" do
        program_arguments [
          "/bin/sleep",
          "60",
        ]
        run_at_load true
        type "daemon"
        action :enable
      end
      launchd "io.chef.testing.fake" do
        type "daemon"
        action :delete
      end.should_be_updated
      expect(File.exist?("/Library/LaunchDaemons/io.chef.testing.fake.plist")).to be false
      expect(shell_out("launchctl list io.chef.testing.fake").exitstatus).not_to eql(0)
    end
    it "is idempotent" do
      launchd "io.chef.testing.fake" do
        program_arguments [
          "/bin/sleep",
          "60",
        ]
        run_at_load true
        type "daemon"
        action :enable
      end
      launchd "io.chef.testing.fake" do
        type "daemon"
        action :delete
      end.should_be_updated
      launchd "io.chef.testing.fake" do
        type "daemon"
        action :delete
      end.should_not_be_updated
    end
    it "works if the file does not exist" do
      launchd "io.chef.testing.fake" do
        type "daemon"
        action :delete
      end.should_not_be_updated
    end
  end

  context ":disable" do
    it "deletes a service" do
      launchd "io.chef.testing.fake" do
        program_arguments [
          "/bin/sleep",
          "1",
        ]
        type "daemon"
        action :enable
      end
      launchd "io.chef.testing.fake" do
        type "daemon"
        action :disable
      end.should_be_updated
      expect(File.exist?("/Library/LaunchDaemons/io.chef.testing.fake.plist")).to be true
      expect(shell_out("launchctl list io.chef.testing.fake").exitstatus).not_to eql(0)
    end
    it "is idempotent" do
      launchd "io.chef.testing.fake" do
        program_arguments [
          "/bin/sleep",
          "1",
        ]
        type "daemon"
        action :enable
      end
      launchd "io.chef.testing.fake" do
        type "daemon"
        action :disable
      end.should_be_updated
      launchd "io.chef.testing.fake" do
        type "daemon"
        action :disable
      end.should_not_be_updated
    end
    it "should work if the plist does not exist" do
      launchd "io.chef.testing.fake" do
        type "daemon"
        action :disable
      end.should_not_be_updated
    end
  end
end
