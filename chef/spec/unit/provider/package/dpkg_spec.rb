#
# Author:: Bryan McLellan (btm@loftninjas.org)
# Copyright:: Copyright (c) 2009 Bryan McLellan
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

describe Chef::Provider::Package::Dpkg do
  include SpecHelpers::Providers::Package

  let(:package_name) { 'wget' }

  let(:pid) { mock("PID") }
  let(:assume_dpkg_exists) { provider.stub!(:assert_dpkg_exists!).and_return(dpkg_exists?) }
  let(:assume_source) { new_resource.source source_file }
  let(:assume_options) { new_resource.options '--force-yes' }
  let(:assume_package_name_and_version) { provider.stub!(:package_name_and_version).and_return([package_name, package_version]) }
  let(:assume_installed_version) { provider.stub!(:installed_version).and_return(installed_version) }

  let(:installed_version) { package_version }
  let(:should_shell_out_with_systems_locale!) do
    provider.
      should_receive(:shell_out_with_systems_locale!).
      with(dpkg_cmd, :environment => environment)
  end
  let(:source_file) { "/tmp/wget_1.11.4-1ubuntu1_amd64.deb" }
  let(:package_version) { "1.11.4-1ubuntu1" }
  let(:dpkg_exists?) { true }

  let(:environment) { { "DEBIAN_FRONTEND" => "noninteractive" } }

  describe "#load_current_resource" do
    subject { given; provider.load_current_resource }
    let(:given) { assume_source and assume_package_name_and_version and assume_installed_version }

    it "should create a current resource with the name of the new_resource" do
      subject.package_name.should eql(new_resource.package_name)
    end

    it 'should return the current resource'
    it 'should set the new resource version'
    it 'should set current package version'

    context 'when dpkg has a different package name' do
      it 'should set current package name to source dpkg name'
    end

    context 'without source' do
      let(:given) { assume_dpkg_exists }

      it "should raise an exception if the source is not set but we are installing" do
        lambda { subject }.should raise_error(Chef::Exceptions::Package)
      end
    end
  end

  describe "#install_package" do
    subject { given; provider.install_package(package_name, package_version) }
    let(:given) { assume_source and should_shell_out_with_systems_locale! }
    let(:dpkg_cmd) { "dpkg -i #{source_file}" }

    it "should run dpkg -i" do
      should_shell_out_with_systems_locale! and subject
    end

    context 'when package name is a path' do
      let(:package_name) { source_file }

      it "should run dpkg -i" do
        new_resource.source.should be_nil
        should_shell_out_with_systems_locale! and subject
      end
    end

    context 'with source options' do
      let(:given) { assume_source and assume_options }
      let(:dpkg_cmd) { "dpkg -i --force-yes #{source_file}" }
      let(:assume_options) { new_resource.options '--force-yes' }

      it "should run dpkg -i with the package source and options if specified" do
        should_shell_out_with_systems_locale! and subject
      end
    end
  end

  describe '#upgrade_package' do
    subject { given; provider.upgrade_package(package_name, package_version) }

    let(:given) { assume_source }
    let(:dpkg_cmd) { "dpkg -i #{source_file}" }

    context 'when package is a path' do
      let(:package_name) { source_file }

      it "should run dpkg -i" do
        should_shell_out_with_systems_locale! and subject
      end
    end

    it "should upgrade by running install_package" do
      provider.should_receive(:install_package).with("wget", "1.11.4-1ubuntu1")
      provider.upgrade_package("wget", "1.11.4-1ubuntu1")
    end
  end

  describe "#remove_package" do
    subject { given; provider.remove_package(package_name, package_version) }
    let(:dpkg_cmd) { "dpkg -r #{package_name}" }
    let(:given) { assume_source }

    it "should run dpkg -r to remove the package" do
      should_shell_out_with_systems_locale! and subject
    end

    context 'with options' do
      let(:given) { assume_source and assume_options }
      let(:package_name) { source_file }
      let(:dpkg_cmd) { "dpkg -r --force-yes #{source_file}" }

      it "should run dpkg -r to remove the package with options if specified" do
        should_shell_out_with_systems_locale! and subject
      end
    end
  end

  describe "#purge_package" do
    subject { given; provider.purge_package(package_name, package_version) }
    let(:dpkg_cmd) { "dpkg -P #{package_name}" }
    let(:given) { assume_source }

    it "should run dpkg -P to remove the package" do
      should_shell_out_with_systems_locale! and subject
    end

    context 'with options' do
      let(:given) { assume_source and assume_options }
      let(:package_name) { source_file }
      let(:dpkg_cmd) { "dpkg -P --force-yes #{source_file}" }

      it "should run dpkg -P" do
        should_shell_out_with_systems_locale! and subject
      end
    end
  end

  describe '#package_name_and_version' do
    subject { given; provider.package_name_and_version }
    let(:given) { assume_source and assume_dpkg_exists and should_shell_out! }
    let(:source_name) { subject[0] }
    let(:source_version) { subject[1] }

    let(:should_shell_out!) do
      provider.
        should_receive(:shell_out!).
        with("dpkg-deb -W #{new_resource.source}").
        and_return(status)
    end

    context 'when getting the source package version from dpkg-deb' do

      def self.with(_version_type, _version, &_example)
        let(:version) { _version }
        let(:stdout) { StringIO.new("wget\t#{version}") }
        context "with #{_version_type}" do
          it 'should return version', &_example
        end
      end

      with('short version', '1.11.4') { source_version.should eql(version) }
      with('extended version', '1.11.4-1ubuntu1') { source_version.should eql(version) }
      with('distro-specific version', '1.11.4-1ubuntu1~lucid') { source_version.should eql(version) }
    end

    context "when source package name has `-', `+' or `.' characters" do
      let(:stdout) { StringIO.new("f.o.o-pkg++2\t1.11.4-1ubuntu1") }
      it 'should return package name' do
        source_name.should eql("f.o.o-pkg++2")
      end

      it 'should return package version' do
        source_version.should eql('1.11.4-1ubuntu1')
      end
    end
  end

  describe '#assert_dpkg_exists!' do
    subject { given; provider.assert_dpkg_exists! }
    let(:given) { assume_new_resource and assume_source and should_check_file_existence }
    let(:should_check_file_existence) { ::File.should_receive(:exists?).with(new_resource.source).and_return(dpkg_exists?) }

    context 'when source dpkg exists' do
      let(:dpkg_exists?) { true }

      it "should not raise Chef::Exceptions::Package" do
        lambda { subject }.should_not raise_error(Chef::Exceptions::Package)
      end
    end

    context 'when source dpkg does not exist' do
      let(:dpkg_exists?) { false }

      it "should raise Chef::Exceptions::Package" do
        lambda { subject }.should raise_error(Chef::Exceptions::Package)
      end
    end

  end

  describe '#installed_version' do
    let(:stdout) { StringIO.new(<<-DPKG_S) }
Package: wget
Status: install ok installed
Priority: important
Section: web
Installed-Size: 1944
Maintainer: Ubuntu Core developers <ubuntu-devel-discuss@lists.ubuntu.com>
Architecture: amd64
Version: 1.11.4-1ubuntu1
Config-Version: 1.11.4-1ubuntu1
Depends: libc6 (>= 2.8~20080505), libssl0.9.8 (>= 0.9.8f-5)
Conflicts: wget-ssl
DPKG_S

    it "should return the current version installed if found by dpkg" do
      provider.stub!(:shell_out!).with("dpkg -s wget").and_return(status)
      assume_current_resource
      provider.installed_version.should == "1.11.4-1ubuntu1"
    end

    context 'when shell out exits with -1' do
      let(:exitstatus) { -1 }
      it "should raise an exception if dpkg fails to run" do
        assume_current_resource
        should_shell_out!
        lambda { provider.installed_version }.should raise_error(Chef::Exceptions::Package)
      end
    end
  end
end
