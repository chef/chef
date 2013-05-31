#
# Author:: Seth Chisamore (<schisamo@opscode.com>)
# Copyright:: Copyright (c) 2011 Opscode, Inc.
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

describe Chef::Resource::Template do

  include_context Chef::Resource::File

  let(:file_base) { "template_spec" }
  let(:expected_content) { "slappiness is a warm gun" }

  let(:node) do
    node = Chef::Node.new
    node.normal[:slappiness] = "a warm gun"
    node
  end

  def create_resource
    cookbook_repo = File.expand_path(File.join(CHEF_SPEC_DATA, "cookbooks"))
    Chef::Cookbook::FileVendor.on_create { |manifest| Chef::Cookbook::FileSystemFileVendor.new(manifest, cookbook_repo) }
    cl = Chef::CookbookLoader.new(cookbook_repo)
    cl.load_cookbooks
    cookbook_collection = Chef::CookbookCollection.new(cl)
    events = Chef::EventDispatch::Dispatcher.new
    run_context = Chef::RunContext.new(node, cookbook_collection, events)
    resource = Chef::Resource::Template.new(path, run_context)
    resource.source('openldap_stuff.conf.erb')
    resource.cookbook('openldap')

    # NOTE: partials rely on `cookbook_name` getting set by chef internals and
    # ignore the user-set `cookbook` attribute.
    resource.cookbook_name = "openldap"

    resource
  end

  let!(:resource) do
    create_resource
  end

  let(:default_mode) { ((0100666 - File.umask) & 07777).to_s(8) }

  it_behaves_like "a file resource"

  it_behaves_like "a securable resource with reporting"

  context "when the target file does not exist" do
    it "creates the template with the rendered content using the variable attribute when the :create action is run" do
      resource.source('openldap_variable_stuff.conf.erb')
      resource.variables(:secret => "nutella")
      resource.run_action(:create)
      IO.read(path).should == "super secret is nutella"
    end

    it "creates the template with the rendered content using a local erb file when the :create action is run" do
      resource.source(File.expand_path(File.join(CHEF_SPEC_DATA,'cookbooks','openldap','templates','default','openldap_stuff.conf.erb')))
      resource.cookbook(nil)
      resource.local(true)
      resource.run_action(:create)
      IO.read(path).should == expected_content
    end
  end

  describe "when the template resource defines helper methods" do

    include_context "diff disabled"

    let!(:resource) do
      r = create_resource
      r.source "helper_test.erb"
      r
    end

    let(:expected_content) { "value from helper method\n" }

    shared_examples "a template with helpers" do
      it "generates expected content by calling helper methods" do
        resource.run_action(:create)
        IO.read(path).should == expected_content
      end
    end

    context "using single helper syntax" do
      before do
        resource.helper(:helper_method) { "value from helper method" }
      end

      it_behaves_like "a template with helpers"
    end

    context "using single helper syntax referencing @node" do
      before do
        node.set[:helper_test_attr] = "value from helper method"
        resource.helper(:helper_method) { "#{@node[:helper_test_attr]}" }
      end

      it_behaves_like "a template with helpers"
    end

    context "using an inline block to define helpers" do
      before do
        resource.helpers do
          def helper_method
            "value from helper method"
          end
        end
      end

      it_behaves_like "a template with helpers"
    end

    context "using an inline block referencing @node" do
      before do
        node.set[:helper_test_attr] = "value from helper method"

        resource.helpers do
          def helper_method
            @node[:helper_test_attr]
          end
        end
      end

      it_behaves_like "a template with helpers"

    end

    context "using a module from a library" do

      module ExampleModule
        def helper_method
          "value from helper method"
        end
      end

      before do
        resource.helpers(ExampleModule)
      end

      it_behaves_like "a template with helpers"

    end
    context "using a module from a library referencing @node" do

      module ExampleModuleReferencingATNode
        def helper_method
          @node[:helper_test_attr]
        end
      end

      before do
        node.set[:helper_test_attr] = "value from helper method"

        resource.helpers(ExampleModuleReferencingATNode)
      end

      it_behaves_like "a template with helpers"

    end

    context "using helpers with partial templates" do
      before do
        resource.source("helpers_via_partial_test.erb")
        resource.helper(:helper_method) { "value from helper method" }
      end

      it_behaves_like "a template with helpers"

    end
  end

  describe "when template source contains windows style line endings" do

    include_context "diff disabled"

    let (:expected_content) {
      "Template rendering libraries\r\nshould support\r\ndifferent line endings\r\n\r\n"
    }

    context "for all lines" do
      let!(:resource) do
        r = create_resource
        r.source "all_windows_line_endings.erb"
        r
      end

      it "output should contain windows line endings" do
        resource.run_action(:create)
        IO.read(path).each_line do |line|
          line.should end_with("\r\n")
        end
      end
    end

    context "for some lines" do
      let!(:resource) do
        r = create_resource
        r.source "some_windows_line_endings.erb"
        r
      end

      it "output should contain windows line endings" do
        resource.run_action(:create)
        IO.read(path).each_line do |line|
          line.should end_with("\r\n")
        end
      end
    end

    context "for no lines" do
      let!(:resource) do
        r = create_resource
        r.source "no_windows_line_endings.erb"
        r
      end

      it "output should not contain windows line endings" do
        resource.run_action(:create)
        IO.read(path).each_line do |line|
          line.should_not end_with("\r\n")
        end
      end
    end
  end

end
