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
  before(:each) do
    @node = Chef::Node.new
    @events = Chef::EventDispatch::Dispatcher.new
    @run_context = Chef::RunContext.new(@node, {}, @events)
    @new_resource = Chef::Resource::Package.new("wget")
    @new_resource.source "/tmp/wget_1.11.4-1ubuntu1_amd64.deb"

    @provider = Chef::Provider::Package::Dpkg.new(@new_resource, @run_context)

    @stdin = StringIO.new
    @stdout = StringIO.new
    @status = double("Status", :exitstatus => 0)
    @stderr = StringIO.new
    @pid = double("PID")
    allow(@provider).to receive(:popen4).and_return(@status)

    allow(::File).to receive(:exists?).and_return(true)
  end

  describe "when loading the current resource state" do

    it "should create a current resource with the name of the new_resource" do
      @provider.load_current_resource
      expect(@provider.current_resource.package_name).to eq("wget")
    end

    it "should raise an exception if a source is supplied but not found" do
      @provider.load_current_resource
      @provider.define_resource_requirements
      allow(::File).to receive(:exists?).and_return(false)
      expect { @provider.run_action(:install) }.to raise_error(Chef::Exceptions::Package)
    end

    describe 'gets the source package version from dpkg-deb' do
      def check_version(version)
        @stdout = StringIO.new("wget\t#{version}")
        allow(@provider).to receive(:popen4).with("dpkg-deb -W #{@new_resource.source}").and_yield(@pid, @stdin, @stdout, @stderr).and_return(@status)
        @provider.load_current_resource
        expect(@provider.current_resource.package_name).to eq("wget")
        expect(@new_resource.version).to eq(version)
      end

      it 'if short version provided' do
        check_version('1.11.4')
      end

      it 'if extended version provided' do
        check_version('1.11.4-1ubuntu1')
      end

      it 'if distro-specific version provided' do
        check_version('1.11.4-1ubuntu1~lucid')
      end

      it 'returns the version if an epoch is used' do
        check_version('1:1.8.3-2')
      end
    end

    it "gets the source package name from dpkg-deb correctly when the package name has `-', `+' or `.' characters" do
      @stdout = StringIO.new("f.o.o-pkg++2\t1.11.4-1ubuntu1")
      allow(@provider).to receive(:popen4).and_yield(@pid, @stdin, @stdout, @stderr).and_return(@status)
      @provider.load_current_resource
      expect(@provider.current_resource.package_name).to eq("f.o.o-pkg++2")
    end

    it "should raise an exception if the source is not set but we are installing" do
      @new_resource = Chef::Resource::Package.new("wget")
      @provider.new_resource = @new_resource
      @provider.load_current_resource
      @provider.define_resource_requirements
      expect { @provider.run_action(:install)}.to raise_error(Chef::Exceptions::Package)
    end

    it "should return the current version installed if found by dpkg" do
      @stdout = StringIO.new(<<-DPKG_S)
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
      allow(@provider).to receive(:popen4).with("dpkg -s wget").and_yield(@pid, @stdin, @stdout, @stderr).and_return(@status)

      @provider.load_current_resource
      expect(@provider.current_resource.version).to eq("1.11.4-1ubuntu1")
    end

    it "should raise an exception if dpkg fails to run" do
      @status = double("Status", :exitstatus => -1)
      allow(@provider).to receive(:popen4).and_return(@status)
      expect { @provider.load_current_resource }.to raise_error(Chef::Exceptions::Package)
    end
  end

  describe Chef::Provider::Package::Dpkg, "install and upgrade" do
    it "should run dpkg -i with the package source" do
      expect(@provider).to receive(:run_noninteractive).with(
        "dpkg -i /tmp/wget_1.11.4-1ubuntu1_amd64.deb"
      )
      @provider.install_package("wget", "1.11.4-1ubuntu1")
    end

    it "should run dpkg -i if the package is a path and the source is nil" do
      @new_resource = Chef::Resource::Package.new("/tmp/wget_1.11.4-1ubuntu1_amd64.deb")
      @provider = Chef::Provider::Package::Dpkg.new(@new_resource, @run_context)
      expect(@provider).to receive(:run_noninteractive).with(
        "dpkg -i /tmp/wget_1.11.4-1ubuntu1_amd64.deb"
      )
      @provider.install_package("/tmp/wget_1.11.4-1ubuntu1_amd64.deb", "1.11.4-1ubuntu1")
    end

    it "should run dpkg -i if the package is a path and the source is nil for an upgrade" do
      @new_resource = Chef::Resource::Package.new("/tmp/wget_1.11.4-1ubuntu1_amd64.deb")
      @provider = Chef::Provider::Package::Dpkg.new(@new_resource, @run_context)
      expect(@provider).to receive(:run_noninteractive).with(
        "dpkg -i /tmp/wget_1.11.4-1ubuntu1_amd64.deb"
      )
      @provider.upgrade_package("/tmp/wget_1.11.4-1ubuntu1_amd64.deb", "1.11.4-1ubuntu1")
    end

    it "should run dpkg -i with the package source and options if specified" do
      expect(@provider).to receive(:run_noninteractive).with(
        "dpkg -i --force-yes /tmp/wget_1.11.4-1ubuntu1_amd64.deb"
      )
      allow(@new_resource).to receive(:options).and_return("--force-yes")

      @provider.install_package("wget", "1.11.4-1ubuntu1")
    end
    it "should upgrade by running install_package" do
      expect(@provider).to receive(:install_package).with("wget", "1.11.4-1ubuntu1")
      @provider.upgrade_package("wget", "1.11.4-1ubuntu1")
    end
  end

  describe Chef::Provider::Package::Dpkg, "remove and purge" do
    it "should run dpkg -r to remove the package" do
      expect(@provider).to receive(:run_noninteractive).with(
        "dpkg -r wget"
      )
      @provider.remove_package("wget", "1.11.4-1ubuntu1")
    end

    it "should run dpkg -r to remove the package with options if specified" do
      expect(@provider).to receive(:run_noninteractive).with(
        "dpkg -r --force-yes wget"
      )
      allow(@new_resource).to receive(:options).and_return("--force-yes")

      @provider.remove_package("wget", "1.11.4-1ubuntu1")
    end

    it "should run dpkg -P to purge the package" do
      expect(@provider).to receive(:run_noninteractive).with(
        "dpkg -P wget"
      )
      @provider.purge_package("wget", "1.11.4-1ubuntu1")
    end

    it "should run dpkg -P to purge the package with options if specified" do
      expect(@provider).to receive(:run_noninteractive).with(
        "dpkg -P --force-yes wget"
      )
      allow(@new_resource).to receive(:options).and_return("--force-yes")

      @provider.purge_package("wget", "1.11.4-1ubuntu1")
    end
  end
end
