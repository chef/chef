#
# Author:: Adam Jacob (<adam@chef.io>)
# Author:: Tim Hinderliter (<tim@chef.io>)
# Author:: Christopher Walters (<cw@chef.io>)
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
require "support/lib/library_load_order"

describe Chef::RunContext::ChildRunContext do
  context "with a run context with stuff in it" do
    let(:chef_repo_path) { File.expand_path(File.join(CHEF_SPEC_DATA, "run_context", "cookbooks")) }
    let(:cookbook_collection) do
      cl = Chef::CookbookLoader.new(chef_repo_path)
      cl.load_cookbooks
      Chef::CookbookCollection.new(cl)
    end
    let(:node) do
      node = Chef::Node.new
      node.run_list << "test" << "test::one" << "test::two"
      node
    end
    let(:events) { Chef::EventDispatch::Dispatcher.new }
    let(:run_context) { Chef::RunContext.new(node, cookbook_collection, events) }

    context "and a child run context" do
      let(:child) { run_context.create_child }

      it "parent_run_context is set to the parent" do
        expect(child.parent_run_context).to eq run_context
      end

      it "audits is not the same as the parent" do
        expect(child.audits.object_id).not_to eq run_context.audits.object_id
        child.audits["hi"] = "lo"
        expect(child.audits["hi"]).to eq("lo")
        expect(run_context.audits["hi"]).not_to eq("lo")
      end

      it "resource_collection is not the same as the parent" do
        expect(child.resource_collection.object_id).not_to eq run_context.resource_collection.object_id
        f = Chef::Resource::File.new("hi", child)
        child.resource_collection.insert(f)
        expect(child.resource_collection).to include f
        expect(run_context.resource_collection).not_to include f
      end

      it "immediate_notification_collection is not the same as the parent" do
        expect(child.immediate_notification_collection.object_id).not_to eq run_context.immediate_notification_collection.object_id
        src = Chef::Resource::File.new("hi", child)
        dest = Chef::Resource::File.new("argh", child)
        notification = Chef::Resource::Notification.new(dest, :create, src)
        child.notifies_immediately(notification)
        expect(child.immediate_notification_collection["file[hi]"]).to eq([notification])
        expect(run_context.immediate_notification_collection["file[hi]"]).not_to eq([notification])
      end

      it "immediate_notifications is not the same as the parent" do
        src = Chef::Resource::File.new("hi", child)
        dest = Chef::Resource::File.new("argh", child)
        notification = Chef::Resource::Notification.new(dest, :create, src)
        child.notifies_immediately(notification)
        expect(child.immediate_notifications(src)).to eq([notification])
        expect(run_context.immediate_notifications(src)).not_to eq([notification])
      end

      it "delayed_notification_collection is not the same as the parent" do
        expect(child.delayed_notification_collection.object_id).not_to eq run_context.delayed_notification_collection.object_id
        src = Chef::Resource::File.new("hi", child)
        dest = Chef::Resource::File.new("argh", child)
        notification = Chef::Resource::Notification.new(dest, :create, src)
        child.notifies_delayed(notification)
        expect(child.delayed_notification_collection["file[hi]"]).to eq([notification])
        expect(run_context.delayed_notification_collection["file[hi]"]).not_to eq([notification])
      end

      it "delayed_notifications is not the same as the parent" do
        src = Chef::Resource::File.new("hi", child)
        dest = Chef::Resource::File.new("argh", child)
        notification = Chef::Resource::Notification.new(dest, :create, src)
        child.notifies_delayed(notification)
        expect(child.delayed_notifications(src)).to eq([notification])
        expect(run_context.delayed_notifications(src)).not_to eq([notification])
      end

      it "create_child creates a child-of-child" do
        c = child.create_child
        expect(c.parent_run_context).to eq child
      end

      context "after load('include::default')" do
        before do
          run_list = Chef::RunList.new("include::default").expand("_default")
          # TODO not sure why we had to do this to get everything to work ...
          node.automatic_attrs[:recipes] = []
          child.load(run_list)
        end

        it "load_recipe loads into the child" do
          expect(child.resource_collection).to be_empty
          child.load_recipe("include::includee")
          expect(child.resource_collection).not_to be_empty
        end

        it "include_recipe loads into the child" do
          expect(child.resource_collection).to be_empty
          child.include_recipe("include::includee")
          expect(child.resource_collection).not_to be_empty
        end

        it "load_recipe_file loads into the child" do
          expect(child.resource_collection).to be_empty
          child.load_recipe_file(File.expand_path("include/recipes/includee.rb", chef_repo_path))
          expect(child.resource_collection).not_to be_empty
        end
      end
    end
  end
end
