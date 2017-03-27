#
# Author:: Salim Afiune (<afiune@chef.io)
#
# Copyright:: Copyright 2012-2017, Chef Software Inc.
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

describe Chef::DataCollector::ResourceReport do
  let(:cookbook_repo_path) { File.join(CHEF_SPEC_DATA, "cookbooks") }
  let(:cookbook_collection) { Chef::CookbookCollection.new(Chef::CookbookLoader.new(cookbook_repo_path)) }
  let(:node) { Chef::Node.new }
  let(:events) { Chef::EventDispatch::Dispatcher.new }
  let(:run_context) { Chef::RunContext.new(node, cookbook_collection, events) }
  let(:resource) { Chef::Resource.new("zelda", run_context) }
  let(:report) { described_class.new(resource, :create) }

  describe "#skipped" do
    let(:conditional) { double("Chef::Resource::Conditional") }

    it "should set status and conditional" do
      report.skipped(conditional)
      expect(report.conditional).to eq conditional
      expect(report.status).to eq "skipped"
    end
  end

  describe "#up_to_date" do
    it "should set status" do
      report.up_to_date
      expect(report.status).to eq "up-to-date"
    end
  end

  describe "#updated" do
    it "should set status" do
      report.updated
      expect(report.status).to eq "updated"
    end
  end

  describe "#elapsed_time_in_milliseconds" do

    context "when elapsed_time is not set" do
      it "should return nil" do
        allow(report).to receive(:elapsed_time).and_return(nil)
        expect(report.elapsed_time_in_milliseconds).to eq nil
      end
    end

    context "when elapsed_time is set" do
      it "should return it in milliseconds" do
        allow(report).to receive(:elapsed_time).and_return(1)
        expect(report.elapsed_time_in_milliseconds).to eq 1000
      end
    end
  end

  describe "#failed" do
    let(:exception) { double("Chef::Exception::Test") }

    it "should set exception and status" do
      report.failed(exception)
      expect(report.exception).to eq exception
      expect(report.status).to eq "failed"
    end
  end

  describe "#to_hash" do
    context "for a simple_resource" do
      let(:resource) do
        klass = Class.new(Chef::Resource) do
          resource_name "zelda"
        end
        klass.new("hyrule", run_context)
      end
      let(:hash) do
        {
          "after" => {},
          "before" => {},
          "delta" => "",
          "duration" => "",
          "id" => "hyrule",
          "ignore_failure" => false,
          "name" => "hyrule",
          "result" => "create",
          "status" => "unprocessed",
          "type" => :zelda,
        }
      end

      it "returns a hash containing the expected values" do
        expect(report.to_hash).to eq hash
      end
    end

    context "for a lazy_resource that got skipped" do
      let(:resource) do
        klass = Class.new(Chef::Resource) do
          resource_name "link"
          property :sword, String, name_property: true, identity: true
        end
        resource = klass.new("hyrule")
        resource.sword = Chef::DelayedEvaluator.new { nil }
        resource
      end
      let(:hash) do
        {
          "after" => {},
          "before" => {},
          "delta" => "",
          "duration" => "",
          "conditional" => "because",
          "id" => "unknown identity (due to Chef::Exceptions::ValidationFailed)",
          "ignore_failure" => false,
          "name" => "hyrule",
          "result" => "create",
          "status" => "skipped",
          "type" => :link,
        }
      end
      let(:conditional) do
        double("Chef::Resource::Conditional", :to_text => "because")
      end

      it "should handle any Exception and throw a helpful message by mocking the identity" do
        report.skipped(conditional)
        expect(report.to_hash).to eq hash
      end
    end
  end
end
