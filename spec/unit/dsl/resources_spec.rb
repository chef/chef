#
# Author:: Noah Kantrowitz (<noah@coderanger.net>)
# Copyright:: Copyright 2015-2016, Noah Kantrowitz
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
require "chef/dsl/resources"

describe Chef::DSL::Resources do
  let(:declared_resources) { [] }
  let(:test_class) do
    r = declared_resources
    Class.new do
      include Chef::DSL::Resources
      define_method(:declare_resource) do |dsl_name, name, _created_at|
        r << [dsl_name, name]
      end
    end
  end
  subject { declared_resources }
  after do
    # Always clean up after ourselves.
    described_class.remove_resource_dsl(:test_resource)
  end

  context "with a resource added" do
    before do
      Chef::DSL::Resources.add_resource_dsl(:test_resource)
      test_class.new.instance_eval do
        test_resource "test_name" do
        end
      end
    end
    it { is_expected.to eq [[:test_resource, "test_name"]] }
  end

  context "with no resource added" do
    subject do
      test_class.new.instance_eval do
        test_resource "test_name" do
        end
      end
    end

    it { expect { subject }.to raise_error NoMethodError }
  end

  context "with a resource added and removed" do
    before do
      Chef::DSL::Resources.add_resource_dsl(:test_resource)
      Chef::DSL::Resources.remove_resource_dsl(:test_resource)
    end
    subject do
      test_class.new.instance_eval do
        test_resource "test_name" do
        end
      end
    end

    it { expect { subject }.to raise_error NoMethodError }
  end

  context "with a nameless resource" do
    before do
      Chef::DSL::Resources.add_resource_dsl(:test_resource)
      test_class.new.instance_eval do
        test_resource {}
      end
    end
    it { is_expected.to eq [[:test_resource, nil]] }
  end
end
