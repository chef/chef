#
# Author:: Adam Jacob (adam@opscode.com)
# Copyright:: Copyright (c) 2009 Opscode
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

describe Chef::Provider::Script, "action_run" do
  before(:each) do
    @node = Chef::Node.new
    @events = Chef::EventDispatch::Dispatcher.new
    @run_context = Chef::RunContext.new(@node, {}, @events)
    @new_resource = Chef::Resource::Script.new('run some perl code')
    @new_resource.code "$| = 1; print 'i like beans'"
    @new_resource.interpreter 'perl'

    @provider = Chef::Provider::Script.new(@new_resource, @run_context)

    @script_file = StringIO.new
    @script_file.stub!(:path).and_return('/tmp/the_script_file')

    @provider.stub!(:shell_out!).and_return(true)
  end

  it "creates a temporary file to store the script" do
    @provider.script_file.should be_an_instance_of(Tempfile)
  end

  it "unlinks the tempfile when finished" do
    tempfile_path = @provider.script_file.path
    @provider.unlink_script_file
    File.exist?(tempfile_path).should be_false
  end

  it "sets the owner and group for the script file" do
    @new_resource.user 'toor'
    @new_resource.group 'wheel'
    @provider.stub!(:script_file).and_return(@script_file)
    FileUtils.should_receive(:chown).with('toor', 'wheel', "/tmp/the_script_file")
    @provider.set_owner_and_group
  end

  context "with the script file set to the correct owner and group" do
    before do
      @provider.stub!(:set_owner_and_group)
      @provider.stub!(:script_file).and_return(@script_file)
    end
    describe "when writing the script to the file" do
      it "should put the contents of the script in the temp file" do
        @provider.action_run
        @script_file.rewind
        @script_file.string.should == "$| = 1; print 'i like beans'\n"
      end

      it "closes before executing the script and unlinks it when finished" do
        @provider.action_run
        @script_file.should be_closed
      end

    end

    describe "when running the script" do
      it 'should set the command to "interpreter"  "tempfile"' do
        @provider.action_run
        @new_resource.command.should == '"perl"  "/tmp/the_script_file"'
      end

      describe "with flags set on the resource" do
        before do
          @new_resource.flags '-f'
        end

        it "should set the command to 'interpreter flags tempfile'" do
          @provider.action_run
          @new_resource.command.should == '"perl" -f "/tmp/the_script_file"'
        end

      end

    end
  end

end
