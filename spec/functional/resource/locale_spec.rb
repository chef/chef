#
# Author:: Nimesh Patni (<nimesh.patni@msystechnologies.com>)
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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

describe Chef::Resource::Locale, :requires_root do
  let(:node) do
    n = Chef::Node.new
    n.consume_external_attrs(OHAI_SYSTEM.data, {})
    n
  end
  let(:events) { Chef::EventDispatch::Dispatcher.new }
  let(:run_context) { Chef::RunContext.new(node, {}, events) }
  let(:resource) { Chef::Resource::Locale.new("fakey_fakerton", run_context) }

  context "on debian/ubuntu", :debian_family_only do
    def sets_system_locale(*locales)
      system_locales = File.readlines("/etc/locale.conf")
      expect(system_locales.map(&:strip)).to eq(locales)
    end

    def unsets_system_locale(*locales)
      system_locales = File.readlines("/etc/locale.conf")
      expect(system_locales.map(&:strip)).not_to eq(locales)
    end

    describe "action: update" do
      context "Sets system variable" do
        it "when LC var is given" do
          resource.lc_env({ "LC_MESSAGES" => "en_US" })
          resource.run_action(:update)
          sets_system_locale("LC_MESSAGES=en_US")
        end
        it "when lang is given" do
          resource.lang("en_US")
          resource.run_action(:update)
          sets_system_locale("LANG=en_US")
        end
        it "when both lang & LC vars are given" do
          resource.lang("en_US")
          resource.lc_env({ "LC_TIME" => "en_IN" })
          resource.run_action(:update)
          sets_system_locale("LANG=en_US", "LC_TIME=en_IN")
        end
      end

      context "Unsets system variable" do
        it "when LC var is not given" do
          resource.lc_env
          resource.run_action(:update)
          unsets_system_locale("LC_MESSAGES=en_US")
        end
        it "when lang is not given" do
          resource.lang
          resource.run_action(:update)
          unsets_system_locale("LANG=en_US")
        end
        it "when both lang & LC vars are not given" do
          resource.lang
          resource.lc_env
          resource.run_action(:update)
          expect(resource).not_to be_updated_by_last_action
        end
      end
    end
  end

  context "on rhel", :rhel do
    it "raises an exception due lacking the locale-gen tool" do
      resource.lang("en_US")
      expect { resource.run_action(:update) }.to raise_error(Chef::Exceptions::ProviderNotFound)
    end
  end

  context "on macos", :macos_only do
    it "raises an exception due to being an unsupported platform" do
      resource.lang("en_US")
      expect { resource.run_action(:update) }.to raise_error(Chef::Exceptions::ProviderNotFound)
    end
  end

  # @TODO we need to enable these again
  # context "on windows", :windows_only, requires_root: false do
  #   describe "action: update" do
  #     context "Sets system locale" do
  #       it "when lang is given" do
  #         resource.lang("en-US")
  #         resource.run_action(:update)
  #       end
  #     end
  #   end
  # end
end
