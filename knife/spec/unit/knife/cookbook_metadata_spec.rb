#
# Author:: Thomas Bishop (<bishop.thomas@gmail.com>)
# Copyright:: Copyright 2011-2016, Thomas Bishop
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

require "knife_spec_helper"

describe Chef::Knife::CookbookMetadata do
  let(:knife) do
    knife = Chef::Knife::CookbookMetadata.new
    knife.name_args = ["foobar"]
    knife
  end

  let(:cookbook_dir) { Dir.mktmpdir }

  let(:stdout) { StringIO.new }

  let(:stderr) { StringIO.new }

  before(:each) do
    allow(knife.ui).to receive(:stdout).and_return(stdout)
    allow(knife.ui).to receive(:stderr).and_return(stderr)
  end

  def create_metadata_rb(**kwargs)
    name = kwargs[:name]
    Dir.mkdir("#{cookbook_dir}/#{name}")
    File.open("#{cookbook_dir}/#{name}/metadata.rb", "w+") do |f|
      kwargs.each do |key, value|
        if value.is_a?(Array)
          f.puts "#{key} #{value.map { |v| "\"#{v}\"" }.join(", ")}"
        else
          f.puts "#{key} \"#{value}\""
        end
      end
    end
  end

  def create_metadata_json(**kwargs)
    name = kwargs[:name]
    Dir.mkdir("#{cookbook_dir}/#{name}")
    File.open("#{cookbook_dir}/#{name}/metadata.json", "w+") do |f|
      f.write(FFI_Yajl::Encoder.encode(kwargs))
    end
  end

  def create_invalid_json
    Dir.mkdir("#{cookbook_dir}/foobar")
    File.open("#{cookbook_dir}/foobar/metadata.json", "w+") do |f|
      f.write <<-EOH
      { "version": "1.0.0", {ImInvalid}}
      EOH
    end
  end

  describe "run" do
    it "should print an error and exit if a cookbook name was not provided" do
      knife.name_args = []
      expect(knife.ui).to receive(:error).with(/you must specify the cookbook.+use the --all/i)
      expect { knife.run }.to raise_error(SystemExit)
    end

    it "should print an error and exit if an empty cookbook name was provided" do
      knife.name_args = [""]
      expect(knife.ui).to receive(:error).with(/you must specify the cookbook.+use the --all/i)
      expect { knife.run }.to raise_error(SystemExit)
    end

    it "should generate the metadata for the cookbook" do
      expect(knife).to receive(:generate_metadata).with("foobar")
      knife.run
    end

    describe "with -a or --all" do
      before(:each) do
        Chef::Config[:cookbook_path] = cookbook_dir
        knife.config[:all] = true
        create_metadata_rb(name: "foo", version: "1.0.0")
        create_metadata_rb(name: "bar", version: "2.0.0")
        expect(knife).to receive(:generate_metadata).with("foo").and_call_original
        expect(knife).to receive(:generate_metadata).with("bar").and_call_original
      end

      it "should generate the metadata for each cookbook" do
        expect(Chef::CookbookLoader).to receive(:new).with(cookbook_dir).and_call_original
        knife.run
        expect(stderr.string).to match %r{generating metadata for foo from #{cookbook_dir}/foo/metadata\.rb}im
        expect(stderr.string).to match %r{generating metadata for bar from #{cookbook_dir}/bar/metadata\.rb}im
      end

      it "with -o or --cookbook_path should look in the provided path and generate cookbook metadata" do
        Chef::Config[:cookbook_path] = "/dev/null"
        knife.config[:cookbook_path] = cookbook_dir
        expect(Chef::CookbookLoader).to receive(:new).with(cookbook_dir).and_call_original
        knife.run
        expect(stderr.string).to match %r{generating metadata for foo from #{cookbook_dir}/foo/metadata\.rb}im
        expect(stderr.string).to match %r{generating metadata for bar from #{cookbook_dir}/bar/metadata\.rb}im
      end
    end

  end

  describe "generate_metadata" do
    before(:each) do
      Chef::Config[:cookbook_path] = cookbook_dir
    end

    it "should generate the metadata from metadata.rb if it exists" do
      create_metadata_rb(name: "foobar", version: "1.0.0")
      expect(knife).to receive(:generate_metadata_from_file).with("foobar", "#{cookbook_dir}/foobar/metadata.rb").and_call_original
      knife.run
      expect(File.exist?("#{cookbook_dir}/foobar/metadata.json")).to be true
      json = FFI_Yajl::Parser.parse(IO.read("#{cookbook_dir}/foobar/metadata.json"))
      expect(json["name"]).to eql("foobar")
      expect(json["version"]).to eql("1.0.0")
    end

    it "should validate the metadata json if metadata.rb does not exist" do
      create_metadata_json(name: "foobar", version: "1.0.0")
      expect(knife).to receive(:validate_metadata_json).with(cookbook_dir, "foobar").and_call_original
      knife.run
    end
  end

  describe "validation errors" do
    before(:each) do
      Chef::Config[:cookbook_path] = cookbook_dir
    end

    it "should fail for obsolete operators in metadata.rb" do
      create_metadata_rb(name: "foobar", version: "1.0.0", depends: [ "foo:bar", ">> 0.2" ])
      expect(Chef::Cookbook::Metadata).not_to receive(:validate_json)
      expect { knife.run }.to raise_error(SystemExit)
      expect(stderr.string).to match(/error: the cookbook 'foobar' contains invalid or obsolete metadata syntax/im)
    end

    it "should fail for obsolete format in metadata.rb (sadly)" do
      create_metadata_rb(name: "foobar", version: "1.0.0", depends: [ "foo:bar", "> 0.2", "< 1.0" ])
      expect(Chef::Cookbook::Metadata).not_to receive(:validate_json)
      expect { knife.run }.to raise_error(SystemExit)
      expect(stderr.string).to match(/error: the cookbook 'foobar' contains invalid or obsolete metadata syntax/im)
    end

    it "should fail for obsolete operators in metadata.json" do
      create_metadata_json(name: "foobar", version: "1.0.0", dependencies: { "foo:bar" => ">> 0.2" })
      expect { knife.run }.to raise_error(SystemExit)
      expect(stderr.string).to match(/error: the cookbook 'foobar' contains invalid or obsolete metadata syntax/im)
    end

    it "should not fail for unknown field in metadata.rb" do
      create_metadata_rb(name: "sounders", version: "2.0.0", beats: "toronto")
      expect(Chef::Cookbook::Metadata).not_to receive(:validate_json)
      expect { knife.run }.not_to raise_error
      expect(stderr.string).to eql("")
    end

    it "should not fail for unknown field in metadata.json" do
      create_metadata_json(name: "sounders", version: "2.0.0", beats: "toronto")
      expect { knife.run }.not_to raise_error
      expect(stderr.string).to eql("")
    end

    it "should fail on unparsable json" do
      create_invalid_json
      expect { knife.run }.to raise_error(Chef::Exceptions::JSON::ParseError)
    end
  end
end
