# Author:: Daniel DeLeo (<dan@kallistec.com>)
# Copyright:: Copyright (c) 2009 Daniel DeLeo
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
require "ostruct"

ObjectTestHarness = Proc.new do
  extend Shell::Extensions::ObjectCoreExtensions

  def conf=(new_conf)
    @conf = new_conf
  end

  def conf
    @conf
  end

  desc "rspecin'"
  def rspec_method
  end
end

class TestJobManager
  attr_accessor :jobs
end

describe Shell do

  before do
    Shell.irb_conf = {}
    allow(Shell::ShellSession.instance).to receive(:reset!)
    allow(Chef::Platform).to receive(:windows?).and_return(false)
    allow(Chef::Util::PathHelper).to receive(:home).and_return('/home/foo')
  end

  describe "reporting its status" do

    it "always says it is running" do
      expect(Shell).to be_running
    end

  end

  describe "configuring IRB" do
    it "configures irb history" do
      Shell.configure_irb
      expect(Shell.irb_conf[:HISTORY_FILE]).to eq(Chef::Util::PathHelper.home('.chef', 'chef_shell_history'))
      expect(Shell.irb_conf[:SAVE_HISTORY]).to eq(1000)
    end

    it "has a prompt like ``chef > '' in the default context" do
      Shell.configure_irb

      conf = OpenStruct.new
      conf.main = Object.new
      conf.main.instance_eval(&ObjectTestHarness)
      Shell.irb_conf[:IRB_RC].call(conf)
      expect(conf.prompt_c).to      eq("chef > ")
      expect(conf.return_format).to eq(" => %s \n")
      expect(conf.prompt_i).to      eq("chef (#{Chef::VERSION})> ")
      expect(conf.prompt_n).to      eq("chef ?> ")
      expect(conf.prompt_s).to      eq("chef%l> ")
      expect(conf.use_tracer).to    eq(false)
    end

    it "has a prompt like ``chef:recipe > '' in recipe context" do
      Shell.configure_irb

      conf = OpenStruct.new
      events = Chef::EventDispatch::Dispatcher.new
      conf.main = Chef::Recipe.new(nil,nil,Chef::RunContext.new(Chef::Node.new, {}, events))
      Shell.irb_conf[:IRB_RC].call(conf)
      expect(conf.prompt_c).to      eq("chef:recipe > ")
      expect(conf.prompt_i).to      eq("chef:recipe (#{Chef::VERSION})> ")
      expect(conf.prompt_n).to      eq("chef:recipe ?> ")
      expect(conf.prompt_s).to      eq("chef:recipe%l> ")
    end

    it "has a prompt like ``chef:attributes > '' in attributes/node context" do
      Shell.configure_irb

      conf = OpenStruct.new
      conf.main = Chef::Node.new
      Shell.irb_conf[:IRB_RC].call(conf)
      expect(conf.prompt_c).to      eq("chef:attributes > ")
      expect(conf.prompt_i).to      eq("chef:attributes (#{Chef::VERSION})> ")
      expect(conf.prompt_n).to      eq("chef:attributes ?> ")
      expect(conf.prompt_s).to      eq("chef:attributes%l> ")
    end

  end

  describe "convenience macros for creating the chef object" do

    before do
      @chef_object = Object.new
      @chef_object.instance_eval(&ObjectTestHarness)
    end

    it "creates help text for methods with descriptions" do
      expect(@chef_object.help_descriptions).to eq([Shell::Extensions::Help.new("rspec_method", "rspecin'", nil)])
    end

    it "adds help text when a new method is described then defined" do
      describe_define =<<-EVAL
        desc "foo2the Bar"
        def baz
        end
      EVAL
      @chef_object.instance_eval describe_define
      expect(@chef_object.help_descriptions).to eq([Shell::Extensions::Help.new("rspec_method", "rspecin'"),
                                                Shell::Extensions::Help.new("baz", "foo2the Bar")])
    end

    it "adds help text for subcommands" do
      describe_define =<<-EVAL
        subcommands :baz_obj_command => "something you can do with baz.baz_obj_command"
        def baz
        end
      EVAL
      @chef_object.instance_eval describe_define
      expected_help_text_fragments = [Shell::Extensions::Help.new("rspec_method", "rspecin'")]
      expected_help_text_fragments << Shell::Extensions::Help.new("baz.baz_obj_command", "something you can do with baz.baz_obj_command")
      expect(@chef_object.help_descriptions).to eq(expected_help_text_fragments)
    end

    it "doesn't add previous subcommand help to commands defined afterward" do
      describe_define =<<-EVAL
        desc "swingFromTree"
        def monkey_time
        end

        def super_monkey_time
        end

      EVAL
      @chef_object.instance_eval describe_define
      expect(@chef_object.help_descriptions.size).to eq(2)
      expect(@chef_object.help_descriptions.select {|h| h.cmd == "super_monkey_time" }).to be_empty
    end

    it "creates a help banner with the command descriptions" do
      expect(@chef_object.help_banner).to match(/^\|\ Command[\s]+\|\ Description[\s]*$/)
      expect(@chef_object.help_banner).to match(/^\|\ rspec_method[\s]+\|\ rspecin\'[\s]*$/)
    end
  end

end
