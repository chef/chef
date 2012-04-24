#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2008 Opscode, Inc.
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

require 'spec_helper'

describe Chef::Provider::Package::Zypper do
  include SpecHelpers::Providers::Package

  let(:given) do
    assume_zypper_info
    assume_zypper_version
  end

  let(:assume_zypper_info) { provider.stub!(:shell_out!).and_return(status) }
  let(:assume_zypper_version) { provider.stub!(:zypper_version).and_return(zypper_version) }
  let(:zypper_version) { 2.0 }

  describe "#load_current_resource" do
    subject { given; provider.load_current_resource }

    it "should return the current resouce" do
      subject.should eql(provider.current_resource)
    end

    it "should create a current resource with the name of the new_resource" do
      subject.name.should eql(new_resource.name)
    end

    it "should set the current resources package name to the new resources package name" do
      subject.package_name.should eql(new_resource.package_name)
    end

    it "should not raise Chef::Exceptions::Package" do
      lambda { subject }.should_not raise_error(Chef::Exceptions::Package)
    end

    it "should run zypper info with the package name" do
      provider.should_receive(:shell_out!).with("zypper info #{new_resource.package_name}").and_return(status)
      provider.load_current_resource
    end

    context 'when zypper info installed version is (none)' do
      let(:stdout) { StringIO.new('(none)') }
      it "should set the installed version to nil on the current resource if zypper info installed version is (none)" do
        subject.version.should be_nil
      end
    end

    context 'when zypper info reports an installed version' do
      let(:stdout) { StringIO.new("Version: 1.0\nInstalled: Yes\n") }

      it "should set the installed version if zypper info has one" do
        subject.version.should eql('1.0')
      end
    end

    context 'when zypper info reports an outdated, available version' do
      let(:stdout) { StringIO.new("Version: 1.0\nInstalled: No\nStatus: out-of-date (version 0.9 installed)") }

      it "should set version to current, outdated version" do
        subject
        provider.current_resource.version.should eql('0.9')
      end

      it "should set the candidate version" do
        should_not be_nil
        provider.candidate_version.should eql("1.0")
      end
    end

    context 'when zypper info fails' do
      let(:exitstatus) { 1 }
      it "should raise an exception if zypper info fails" do
        lambda { subject }.should raise_error(Chef::Exceptions::Package)
      end
    end
  end

  describe "#install_package" do
    it "should run zypper install with the package name and version" do
      assume_zypper_version
      provider.should_receive(:shell_out!).with("zypper -n --no-gpg-checks install -l  emacs=1.0")
      provider.install_package("emacs", "1.0")
    end
  end

  describe "#upgrade_package" do
    it "should run zypper update with the package name and version" do
      assume_zypper_version
      provider.should_receive(:shell_out!).with("zypper -n --no-gpg-checks install -l emacs=1.0")
      provider.upgrade_package("emacs", "1.0")
    end
  end

  describe "#remove_package" do
    it "should run zypper remove with the package name" do
      assume_zypper_version
      provider.should_receive(:shell_out!).with("zypper -n --no-gpg-checks remove  emacs=1.0")
      provider.remove_package("emacs", "1.0")
    end
  end

  describe "#purge_package" do
    it "should run remove_package with the name and version" do
      assume_zypper_version
      provider.should_receive(:remove_package).with("emacs", "1.0")
      provider.purge_package("emacs", "1.0")
    end
  end

  context "with an older zypper" do
    let(:zypper_version) { '0.11.6'.to_f }

    describe "#install_package" do
      it "should run zypper install with the package name and version" do
        assume_zypper_version
        provider.should_receive(:shell_out!).with("zypper install -y emacs")
        provider.install_package("emacs", "1.0")
      end
    end

    describe "#upgrade_package" do
      it "should run zypper update with the package name and version" do
        assume_zypper_version
        provider.should_receive(:shell_out!).with("zypper install -y emacs")
        provider.upgrade_package("emacs", "1.0")
      end
    end

    describe "#remove_package" do
      it "should run zypper remove with the package name" do
        assume_zypper_version
        provider.should_receive(:shell_out!).with("zypper remove -y emacs")
        provider.remove_package("emacs", "1.0")
      end
    end
  end

  describe '#zypper_version'
end
