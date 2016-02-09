#
# Author:: Adam Jacob (<adam@chef.io>)
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
require "chef/role"

describe Chef::Role do
  before(:each) do
    allow(ChefConfig).to receive(:windows?) { false }
    @role = Chef::Role.new
    @role.name("ops_master")
  end

  it "has a name" do
    expect(@role.name("ops_master")).to eq("ops_master")
  end

  it "does not accept a name with spaces" do
    expect { @role.name "ops master" }.to raise_error(ArgumentError)
  end

  it "does not accept non-String objects for the name" do
    expect { @role.name({}) }.to raise_error(ArgumentError)
  end

  describe "when a run list is set" do

    before do
      @role.run_list(%w{ nginx recipe[ree] role[base]})
    end

    it "returns the run list" do
      expect(@role.run_list).to eq(%w{ nginx recipe[ree] role[base]})
    end

    describe "and per-environment run lists are set" do
      before do
        @role.name("base")
        @role.run_list(%w{ recipe[nagios::client] recipe[tims-acl::bork]})
        @role.env_run_list["prod"] = Chef::RunList.new(*(@role.run_list.to_a << "recipe[prod-base]"))
        @role.env_run_list["dev"]  = Chef::RunList.new
      end

      it "uses the default run list as *the* run_list" do
        expect(@role.run_list).to eq(Chef::RunList.new("recipe[nagios::client]", "recipe[tims-acl::bork]"))
      end

      it "gives the default run list as the when getting the _default run list" do
        expect(@role.run_list_for("_default")).to eq(@role.run_list)
      end

      it "gives an environment specific run list" do
        expect(@role.run_list_for("prod")).to eq(Chef::RunList.new("recipe[nagios::client]", "recipe[tims-acl::bork]", "recipe[prod-base]"))
      end

      it "gives the default run list when no run list exists for the given environment" do
        expect(@role.run_list_for("qa")).to eq(@role.run_list)
      end

      it "gives the environment specific run list even if it is empty" do
        expect(@role.run_list_for("dev")).to eq(Chef::RunList.new)
      end

      it "env_run_lists can only be set with _default run list in it" do
        long_exception_name = Chef::Exceptions::InvalidEnvironmentRunListSpecification
        expect { @role.env_run_lists({}) }.to raise_error(long_exception_name)
      end

    end

    describe "using the old #recipes API" do
      it "should let you set the recipe array" do
        expect(@role.recipes(%w{one two})).to eq(%w{one two})
      end

      it "should let you return the recipe array" do
        @role.recipes(%w{one two})
        expect(@role.recipes).to eq(%w{one two})
      end

      it "should not list roles in the recipe array" do
        @role.run_list([ "one", "role[two]"])
        expect(@role.recipes).to eq([ "recipe[one]", "role[two]" ])
      end

    end

  end

  describe "default_attributes" do
    it "should let you set the default attributes hash explicitly" do
      expect(@role.default_attributes({ :one => "two" })).to eq({ :one => "two" })
    end

    it "should let you return the default attributes hash" do
      @role.default_attributes({ :one => "two" })
      expect(@role.default_attributes).to eq({ :one => "two" })
    end

    it "should throw an ArgumentError if we aren't a kind of hash" do
      expect { @role.default_attributes(Array.new) }.to raise_error(ArgumentError)
    end
  end

  describe "override_attributes" do
    it "should let you set the override attributes hash explicitly" do
      expect(@role.override_attributes({ :one => "two" })).to eq({ :one => "two" })
    end

    it "should let you return the override attributes hash" do
      @role.override_attributes({ :one => "two" })
      expect(@role.override_attributes).to eq({ :one => "two" })
    end

    it "should throw an ArgumentError if we aren't a kind of hash" do
      expect { @role.override_attributes(Array.new) }.to raise_error(ArgumentError)
    end
  end

  describe "update_from!" do
    before(:each) do
      @role.name("mars_volta")
      @role.description("Great band!")
      @role.run_list("one", "two", "role[a]")
      @role.default_attributes({ :el_groupo => "nuevo" })
      @role.override_attributes({ :deloused => "in the comatorium" })

      @example = Chef::Role.new
      @example.name("newname")
      @example.description("Really Great band!")
      @example.run_list("alpha", "bravo", "role[alpha]")
      @example.default_attributes({ :el_groupo => "nuevo dos" })
      @example.override_attributes({ :deloused => "in the comatorium XOXO" })
    end

    it "should update all fields except for name" do
      @role.update_from!(@example)
      expect(@role.name).to eq("mars_volta")
      expect(@role.description).to eq(@example.description)
      expect(@role.run_list).to eq(@example.run_list)
      expect(@role.default_attributes).to eq(@example.default_attributes)
      expect(@role.override_attributes).to eq(@example.override_attributes)
    end
  end

  describe "when serialized as JSON", :json => true do
    before(:each) do
      @role.name("mars_volta")
      @role.description("Great band!")
      @role.run_list("one", "two", "role[a]")
      @role.default_attributes({ :el_groupo => "nuevo" })
      @role.override_attributes({ :deloused => "in the comatorium" })
      @serialized_role = Chef::JSONCompat.to_json(@role)
    end

    it "should serialize to a json hash" do
      expect(Chef::JSONCompat.to_json(@role)).to match(/^\{.+\}$/)
    end

    it "includes the name in the JSON output" do
      expect(@serialized_role).to match(/"name":"mars_volta"/)
    end

    it "includes its description in the JSON" do
      expect(@serialized_role).to match(/"description":"Great band!"/)
    end

    it "should include 'default_attributes'" do
      expect(@serialized_role).to match(/"default_attributes":\{"el_groupo":"nuevo"\}/)
    end

    it "should include 'override_attributes'" do
      expect(@serialized_role).to match(/"override_attributes":\{"deloused":"in the comatorium"\}/)
    end

    it "should include 'run_list'" do
      #Activesupport messes with Chef json formatting
      #This test should pass with and without activesupport
      expect(@serialized_role).to match(/"run_list":\["recipe\[one\]","recipe\[two\]","role\[a\]"\]/)
    end

    describe "and it has per-environment run lists" do
      before do
        @role.env_run_lists("_default" => ["one", "two", "role[a]"], "production" => ["role[monitoring]", "role[auditing]", "role[apache]"], "dev" => ["role[nginx]"])
        @serialized_role = Chef::JSONCompat.parse(Chef::JSONCompat.to_json(@role), :create_additions => false)
      end

      it "includes the per-environment run lists" do
        #Activesupport messes with Chef json formatting
        #This test should pass with and without activesupport
        expect(@serialized_role["env_run_lists"]["production"]).to eq(["role[monitoring]", "role[auditing]", "role[apache]"])
        expect(@serialized_role["env_run_lists"]["dev"]).to eq(["role[nginx]"])
      end

      it "does not include the default environment in the per-environment run lists" do
        expect(@serialized_role["env_run_lists"]).not_to have_key("_default")
      end

    end

    include_examples "to_json equivalent to Chef::JSONCompat.to_json" do
      let(:jsonable) { @role }
    end
  end

  describe "when created from JSON", :json => true do
    before(:each) do
      @role.name("mars_volta")
      @role.description("Great band!")
      @role.run_list("one", "two", "role[a]")
      @role.default_attributes({ "el_groupo" => "nuevo" })
      @role.override_attributes({ "deloused" => "in the comatorium" })
      @deserial = Chef::Role.from_hash(Chef::JSONCompat.parse(Chef::JSONCompat.to_json(@role)))
    end

    it "should deserialize to a Chef::Role object" do
      expect(@deserial).to be_a_kind_of(Chef::Role)
    end

    %w{
      name
      description
      default_attributes
      override_attributes
      run_list
    }.each do |t|
      it "should preserves the '#{t}' attribute from the JSON object" do
        expect(@deserial.send(t.to_sym)).to eq(@role.send(t.to_sym))
      end
    end
  end

  ROLE_DSL = <<-EOR
