#
# Author:: Bryan W. Berry (<bryan.berry@gmail.com>)
# Copyright:: Copyright 2012-2016, Bryan W. Berry
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

require "spec_helper"

describe Chef::Application::Apply do

  before do
    @app = Chef::Application::Apply.new
    allow(@app).to receive(:configure_logging).and_return(true)
    allow(Chef::Log).to receive(:debug).with("FIPS mode is enabled.")
    @recipe_text = "package 'nyancat'"
    Chef::Config[:solo_legacy_mode] = true
  end

  describe "configuring the application" do
    it "should set solo mode to true" do
      @app.reconfigure
      expect(Chef::Config[:solo_legacy_mode]).to be_truthy
    end
  end
  describe "read_recipe_file" do
    before do
      @recipe_file_name = "foo.rb"
      @recipe_path = File.expand_path(@recipe_file_name)
      @recipe_file = double("Tempfile (mock)", :read => @recipe_text)
      allow(@app).to receive(:open).with(@recipe_path).and_return(@recipe_file)
      allow(File).to receive(:exist?).with(@recipe_path).and_return(true)
      allow(Chef::Application).to receive(:fatal!).and_return(true)
    end

    it "should read text properly" do
      expect(@app.read_recipe_file(@recipe_file_name)[0]).to eq(@recipe_text)
    end
    it "should return a file_handle" do
      expect(@app.read_recipe_file(@recipe_file_name)[1]).to be_instance_of(RSpec::Mocks::Double)
    end

    describe "when recipe is nil" do
      it "should raise a fatal with the missing filename message" do
        expect(Chef::Application).to receive(:fatal!).with("No recipe file was provided",
          Chef::Exceptions::RecipeNotFound.new)
        @app.read_recipe_file(nil)
      end
    end
    describe "when recipe doesn't exist" do
      before do
        allow(File).to receive(:exist?).with(@recipe_path).and_return(false)
      end
      it "should raise a fatal with the file doesn't exist message" do
        expect(Chef::Application).to receive(:fatal!).with(/^No file exists at/,
          Chef::Exceptions::RecipeNotFound.new)
        @app.read_recipe_file(@recipe_file_name)
      end
    end
  end
  describe "temp_recipe_file" do
    before do
      @app.instance_variable_set(:@recipe_text, @recipe_text)
      @app.temp_recipe_file
      @recipe_fh = @app.instance_variable_get(:@recipe_fh)
    end
    it "should open a tempfile" do
      expect(@recipe_fh.path).to match(/.*recipe-temporary-file.*/)
    end
    it "should write recipe text to the tempfile" do
      expect(@recipe_fh.read).to eq(@recipe_text)
    end
    it "should save the filename for later use" do
      expect(@recipe_fh.path).to eq(@app.instance_variable_get(:@recipe_filename))
    end
  end
  describe "recipe_file_arg" do
    before do
      ARGV.clear
    end
    it "should exit and log message" do
      expect(Chef::Log).to receive(:debug).with(/^No recipe file provided/)
      expect { @app.run }.to raise_error(SystemExit) { |e| expect(e.status).to eq(1) }
    end

  end
  describe "when the json_attribs configuration option is specified" do
    let(:json_attribs) { { "a" => "b" } }
    let(:config_fetcher) { double(Chef::ConfigFetcher, :fetch_json => json_attribs) }
    let(:json_source) { "https://foo.com/foo.json" }

    before do
      Chef::Config[:json_attribs] = json_source
      expect(Chef::ConfigFetcher).to receive(:new).with(json_source).
        and_return(config_fetcher)
    end

    it "reads the JSON attributes from the specified source" do
      @app.reconfigure
      expect(@app.json_attribs).to eq(json_attribs)
    end
  end
end
