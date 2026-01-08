#
# Authors:: AJ Christensen (<aj@chef.io>)
#           Richard Manyanza (<liseki@nyikacraftsmen.com>)
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
# Copyright:: Copyright 2014-2016, Richard Manyanza.
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
require "ostruct"

describe Chef::Resource::FreebsdPackage do
  let(:node) { Chef::Node.new }
  let(:events) { Chef::EventDispatch::Dispatcher.new }
  let(:run_context) { Chef::RunContext.new(node, {}, events) }
  let(:resource) { Chef::Resource::FreebsdPackage.new("foo", run_context) }

  describe "Initialization" do

    it "is a subclass of Chef::Resource::Package" do
      expect(resource).to be_a_kind_of(Chef::Resource::Package)
    end

    it "sets the resource_name to :freebsd_package" do
      expect(resource.resource_name).to eql(:freebsd_package)
    end

    it "does not set the provider" do
      expect(resource.provider).to be_nil
    end
  end

  describe "Actions" do
    it "sets the default action as :install" do
      expect(resource.action).to eql([:install])
    end

    it "supports :install, :lock, :purge, :reconfig, :remove, :unlock, :upgrade actions" do
      expect { resource.action :install }.not_to raise_error
      expect { resource.action :lock }.not_to raise_error
      expect { resource.action :purge }.not_to raise_error
      expect { resource.action :reconfig }.not_to raise_error
      expect { resource.action :remove }.not_to raise_error
      expect { resource.action :unlock }.not_to raise_error
      expect { resource.action :upgrade }.not_to raise_error
    end
  end

  describe "Assigning provider after creation" do
    describe "if ports specified as source" do
      it "is Freebsd::Port" do
        resource.source("ports")
        resource.after_created
        expect(resource.provider).to eq(Chef::Provider::Package::Freebsd::Port)
      end
    end

    describe "if ports is not specified" do
      it "is Freebsd::Pkgng" do
        resource.after_created
        expect(resource.provider).to eq(Chef::Provider::Package::Freebsd::Pkgng)
      end
    end
  end
end
