#
# Author:: Tim Smith (<tsmith@chef.io>)
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
describe Chef::Resource::UserUlimit do
  let(:node) { Chef::Node.new }
  let(:events) { Chef::EventDispatch::Dispatcher.new }
  let(:run_context) { Chef::RunContext.new(node, {}, events) }
  let(:resource) { Chef::Resource::UserUlimit.new("fakey_fakerton", run_context) }

  it "the username property is the name_property" do
    expect(resource.username).to eql("fakey_fakerton")
  end

  it "sets the default action as :create" do
    expect(resource.action).to eql([:create])
  end

  it "coerces filename value to end in .conf" do
    resource.filename("foo")
    expect(resource.filename).to eql("foo.conf")
  end

  it "if username is * then the filename defaults to 00_all_limits.conf" do
    resource.username("*")
    expect(resource.filename).to eql("00_all_limits.conf")
  end

  it "if username is NOT * then the filename defaults to USERNAME_limits.conf" do
    expect(resource.filename).to eql("fakey_fakerton_limits.conf")
  end

  it "supports :create and :delete actions" do
    expect { resource.action :create }.not_to raise_error
    expect { resource.action :delete }.not_to raise_error
  end

  describe "sensitive attribute" do
    context "should be insensitive by default" do
      it { expect(resource.sensitive).to(be_falsey) }
    end

    context "when set" do
      before { resource.sensitive(true) }

      it "should be set on the resource" do
        expect(resource.sensitive).to(be_truthy)
      end
    end
  end

  describe "#solaris_project_name" do
    it "builds the project(4) name from the username" do
      resource.username("tomcat")
      expect(resource.solaris_project_name).to eql("user.tomcat")
    end
  end

  describe "#solaris_project_exists?" do
    it "returns true when the project line is present in /etc/project" do
      allow(::TargetIO::File).to receive(:read).with("/etc/project")
        .and_return("default:3:Default Project:::\nuser.tomcat:100::tomcat::\n")
      expect(resource.solaris_project_exists?("user.tomcat")).to be true
    end

    it "returns false when the project line is absent from /etc/project" do
      allow(::TargetIO::File).to receive(:read).with("/etc/project")
        .and_return("default:3:Default Project:::\n")
      expect(resource.solaris_project_exists?("user.tomcat")).to be false
    end

    it "returns false when /etc/project cannot be read" do
      allow(::TargetIO::File).to receive(:read).with("/etc/project").and_raise(Errno::ENOENT)
      expect(resource.solaris_project_exists?("user.tomcat")).to be false
    end
  end

  describe "#solaris_rctl_clauses" do
    it "sets both basic and privileged to the same value when only the unsuffixed value is given" do
      expect(resource.solaris_rctl_clauses(8192, nil, nil)).to eql(
        ["(basic,8192,deny)", "(privileged,8192,deny)"]
      )
    end

    it "sets only basic when only a soft value is given" do
      expect(resource.solaris_rctl_clauses(nil, 1024, nil)).to eql(["(basic,1024,deny)"])
    end

    it "sets only privileged when only a hard value is given" do
      expect(resource.solaris_rctl_clauses(nil, nil, 2048)).to eql(["(privileged,2048,deny)"])
    end

    it "sets both when soft and hard are both given" do
      expect(resource.solaris_rctl_clauses(nil, 1024, 2048)).to eql(
        ["(basic,1024,deny)", "(privileged,2048,deny)"]
      )
    end

    it "returns an empty array when nothing is given" do
      expect(resource.solaris_rctl_clauses(nil, nil, nil)).to eql([])
    end
  end

  describe "#solaris_rctl_set?" do
    it "returns true when every required clause is present on the project's line" do
      allow(::TargetIO::File).to receive(:read).with("/etc/project").and_return(
        "user.tomcat:100::tomcat::process.max-file-descriptor=(basic,8192,deny),(privileged,8192,deny)\n"
      )
      expect(
        resource.solaris_rctl_set?("user.tomcat", ["(basic,8192,deny)", "(privileged,8192,deny)"])
      ).to be true
    end

    it "returns false when a required clause is missing" do
      allow(::TargetIO::File).to receive(:read).with("/etc/project").and_return(
        "user.tomcat:100::tomcat::process.max-file-descriptor=(basic,8192,deny)\n"
      )
      expect(
        resource.solaris_rctl_set?("user.tomcat", ["(basic,8192,deny)", "(privileged,8192,deny)"])
      ).to be false
    end

    it "returns false when the project does not exist" do
      allow(::TargetIO::File).to receive(:read).with("/etc/project").and_return("default:3:Default Project:::\n")
      expect(resource.solaris_rctl_set?("user.tomcat", ["(basic,8192,deny)"])).to be false
    end
  end

  describe "#raise_if_unsupported_solaris_properties!" do
    it "does not raise when only supported properties are set" do
      resource.filehandle_limit(8192)
      resource.cpu_limit(60)
      expect { resource.raise_if_unsupported_solaris_properties! }.not_to raise_error
    end

    it "raises when an unsupported property is set" do
      resource.maxlogins_limit(5)
      expect { resource.raise_if_unsupported_solaris_properties! }
        .to raise_error(Chef::Exceptions::UnsupportedAction, /maxlogins_limit/)
    end

    it "raises listing every unsupported property that was set" do
      resource.locks_limit(10)
      resource.rtprio_limit(20)
      expect { resource.raise_if_unsupported_solaris_properties! }
        .to raise_error(Chef::Exceptions::UnsupportedAction, /locks_limit.*rtprio_limit/)
    end
  end

  describe "#raise_unless_target_mode_for_solaris!" do
    it "does not raise when Target Mode is active" do
      allow(ChefConfig::Config).to receive(:target_mode?).and_return(true)
      expect { resource.raise_unless_target_mode_for_solaris! }.not_to raise_error
    end

    it "raises when Target Mode is not active" do
      allow(ChefConfig::Config).to receive(:target_mode?).and_return(false)
      expect { resource.raise_unless_target_mode_for_solaris! }
        .to raise_error(RuntimeError, /only available in Target Mode/)
    end
  end

  describe "#solaris_shell_command" do
    it "joins tokens into a single space-separated string" do
      expect(resource.solaris_shell_command("projadd", "-U", "tomcat", "user.tomcat"))
        .to eql("projadd -U tomcat user.tomcat")
    end

    it "shell-escapes tokens containing parentheses, so the remote shell does not " \
       "misinterpret them as subshell syntax (the bug behind this fix)" do
         command = resource.solaris_shell_command(
           "projmod", "-s", "-K",
           "process.max-file-descriptor=(basic,8192,deny),(privileged,8192,deny)",
           "user.tomcat"
         )
         expect(command).to eql(
           "projmod -s -K process.max-file-descriptor\\=\\(basic,8192,deny\\),\\(privileged,8192,deny\\) user.tomcat"
         )
       end
  end
end
