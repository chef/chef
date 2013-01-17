#
# Author:: Bryan W. Berry (<bryan.berry@gmail.com>)
# Copyright:: Copyright (c) 2012 Bryan W. Berry
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

require 'spec_helper'

describe Chef::Application::Apply do

  before do
    @original_config = Chef::Config.configuration
    @app = Chef::Application::Recipe.new
    @app.stub!(:configure_logging).and_return(true)
    @recipe_text = "package 'nyancat'"
    Chef::Config[:solo] = true
  end

  after do
    Chef::Config[:solo] = nil
    Chef::Config.configuration.replace(@original_config)
    Chef::Config[:solo] = false
  end


  describe "configuring the application" do
    it "should set solo mode to true" do
      @app.reconfigure
      Chef::Config[:solo].should be_true
    end
  end
  describe "read_recipe_file" do
    before do
      @recipe_file_name = "foo.rb"
      @recipe_path = File.expand_path("foo.rb")
      @recipe_file = mock("Tempfile (mock)", :read => @recipe_text)
      @app.stub!(:open).with(@recipe_path).and_return(@recipe_file)
      File.stub!(:exist?).with("foo.rb").and_return(true)
      Chef::Application.stub!(:fatal!).and_return(true)
    end
    it "should read text properly" do
      @app.read_recipe_file(@recipe_file_name)[0].should == @recipe_text
    end
    it "should return a file_handle" do
      @app.read_recipe_file(@recipe_file_name)[1].should be_instance_of(RSpec::Mocks::Mock)
    end
    describe "when recipe doesn't exist" do
      before do
        File.stub!(:exist?).with(@recipe_file_name).and_return(false)
      end
      it "should raise a fatal" do
        Chef::Application.should_receive(:fatal!)
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
      @recipe_fh.path.should match(/.*recipe-temporary-file.*/)
    end
    it "should write recipe text to the tempfile" do
      @recipe_fh.read.should == @recipe_text
    end
    it "should save the filename for later use" do
      @recipe_fh.path.should == @app.instance_variable_get(:@recipe_filename)
    end
  end
end
