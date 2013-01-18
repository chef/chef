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
    resource
  end

  let!(:resource) do
    create_resource
  end

  let(:default_mode) do
    # TODO: Lots of ugly here :(
    # RemoteFile uses FileUtils.cp. FileUtils does a copy by opening the
    # destination file and writing to it. Before 1.9.3, it does not preserve
    # the mode of the copied file. In 1.9.3 and after, it does. So we have to
    # figure out what the default mode ought to be via heuristic.

    t = Tempfile.new("get-the-mode")
    path = t.path
    path_2 = t.path + "fileutils-mode-test"
    FileUtils.cp(path, path_2)
    t.close
    m = File.stat(path_2).mode
    (07777 & m).to_s(8)
  end


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
end
