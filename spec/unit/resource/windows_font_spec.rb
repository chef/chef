#
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

describe Chef::Resource::WindowsFont do
  let(:resource) { Chef::Resource::WindowsFont.new("fakey_fakerton") }

  it "sets resource name as :windows_font" do
    expect(resource.resource_name).to eql(:windows_font)
  end

  it "the font_name property is the name_property" do
    expect(resource.font_name).to eql("fakey_fakerton")
  end

  it "sets the default action as :install" do
    expect(resource.action).to eql([:install])
  end

  it "supports :install action" do
    expect { resource.action :install }.not_to raise_error
  end

  it "coerces backslashes in the source property to forward slashes" do
    resource.source 'C:\foo\bar\fontfile'
    expect(resource.source).to eql("C:/foo/bar/fontfile")
  end

  describe "when the font lives in a cookbook subdirectory" do
    let(:node) { Chef::Node.new }
    let(:events) { Chef::EventDispatch::Dispatcher.new }
    let(:run_context) { Chef::RunContext.new(node, {}, events) }
    let(:resource) { Chef::Resource::WindowsFont.new('fonts\Source_Sans_Pro\SourceSansPro-Regular.ttf') }
    let(:provider) do
      resource.run_context = run_context
      resource.provider_for_action(:install)
    end

    before do
      stub_const("ENV", ENV.to_hash.merge("TEMP" => "C:/tmp"))
    end

    it "strips the directories when naming the staged file" do
      expect(provider.font_basename).to eq("SourceSansPro-Regular.ttf")
    end

    it "stages the font flat in TEMP rather than under the cookbook subdirectory" do
      # PathHelper.join uses the platform separator, so build the expectation
      # the same way rather than hardcoding one
      expect(provider.temp_font_path).to eq(Chef::Util::PathHelper.join("C:/tmp", "SourceSansPro-Regular.ttf"))
      expect(provider.temp_font_path).not_to include("Source_Sans_Pro")
    end

    it "keeps the subdirectory when looking the file up in the cookbook" do
      expect(provider.cookbook_source_path).to eq("fonts/Source_Sans_Pro/SourceSansPro-Regular.ttf")
    end
  end

  describe "when the font name is a bare file name" do
    let(:node) { Chef::Node.new }
    let(:events) { Chef::EventDispatch::Dispatcher.new }
    let(:run_context) { Chef::RunContext.new(node, {}, events) }
    let(:resource) { Chef::Resource::WindowsFont.new("Custom.ttf") }
    let(:provider) do
      resource.run_context = run_context
      resource.provider_for_action(:install)
    end

    before do
      stub_const("ENV", ENV.to_hash.merge("TEMP" => "C:/tmp"))
    end

    it "leaves the name alone" do
      expect(provider.font_basename).to eq("Custom.ttf")
      expect(provider.cookbook_source_path).to eq("Custom.ttf")
      expect(provider.temp_font_path).to eq(Chef::Util::PathHelper.join("C:/tmp", "Custom.ttf"))
    end
  end
end
