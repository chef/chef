# frozen_string_literal: true
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

RSpec.describe ChefUtils::DSL::Service do
  class ServiceTestClass
    include ChefUtils::DSL::Service
  end

  let(:test_instance) { ServiceTestClass.new }

  context "#debianrcd?" do
    it "is true if the binary is installed" do
      expect(File).to receive(:exist?).with("/usr/sbin/update-rc.d").and_return(true)
      expect(test_instance.debianrcd?).to be true
    end
    it "is false if the binary is not installed" do
      expect(File).to receive(:exist?).with("/usr/sbin/update-rc.d").and_return(false)
      expect(test_instance.debianrcd?).to be false
    end
  end

  context "#invokercd?" do
    it "is true if the binary is installed" do
      expect(File).to receive(:exist?).with("/usr/sbin/invoke-rc.d").and_return(true)
      expect(test_instance.invokercd?).to be true
    end
    it "is false if the binary is not installed" do
      expect(File).to receive(:exist?).with("/usr/sbin/invoke-rc.d").and_return(false)
      expect(test_instance.invokercd?).to be false
    end
  end

  context "#upstart?" do
    it "is true if the binary is installed" do
      expect(File).to receive(:exist?).with("/sbin/initctl").and_return(true)
      expect(test_instance.upstart?).to be true
    end
    it "is false if the binary is not installed" do
      expect(File).to receive(:exist?).with("/sbin/initctl").and_return(false)
      expect(test_instance.upstart?).to be false
    end
  end

  context "#insserv?" do
    it "is true if the binary is installed" do
      expect(File).to receive(:exist?).with("/sbin/insserv").and_return(true)
      expect(test_instance.insserv?).to be true
    end
    it "is false if the binary is not installed" do
      expect(File).to receive(:exist?).with("/sbin/insserv").and_return(false)
      expect(test_instance.insserv?).to be false
    end
  end

  context "#redhatrcd?" do
    it "is true if the binary is installed" do
      expect(File).to receive(:exist?).with("/sbin/chkconfig").and_return(true)
      expect(test_instance.redhatrcd?).to be true
    end
    it "is false if the binary is not installed" do
      expect(File).to receive(:exist?).with("/sbin/chkconfig").and_return(false)
      expect(test_instance.redhatrcd?).to be false
    end
  end

  context "#service_script_exist?" do
    it "is true if the type is :initd and /etc/init.d script exists" do
      expect(File).to receive(:exist?).with("/etc/init.d/example").and_return(true)
      expect(test_instance.service_script_exist?(:initd, "example")).to be true
    end
    it "is false if the type is :initd and /etc/init.d script does not exist" do
      expect(File).to receive(:exist?).with("/etc/init.d/example").and_return(false)
      expect(test_instance.service_script_exist?(:initd, "example")).to be false
    end
    it "is true if the type is :upstart and /etc/init script exists" do
      expect(File).to receive(:exist?).with("/etc/init/example.conf").and_return(true)
      expect(test_instance.service_script_exist?(:upstart, "example")).to be true
    end
    it "is false if the type is :upstart and /etc/init script does not exist" do
      expect(File).to receive(:exist?).with("/etc/init/example.conf").and_return(false)
      expect(test_instance.service_script_exist?(:upstart, "example")).to be false
    end
    it "is true if the type is :xinetd and /etc/xinetd.d script exists" do
      expect(File).to receive(:exist?).with("/etc/xinetd.d/example").and_return(true)
      expect(test_instance.service_script_exist?(:xinetd, "example")).to be true
    end
    it "is false if the type is :xinetd and /etc/xinetd.d script does not exist" do
      expect(File).to receive(:exist?).with("/etc/xinetd.d/example").and_return(false)
      expect(test_instance.service_script_exist?(:xinetd, "example")).to be false
    end
    it "is true if the type is :etc_rcd and /etc/rc.d script exists" do
      expect(File).to receive(:exist?).with("/etc/rc.d/example").and_return(true)
      expect(test_instance.service_script_exist?(:etc_rcd, "example")).to be true
    end
    it "is false if the type is :etc_rcd and /etc/rc.d script does not exist" do
      expect(File).to receive(:exist?).with("/etc/rc.d/example").and_return(false)
      expect(test_instance.service_script_exist?(:etc_rcd, "example")).to be false
    end
  end
end
