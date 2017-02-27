#
# Author:: Joshua Timberman (<joshua@chef.io>)
# Author:: Daniel DeLeo (<dan@chef.io>)
# Copyright:: Copyright 2008-2016, Chef Software Inc.
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

describe Chef::Provider::Package::Rpm do
  let(:provider) { Chef::Provider::Package::Rpm.new(new_resource, run_context) }
  let(:node) { Chef::Node.new }
  let(:events) { Chef::EventDispatch::Dispatcher.new }
  let(:run_context) { Chef::RunContext.new(node, {}, events) }

  let(:package_source) { "/tmp/ImageMagick-c++-6.5.4.7-7.el6_5.x86_64.rpm" }

  let(:package_name) { "ImageMagick-c++" }

  let(:new_resource) do
    Chef::Resource::Package.new(package_name).tap do |resource|
      resource.source(package_source)
    end
  end

  # `rpm -qp [stuff] $source`
  let(:rpm_qp_status) { instance_double("Mixlib::ShellOut", exitstatus: rpm_qp_exitstatus, stdout: rpm_qp_stdout) }

  # `rpm -q [stuff] $package_name`
  let(:rpm_q_status) { instance_double("Mixlib::ShellOut", exitstatus: rpm_q_exitstatus, stdout: rpm_q_stdout) }

  before(:each) do
    allow(::File).to receive(:exist?).with("PLEASE STUB File.exists? EXACTLY").and_return(true)

    # Ensure all shell out usage is stubbed with exact arguments
    allow(provider).to receive(:shell_out!).with("PLEASE STUB YOUR SHELLOUT CALLS").and_return(nil)
    allow(provider).to receive(:shell_out).with("PLEASE STUB YOUR SHELLOUT CALLS").and_return(nil)
  end

  describe "when the package source is not valid" do

    context "when source is not defiend" do
      let(:new_resource) { Chef::Resource::Package.new("ImageMagick-c++") }

      it "should raise an exception when attempting any action" do
        expect { provider.run_action(:any) }.to raise_error(Chef::Exceptions::Package)
      end
    end

    context "when the source is a file that doesn't exist" do

      it "should raise an exception when attempting any action" do
        allow(::File).to receive(:exist?).with(package_source).and_return(false)
        expect { provider.run_action(:any) }.to raise_error(Chef::Exceptions::Package)
      end
    end

    context "when the source is an unsupported URI scheme" do

      let(:package_source) { "foobar://example.com/ImageMagick-c++-6.5.4.7-7.el6_5.x86_64.rpm" }

      it "should raise an exception if an uri formed source is non-supported scheme" do
        allow(::File).to receive(:exist?).with(package_source).and_return(false)

        # verify let bindings are as we expect
        expect(new_resource.source).to eq("foobar://example.com/ImageMagick-c++-6.5.4.7-7.el6_5.x86_64.rpm")
        expect(provider.load_current_resource).to be_nil
        expect { provider.run_action(:any) }.to raise_error(Chef::Exceptions::Package)
      end
    end

  end

  describe "when the package source is valid" do

    before do
      expect(provider).to receive(:shell_out!).
        with("rpm", "-qp", "--queryformat", "%{NAME} %{VERSION}-%{RELEASE}\n", package_source, timeout: 900).
        and_return(rpm_qp_status)

      expect(provider).to receive(:shell_out).
        with("rpm", "-q", "--queryformat", "%{NAME} %{VERSION}-%{RELEASE}\n", package_name, timeout: 900).
        and_return(rpm_q_status)
    end

    context "when rpm fails when querying package installed state" do

      before do
        allow(::File).to receive(:exist?).with(package_source).and_return(true)
      end

      let(:rpm_qp_stdout) { "ImageMagick-c++ 6.5.4.7-7.el6_5" }
      let(:rpm_q_stdout) { "" }

      let(:rpm_qp_exitstatus) { 0 }
      let(:rpm_q_exitstatus) { -1 }

      it "raises an exception when attempting any action" do
        expected_message = "Unable to determine current version due to RPM failure."

        expect { provider.run_action(:install) }.to raise_error do |error|
          expect(error).to be_a_kind_of(Chef::Exceptions::Package)
          expect(error.to_s).to include(expected_message)
        end
      end
    end

    context "when the package is installed" do

      let(:rpm_qp_stdout) { "ImageMagick-c++ 6.5.4.7-7.el6_5" }
      let(:rpm_q_stdout) { "ImageMagick-c++ 6.5.4.7-7.el6_5" }

      let(:rpm_qp_exitstatus) { 0 }
      let(:rpm_q_exitstatus) { 0 }

      let(:action) { :install }

      context "when the source is a file system path" do

        before do
          allow(::File).to receive(:exist?).with(package_source).and_return(true)

          provider.action = action

          provider.load_current_resource
          provider.define_resource_requirements
          provider.process_resource_requirements
        end

        it "should get the source package version from rpm if provided" do
          expect(provider.current_resource.package_name).to eq("ImageMagick-c++")
          expect(provider.new_resource.version).to eq("6.5.4.7-7.el6_5")
        end

        it "should return the current version installed if found by rpm" do
          expect(provider.current_resource.version).to eq("6.5.4.7-7.el6_5")
        end

        describe "action install" do

          context "when at the desired version already" do
            it "does nothing when the correct version is installed" do
              expect(provider).to_not receive(:shell_out!).with("rpm", "-i", "/tmp/imagemagick-c++-6.5.4.7-7.el6_5.x86_64.rpm", timeout: 900)

              provider.action_install
            end
          end

          context "when a newer version is desired" do

            let(:rpm_q_stdout) { "imagemagick-c++ 0.5.4.7-7.el6_5" }

            it "runs rpm -u with the package source to upgrade" do
              expect(provider).to receive(:shell_out!).with("rpm", "-U", "/tmp/ImageMagick-c++-6.5.4.7-7.el6_5.x86_64.rpm", timeout: 900)
              provider.action_install
            end
          end

          context "when an older version is desired" do
            let(:new_resource) do
              Chef::Resource::RpmPackage.new(package_name).tap do |r|
                r.source(package_source)
                r.allow_downgrade(true)
              end
            end

            let(:rpm_q_stdout) { "imagemagick-c++ 21.4-19.el6_5" }

            it "should run rpm -u --oldpackage with the package source to downgrade" do
              expect(provider).to receive(:shell_out!).with("rpm", "-U", "--oldpackage", "/tmp/ImageMagick-c++-6.5.4.7-7.el6_5.x86_64.rpm", timeout: 900)
              provider.action_install
            end

          end

        end

        describe "action upgrade" do

          let(:action) { :upgrade }

          context "when at the desired version already" do
            it "does nothing when the correct version is installed" do
              expect(provider).to_not receive(:shell_out!).with("rpm", "-i", "/tmp/imagemagick-c++-6.5.4.7-7.el6_5.x86_64.rpm", timeout: 900)

              provider.action_upgrade
            end
          end

          context "when a newer version is desired" do

            let(:rpm_q_stdout) { "imagemagick-c++ 0.5.4.7-7.el6_5" }

            it "runs rpm -u with the package source to upgrade" do
              expect(provider).to receive(:shell_out!).with("rpm", "-U", "/tmp/ImageMagick-c++-6.5.4.7-7.el6_5.x86_64.rpm", timeout: 900)
              provider.action_upgrade
            end
          end

          context "when an older version is desired" do
            let(:new_resource) do
              Chef::Resource::RpmPackage.new(package_name).tap do |r|
                r.source(package_source)
                r.allow_downgrade(true)
              end
            end

            let(:rpm_q_stdout) { "imagemagick-c++ 21.4-19.el6_5" }

            it "should run rpm -u --oldpackage with the package source to downgrade" do
              expect(provider).to receive(:shell_out!).with("rpm", "-U", "--oldpackage", "/tmp/ImageMagick-c++-6.5.4.7-7.el6_5.x86_64.rpm", timeout: 900)
              provider.action_upgrade
            end

          end
        end

        describe "action :remove" do

          let(:action) { :remove }

          it "should remove the package" do
            expect(provider).to receive(:shell_out!).with("rpm", "-e", "ImageMagick-c++-6.5.4.7-7.el6_5", timeout: 900)
            provider.action_remove
          end
        end

        context "when the package name contains a tilde (chef#3503)" do

          let(:package_name) { "supermarket" }

          let(:package_source) { "/tmp/supermarket-1.10.1~alpha.0-1.el5.x86_64.rpm" }

          let(:rpm_qp_stdout) { "supermarket 1.10.1~alpha.0-1.el5" }
          let(:rpm_q_stdout) { "supermarket 1.10.1~alpha.0-1.el5" }

          let(:rpm_qp_exitstatus) { 0 }
          let(:rpm_q_exitstatus) { 0 }

          it "should correctly determine the candidate version and installed version" do
            expect(provider.current_resource.package_name).to eq("supermarket")
            expect(provider.new_resource.version).to eq("1.10.1~alpha.0-1.el5")
          end
        end

        context "when the package name contains a plus symbol (chef#3671)" do

          let(:package_name) { "chef-server-core" }

          let(:package_source) { "/tmp/chef-server-core-12.2.0+20150713220422-1.el6.x86_64.rpm" }

          let(:rpm_qp_stdout) { "chef-server-core 12.2.0+20150713220422-1.el6" }
          let(:rpm_q_stdout) { "chef-server-core 12.2.0+20150713220422-1.el6" }

          let(:rpm_qp_exitstatus) { 0 }
          let(:rpm_q_exitstatus) { 0 }

          it "should correctly determine the candidate version and installed version" do
            expect(provider.current_resource.package_name).to eq("chef-server-core")
            expect(provider.new_resource.version).to eq("12.2.0+20150713220422-1.el6")
          end
        end

      end

      context "when the source is given as an URI" do
        before(:each) do
          allow(::File).to receive(:exist?).with(package_source).and_return(false)

          provider.action = action

          provider.load_current_resource
          provider.define_resource_requirements
          provider.process_resource_requirements
        end

        %w{http HTTP https HTTPS ftp FTP file FILE}.each do |scheme|

          context "when the source URI uses protocol scheme '#{scheme}'" do

            let(:package_source) { "#{scheme}://example.com/ImageMagick-c++-6.5.4.7-7.el6_5.x86_64.rpm" }

            it "should get the source package version from rpm if provided" do
              expect(provider.current_resource.package_name).to eq("ImageMagick-c++")
              expect(provider.new_resource.version).to eq("6.5.4.7-7.el6_5")
            end

            it "should return the current version installed if found by rpm" do
              expect(provider.current_resource.version).to eq("6.5.4.7-7.el6_5")
            end

          end
        end

      end

    end

    context "when the package is not installed" do

      let(:package_name) { "openssh-askpass" }

      let(:package_source) { "/tmp/openssh-askpass-1.2.3-4.el6_5.x86_64.rpm" }

      let(:rpm_qp_stdout) { "openssh-askpass 1.2.3-4.el6_5" }
      let(:rpm_q_stdout) { "package openssh-askpass is not installed" }

      let(:rpm_qp_exitstatus) { 0 }
      let(:rpm_q_exitstatus) { 0 }

      let(:action) { :install }

      before do
        allow(File).to receive(:exist?).with(package_source).and_return(true)

        provider.action = action

        provider.load_current_resource
        provider.define_resource_requirements
        provider.process_resource_requirements
      end

      it "should not detect the package name as version when not installed" do
        expect(provider.current_resource.version).to be_nil
      end

      context "when the package name contains a tilde (chef#3503)" do

        let(:package_name) { "supermarket" }

        let(:package_source) { "/tmp/supermarket-1.10.1~alpha.0-1.el5.x86_64.rpm" }

        let(:rpm_qp_stdout) { "supermarket 1.10.1~alpha.0-1.el5" }
        let(:rpm_q_stdout) { "package supermarket is not installed" }

        let(:rpm_qp_exitstatus) { 0 }
        let(:rpm_q_exitstatus) { 0 }

        it "should correctly determine the candidate version" do
          expect(provider.new_resource.version).to eq("1.10.1~alpha.0-1.el5")
        end
      end

      describe "managing the package" do

        describe "action install" do

          it "installs the package" do
            expect(provider).to receive(:shell_out!).with("rpm", "-i", package_source, timeout: 900)

            provider.action_install
          end

          context "when custom resource options are given" do
            it "installs with custom options specified in the resource" do
              new_resource.options("--dbpath /var/lib/rpm")
              expect(provider).to receive(:shell_out!).with("rpm", "--dbpath", "/var/lib/rpm", "-i", package_source, timeout: 900)
              provider.action_install
            end
          end
        end

        describe "action upgrade" do

          let(:action) { :upgrade }

          it "installs the package" do
            expect(provider).to receive(:shell_out!).with("rpm", "-i", package_source, timeout: 900)

            provider.action_upgrade
          end
        end

        describe "when removing the package" do

          let(:action) { :remove }

          it "should do nothing" do
            expect(provider).to_not receive(:shell_out!).with("rpm", "-e", "ImageMagick-c++-6.5.4.7-7.el6_5", timeout: 900)
            provider.action_remove
          end
        end

      end

    end
  end

  context "when the resource name is the path to the package" do

    let(:new_resource) do
      # When we pass a source in as the name, then #initialize in the
      # provider will call File.exists?. Because of the ordering in our
      # let() bindings and such, we have to set the stub here and not in a
      # before block.
      allow(::File).to receive(:exist?).with(package_source).and_return(true)
      Chef::Resource::Package.new("/tmp/ImageMagick-c++-6.5.4.7-7.el6_5.x86_64.rpm")
    end

    let(:current_resource) { Chef::Resource::Package.new("ImageMagick-c++") }

    it "should install from a path when the package is a path and the source is nil" do
      expect(new_resource.source).to eq("/tmp/ImageMagick-c++-6.5.4.7-7.el6_5.x86_64.rpm")
      provider.current_resource = current_resource
      expect(provider).to receive(:shell_out!).with("rpm", "-i", "/tmp/ImageMagick-c++-6.5.4.7-7.el6_5.x86_64.rpm", timeout: 900)
      provider.install_package("/tmp/ImageMagick-c++-6.5.4.7-7.el6_5.x86_64.rpm", "6.5.4.7-7.el6_5")
    end

    it "should uprgrade from a path when the package is a path and the source is nil" do
      expect(new_resource.source).to eq("/tmp/ImageMagick-c++-6.5.4.7-7.el6_5.x86_64.rpm")
      current_resource.version("21.4-19.el5")
      provider.current_resource = current_resource
      expect(provider).to receive(:shell_out!).with("rpm", "-U", "/tmp/ImageMagick-c++-6.5.4.7-7.el6_5.x86_64.rpm", timeout: 900)
      provider.upgrade_package("/tmp/ImageMagick-c++-6.5.4.7-7.el6_5.x86_64.rpm", "6.5.4.7-7.el6_5")
    end
  end

end
