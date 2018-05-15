#
# Author:: Lamont Granquist (<lamont@chef.io>)
# Copyright:: Copyright 2013-2016, Chef Software Inc.
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

describe Chef::Provider::Template::Content do

  let(:enclosing_directory) do
    canonicalize_path(Dir.mktmpdir)
  end

  let(:resource_path) do
    canonicalize_path(File.expand_path(File.join(enclosing_directory, "openldap_stuff.conf")))
  end

  let(:new_resource) do
    double("Chef::Resource::Template (new)",
         :cookbook_name => "openldap",
         :recipe_name => "default",
         :source_line => "/Users/lamont/solo/cookbooks/openldap/recipes/default.rb:2:in `from_file'",
         :source_line_file => "/Users/lamont/solo/cookbooks/openldap/recipes/default.rb",
         :source_line_number => "2",
         :source => "openldap_stuff.conf.erb",
         :name => "openldap_stuff.conf",
         :path => resource_path,
         :local => false,
         :cookbook => nil,
         :variables => {},
         :inline_helper_blocks => {},
         :inline_helper_modules => [],
         :helper_modules => [])
  end

  let(:rendered_file_locations) do
    [Dir.tmpdir + "/openldap_stuff.conf",
     enclosing_directory + "/openldap_stuff.conf"]
  end

  let(:run_context) do
    cookbook_repo = File.expand_path(File.join(CHEF_SPEC_DATA, "cookbooks"))
    Chef::Cookbook::FileVendor.fetch_from_disk(cookbook_repo)
    cl = Chef::CookbookLoader.new(cookbook_repo)
    cl.load_cookbooks
    cookbook_collection = Chef::CookbookCollection.new(cl)
    node = Chef::Node.new
    double("Chef::Resource::RunContext", :node => node, :cookbook_collection => cookbook_collection)
  end

  let(:content) do
    current_resource = double("Chef::Resource::Template (current)")
    Chef::Provider::Template::Content.new(new_resource, current_resource, run_context)
  end

  after do
    rendered_file_locations.each do |file|
      FileUtils.rm(file) if ::File.exist?(file)
    end
  end

  it "finds the template file in the cookbook cache if it isn't local" do
    expect(content.template_location).to eq(CHEF_SPEC_DATA + "/cookbooks/openldap/templates/default/openldap_stuff.conf.erb")
  end

  it "finds the template file locally if it is local" do
    allow(new_resource).to receive(:local).and_return(true)
    allow(new_resource).to receive(:source).and_return("/tmp/its_on_disk.erb")
    expect(content.template_location).to eq("/tmp/its_on_disk.erb")
  end

  it "should use the cookbook name if defined in the template resource" do
    allow(new_resource).to receive(:cookbook_name).and_return("apache2")
    allow(new_resource).to receive(:cookbook).and_return("openldap")
    allow(new_resource).to receive(:source).and_return("test.erb")
    expect(content.template_location).to eq(CHEF_SPEC_DATA + "/cookbooks/openldap/templates/default/test.erb")
  end

  it "returns a tempfile in the tempdir when :file_staging_uses_destdir is not set" do
    Chef::Config[:file_staging_uses_destdir] = false
    expect(content.tempfile.path.start_with?(Dir.tmpdir)).to be true
    expect(canonicalize_path(content.tempfile.path).start_with?(enclosing_directory)).to be false
  end

  it "returns a tempfile in the destdir when :file_staging_uses_destdir is set" do
    Chef::Config[:file_staging_uses_destdir] = true
    expect(canonicalize_path(content.tempfile.path).start_with?(enclosing_directory)).to be true
  end

  context "when creating a tempfile in destdir fails" do
    let(:enclosing_directory) do
      canonicalize_path("/nonexisting/path")
    end

    it "returns a tempfile in the tempdir when :file_deployment_uses_destdir is set to :auto" do
      Chef::Config[:file_staging_uses_destdir] = :auto
      expect(content.tempfile.path.start_with?(Dir.tmpdir)).to be true
      expect(canonicalize_path(content.tempfile.path).start_with?(enclosing_directory)).to be false
    end

    it "fails when :file_desployment_uses_destdir is set" do
      Chef::Config[:file_staging_uses_destdir] = true
      expect { content.tempfile }.to raise_error(Chef::Exceptions::FileContentStagingError)
    end

    it "returns a tempfile in the tempdir when :file_desployment_uses_destdir is not set" do
      expect(content.tempfile.path.start_with?(Dir.tmpdir)).to be true
      expect(canonicalize_path(content.tempfile.path).start_with?(enclosing_directory)).to be false
    end
  end

  it "creates the template with the rendered content" do
    run_context.node.normal[:slappiness] = "a warm gun"
    expect(IO.read(content.tempfile.path)).to eq("slappiness is a warm gun")
  end

  describe "when using location helpers" do
    let(:new_resource) do
      double("Chef::Resource::Template (new)",
             :cookbook_name => "openldap",
             :recipe_name => "default",
             :source_line => CHEF_SPEC_DATA + "/cookbooks/openldap/recipes/default.rb:2:in `from_file'",
             :source_line_file => CHEF_SPEC_DATA + "/cookbooks/openldap/recipes/default.rb",
             :source_line_number => "2",
             :source => "helpers.erb",
             :name => "helpers.erb",
             :path => CHEF_SPEC_DATA + "/cookbooks/openldap/templates/default/helpers.erb",
             :local => false,
             :cookbook => nil,
             :variables => {},
             :inline_helper_blocks => {},
             :inline_helper_modules => [],
             :helper_modules => [])
    end

    it "creates the template with the rendered content" do
      expect(IO.read(content.tempfile.path)).to eql <<EOF
openldap
default
#{CHEF_SPEC_DATA}/cookbooks/openldap/recipes/default.rb:2:in `from_file'
#{CHEF_SPEC_DATA}/cookbooks/openldap/recipes/default.rb
2
helpers.erb
#{CHEF_SPEC_DATA}/cookbooks/openldap/templates/default/helpers.erb
openldap
default
#{CHEF_SPEC_DATA}/cookbooks/openldap/recipes/default.rb:2:in `from_file'
#{CHEF_SPEC_DATA}/cookbooks/openldap/recipes/default.rb
2
helpers.erb
#{CHEF_SPEC_DATA}/cookbooks/openldap/templates/default/helpers.erb
EOF
    end

  end
end
