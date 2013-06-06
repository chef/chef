#
# Author:: Lamont Granquist (<lamont@opscode.com>)
# Copyright:: Copyright (c) 2013 Opscode, Inc.
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

describe Chef::Provider::Template::Content do

  let(:new_resource) do
    mock("Chef::Resource::Template (new)",
         :cookbook_name => 'openldap',
         :source => 'openldap_stuff.conf.erb',
         :local => false,
         :cookbook => nil,
         :variables => {},
         :inline_helper_blocks => {},
         :inline_helper_modules => [],
         :helper_modules => [])
  end

  let(:rendered_file_location) { Dir.tmpdir + '/openldap_stuff.conf' }

  let(:run_context) do
    cookbook_repo = File.expand_path(File.join(CHEF_SPEC_DATA, "cookbooks"))
    Chef::Cookbook::FileVendor.on_create { |manifest| Chef::Cookbook::FileSystemFileVendor.new(manifest, cookbook_repo) }
    cl = Chef::CookbookLoader.new(cookbook_repo)
    cl.load_cookbooks
    cookbook_collection = Chef::CookbookCollection.new(cl)
    node = Chef::Node.new
    mock("Chef::Resource::RunContext", :node => node, :cookbook_collection => cookbook_collection)
  end

  let(:content) do
    current_resource = mock("Chef::Resource::Template (current)")
    Chef::Provider::Template::Content.new(new_resource, current_resource, run_context)
  end

  after do
    FileUtils.rm(rendered_file_location) if ::File.exist?(rendered_file_location)
  end

  it "finds the template file in the cookbook cache if it isn't local" do
    content.template_location.should == CHEF_SPEC_DATA + '/cookbooks/openldap/templates/default/openldap_stuff.conf.erb'
  end

  it "finds the template file locally if it is local" do
    new_resource.stub!(:local).and_return(true)
    new_resource.stub!(:source).and_return('/tmp/its_on_disk.erb')
    content.template_location.should == '/tmp/its_on_disk.erb'
  end

  it "should use the cookbook name if defined in the template resource" do
    new_resource.stub!(:cookbook_name).and_return('apache2')
    new_resource.stub!(:cookbook).and_return('openldap')
    new_resource.stub!(:source).and_return("test.erb")
    content.template_location.should == CHEF_SPEC_DATA + '/cookbooks/openldap/templates/default/test.erb'
  end

  it "creates the template with the rendered content" do
    run_context.node.normal[:slappiness] = "a warm gun"
    IO.read(content.tempfile.path).should == "slappiness is a warm gun"
  end

end
