#
# Author:: Jan Zimmek (<jan.zimmek@web.de>)
# Copyright:: Copyright 2010-2016, Jan Zimmek
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

RSpec.shared_examples "current_resource" do |pkg, version, candidate|
  let(:current_resource) { @provider.load_current_resource }
  before(:each) do
    @provider = create_provider_for(pkg)
  end

  it "sets current_resource name" do
    expect(current_resource.package_name).to eql(pkg)
  end

  it "sets current_resource version" do
    expect(current_resource.version).to eql(version)
  end

  it "sets candidate version" do
    current_resource
    expect(@provider.candidate_version).to eql(candidate)
  end
end

describe Chef::Provider::Package::Pacman do
  def create_provider_for(name)
    new_resource = Chef::Resource::Package.new(name)
    run_context = Chef::RunContext.new(Chef::Node.new, {}, Chef::EventDispatch::Dispatcher.new)
    provider = Chef::Provider::Package::Pacman.new(new_resource, run_context)

    pacman_out = <<~PACMAN_OUT
      extra nano 3.450-1
      extra emacs 0.12.0-1 [installed]
      core sed 3.234-2 [installed: 3.234-1]
    PACMAN_OUT

    allow(provider).to receive(:shell_out_compacted).and_return(double(stdout: pacman_out, exitstatus: 0))
    provider
  end

  before(:each) do
    pacman_conf = <<~PACMAN_CONF
      [options]
      HoldPkg      = pacman glibc
      Architecture = auto

      [customrepo]
      Server = https://my.custom.repo

      [core]
      Include = /etc/pacman.d/mirrorlist

      [extra]
      Include = /etc/pacman.d/mirrorlist

      [community]
      Include = /etc/pacman.d/mirrorlist
    PACMAN_CONF

    allow(::File).to receive(:exist?).with("/etc/pacman.conf").and_return(true)
    allow(::File).to receive(:read).with("/etc/pacman.conf").and_return(pacman_conf)
  end

  describe "loading the current resource" do

    describe "for an existing and installed but upgradable package" do
      include_examples "current_resource", ["sed"], ["3.234-1"], ["3.234-2"]
    end

    describe "for an existing and installed package" do
      include_examples "current_resource", ["emacs"], ["0.12.0-1"], ["0.12.0-1"]
    end

    describe "for an existing non installed package" do
      include_examples "current_resource", ["nano"], [nil], ["3.450-1"]
    end

    describe "for a non existing and an upgradable package" do
      include_examples "current_resource", %w{nano sed}, [nil, "3.234-1"], ["3.450-1", "3.234-2"]
    end

    describe "for a non existing package" do
      let(:current_resource) { @provider.load_current_resource }
      before(:each) do
        @provider = create_provider_for("vim")
      end

      it "raises an error" do
        expect { current_resource }.to raise_error(Chef::Exceptions::Package)
      end
    end

  end
end
