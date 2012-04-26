#
# Author:: Toomas Pelberg (<toomasp@gmx.net>)
# Copyright:: Copyright (c) 2010 Opscode, Inc.
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

describe Chef::Provider::Package::Solaris do
  include SpecHelpers::Providers::Package

  let(:new_resource) { Chef::Resource::Package.new(package_name).tap(&with_attributes.call(new_resource_attributes)) }

  let(:assume_source_package_exists) { ::File.stub!(:exists?).and_return(true) }
  let(:assume_source_version) { provider.should_receive(:source_version).and_return(source_version) }
  let(:assume_installed_version) { provider.should_receive(:installed_version).and_return(installed_version) }
  let(:should_shell_out) { provider.should_receive(:shell_out!).and_return(status) }

  let(:source_file) { '/tmp/bash.pkg' }
  let(:package_name) { 'SUNWbash' }
  let(:source_version) { "11.10.0,REV=2005.01.08.05.16" }
  let(:installed_version) { source_version }

  let(:new_resource_attributes) { { :source => source_file } }

  let(:pkginfo) { <<PKGINFO }
PKGINST:  SUNWbash
NAME:  GNU Bourne-Again shell (bash)
CATEGORY:  system
ARCH:  sparc
VERSION:  11.10.0,REV=2005.01.08.05.16
BASEDIR:  /
VENDOR:  Sun Microsystems, Inc.
DESC:  GNU Bourne-Again shell (bash) version 3.0
PSTAMP:  sfw10-patch20070430084444
INSTDATE:  Nov 04 2009 01:02
HOTLINE:  Please contact your local service provider
PKGINFO

  describe "#load_current_resource" do
    subject { given; provider.load_current_resource }

    let(:given) do
      new_resource.source source_file
      assume_source_version
      assume_installed_version
    end

    it "should create a current resource with the name of new_resource" do
      subject.name.should eql(new_resource.name)
    end

    it "should set the current reource package name to the new resource package name" do
      subject.package_name.should eql(new_resource.package_name)
    end

    context 'when installing' do
      it "should raise an exception if the source is not set but we are installing" do
        lambda { provider.load_current_resource }.should raise_error(Chef::Exceptions::Package)
      end
    end

    context 'with source version' do
      let(:source_version) { rand(1000000).to_s }

      it 'should set source version' do
        subject
        provider.new_resource.version.should eql(source_version)
      end
    end

    context 'with current version' do
      let(:installed_version) { rand(1000000).to_s }

      it 'should set current version' do
        subject.version.should eql(installed_version)
      end
    end
  end

  describe "#install_package" do
    it "should run pkgadd -n -d with the package source to install" do
      provider.should_receive(:shell_out_with_systems_locale!).with("pkgadd -n -d /tmp/bash.pkg all")
      provider.install_package("SUNWbash", "11.10.0,REV=2005.01.08.05.16")
    end

    it "should run pkgadd -n -d when the package is a path to install" do
      provider.should_receive(:shell_out_with_systems_locale!).with("pkgadd -n -d /tmp/bash.pkg all")
      provider.install_package("/tmp/bash.pkg", "11.10.0,REV=2005.01.08.05.16")
    end

    it "should run pkgadd -n -a /tmp/myadmin -d with the package options -a /tmp/myadmin" do
      new_resource.stub!(:options).and_return("-a /tmp/myadmin")
      provider.should_receive(:shell_out_with_systems_locale!).with("pkgadd -n -a /tmp/myadmin -d /tmp/bash.pkg all")
      provider.install_package("SUNWbash", "11.10.0,REV=2005.01.08.05.16")
    end
  end

  describe "#remove_package" do
    it "should run pkgrm -n to remove the package" do
      provider.should_receive(:shell_out_with_systems_locale!).with("pkgrm -n SUNWbash")
      provider.remove_package("SUNWbash", "11.10.0,REV=2005.01.08.05.16")
    end

    it "should run pkgrm -n -a /tmp/myadmin with options -a /tmp/myadmin" do
      new_resource.stub!(:options).and_return("-a /tmp/myadmin")
      provider.should_receive(:shell_out_with_systems_locale!).with("pkgrm -n -a /tmp/myadmin SUNWbash")
      provider.remove_package("SUNWbash", "11.10.0,REV=2005.01.08.05.16")
    end
  end

  describe '#candidate_version' do
    let(:version) { rand(100000).to_s }

    it "should lookup the candidate_version if the variable is not already set" do
      provider.should_receive(:source_version).and_return(version)
      provider.candidate_version.should eql(version)
    end

    it 'should set candidate_version' do
      provider.should_receive(:source_version).and_return(version)
      provider.candidate_version
      provider.instance_variable_get(:@candidate_version).should eql(version)
    end
  end

  describe '#source_version' do
    subject { given; provider.source_version }
    let(:given) do
      assume_source_package_exists
      should_shell_out
    end

    let(:stdout) { StringIO.new(pkginfo) }
    let(:assume_source_package_exists) { provider.stub!(:assert_source_file_exists!) }
    let(:assume_source_package_not_found) { ::File.stub!(:exists?).and_return(false) }
    let(:should_shell_out) {  provider.should_receive(:shell_out!).with("pkginfo -l -d #{source_file} #{package_name}").and_return(status) }

    it "should should shell out to `pkginfo`" do
      should_not be_nil
    end

    it "should get version from package info" do
      should eql("11.10.0,REV=2005.01.08.05.16")
    end

    context 'when source package is not found' do
      let(:given) { assume_source_package_not_found }

      it "should raise an exception if a source is supplied but not found" do
        lambda { subject }.should raise_error(Chef::Exceptions::Package)
      end
    end

    context 'when `pkginfo` exits with 0' do
      let(:exitstatus) { 0 }

      it "should not raise Chef::Exceptions::Package" do
        lambda { subject }.should_not raise_error(Chef::Exceptions::Package)
      end
    end

    context 'when `pkginfo` exits with 1' do
      let(:exitstatus) { 1 }

      it "should raise an exception if rpm fails to run" do
        lambda { subject }.should raise_error(Chef::Exceptions::Package)
      end
    end
  end

  describe '#installed_version' do
    subject { given; provider.installed_version }
    let(:given) do
      should_shell_out
      provider.current_resource = current_resource
    end

    let(:should_shell_out) { provider.should_receive(:shell_out!).with("pkginfo -l #{package_name}").and_return(status) }
    let(:stdout) { StringIO.new(pkginfo) }

    it 'should shell out to `pkginfo`' do
      should_not be_nil
    end

    it "should return the current version installed" do
      should eql("11.10.0,REV=2005.01.08.05.16")
    end

    context 'when unable to find package' do
      let(:stdout) { StringIO.new }

      it "should return a current resource with a nil version if the package is not found" do
        should be_nil
      end
    end

    context 'when `pkginfo` exits with 0' do
      let(:exitstatus) { 0 }

      it "should not raise Chef::Exceptions::Package" do
        lambda { subject }.should_not raise_error(Chef::Exceptions::Package)
      end
    end

    context 'when `pkginfo` exits with 1' do
      let(:exitstatus) { 1 }

      it "should not raise Chef::Exceptions::Package" do
        lambda { subject }.should_not raise_error(Chef::Exceptions::Package)
      end
    end

    context 'when `pkginfo` exits with -1' do
      let(:exitstatus) { -1 }

      it "should raise Chef::Exceptions::Package" do
        lambda { subject }.should raise_error(Chef::Exceptions::Package)
      end
    end

  end
end
