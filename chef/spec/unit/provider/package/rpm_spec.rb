#
# Author:: Joshua Timberman (<joshua@opscode.com>)
# Author:: Daniel DeLeo (<dan@opscode.com>)
# Copyright:: Copyright (c) 2008, 2010 Opscode, Inc.
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

describe Chef::Provider::Package::Rpm do
  include SpecHelpers::Providers::Package

  let(:package_name) { 'emacs' }
  let(:source_package_name) { package_name }
  let(:source_file) { "/tmp/emacs-21.4-20.el5.i386.rpm" }

  let(:assume_rpm_exists) { provider.stub!(:assert_rpm_exists!).and_return(true) }
  let(:source_version) { '21.4-20.el5' }
  let(:installed_version) { source_version }

  context "when determining the current state of the package" do
    subject { given; provider.load_current_resource }
    let(:given) { assume_source and assume_package_name_and_version and assume_installed_version }

    it "should create a current resource with the name of new_resource" do
      subject.name.should eql(new_resource.name)
    end

    it "should set the current reource package name to the new resource package name" do
      subject.package_name.should eql(new_resource.package_name)
    end

    it "should set installed version on current resource" do
      subject.version.should eql(installed_version)
    end

    context 'when source is specified' do
      context 'with different package name' do
        let(:source_package_name) { "emacs-#{rand(10000)}" }

        it 'should set package name of current resource' do
          subject.package_name.should eql(source_package_name)
        end
      end

      context 'with different version' do
        let(:source_version) { rand(10000).to_s }

        it 'should set version of new resource' do
          subject.should_not be_nil
          provider.new_resource.version.should eql(source_version)
        end
      end
    end

    context 'when attempting to install and source is not specified' do
      it "should raise Chef::Exceptions::Package" do
        new_resource = Chef::Resource::Package.new("emacs")
        provider = Chef::Provider::Package::Rpm.new(new_resource, run_context)
        lambda { provider.load_current_resource }.should raise_error(Chef::Exceptions::Package)
      end
    end
  end

  describe '#install_package' do
    before(:each) do
      assume_current_resource
      assume_new_resource
      assume_source
    end

    it "should run rpm -i with the package source to install" do
      provider.should_receive(:shell_out_with_systems_locale!).with("rpm  -i /tmp/emacs-21.4-20.el5.i386.rpm")
      provider.install_package("emacs", "21.4-20.el5")
    end

    it "should install with custom options specified in the resource" do
      provider.candidate_version = '11'
      new_resource.options("--dbpath /var/lib/rpm")
      provider.should_receive(:shell_out_with_systems_locale!).with("rpm --dbpath /var/lib/rpm -i /tmp/emacs-21.4-20.el5.i386.rpm")
      provider.install_package(new_resource.name, provider.candidate_version)
    end

    context 'when package is a path' do
      let(:new_resource) { Chef::Resource::Package.new("/tmp/emacs-21.4-20.el5.i386.rpm") }

      it "should install from a path when the package is a path and the source is nil" do
        assume_current_resource
        new_resource.source.should eql("/tmp/emacs-21.4-20.el5.i386.rpm")

        provider.should_receive(:shell_out_with_systems_locale!).with("rpm  -i /tmp/emacs-21.4-20.el5.i386.rpm")
        provider.install_package("/tmp/emacs-21.4-20.el5.i386.rpm", "21.4-20.el5")
      end
    end
  end

  describe '#upgrade_package' do
    before(:each) do
      assume_current_resource
      assume_new_resource
      assume_source
    end

    it "should run rpm -U with the package source to upgrade" do
      provider.current_resource.version("21.4-19.el5")
      provider.should_receive(:shell_out_with_systems_locale!).with("rpm  -U /tmp/emacs-21.4-20.el5.i386.rpm")
      provider.upgrade_package("emacs", "21.4-20.el5")
    end

    context 'when package is a path' do
      let(:new_resource) { Chef::Resource::Package.new("/tmp/emacs-21.4-20.el5.i386.rpm") }

      it "should uprgrade from a path when the package is a path and the source is nil" do
        assume_current_resource
        new_resource.source.should eql("/tmp/emacs-21.4-20.el5.i386.rpm")
        current_resource.version("21.4-19.el5")

        provider.should_receive(:shell_out_with_systems_locale!).with("rpm  -U /tmp/emacs-21.4-20.el5.i386.rpm")
        provider.upgrade_package("/tmp/emacs-21.4-20.el5.i386.rpm", "21.4-20.el5")
      end
    end
  end

  describe "#remove_package" do
    it "should run rpm -e to remove the package" do
      provider.should_receive(:shell_out_with_systems_locale!).with("rpm  -e emacs-21.4-20.el5")
      provider.remove_package("emacs", "21.4-20.el5")
    end
  end

  describe '#assert_rpm_exists!' do
    subject { provider.assert_rpm_exists! }

    it "should not raise an exception if a source is found" do
      assume_new_resource
      ::File.stub!(:exists?).and_return(true)
      lambda { subject }.should_not raise_error(Chef::Exceptions::Package)
    end

    it "should raise an exception if a source is not found" do
      assume_new_resource
      ::File.stub!(:exists?).and_return(false)
      lambda { subject }.should raise_error(Chef::Exceptions::Package)
    end
  end

  describe "#package_name_and_version" do
    subject { given; provider.package_name_and_version }

    let(:given) do
      assume_new_resource
      assume_source
      assume_rpm_exists
      should_query_rpm
    end

    let(:stdout) { StringIO.new("emacs 21.4-20.el5") }
    let(:should_query_rpm) { provider.should_receive(:shell_out!).with("rpm -qp --queryformat '%{NAME} %{VERSION}-%{RELEASE}\n' /tmp/emacs-21.4-20.el5.i386.rpm").and_return(status) }

    let(:returned_package_name) { subject[0] }
    let(:returned_version) { subject[1] }

    it 'should return package name' do
      returned_package_name.should eql(package_name)
    end

    it "should return source package version" do
      returned_version.should eql("21.4-20.el5")
    end

    context 'when source is not specified' do
      let(:given) { assume_new_resource }

      it 'should return [ nil, nil ]' do
        should eql([nil, nil])
      end
    end
  end

  describe "#installed_verison" do
    subject { given; provider.installed_version }

    let(:given) { assume_current_resource }
    let(:stdout) { StringIO.new("emacs 21.4-20.el5") }

    it "should call `rpm` to determine installed version" do
      provider.
        should_receive(:shell_out!).
        with("rpm -q --queryformat '%{NAME} %{VERSION}-%{RELEASE}\n' emacs").
        and_return(status)

      should eql("21.4-20.el5")
    end

    context 'when `rpm` exits with status -1' do
      let(:exitstatus) { -1 }

      it "should raise an exception if rpm fails to run" do
        provider.stub!(:shell_out!).and_return(status)
        lambda { provider.load_current_resource }.should raise_error(Chef::Exceptions::Package)
      end
    end
  end
end

