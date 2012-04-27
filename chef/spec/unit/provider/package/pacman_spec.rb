#
# Author:: Jan Zimmek (<jan.zimmek@web.de>)
# Copyright:: Copyright (c) 2010 Jan Zimmek
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

describe Chef::Provider::Package::Pacman do
  include SpecHelpers::Providers::Package

  let(:package_name) { 'nano' }
  let(:stdin) { StringIO.new }
  let(:stdout) { pacman_output_without_package }

  let(:assume_installed_version) { provider.should_receive(:installed_version).and_return(installed_version) }
  let(:installed_version) { '2.2.2-1' }

  let(:pacman_output_without_package) { StringIO.new(<<-ERR) }
error: package "nano" not found
ERR

  let(:pacman_output_with_package) { StringIO.new(<<-PACMAN) }
Name           : nano
Version        : 2.2.2-1
URL            : http://www.nano-editor.org
Licenses       : GPL
Groups         : base
Provides       : None
Depends On     : glibc  ncurses
Optional Deps  : None
Required By    : None
Conflicts With : None
Replaces       : None
Installed Size : 1496.00 K
Packager       : Andreas Radke <andyrtr@archlinux.org>
Architecture   : i686
Build Date     : Mon 18 Jan 2010 06:16:16 PM CET
Install Date   : Mon 01 Feb 2010 10:06:30 PM CET
Install Reason : Explicitly installed
Install Script : Yes
Description    : Pico editor clone with enhancements
PACMAN

    let(:pacman_query_output) { StringIO.new(<<-END) }
core/nano 2.2.3-1 (base)
    Pico editor clone with enhancements
community/nanoblogger 3.4.1-1
    NanoBlogger is a small weblog engine written in Bash for the command line
END

  context "#load_current_resource" do
    subject { given; provider.load_current_resource }
    let(:given) { assume_installed_version }

    it "should create a current resource with the name of the new_resource" do
      subject.name.should eql(new_resource.name)
    end

    it "should set the current resources package name to the new resources package name" do
      subject.package_name.should eql(new_resource.package_name)
    end

    it 'should set current installed version' do
      subject.version.should eql(installed_version)
    end

    it "should return the current resouce" do
      subject
      should eql(provider.current_resource)
    end
  end

  describe "#install_package" do
    it "should run pacman install with the package name and version" do
      provider.should_receive(:shell_out_with_systems_locale!).with("pacman --sync --noconfirm --noprogressbar nano")
      provider.install_package("nano", "1.0")
    end

    it "should run pacman install with the package name and version and options if specified" do
      provider.should_receive(:shell_out_with_systems_locale!).with("pacman --sync --noconfirm --noprogressbar --debug nano")
      new_resource.stub!(:options).and_return("--debug")

      provider.install_package("nano", "1.0")
    end
  end

  describe "#upgrade_package" do
    it "should run install_package with the name and version" do
      provider.should_receive(:install_package).with("nano", "1.0")
      provider.upgrade_package("nano", "1.0")
    end
  end

  describe "#remove_package" do
    it "should run pacman remove with the package name" do
      provider.should_receive(:shell_out_with_systems_locale!).with("pacman --remove --noconfirm --noprogressbar nano")
      provider.remove_package("nano", "1.0")
    end

    it "should run pacman remove with the package name and options if specified" do
      provider.should_receive(:shell_out_with_systems_locale!).with("pacman --remove --noconfirm --noprogressbar --debug nano" )
      new_resource.stub!(:options).and_return("--debug")

      provider.remove_package("nano", "1.0")
    end
  end

  describe "#purge_package" do
    it "should run remove_package with the name and version" do
      provider.should_receive(:remove_package).with("nano", "1.0")
      provider.purge_package("nano", "1.0")
    end
  end

  describe '#candidate_version' do
    subject { given; provider.candidate_version }

    let(:given) do
      provider.new_resource = new_resource
      should_shell_out!
    end

    context 'with available version' do
      let(:stdout) { pacman_query_output }

      it "should return candidate version" do
        should eql("2.2.3-1")
      end

      it 'should memoize candidate version' do
        provider.instance_variable_get(:@candidate_version).should be_nil

        should_not be_nil
        provider.instance_variable_get(:@candidate_version).should eql('2.2.3-1')
      end
    end

    context 'without available version' do
      let(:stdout) { StringIO.new }

      it "should raise an exception if pacman does not return a candidate version" do
        lambda { subject }.should raise_error(Chef::Exceptions::Package)
      end
    end
  end

  describe '#installed_version' do
    subject { given; provider.installed_version }

    let(:given) do
      assume_new_resource
      should_shell_out!
    end

    let(:assume_new_resource) { new_resource }

    it "should run pacman query with the package name" do
      provider.should_receive(:shell_out!).with("pacman -Qi #{new_resource.package_name}").and_return(status)
      provider.installed_version
    end

    context 'without installed package' do
      it { should be_nil }
    end

    context 'with installed package' do
      let(:stdout) { pacman_output_with_package }

      it "should return the version" do
        should eql("2.2.2-1")
      end
    end

    context 'when `pacman` exits with 2' do
      let(:exitstatus) { 2 }

      it "should raise Chef::Exceptions::Package" do
        lambda { subject }.should raise_error(Chef::Exceptions::Package)
      end
    end

    context 'when `pacman` exits with 0' do
      let(:exitstatus) { 0 }

      it "should not raise Chef::Exceptions::Package" do
        lambda { subject .should_not raise_error(Chef::Exceptions::Package) }
      end
    end
  end
end
