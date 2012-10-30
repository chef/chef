#
# Author:: Daniel DeLeo (<dan@opscode.com>)
# Copyright:: Copyright (c) 2012 Opscode, Inc.
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

BAD_RECIPE=<<-E
#
# Cookbook Name:: syntax-err
# Recipe:: default
#
# Copyright 2012, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#


file "/tmp/explode-me" do
  mode 0655
  owner "root"
  this_is_not_a_valid_method
end
E

describe Chef::Formatters::ErrorInspectors::CompileErrorInspector do
  before do
    @node_name = "test-node.example.com"
    @description = Chef::Formatters::ErrorDescription.new("Error Evaluating File:")
    @exception = NoMethodError.new("undefined method `this_is_not_a_valid_method' for Chef::Resource::File")

    @outputter = Chef::Formatters::Outputter.new(StringIO.new, STDERR)
    #@outputter = Chef::Formatters::Outputter.new(STDOUT, STDERR)
  end

  describe "when scrubbing backtraces" do
    it "shows backtrace lines from cookbook files" do
      # Error inspector originally used file_cache_path which is incorrect on
      # chef-solo. Using cookbook_path should do the right thing for client and
      # solo.
      Chef::Config.stub!(:cookbook_path).and_return([ "/home/someuser/dev-laptop/cookbooks" ])
      @trace = [
        "/home/someuser/dev-laptop/cookbooks/syntax-err/recipes/default.rb:14:in `from_file'",
        "/home/someuser/dev-laptop/cookbooks/syntax-err/recipes/default.rb:11:in `from_file'",
        "/home/someuser/.multiruby/gems/chef/lib/chef/client.rb:123:in `run'"
      ]
      @exception.set_backtrace(@trace)
      @path = "/var/chef/cache/cookbooks/syntax-err/recipes/default.rb"
      @inspector = described_class.new(@path, @exception)

      @expected_filtered_trace = [
        "/home/someuser/dev-laptop/cookbooks/syntax-err/recipes/default.rb:14:in `from_file'",
        "/home/someuser/dev-laptop/cookbooks/syntax-err/recipes/default.rb:11:in `from_file'",
      ]
      @inspector.filtered_bt.should == @expected_filtered_trace
    end
  end

  describe "when explaining an error in the compile phase" do
    before do
      Chef::Config.stub!(:cookbook_path).and_return([ "/var/chef/cache/cookbooks" ])
      recipe_lines = BAD_RECIPE.split("\n").map {|l| l << "\n" }
      IO.should_receive(:readlines).with("/var/chef/cache/cookbooks/syntax-err/recipes/default.rb").and_return(recipe_lines)
      @trace = [
        "/var/chef/cache/cookbooks/syntax-err/recipes/default.rb:14:in `from_file'",
        "/var/chef/cache/cookbooks/syntax-err/recipes/default.rb:11:in `from_file'",
        "/usr/local/lib/ruby/gems/chef/lib/chef/client.rb:123:in `run'" # should not display
      ]
      @exception.set_backtrace(@trace)
      @path = "/var/chef/cache/cookbooks/syntax-err/recipes/default.rb"
      @inspector = described_class.new(@path, @exception)
      @inspector.add_explanation(@description)
    end

    it "finds the line number of the error from the stacktrace" do
      @inspector.culprit_line.should == 14
    end

    it "prints a pretty message" do
      @description.display(@outputter)
    end
  end

  describe "when explaining an error on windows" do
    before do
      Chef::Config.stub!(:cookbook_path).and_return([ "C:/opscode/chef/var/cache/cookbooks" ])
      recipe_lines = BAD_RECIPE.split("\n").map {|l| l << "\n" }
      IO.should_receive(:readlines).at_least(1).times.with(/:\/opscode\/chef\/var\/cache\/cookbooks\/foo\/recipes\/default.rb/).and_return(recipe_lines)      
      @trace = [
        "C:/opscode/chef/var/cache/cookbooks/foo/recipes/default.rb:14 in `from_file'",
        "C:/opscode/chef/embedded/lib/ruby/gems/1.9.1/gems/chef-10.14.0/lib/chef/run_context.rb:144:in `rescue in block in load_libraries'",
        "C:/opscode/chef/embedded/lib/ruby/gems/1.9.1/gems/chef-10.14.0/lib/chef/run_context.rb:138:in `block in load_libraries'",
        "C:/opscode/chef/embedded/lib/ruby/gems/1.9.1/gems/chef-10.14.0/lib/chef/run_context.rb:230:in `call'",
        "C:/opscode/chef/embedded/lib/ruby/gems/1.9.1/gems/chef-10.14.0/lib/chef/run_context.rb:230:in `block (2 levels) in foreach_cookbook_load_segment'",
        "C:/opscode/chef/embedded/lib/ruby/gems/1.9.1/gems/chef-10.14.0/lib/chef/run_context.rb:229:in `each'",
        "C:/opscode/chef/embedded/lib/ruby/gems/1.9.1/gems/chef-10.14.0/lib/chef/run_context.rb:229:in `block in foreach_cookbook_load_segment'",
        "C:/opscode/chef/embedded/lib/ruby/gems/1.9.1/gems/chef-10.14.0/lib/chef/run_context.rb:227:in `each'",
        "C:/opscode/chef/embedded/lib/ruby/gems/1.9.1/gems/chef-10.14.0/lib/chef/run_context.rb:227:in `foreach_cookbook_load_segment'",
        "C:/opscode/chef/embedded/lib/ruby/gems/1.9.1/gems/chef-10.14.0/lib/chef/run_context.rb:137:in `load_libraries'",
        "C:/opscode/chef/embedded/lib/ruby/gems/1.9.1/gems/chef-10.14.0/lib/chef/run_context.rb:62:in `load'",
        "C:/opscode/chef/embedded/lib/ruby/gems/1.9.1/gems/chef-10.14.0/lib/chef/client.rb:198:in `setup_run_context'",
        "C:/opscode/chef/embedded/lib/ruby/gems/1.9.1/gems/chef-10.14.0/lib/chef/client.rb:418:in `do_run'",
        "C:/opscode/chef/embedded/lib/ruby/gems/1.9.1/gems/chef-10.14.0/lib/chef/client.rb:176:in `run'",
        "C:/opscode/chef/embedded/lib/ruby/gems/1.9.1/gems/chef-10.14.0/lib/chef/application/client.rb:283:in `block in run_application'",
        "C:/opscode/chef/embedded/lib/ruby/gems/1.9.1/gems/chef-10.14.0/lib/chef/application/client.rb:270:in `loop'",
        "C:/opscode/chef/embedded/lib/ruby/gems/1.9.1/gems/chef-10.14.0/lib/chef/application/client.rb:270:in `run_application'",
        "C:/opscode/chef/embedded/lib/ruby/gems/1.9.1/gems/chef-10.14.0/lib/chef/application.rb:70:in `run'",
        "C:/opscode/chef/embedded/lib/ruby/gems/1.9.1/gems/chef-10.14.0/bin/chef-client:26:in `<top (required)>'",
        "C:/opscode/chef/bin/chef-client:19:in `load'",
        "C:/opscode/chef/bin/chef-client:19:in `<main>'"
      ]
      @exception.set_backtrace(@trace)
      @path = "/var/chef/cache/cookbooks/syntax-err/recipes/default.rb"
      @inspector = described_class.new(@path, @exception)
      @inspector.add_explanation(@description)
    end


    describe "and examining the stack trace for a recipe" do
      it "find the culprit recipe name when the drive letter is upper case" do
        @inspector.culprit_file.should == "C:/opscode/chef/var/cache/cookbooks/foo/recipes/default.rb"
      end

      it "find the culprit recipe name when the drive letter is lower case" do
        @trace.each { |line| line.gsub!(/^C:/, "c:") }
        @exception.set_backtrace(@trace)
        @inspector = described_class.new(@path, @exception)
        @inspector.add_explanation(@description)
        @inspector.culprit_file.should == "c:/opscode/chef/var/cache/cookbooks/foo/recipes/default.rb"
      end
    end 

    it "finds the line number of the error from the stack trace" do
      @inspector.culprit_line.should == 14
    end

    it "prints a pretty message" do
      @description.display(@outputter)
    end
  end

  describe "when explaining an error on windows, and the backtrace lowercases the drive letter" do
    before do
      Chef::Config.stub!(:cookbook_path).and_return([ "C:/opscode/chef/var/cache/cookbooks" ])
      recipe_lines = BAD_RECIPE.split("\n").map {|l| l << "\n" }
      IO.should_receive(:readlines).with("c:/opscode/chef/var/cache/cookbooks/foo/recipes/default.rb").and_return(recipe_lines)
      @trace = [
        "c:/opscode/chef/var/cache/cookbooks/foo/recipes/default.rb:14 in `from_file'",
        "c:/opscode/chef/embedded/lib/ruby/gems/1.9.1/gems/chef-10.14.0/lib/chef/run_context.rb:144:in `rescue in block in load_libraries'",
        "c:/opscode/chef/embedded/lib/ruby/gems/1.9.1/gems/chef-10.14.0/lib/chef/run_context.rb:138:in `block in load_libraries'",
        "c:/opscode/chef/embedded/lib/ruby/gems/1.9.1/gems/chef-10.14.0/lib/chef/run_context.rb:230:in `call'",
        "c:/opscode/chef/embedded/lib/ruby/gems/1.9.1/gems/chef-10.14.0/lib/chef/run_context.rb:230:in `block (2 levels) in foreach_cookbook_load_segment'",
        "c:/opscode/chef/embedded/lib/ruby/gems/1.9.1/gems/chef-10.14.0/lib/chef/run_context.rb:229:in `each'",
        "c:/opscode/chef/embedded/lib/ruby/gems/1.9.1/gems/chef-10.14.0/lib/chef/run_context.rb:229:in `block in foreach_cookbook_load_segment'",
        "c:/opscode/chef/embedded/lib/ruby/gems/1.9.1/gems/chef-10.14.0/lib/chef/run_context.rb:227:in `each'",
        "c:/opscode/chef/embedded/lib/ruby/gems/1.9.1/gems/chef-10.14.0/lib/chef/run_context.rb:227:in `foreach_cookbook_load_segment'",
        "c:/opscode/chef/embedded/lib/ruby/gems/1.9.1/gems/chef-10.14.0/lib/chef/run_context.rb:137:in `load_libraries'",
        "c:/opscode/chef/embedded/lib/ruby/gems/1.9.1/gems/chef-10.14.0/lib/chef/run_context.rb:62:in `load'",
        "c:/opscode/chef/embedded/lib/ruby/gems/1.9.1/gems/chef-10.14.0/lib/chef/client.rb:198:in `setup_run_context'",
        "c:/opscode/chef/embedded/lib/ruby/gems/1.9.1/gems/chef-10.14.0/lib/chef/client.rb:418:in `do_run'",
        "c:/opscode/chef/embedded/lib/ruby/gems/1.9.1/gems/chef-10.14.0/lib/chef/client.rb:176:in `run'",
        "c:/opscode/chef/embedded/lib/ruby/gems/1.9.1/gems/chef-10.14.0/lib/chef/application/client.rb:283:in `block in run_application'",
        "c:/opscode/chef/embedded/lib/ruby/gems/1.9.1/gems/chef-10.14.0/lib/chef/application/client.rb:270:in `loop'",
        "c:/opscode/chef/embedded/lib/ruby/gems/1.9.1/gems/chef-10.14.0/lib/chef/application/client.rb:270:in `run_application'",
        "c:/opscode/chef/embedded/lib/ruby/gems/1.9.1/gems/chef-10.14.0/lib/chef/application.rb:70:in `run'",
        "c:/opscode/chef/embedded/lib/ruby/gems/1.9.1/gems/chef-10.14.0/bin/chef-client:26:in `<top (required)>'",
        "c:/opscode/chef/bin/chef-client:19:in `load'",
        "c:/opscode/chef/bin/chef-client:19:in `<main>'"
      ]
      @exception.set_backtrace(@trace)
      @path = "/var/chef/cache/cookbooks/syntax-err/recipes/default.rb"
      @inspector = described_class.new(@path, @exception)
      @inspector.add_explanation(@description)
    end

    it "finds the culprit recipe name from the stacktrace" do
      @inspector.culprit_file.should == "c:/opscode/chef/var/cache/cookbooks/foo/recipes/default.rb"
    end

    it "finds the line number of the error from the stack trace" do
      @inspector.culprit_line.should == 14
    end

    it "prints a pretty message" do
      @description.display(@outputter)
    end
  end

end
