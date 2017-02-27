#
# Author:: Daniel DeLeo (<dan@chef.io>)
# Copyright:: Copyright 2012-2016, Chef Software Inc.
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

BAD_RECIPE = <<-E
#
# Cookbook Name:: syntax-err
# Recipe:: default
#
# Copyright 2012-2016, YOUR_COMPANY_NAME
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

  let(:node_name) { "test-node.example.com" }

  let(:description) { Chef::Formatters::ErrorDescription.new("Error Evaluating File:") }

  let(:exception) do
    e = NoMethodError.new("undefined method `this_is_not_a_valid_method' for Chef::Resource::File")
    e.set_backtrace(trace)
    e
  end

  # Change to $stdout to print error messages for manual inspection
  let(:stdout) { StringIO.new }

  let(:outputter) { Chef::Formatters::IndentableOutputStream.new(StringIO.new, STDERR) }

  subject(:inspector) { described_class.new(path_to_failed_file, exception) }

  describe "finding the code responsible for the error" do

    context "when the stacktrace includes cookbook files" do

      let(:trace) do
        [
          "/home/someuser/dev-laptop/cookbooks/syntax-err/recipes/default.rb:14:in `from_file'",
          "/home/someuser/dev-laptop/cookbooks/syntax-err/recipes/default.rb:11:in `from_file'",
          "/home/someuser/.multiruby/gems/chef/lib/chef/client.rb:123:in `run'",
        ]
      end

      let(:expected_filtered_trace) do
        [
          "/home/someuser/dev-laptop/cookbooks/syntax-err/recipes/default.rb:14:in `from_file'",
          "/home/someuser/dev-laptop/cookbooks/syntax-err/recipes/default.rb:11:in `from_file'",
        ]
      end

      let(:path_to_failed_file) { "/home/someuser/dev-laptop/cookbooks/syntax-err/recipes/default.rb" }

      before do
        # Error inspector originally used file_cache_path which is incorrect on
        # chef-solo. Using cookbook_path should do the right thing for client and
        # solo.
        allow(Chef::Config).to receive(:cookbook_path).and_return([ "/home/someuser/dev-laptop/cookbooks" ])
      end

      describe "when scrubbing backtraces" do
        it "shows backtrace lines from cookbook files" do
          expect(inspector.filtered_bt).to eq(expected_filtered_trace)
        end
      end

      describe "when explaining an error in the compile phase" do
        before do
          recipe_lines = BAD_RECIPE.split("\n").map { |l| l << "\n" }
          expect(IO).to receive(:readlines).with(path_to_failed_file).and_return(recipe_lines)
          inspector.add_explanation(description)
        end

        it "reports the error was not located within cookbooks" do
          expect(inspector.found_error_in_cookbooks?).to be(true)
        end

        it "finds the line number of the error from the stacktrace" do
          expect(inspector.culprit_line).to eq(14)
        end

        it "prints a pretty message" do
          description.display(outputter)
        end
      end
    end

    context "when the error is a RuntimeError about frozen object" do
      let(:exception) do
        e = RuntimeError.new("can't modify frozen Array")
        e.set_backtrace(trace)
        e
      end

      let(:path_to_failed_file) { "/tmp/kitchen/cache/cookbooks/foo/recipes/default.rb" }

      let(:trace) do
        [
          "/tmp/kitchen/cache/cookbooks/foo/recipes/default.rb:2:in `block in from_file'",
          "/tmp/kitchen/cache/cookbooks/foo/recipes/default.rb:1:in `from_file'",
        ]
      end

      describe "when explaining a runtime error in the compile phase" do
        it "correctly detects RuntimeError for frozen objects" do
          expect(inspector.exception_message_modifying_frozen?).to be(true)
        end

        # could also test for description.section to be called, but would have
        # to adjust every other test to begin using a test double for description
      end
    end

    context "when the error does not contain any lines from cookbooks" do

      let(:trace) do
        [
          "/opt/chef/embedded/lib/ruby/gems/1.9.1/gems/chef-10.14.0/lib/chef/run_context.rb:144:in `rescue in block in load_libraries'",
          "/opt/chef/embedded/lib/ruby/gems/1.9.1/gems/chef-10.14.0/lib/chef/run_context.rb:138:in `block in load_libraries'",
          "/opt/chef/embedded/lib/ruby/gems/1.9.1/gems/chef-10.14.0/lib/chef/run_context.rb:230:in `call'",
          "/opt/chef/embedded/lib/ruby/gems/1.9.1/gems/chef-10.14.0/lib/chef/run_context.rb:230:in `block (2 levels) in foreach_cookbook_load_segment'",
          "/opt/chef/embedded/lib/ruby/gems/1.9.1/gems/chef-10.14.0/lib/chef/run_context.rb:229:in `each'",
          "/opt/chef/embedded/lib/ruby/gems/1.9.1/gems/chef-10.14.0/lib/chef/run_context.rb:229:in `block in foreach_cookbook_load_segment'",
          "/opt/chef/embedded/lib/ruby/gems/1.9.1/gems/chef-10.14.0/lib/chef/run_context.rb:227:in `each'",
          "/opt/chef/embedded/lib/ruby/gems/1.9.1/gems/chef-10.14.0/lib/chef/run_context.rb:227:in `foreach_cookbook_load_segment'",
          "/opt/chef/embedded/lib/ruby/gems/1.9.1/gems/chef-10.14.0/lib/chef/run_context.rb:137:in `load_libraries'",
        ]
      end

      let(:exception) do
        e = Chef::Exceptions::RecipeNotFound.new("recipe nope:nope not found")
        e.set_backtrace(trace)
        e
      end

      let(:path_to_failed_file) { nil }

      it "gives a full, non-filtered trace" do
        expect(inspector.filtered_bt).to eq(trace)
      end

      it "does not error when displaying the error" do
        expect { description.display(outputter) }.to_not raise_error
      end

      it "reports the error was not located within cookbooks" do
        expect(inspector.found_error_in_cookbooks?).to be(false)
      end

    end
  end

  describe "when explaining an error on windows" do

    let(:trace_with_upcase_drive) do
      [
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
        "C:/opscode/chef/bin/chef-client:19:in `<main>'",
      ]
    end

    let(:trace) { trace_with_upcase_drive }

    let(:path_to_failed_file) { "/var/cache/cookbooks/foo/recipes/default.rb" }

    before do
      allow(Chef::Config).to receive(:cookbook_path).and_return([ "C:/opscode/chef/var/cache/cookbooks" ])
      recipe_lines = BAD_RECIPE.split("\n").map { |l| l << "\n" }
      expect(IO).to receive(:readlines).at_least(1).times.with(full_path_to_failed_file).and_return(recipe_lines)
      inspector.add_explanation(description)
    end

    context "when the drive letter in the path is uppercase" do

      let(:full_path_to_failed_file) { "C:/opscode/chef#{path_to_failed_file}" }

      it "reports the error was not located within cookbooks" do
        expect(inspector.found_error_in_cookbooks?).to be(true)
      end

      it "finds the culprit recipe name" do
        expect(inspector.culprit_file).to eq("C:/opscode/chef/var/cache/cookbooks/foo/recipes/default.rb")
      end

      it "finds the line number of the error from the stack trace" do
        expect(inspector.culprit_line).to eq(14)
      end

      it "prints a pretty message" do
        description.display(outputter)
      end
    end

    context "when the drive letter in the path is lowercase" do

      let(:trace) do
        trace_with_upcase_drive.map { |line| line.gsub(/^C:/, "c:") }
      end

      let(:full_path_to_failed_file) { "c:/opscode/chef#{path_to_failed_file}" }

      it "reports the error was not located within cookbooks" do
        expect(inspector.found_error_in_cookbooks?).to be(true)
      end

      it "finds the culprit recipe name from the stacktrace" do
        expect(inspector.culprit_file).to eq("c:/opscode/chef/var/cache/cookbooks/foo/recipes/default.rb")
      end

      it "finds the line number of the error from the stack trace" do
        expect(inspector.culprit_line).to eq(14)
      end

      it "prints a pretty message" do
        description.display(outputter)
      end
    end

  end

end
