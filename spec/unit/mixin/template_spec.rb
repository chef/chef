#
# Author:: Adam Jacob (<adam@chef.io>)
# Copyright:: Copyright 2008-2016, Chef Software Inc.
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

require "cgi"
describe Chef::Mixin::Template, "render_template" do

  let(:sep) { Chef::Platform.windows? ? "\r\n" : "\n" }

  before :each do
    @context = Chef::Mixin::Template::TemplateContext.new({})
  end

  it "should render the template evaluated in the given context" do
    @context[:foo] = "bar"
    output = @context.render_template_from_string("<%= @foo %>")
    expect(output).to eq("bar")
  end

  template_contents = [ "Fancy\r\nTemplate\r\n\r\n",
                        "Fancy\nTemplate\n\n",
                        "Fancy\r\nTemplate\n\r\n"]

  describe "when running on windows" do
    before do
      allow(ChefConfig).to receive(:windows?).and_return(true)
    end

    it "should render the templates with windows line endings" do
      template_contents.each do |template_content|
        output = @context.render_template_from_string(template_content)
        output.each_line do |line|
          expect(line).to end_with("\r\n")
        end
      end
    end
  end

  describe "when running on unix" do
    before do
      allow(ChefConfig).to receive(:windows?).and_return(false)
    end

    it "should render the templates with unix line endings" do
      template_contents.each do |template_content|
        output = @context.render_template_from_string(template_content)
        output.each_line do |line|
          expect(line).to end_with("\n")
        end
      end
    end
  end

  it "should provide a node method to access @node" do
    @context[:node] = "tehShizzle"
    output = @context.render_template_from_string("<%= @node %>")
    expect(output).to eq("tehShizzle")
  end

  describe "with a template resource" do
    before :each do
      @cookbook_repo = File.expand_path(File.join(CHEF_SPEC_DATA, "cookbooks"))
      Chef::Cookbook::FileVendor.fetch_from_disk(@cookbook_repo)

      @node = Chef::Node.new
      cl = Chef::CookbookLoader.new(@cookbook_repo)
      cl.load_cookbooks
      @cookbook_collection = Chef::CookbookCollection.new(cl)
      @events = Chef::EventDispatch::Dispatcher.new
      @run_context = Chef::RunContext.new(@node, @cookbook_collection, @events)

      @rendered_file_location = Dir.tmpdir + "/openldap_stuff.conf"

      @resource = Chef::Resource::Template.new(@rendered_file_location)
      @resource.cookbook_name = "openldap"
      @current_resource = @resource.dup

      @content_provider = Chef::Provider::Template::Content.new(@resource, @current_resource, @run_context)

      @template_context = Chef::Mixin::Template::TemplateContext.new({})
      @template_context[:node] = @node
      @template_context[:template_finder] = Chef::Provider::TemplateFinder.new(@run_context, @resource.cookbook_name, @node)
    end

    it "should provide a render method" do
      output = @template_context.render_template_from_string("before {<%= render('test.erb').strip -%>} after")
      expect(output).to eq("before {We could be diving for pearls!} after")
    end

    it "should render local files" do
      begin
        tf = Tempfile.new("partial")
        tf.write "test"
        tf.rewind

        output = @template_context.render_template_from_string("before {<%= render '#{tf.path}', :local => true %>} after")
        expect(output).to eq("before {test} after")
      ensure
        tf.close
      end
    end

    it "should render partials from a different cookbook" do
      @template_context[:template_finder] = Chef::Provider::TemplateFinder.new(@run_context, "apache2", @node)

      output = @template_context.render_template_from_string("before {<%= render('test.erb', :cookbook => 'openldap').strip %>} after")
      expect(output).to eq("before {We could be diving for pearls!} after")
    end

    it "should render using the source argument if provided" do
      begin
        tf = Tempfile.new("partial")
        tf.write "test"
        tf.rewind

        output = @template_context.render_template_from_string("before {<%= render 'something', :local => true, :source => '#{tf.path}' %>} after")
        expect(output).to eq("before {test} after")
      ensure
        tf.close
      end
    end

    it "should pass the node to partials" do
      @node.normal[:slappiness] = "happiness"

      output = @template_context.render_template_from_string("before {<%= render 'openldap_stuff.conf.erb' %>} after")
      expect(output).to eq("before {slappiness is happiness} after")
    end

    it "should pass the original variables to partials" do
      @template_context[:secret] = "candy"

      output = @template_context.render_template_from_string("before {<%= render 'openldap_variable_stuff.conf.erb' %>} after")
      output == "before {super secret is candy} after"
    end

    it "should pass the template finder to the partials" do
      output = @template_context.render_template_from_string("before {<%= render 'nested_openldap_partials.erb', :variables => {:hello => 'Hello World!' } %>} after")
      output == "before {Hello World!} after"
    end

    it "should pass variables to partials" do
      output = @template_context.render_template_from_string("before {<%= render 'openldap_variable_stuff.conf.erb', :variables => {:secret => 'whatever' } %>} after")
      expect(output).to eq("before {super secret is whatever} after")
    end

    it "should pass variables to partials even if they are named the same" do
      @template_context[:secret] = "one"

      output = @template_context.render_template_from_string("before {<%= render 'openldap_variable_stuff.conf.erb', :variables => {:secret => 'two' } %>} after <%= @secret %>")
      expect(output).to eq("before {super secret is two} after one")
    end

    it "should pass nil for missing variables in partials" do
      output = @template_context.render_template_from_string("before {<%= render 'openldap_variable_stuff.conf.erb', :variables => {} %>} after")
      expect(output).to eq("before {super secret is } after")

      output = @template_context.render_template_from_string("before {<%= render 'openldap_variable_stuff.conf.erb' %>} after")
      expect(output).to eq("before {super secret is } after")
    end

    it "should render nested partials" do
      path = File.expand_path(File.join(CHEF_SPEC_DATA, "partial_one.erb"))

      output = @template_context.render_template_from_string("before {<%= render('#{path}', :local => true).strip %>} after")
      expect(output).to eq("before {partial one We could be diving for pearls! calling home} after")
    end

    describe "when customizing the template context" do

      it "extends the context to include modules" do
        mod = Module.new do
          def hello
            "ohai"
          end
        end
        @template_context._extend_modules([mod])
        output = @template_context.render_template_from_string("<%=hello%>")
        expect(output).to eq("ohai")
      end

      it "emits a warning when overriding 'core' methods" do
        mod = Module.new do
          def render
          end

          def node
          end

          def render_template
          end

          def render_template_from_string
          end
        end
        %w{node render render_template render_template_from_string}.each do |method_name|
          expect(Chef::Log).to receive(:warn).with(/^Core template method `#{method_name}' overridden by extension module/)
        end
        @template_context._extend_modules([mod])
      end
    end

  end

  describe "when an exception is raised in the template" do
    def do_raise
      @context.render_template_from_string("foo\nbar\nbaz\n<%= this_is_not_defined %>\nquin\nqunx\ndunno")
    end

    it "should catch and re-raise the exception as a TemplateError" do
      expect { do_raise }.to raise_error(Chef::Mixin::Template::TemplateError)
    end

    it "should raise an error if an attempt is made to access node but it is nil" do
      expect { @context.render_template_from_string("<%= node %>") { |r| r } }.to raise_error(Chef::Mixin::Template::TemplateError)
    end

    describe "the raised TemplateError" do
      before :each do
        begin
          do_raise
        rescue Chef::Mixin::Template::TemplateError => e
          @exception = e
        end
      end

      it "should have the original exception" do
        expect(@exception.original_exception).to be
        expect(@exception.original_exception.message).to match(/undefined local variable or method `this_is_not_defined'/)
      end

      it "should determine the line number of the exception" do
        expect(@exception.line_number).to eq(4)
      end

      it "should provide a source listing of the template around the exception" do
        expect(@exception.source_listing).to eq("  2: bar\n  3: baz\n  4: <%= this_is_not_defined %>\n  5: quin\n  6: qunx")
      end

      it "should provide the evaluation context of the template" do
        expect(@exception.context).to eq(@context)
      end

      it "should defer the message to the original exception" do
        expect(@exception.message).to match(/undefined local variable or method `this_is_not_defined'/)
      end

      it "should provide a nice source location" do
        expect(@exception.source_location).to eq("on line #4")
      end

      it "should create a pretty output for the terminal" do
        expect(@exception.to_s).to match(/Chef::Mixin::Template::TemplateError/)
        expect(@exception.to_s).to match(/undefined local variable or method `this_is_not_defined'/)
        expect(@exception.to_s).to include("  2: bar\n  3: baz\n  4: <%= this_is_not_defined %>\n  5: quin\n  6: qunx")
        expect(@exception.to_s).to include(@exception.original_exception.backtrace.first)
      end
    end
  end
end
