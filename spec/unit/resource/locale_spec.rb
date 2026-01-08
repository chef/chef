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

describe Chef::Resource::Locale do

  let(:resource) { Chef::Resource::Locale.new("fakey_fakerton") }
  let(:provider) { resource.provider_for_action(:update) }

  describe "default:" do
    it "name would be locale" do
      expect(resource.resource_name).to eq(:locale)
    end
    it "lang would be nil" do
      expect(resource.lang).to be_nil
    end
    it "lc_env would be an empty hash" do
      expect(resource.lc_env).to be_a(Hash)
      expect(resource.lc_env).to be_empty
    end
    it "action would be :update" do
      expect(resource.action).to eql([:update])
    end
  end

  describe "validations:" do
    let(:validation) { Chef::Exceptions::ValidationFailed }
    context "lang" do
      it "is non empty" do
        expect { resource.lang("") }.to raise_error(validation)
      end
      it "does not contain any leading whitespaces" do
        expect { resource.lang("  XX") }.to raise_error(validation)
      end
    end

    context "lc_env" do
      it "is non empty" do
        expect { resource.lc_env({ "LC_TIME" => "" }) }.to raise_error(validation)
      end
      it "does not contain any leading whitespaces" do
        expect { resource.lc_env({ "LC_TIME" => " XX" }) }.to raise_error(validation)
      end
      it "keys are valid and case sensitive" do
        expect { resource.lc_env({ "LC_TIMES" => " XX" }) }.to raise_error(validation)
        expect { resource.lc_env({ "Lc_Time" => " XX" }) }.to raise_error(validation)
        expect(resource.lc_env({ "LC_TIME" => "XX" })).to eql({ "LC_TIME" => "XX" })
      end
    end
  end

  describe "#unavailable_locales" do
    let(:available_locales) do
      <<~LOC
        C
        C.UTF-8
        en_AG
        en_AG.utf8
        en_US
        POSIX
      LOC
    end
    before do
      dummy = Mixlib::ShellOut.new
      allow_any_instance_of(Chef::Mixin::ShellOut).to receive(:shell_out!).with("locale -a").and_return(dummy)
      allow(dummy).to receive(:stdout).and_return(available_locales)
    end
    context "when all locales are available on system" do
      context "with both properties" do
        it "returns an empty array" do
          resource.lang("en_US")
          resource.lc_env({ "LC_TIME" => "en_AG.utf8", "LC_MESSAGES" => "en_AG.utf8" })
          expect(provider.unavailable_locales).to eq([])
        end
      end
      context "without lang" do
        it "returns an empty array" do
          resource.lang
          resource.lc_env({ "LC_TIME" => "en_AG.utf8", "LC_MESSAGES" => "en_AG.utf8" })
          expect(provider.unavailable_locales).to eq([])
        end
      end
      context "without lc_env" do
        it "returns an empty array" do
          resource.lang("en_US")
          resource.lc_env
          expect(provider.unavailable_locales).to eq([])
        end
      end
      context "without both" do
        it "returns an empty array" do
          resource.lang
          resource.lc_env
          expect(provider.unavailable_locales).to eq([])
        end
      end
    end

    context "when some locales are not available" do
      context "with both properties" do
        it "returns list" do
          resource.lang("de_DE")
          resource.lc_env({ "LC_TIME" => "en_AG.utf8", "LC_MESSAGES" => "en_US.utf8" })
          expect(provider.unavailable_locales).to eq(["de_DE", "en_US.utf8"])
        end
      end
      context "without lang" do
        it "returns list" do
          resource.lang
          resource.lc_env({ "LC_TIME" => "en_AG.utf8", "LC_MESSAGES" => "en_US.utf8" })
          expect(provider.unavailable_locales).to eq(["en_US.utf8"])
        end
      end
      context "without lc_env" do
        it "returns list" do
          resource.lang("de_DE")
          resource.lc_env
          expect(provider.unavailable_locales).to eq(["de_DE"])
        end
      end
      context "without both" do
        it "returns an empty array" do
          resource.lang
          resource.lc_env
          expect(provider.unavailable_locales).to eq([])
        end
      end
    end
  end

  describe "#new_content" do
    context "with both properties" do
      before do
        resource.lang("en_US")
        resource.lc_env({ "LC_TIME" => "en_AG.utf8", "LC_MESSAGES" => "en_AG.utf8" })
      end
      it "returns string" do
        expect(provider.new_content).to be_a(String)
        expect(provider.new_content).not_to be_empty
      end
      it "keys will be sorted" do
        expect(provider.new_content.split("\n").map { |x| x.split("=") }.collect(&:first)).to eq(%w{LANG LC_MESSAGES LC_TIME})
      end
      it "ends with a new-line character" do
        expect(provider.new_content[-1]).to eq("\n")
      end
      it "returns a valid string" do
        expect(provider.new_content).to eq("LANG=en_US\nLC_MESSAGES=en_AG.utf8\nLC_TIME=en_AG.utf8\n")
      end
    end
    context "without lang" do
      it "returns a valid string" do
        resource.lang
        resource.lc_env({ "LC_TIME" => "en_AG.utf8", "LC_MESSAGES" => "en_AG.utf8" })
        expect(provider.new_content).to eq("LC_MESSAGES=en_AG.utf8\nLC_TIME=en_AG.utf8\n")
      end
    end
    context "without lc_env" do
      it "returns a valid string" do
        resource.lang("en_US")
        resource.lc_env
        expect(provider.new_content).to eq("LANG=en_US\n")
      end
    end
    context "without both" do
      it "returns string with only new-line character" do
        resource.lang
        resource.lc_env
        expect(provider.new_content).to eq("\n")
      end
    end
  end
end
