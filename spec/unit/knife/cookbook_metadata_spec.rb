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

require "spec_helper"

describe Chef::Knife::CookbookMetadata do
  before(:each) do
    @knife = Chef::Knife::CookbookMetadata.new
    @knife.name_args = ["foobar"]
    @cookbook_dir = Dir.mktmpdir
    @json_data = '{ "version": "1.0.0" }'
    @stdout = StringIO.new
    @stderr = StringIO.new
    allow(@knife.ui).to receive(:stdout).and_return(@stdout)
    allow(@knife.ui).to receive(:stderr).and_return(@stderr)
  end

  describe "run" do
    it "should print an error and exit if a cookbook name was not provided" do
      @knife.name_args = []
      expect(@knife.ui).to receive(:error).with(/you must specify the cookbook.+use the --all/i)
      expect { @knife.run }.to raise_error(SystemExit)
    end

    it "should print an error and exit if an empty cookbook name was provided" do
      @knife.name_args = [""]
      expect(@knife.ui).to receive(:error).with(/you must specify the cookbook.+use the --all/i)
      expect { @knife.run }.to raise_error(SystemExit)
    end

    it "should generate the metadata for the cookbook" do
      expect(@knife).to receive(:generate_metadata).with("foobar")
      @knife.run
    end

    describe "with -a or --all" do
      before(:each) do
        @knife.config[:all] = true
        @foo = Chef::CookbookVersion.new("foo", "/tmp/blah")
        @foo.version = "1.0.0"
        @bar = Chef::CookbookVersion.new("bar", "/tmp/blah")
        @bar.version = "2.0.0"
        @cookbook_loader = {
          "foo" => @foo,
          "bar" => @bar,
        }
        expect(@cookbook_loader).to receive(:load_cookbooks).and_return(@cookbook_loader)
        expect(@knife).to receive(:generate_metadata).with("foo")
        expect(@knife).to receive(:generate_metadata).with("bar")
      end

      it "should generate the metadata for each cookbook" do
        Chef::Config[:cookbook_path] = @cookbook_dir
        expect(Chef::CookbookLoader).to receive(:new).with(@cookbook_dir).and_return(@cookbook_loader)
        @knife.run
      end

      describe "and with -o or --cookbook-path" do
        it "should look in the provided path and generate cookbook metadata" do
          @knife.config[:cookbook_path] = "/opt/chef/cookbooks"
          expect(Chef::CookbookLoader).to receive(:new).with("/opt/chef/cookbooks").and_return(@cookbook_loader)
          @knife.run
        end
      end
    end

  end

  describe "generate_metadata" do
    before(:each) do
      @knife.config[:cookbook_path] = @cookbook_dir
      allow(File).to receive(:expand_path).with("#{@cookbook_dir}/foobar/metadata.rb").
        and_return("#{@cookbook_dir}/foobar/metadata.rb")
    end

    it "should generate the metadata from metadata.rb if it exists" do
      expect(File).to receive(:exists?).with("#{@cookbook_dir}/foobar/metadata.rb").
        and_return(true)
      expect(@knife).to receive(:generate_metadata_from_file).with("foobar", "#{@cookbook_dir}/foobar/metadata.rb")
      @knife.run
    end

    it "should validate the metadata json if metadata.rb does not exist" do
      expect(File).to receive(:exists?).with("#{@cookbook_dir}/foobar/metadata.rb").
        and_return(false)
      expect(@knife).to receive(:validate_metadata_json).with(@cookbook_dir, "foobar")
      @knife.run
    end
  end

  describe "generate_metadata_from_file" do
    before(:each) do
      @metadata_mock = double("metadata")
      @json_file_mock = double("json_file")
    end

    it "should generate the metatdata json from metatdata.rb" do
      allow(Chef::Cookbook::Metadata).to receive(:new).and_return(@metadata_mock)
      expect(@metadata_mock).to receive(:name).with("foobar")
      expect(@metadata_mock).to receive(:from_file).with("#{@cookbook_dir}/foobar/metadata.rb")
      expect(File).to receive(:open).with("#{@cookbook_dir}/foobar/metadata.json", "w").
        and_yield(@json_file_mock)
      expect(@json_file_mock).to receive(:write).with(@json_data)
      expect(Chef::JSONCompat).to receive(:to_json_pretty).with(@metadata_mock).
        and_return(@json_data)
      @knife.generate_metadata_from_file("foobar", "#{@cookbook_dir}/foobar/metadata.rb")
      expect(@stderr.string).to match /generating metadata for foobar from #{@cookbook_dir}\/foobar\/metadata\.rb/im
    end

    { Chef::Exceptions::ObsoleteDependencySyntax => "obsolote dependency",
      Chef::Exceptions::InvalidVersionConstraint => "invalid version constraint",
    }.each_pair do |klass, description|
      it "should print an error and exit when an #{description} syntax exception is encountered" do
        exception = klass.new("#{description} blah")
        allow(Chef::Cookbook::Metadata).to receive(:new).and_raise(exception)
        expect {
          @knife.generate_metadata_from_file("foobar", "#{@cookbook_dir}/foobar/metadata.rb")
        }.to raise_error(SystemExit)
        expect(@stderr.string).to match /error: the cookbook 'foobar' contains invalid or obsolete metadata syntax/im
        expect(@stderr.string).to match /in #{@cookbook_dir}\/foobar\/metadata\.rb/im
        expect(@stderr.string).to match /#{description} blah/im
      end
    end
  end

  describe "validate_metadata_json" do
    it "should validate the metadata json" do
      expect(File).to receive(:exist?).with("#{@cookbook_dir}/foobar/metadata.json").
        and_return(true)
      expect(IO).to receive(:read).with("#{@cookbook_dir}/foobar/metadata.json").
        and_return(@json_data)
      expect(Chef::Cookbook::Metadata).to receive(:validate_json).with(@json_data)
      @knife.validate_metadata_json(@cookbook_dir, "foobar")
    end

    it "should not try to validate the metadata json if the file does not exist" do
      expect(File).to receive(:exist?).with("#{@cookbook_dir}/foobar/metadata.json").
        and_return(false)
      expect(IO).not_to receive(:read)
      expect(Chef::Cookbook::Metadata).not_to receive(:validate_json)
      @knife.validate_metadata_json(@cookbook_dir, "foobar")
    end

    { Chef::Exceptions::ObsoleteDependencySyntax => "obsolote dependency",
      Chef::Exceptions::InvalidVersionConstraint => "invalid version constraint",
    }.each_pair do |klass, description|
      it "should print an error and exit when an #{description} syntax exception is encountered" do
        expect(File).to receive(:exist?).with("#{@cookbook_dir}/foobar/metadata.json").
          and_return(true)
        expect(IO).to receive(:read).with("#{@cookbook_dir}/foobar/metadata.json").
          and_return(@json_data)
        exception = klass.new("#{description} blah")
        allow(Chef::Cookbook::Metadata).to receive(:validate_json).and_raise(exception)
        expect {
          @knife.validate_metadata_json(@cookbook_dir, "foobar")
        }.to raise_error(SystemExit)
        expect(@stderr.string).to match /error: the cookbook 'foobar' contains invalid or obsolete metadata syntax/im
        expect(@stderr.string).to match /in #{@cookbook_dir}\/foobar\/metadata\.json/im
        expect(@stderr.string).to match /#{description} blah/im
      end
    end
  end

end
