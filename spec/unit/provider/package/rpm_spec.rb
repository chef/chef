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
  let(:provider) { Chef::Provider::Package::Rpm.new(new_resource, run_context) }
  let(:node) { Chef::Node.new }
  let(:events) { Chef::EventDispatch::Dispatcher.new }
  let(:run_context) { Chef::RunContext.new(node, {}, events) }
  let(:new_resource) do
    Chef::Resource::Package.new("ImageMagick-c++").tap do |resource|
      resource.source "/tmp/ImageMagick-c++-6.5.4.7-7.el6_5.x86_64.rpm"
    end
  end
  let(:exitstatus) { 0 }
  let(:stdout) { String.new('') }
  let(:status) { double('Process::Status', exitstatus: exitstatus, stdout: stdout) }

  before(:each) do
    allow(::File).to receive(:exists?).and_return(true)
    allow(provider).to receive(:shell_out!).and_return(status)
  end

  describe "when determining the current state of the package" do
    it "should create a current resource with the name of new_resource" do
      provider.load_current_resource
      expect(provider.current_resource.name).to eq("ImageMagick-c++")
    end

    it "should set the current reource package name to the new resource package name" do
      provider.load_current_resource
      expect(provider.current_resource.package_name).to eq('ImageMagick-c++')
    end

    it "should raise an exception if a source is supplied but not found" do
      allow(::File).to receive(:exists?).and_return(false)
      expect { provider.run_action(:any) }.to raise_error(Chef::Exceptions::Package)
    end

    context "installation exists" do
      let(:stdout) { "ImageMagick-c++ 6.5.4.7-7.el6_5" }

      it "should get the source package version from rpm if provided" do
        expect(provider).to receive(:shell_out!).with("rpm -qp --queryformat '%{NAME} %{VERSION}-%{RELEASE}\n' /tmp/ImageMagick-c++-6.5.4.7-7.el6_5.x86_64.rpm").and_return(status)
        expect(provider).to receive(:shell_out).with("rpm -q --queryformat '%{NAME} %{VERSION}-%{RELEASE}\n' ImageMagick-c++").and_return(status)
        provider.load_current_resource
        expect(provider.current_resource.package_name).to eq("ImageMagick-c++")
        expect(provider.new_resource.version).to eq("6.5.4.7-7.el6_5")
      end

      it "should return the current version installed if found by rpm" do
        expect(provider).to receive(:shell_out!).with("rpm -qp --queryformat '%{NAME} %{VERSION}-%{RELEASE}\n' /tmp/ImageMagick-c++-6.5.4.7-7.el6_5.x86_64.rpm").and_return(status)
        expect(provider).to receive(:shell_out).with("rpm -q --queryformat '%{NAME} %{VERSION}-%{RELEASE}\n' ImageMagick-c++").and_return(status)
        provider.load_current_resource
        expect(provider.current_resource.version).to eq("6.5.4.7-7.el6_5")
      end
    end

    context "source is uri formed" do
      before(:each) do
        allow(::File).to receive(:exists?).and_return(false)
      end

      %w(http HTTP https HTTPS ftp FTP).each do |scheme|
        it "should accept uri formed source (#{scheme})" do
          new_resource.source "#{scheme}://example.com/ImageMagick-c++-6.5.4.7-7.el6_5.x86_64.rpm"
          expect(provider.load_current_resource).not_to be_nil
        end
      end

      %w(file FILE).each do |scheme|
        it "should accept uri formed source (#{scheme})" do
          new_resource.source "#{scheme}:///ImageMagick-c++-6.5.4.7-7.el6_5.x86_64.rpm"
          expect(provider.load_current_resource).not_to be_nil
        end
      end

      it "should raise an exception if an uri formed source is non-supported scheme" do
        new_resource.source "foobar://example.com/ImageMagick-c++-6.5.4.7-7.el6_5.x86_64.rpm"
        expect(provider.load_current_resource).to be_nil
        expect { provider.run_action(:any) }.to raise_error(Chef::Exceptions::Package)
      end
    end

    context "source is not defiend" do
      let(:new_resource) { Chef::Resource::Package.new("ImageMagick-c++") }

      it "should raise an exception if the source is not set but we are installing" do
        expect { provider.run_action(:any) }.to raise_error(Chef::Exceptions::Package)
      end
    end

    context "installation does not exist" do
      let(:stdout) { String.new("package openssh-askpass is not installed") }
      let(:exitstatus) { -1 }
      let(:new_resource) do
        Chef::Resource::Package.new("openssh-askpass").tap do |resource|
          resource.source "openssh-askpass"
        end
      end

      it "should raise an exception if rpm fails to run" do
        allow(provider).to receive(:shell_out).and_return(status)
        expect { provider.run_action(:any) }.to raise_error(Chef::Exceptions::Package)
      end

      it "should not detect the package name as version when not installed" do
        expect(provider).to receive(:shell_out!).with("rpm -qp --queryformat '%{NAME} %{VERSION}-%{RELEASE}\n' openssh-askpass").and_return(status)
        expect(provider).to receive(:shell_out).with("rpm -q --queryformat '%{NAME} %{VERSION}-%{RELEASE}\n' openssh-askpass").and_return(status)
        provider.load_current_resource
        expect(provider.current_resource.version).to be_nil
      end
    end
  end

  describe "after the current resource is loaded" do
    let(:current_resource) { Chef::Resource::Package.new("ImageMagick-c++") }
    let(:provider) do
      Chef::Provider::Package::Rpm.new(new_resource, run_context).tap do |provider|
        provider.current_resource = current_resource
      end
    end

    describe "when installing or upgrading" do
      it "should run rpm -i with the package source to install" do
        expect(provider).to receive(:shell_out!).with("rpm  -i /tmp/ImageMagick-c++-6.5.4.7-7.el6_5.x86_64.rpm")
        provider.install_package("ImageMagick-c++", "6.5.4.7-7.el6_5")
      end

      it "should run rpm -U with the package source to upgrade" do
        current_resource.version("21.4-19.el5")
        expect(provider).to receive(:shell_out!).with("rpm  -U /tmp/ImageMagick-c++-6.5.4.7-7.el6_5.x86_64.rpm")
        provider.upgrade_package("ImageMagick-c++", "6.5.4.7-7.el6_5")
      end

      it "should install package if missing and set to upgrade" do
        current_resource.version("ImageMagick-c++")
        expect(provider).to receive(:shell_out!).with("rpm  -U /tmp/ImageMagick-c++-6.5.4.7-7.el6_5.x86_64.rpm")
        provider.upgrade_package("ImageMagick-c++", "6.5.4.7-7.el6_5")
      end

      context "allowing downgrade" do
        let(:new_resource) { Chef::Resource::RpmPackage.new("/tmp/ImageMagick-c++-6.5.4.7-7.el6_5.x86_64.rpm") }
        let(:current_resource) { Chef::Resource::RpmPackage.new("ImageMagick-c++") }

        it "should run rpm -U --oldpackage with the package source to downgrade" do
          new_resource.allow_downgrade(true)
          current_resource.version("21.4-19.el5")
          expect(provider).to receive(:shell_out!).with("rpm  -U --oldpackage /tmp/ImageMagick-c++-6.5.4.7-7.el6_5.x86_64.rpm")
          provider.upgrade_package("ImageMagick-c++", "6.5.4.7-7.el6_5")
        end
      end

      context "installing when the name is a path" do
        let(:new_resource) { Chef::Resource::Package.new("/tmp/ImageMagick-c++-6.5.4.7-7.el6_5.x86_64.rpm") }
        let(:current_resource) { Chef::Resource::Package.new("ImageMagick-c++") }

        it "should install from a path when the package is a path and the source is nil" do
          expect(new_resource.source).to eq("/tmp/ImageMagick-c++-6.5.4.7-7.el6_5.x86_64.rpm")
          provider.current_resource = current_resource
          expect(provider).to receive(:shell_out!).with("rpm  -i /tmp/ImageMagick-c++-6.5.4.7-7.el6_5.x86_64.rpm")
          provider.install_package("/tmp/ImageMagick-c++-6.5.4.7-7.el6_5.x86_64.rpm", "6.5.4.7-7.el6_5")
        end

        it "should uprgrade from a path when the package is a path and the source is nil" do
          expect(new_resource.source).to eq("/tmp/ImageMagick-c++-6.5.4.7-7.el6_5.x86_64.rpm")
          current_resource.version("21.4-19.el5")
          provider.current_resource = current_resource
          expect(provider).to receive(:shell_out!).with("rpm  -U /tmp/ImageMagick-c++-6.5.4.7-7.el6_5.x86_64.rpm")
          provider.upgrade_package("/tmp/ImageMagick-c++-6.5.4.7-7.el6_5.x86_64.rpm", "6.5.4.7-7.el6_5")
        end
      end

      it "installs with custom options specified in the resource" do
        provider.candidate_version = '11'
        new_resource.options("--dbpath /var/lib/rpm")
        expect(provider).to receive(:shell_out!).with("rpm --dbpath /var/lib/rpm -i /tmp/ImageMagick-c++-6.5.4.7-7.el6_5.x86_64.rpm")
        provider.install_package(new_resource.name, provider.candidate_version)
      end
    end

    describe "when removing the package" do
      it "should run rpm -e to remove the package" do
        expect(provider).to receive(:shell_out!).with("rpm  -e ImageMagick-c++-6.5.4.7-7.el6_5")
        provider.remove_package("ImageMagick-c++", "6.5.4.7-7.el6_5")
      end
    end
  end
end
