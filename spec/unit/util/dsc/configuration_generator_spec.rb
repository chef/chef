#
# Author:: Jay Mundrawala <jmundrawala@getchef.com>
# Copyright:: Copyright (c) 2014 Chef Software, Inc.
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

require 'chef'
require 'chef/util/dsc/configuration_generator'

describe Chef::Util::DSC::ConfigurationGenerator do
  before (:all) do
    @node = Chef::Node.new
    @conf_man = Chef::Util::DSC::ConfigurationGenerator.new(@node, 'tmp')
  end

  describe '#validate_configuration_name!' do
    it 'should not raise an error if a name contains all upper case letters' do
      @conf_man.send(:validate_configuration_name!, "HELLO")
    end

    it 'should not raise an error if the name contains all lower case letters' do
      @conf_man.send(:validate_configuration_name!, "hello")
    end

    it 'should not raise an error if no special characters are used except _' do
      @conf_man.send(:validate_configuration_name!, "hello_world")
    end

    %w{! @ # $ % ^ & * & * ( ) - = + \{ \} . ? < > \\ /}.each do |sym|
      it "raises an Argument error if it configuration name contains #{sym}" do
        expect {
          @conf_man.send(:validate_configuration_name!, "Hello#{sym}")
        }.to raise_error(ArgumentError)
      end
    end
  end

  describe "#get_merged_configuration_flags" do
    context 'when strings are used as switches' do
      it 'should merge the hash if there are no restricted switches' do
        merged = @conf_man.send(:get_merged_configuration_flags!, {'flag' => 'a'}, 'hello')
        merged.should include(:flag)
        merged[:flag].should eql('a')
        merged.should include(:outputpath)
      end

      it 'should raise an ArgumentError if you try to override outputpath' do
        expect {
          @conf_man.send(:get_merged_configuration_flags!, {'outputpath' => 'a'}, 'hello')
        }.to raise_error(ArgumentError)
      end

      it 'should be case insensitive for switches that are not allowed' do
        expect {
          @conf_man.send(:get_merged_configuration_flags!, {'OutputPath' => 'a'}, 'hello')
        }.to raise_error(ArgumentError)
      end

      it 'should be case insensitive to switches that are allowed' do
        merged = @conf_man.send(:get_merged_configuration_flags!, {'FLAG' => 'a'}, 'hello')
        merged.should include(:flag)
      end
    end

    context 'when symbols are used as switches' do
      it 'should merge the hash if there are no restricted switches' do
        merged = @conf_man.send(:get_merged_configuration_flags!, {:flag => 'a'}, 'hello')
        merged.should include(:flag)
        merged[:flag].should eql('a')
        merged.should include(:outputpath)
      end

      it 'should raise an ArgumentError if you try to override outputpath' do
        expect {
          @conf_man.send(:get_merged_configuration_flags!, {:outputpath => 'a'}, 'hello')
        }.to raise_error(ArgumentError)
      end

      it 'should be case insensitive for switches that are not allowed' do
        expect {
          @conf_man.send(:get_merged_configuration_flags!, {:OutputPath => 'a'}, 'hello')
        }.to raise_error(ArgumentError)
      end

      it 'should be case insensitive to switches that are allowed' do
        merged = @conf_man.send(:get_merged_configuration_flags!, {:FLAG => 'a'}, 'hello')
        merged.should include(:flag)
      end
    end

    context 'when there are no flags' do
      it 'should supply an output path if configuration_flags is an empty hash' do
        merged = @conf_man.send(:get_merged_configuration_flags!, {}, 'hello')
        merged.should include(:outputpath)
        merged.length.should eql(1)
      end

      it 'should supply an output path if configuration_flags is an empty hash' do
        merged = @conf_man.send(:get_merged_configuration_flags!, nil, 'hello')
        merged.should include(:outputpath)
        merged.length.should eql(1)
      end
    end

    # What should happen if configuration flags contains duplicates?
    # flagA => 'a', flaga => 'a'
    # or
    # flagA => 'a', flaga => 'b'
    #
  end

  describe '#write_document_generation_script' do
    before (:each) do
      @file_like_object = double("file like object")
    end

    it "should write the input to a file" do
      File.stub(:open).and_yield(@file_like_object)
      @file_like_object.stub(:write).with(anything())
      File.stub(:join) do |a, b|
        [a,b].join("++")
      end
      @conf_man.send(:write_document_generation_script, 'file', 'hello')
      expect(@file_like_object).to have_received(:write)
    end
  end

  describe "#find_configuration_document" do
    it "should find the mof file" do
      # These tests seem way too implementation specific. Unfortunatly, File and Dir
      # need to be mocked because they are OS specific
      
      File.stub(:join) do |a, b|
        [a,b].join("++")
      end
      Dir.stub(:entries).with("tmp++hello") {['f1', 'f2', 'hello.mof', 'f3']}
      expect(@conf_man.send(:find_configuration_document, 'hello')).to eql('tmp++hello++hello.mof')
    end

    it "should return nil if the mof file is not found" do
      File.stub(:join) do |a, b|
        [a,b].join("++")
      end
      Dir.stub(:entries).with("tmp++hello") {['f1', 'f2', 'f3']}
      expect(@conf_man.send(:find_configuration_document, 'hello')).to be_nil
    end
  end

  describe "#configuration_code" do
    it "should build dsc" do
      dsc = @conf_man.send(:configuration_code, 'archive{}', 'hello')
      found_configuration = false
      dsc.split(';').each do |command|
        if command.downcase =~ /\s*configuration\s+'hello'\s*\{\s*node\s+'localhost'\s*\{\s*archive\s*\{\s*\}\s*\}\s*\}\s*/
          found_configuration = true
        end
      end
      expect(found_configuration).to be_true
    end
  end
end
