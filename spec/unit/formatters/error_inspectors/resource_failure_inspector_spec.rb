#
# Author:: Daniel DeLeo (<dan@chef.io>)
# Copyright:: Copyright (c) Chef Software Inc.
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

describe Chef::Formatters::ErrorInspectors::ResourceFailureInspector do
  include Chef::DSL::Recipe

  def run_context
    node = Chef::Node.new
    node.automatic_attrs[:platform] = "ubuntu"
    node.automatic_attrs[:platform_version] = "10.04"
    Chef::RunContext.new(node, {}, nil)
  end

  def cookbook_name
    "rspec-example"
  end

  def recipe_name
    "rspec-example-recipe"
  end

  before do
    @description = Chef::Formatters::ErrorDescription.new("Error Converging Resource:")
    @stdout = StringIO.new
    @outputter = Chef::Formatters::IndentableOutputStream.new(@stdout, STDERR)
    # @outputter = Chef::Formatters::IndentableOutputStream.new(STDOUT, STDERR)

    allow(Chef::Config).to receive(:cookbook_path).and_return([ "/var/chef/cache" ])
  end

  describe "when explaining an error converging a resource" do
    before do
      @resource = package("non-existing-package") do

        only_if do
          true
        end

        not_if("/bin/false")
        action :upgrade
      end

      @trace = [
        "/var/chef/cache/cookbooks/syntax-err/recipes/default.rb:14:in `from_file'",
        "/var/chef/cache/cookbooks/syntax-err/recipes/default.rb:11:in `from_file'",
        "/usr/local/lib/ruby/gems/chef/lib/chef/client.rb:123:in `run'", # should not display
      ]
      @exception = Chef::Exceptions::Package.new("No such package 'non-existing-package'")
      @exception.set_backtrace(@trace)
      @inspector = Chef::Formatters::ErrorInspectors::ResourceFailureInspector.new(@resource, :create, @exception)
      @inspector.add_explanation(@description)
    end

    it "filters chef core code from the backtrace" do
      @expected_filtered_trace = [
        "/var/chef/cache/cookbooks/syntax-err/recipes/default.rb:14:in `from_file'",
        "/var/chef/cache/cookbooks/syntax-err/recipes/default.rb:11:in `from_file'",
      ]

      expect(@inspector.filtered_bt).to eq(@expected_filtered_trace)
    end

    it "prints a pretty message" do
      @description.display(@outputter)
    end

    describe "and the error is a template error" do
      before do
        @description = Chef::Formatters::ErrorDescription.new("Error Converging Resource:")
        @template_class = Class.new { include Chef::Mixin::Template }
        @template = @template_class.new
        @context = Chef::Mixin::Template::TemplateContext.new({})
        @context[:chef] = "cool"

        @resource = template("/tmp/foo.txt") do
          mode "0644"
        end

        @error = begin
                   @context.render_template_from_string("foo\nbar\nbaz\n<%= this_is_not_defined %>\nquin\nqunx\ndunno")
                 rescue Chef::Mixin::Template::TemplateError => e
                   e
                 end

        @inspector = Chef::Formatters::ErrorInspectors::ResourceFailureInspector.new(@resource, :create, @error)
        @inspector.add_explanation(@description)
      end

      it "includes contextual info from the template error in the output" do
        @description.display(@outputter)
        expect(@stdout.string).to include(@error.source_listing)
      end

    end

    describe "recipe_snippet" do
      before do
        # fake code to run through #recipe_snippet
        source_file = [ "if true", "var = non_existent", "end" ]
        allow(IO).to receive(:readlines).and_return(source_file)
        allow(File).to receive(:exist?).and_return(true)
      end

      it "parses a Windows path" do
        source_line = "C:/Users/btm/chef/chef/spec/unit/fake_file.rb:2: undefined local variable or method `non_existent' for main:Object (NameError)"
        @resource.source_line = source_line
        @inspector = Chef::Formatters::ErrorInspectors::ResourceFailureInspector.new(@resource, :create, @exception)
        expect(@inspector.recipe_snippet).to match(%r{^# In C:/Users/btm})
      end

      it "parses a Windows path" do
        source_line = "C:\\Windows\\Temp\\packer\\cookbooks\\fake_file.rb:2: undefined local variable or method `non_existent' for main:Object (NameError)"
        @resource.source_line = source_line
        @inspector = Chef::Formatters::ErrorInspectors::ResourceFailureInspector.new(@resource, :create, @exception)
        expect(@inspector.recipe_snippet).to match(/^# In C:\\Windows\\Temp\\packer\\/)
      end

      it "parses a unix path" do
        source_line = "/home/btm/src/chef/chef/spec/unit/fake_file.rb:2: undefined local variable or method `non_existent' for main:Object (NameError)"
        @resource.source_line = source_line
        @inspector = Chef::Formatters::ErrorInspectors::ResourceFailureInspector.new(@resource, :create, @exception)
        expect(@inspector.recipe_snippet).to match(%r{^# In /home/btm})
      end

      context "when the recipe file does not exist" do
        before do
          allow(File).to receive(:exist?).and_return(false)
          allow(IO).to receive(:readlines).and_raise(Errno::ENOENT)
        end

        it "does not try to parse a recipe in chef-shell/irb (CHEF-3411)" do
          @resource.source_line = "(irb#1):1:in `irb_binding'"
          @inspector = Chef::Formatters::ErrorInspectors::ResourceFailureInspector.new(@resource, :create, @exception)
          expect(@inspector.recipe_snippet).to be_nil
        end

        it "does not raise an exception trying to load a non-existent file (CHEF-3411)" do
          @resource.source_line = "/somewhere/in/space"
          @inspector = Chef::Formatters::ErrorInspectors::ResourceFailureInspector.new(@resource, :create, @exception)
          expect { @inspector.recipe_snippet }.not_to raise_error
        end
      end
    end

    describe "when examining a resource that confuses the parser" do
      before do
        angry_bash_recipe = File.expand_path("cookbooks/angrybash/recipes/default.rb", CHEF_SPEC_DATA)
        source_line = "#{angry_bash_recipe}:1:in `<main>'"

        # source_line = caller(0)[0]; @resource = bash "go off the rails" do
        #   code <<-END
        #     for i in localhost 127.0.0.1 #{Socket.gethostname()}
        #     do
        #       echo "grant all on *.* to root@'$i' identified by 'a_password'; flush privileges;" | mysql -u root -h 127.0.0.1
        #     done
        #    END
        # end
        @resource = eval(IO.read(angry_bash_recipe))
        @resource.source_line = source_line
        @inspector = Chef::Formatters::ErrorInspectors::ResourceFailureInspector.new(@resource, :create, @exception)

        @exception.set_backtrace(@trace)
        @inspector = Chef::Formatters::ErrorInspectors::ResourceFailureInspector.new(@resource, :create, @exception)
      end

      it "does not generate an error" do
        expect { @inspector.add_explanation(@description) }.not_to raise_error
        @description.display(@outputter)
      end
    end

  end

end