name "ceiling_cat"
description "like Aliens, but furry"
EOR

  describe "when loading from disk" do
    before do
      default_cache_path = windows? ? 'C:\chef' : "/var/chef"
      allow(Chef::Config).to receive(:cache_path).and_return(default_cache_path)
    end

    it "should return a Chef::Role object from JSON" do
      expect(Dir).to receive(:glob).and_return(["#{Chef::Config[:role_path]}/memes", "#{Chef::Config[:role_path]}/memes/lolcat.json"])
      file_path = File.join(Chef::Config[:role_path], "memes/lolcat.json")
      expect(File).to receive(:exists?).with(file_path).exactly(1).times.and_return(true)
      expect(IO).to receive(:read).with(file_path).and_return('{"name": "ceiling_cat", "json_class": "Chef::Role" }')
      expect(@role).to be_a_kind_of(Chef::Role)
      @role.class.from_disk("lolcat")
    end

    it "should return a Chef::Role object from a Ruby DSL" do
      expect(Dir).to receive(:glob).and_return(["#{Chef::Config[:role_path]}/memes", "#{Chef::Config[:role_path]}/memes/lolcat.rb"])
      rb_path = File.join(Chef::Config[:role_path], "memes/lolcat.rb")
      expect(File).to receive(:exists?).with(rb_path).exactly(2).times.and_return(true)
      expect(File).to receive(:readable?).with(rb_path).exactly(1).times.and_return(true)
      expect(IO).to receive(:read).with(rb_path).and_return(ROLE_DSL)
      expect(@role).to be_a_kind_of(Chef::Role)
      @role.class.from_disk("lolcat")
    end

    it "should prefer a Chef::Role Object from JSON over one from a Ruby DSL" do
      expect(Dir).to receive(:glob).and_return(["#{Chef::Config[:role_path]}/memes", "#{Chef::Config[:role_path]}/memes/lolcat.json", "#{Chef::Config[:role_path]}/memes/lolcat.rb"])
      js_path = File.join(Chef::Config[:role_path], "memes/lolcat.json")
      rb_path = File.join(Chef::Config[:role_path], "memes/lolcat.rb")
      expect(File).to receive(:exists?).with(js_path).exactly(1).times.and_return(true)
      expect(File).not_to receive(:exists?).with(rb_path)
      expect(IO).to receive(:read).with(js_path).and_return('{"name": "ceiling_cat", "json_class": "Chef::Role" }')
      expect(@role).to be_a_kind_of(Chef::Role)
      @role.class.from_disk("lolcat")
    end

    it "should raise an exception if the file does not exist" do
      expect(Dir).to receive(:glob).and_return(["#{Chef::Config[:role_path]}/meme.rb"])
      expect(File).not_to receive(:exists?)
      expect { @role.class.from_disk("lolcat") }.to raise_error(Chef::Exceptions::RoleNotFound)
    end

    it "should raise an exception if two files exist with the same name" do
      expect(Dir).to receive(:glob).and_return(["#{Chef::Config[:role_path]}/memes/lolcat.rb", "#{Chef::Config[:role_path]}/lolcat.rb"])
      expect(File).not_to receive(:exists?)
      expect { @role.class.from_disk("lolcat") }.to raise_error(Chef::Exceptions::DuplicateRole)
    end

    it "should not raise an exception if two files exist with a similar name" do
      expect(Dir).to receive(:glob).and_return(["#{Chef::Config[:role_path]}/memes/lolcat.rb", "#{Chef::Config[:role_path]}/super_lolcat.rb"])
      expect(File).to receive(:exists?).with("#{Chef::Config[:role_path]}/memes/lolcat.rb").and_return(true)
      allow_any_instance_of(Chef::Role).to receive(:from_file).with("#{Chef::Config[:role_path]}/memes/lolcat.rb")
      expect { @role.class.from_disk("lolcat") }.not_to raise_error
    end
  end

  describe "when loading from disk and role_path is an array" do

    before(:each) do
      Chef::Config[:role_path] = ["/path1", "/path/path2"]
    end

    it "should return a Chef::Role object from JSON" do
      expect(Dir).to receive(:glob).with(File.join("/path1", "**", "**")).exactly(1).times.and_return(["/path1/lolcat.json"])
      expect(File).to receive(:exists?).with("/path1/lolcat.json").exactly(1).times.and_return(true)
      expect(IO).to receive(:read).with("/path1/lolcat.json").and_return('{"name": "ceiling_cat", "json_class": "Chef::Role" }')
      expect(@role).to be_a_kind_of(Chef::Role)
      @role.class.from_disk("lolcat")
    end

    it "should return a Chef::Role object from JSON when role is in the second path" do
      expect(Dir).to receive(:glob).with(File.join("/path1", "**", "**")).exactly(1).times.and_return([])
      expect(Dir).to receive(:glob).with(File.join("/path/path2", "**", "**")).exactly(1).times.and_return(["/path/path2/lolcat.json"])
      expect(File).to receive(:exists?).with("/path/path2/lolcat.json").exactly(1).times.and_return(true)
      expect(IO).to receive(:read).with("/path/path2/lolcat.json").and_return('{"name": "ceiling_cat", "json_class": "Chef::Role" }')
      expect(@role).to be_a_kind_of(Chef::Role)
      @role.class.from_disk("lolcat")
    end

    it "should return a Chef::Role object from a Ruby DSL" do
      expect(Dir).to receive(:glob).with(File.join("/path1", "**", "**")).exactly(1).times.and_return(["/path1/lolcat.rb"])
      expect(File).to receive(:exists?).with("/path1/lolcat.rb").exactly(2).times.and_return(true)
      expect(File).to receive(:readable?).with("/path1/lolcat.rb").and_return(true)
      expect(IO).to receive(:read).with("/path1/lolcat.rb").exactly(1).times.and_return(ROLE_DSL)
      expect(@role).to be_a_kind_of(Chef::Role)
      @role.class.from_disk("lolcat")
    end

    it "should return a Chef::Role object from a Ruby DSL when role is in the second path" do
      expect(Dir).to receive(:glob).with(File.join("/path1", "**", "**")).exactly(1).times.and_return([])
      expect(Dir).to receive(:glob).with(File.join("/path/path2", "**", "**")).exactly(1).times.and_return(["/path/path2/lolcat.rb"])
      expect(File).to receive(:exists?).with("/path/path2/lolcat.rb").exactly(2).times.and_return(true)
      expect(File).to receive(:readable?).with("/path/path2/lolcat.rb").and_return(true)
      expect(IO).to receive(:read).with("/path/path2/lolcat.rb").exactly(1).times.and_return(ROLE_DSL)
      expect(@role).to be_a_kind_of(Chef::Role)
      @role.class.from_disk("lolcat")
    end

    it "should raise an exception if the file does not exist" do
      expect(Dir).to receive(:glob).with(File.join("/path1", "**", "**")).exactly(1).times.and_return([])
      expect(Dir).to receive(:glob).with(File.join("/path/path2", "**", "**")).exactly(1).times.and_return([])
      expect { @role.class.from_disk("lolcat") }.to raise_error(Chef::Exceptions::RoleNotFound)
    end

  end
end
