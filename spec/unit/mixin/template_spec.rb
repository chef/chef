#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2008 Opscode, Inc.
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

class TinyTemplateClass; include Chef::Mixin::Template; end
require 'cgi'
describe Chef::Mixin::Template, "render_template" do

  before :each do
    @template = TinyTemplateClass.new
    @context = Chef::Mixin::Template::TemplateContext.new({})
  end

  it "should render the template evaluated in the given context" do
    @context[:foo] = "bar"
    @template.render_template("<%= @foo %>", @context) do |tmp|
      tmp.open.read.should == "bar"
    end
  end

  it "should provide a node method to access @node" do
    @context[:node] = "tehShizzle"
    @template.render_template("<%= node %>", @context) do |tmp|
      tmp.open.read.should == "tehShizzle"
    end
  end

  it "should yield the tempfile it renders the template to" do
    @template.render_template("abcdef", {}) do |tempfile|
      tempfile.should be_kind_of(Tempfile)
    end
  end

  describe "with a template resource" do
    before :each do
      @cookbook_repo = File.expand_path(File.join(CHEF_SPEC_DATA, "cookbooks"))
      Chef::Cookbook::FileVendor.on_create { |manifest| Chef::Cookbook::FileSystemFileVendor.new(manifest, @cookbook_repo) }

      @node = Chef::Node.new
      cl = Chef::CookbookLoader.new(@cookbook_repo)
      cl.load_cookbooks
      @cookbook_collection = Chef::CookbookCollection.new(cl)
      @events = Chef::EventDispatch::Dispatcher.new
      @run_context = Chef::RunContext.new(@node, @cookbook_collection, @events)

      @rendered_file_location = Dir.tmpdir + '/openldap_stuff.conf'

      @resource = Chef::Resource::Template.new(@rendered_file_location)
      @resource.cookbook_name = 'openldap'
      @current_resource = @resource.dup

      @content_provider = Chef::Provider::Template::Content.new(@resource, @current_resource, @run_context)

      @template_context = Chef::Mixin::Template::TemplateContext.new({})
      @template_context[:node] = @node
      @template_context[:template_finder] = Chef::Provider::TemplateFinder.new(@run_context, @resource.cookbook_name, @node)
    end

    it "should provide a render method" do
      @content_provider.render_template("before {<%= render 'test.erb' %>} after", @template_context) do |tmp|
        tmp.open.read.should == "before {We could be diving for pearls!\n} after"
      end
    end

    it "should render local files" do
      begin
        tf = Tempfile.new("partial")
        tf.puts "test"
        tf.rewind

        @content_provider.render_template("before {<%= render '#{tf.path}', :local => true %>} after", @template_context) do |tmp|
          tmp.open.read.should == "before {test\n} after"
        end
      ensure
        tf.close
      end
    end

    it "should render partials from a different cookbook" do
      @template_context[:template_finder] = Chef::Provider::TemplateFinder.new(@run_context, 'apache2', @node)

      @content_provider.render_template("before {<%= render 'test.erb', :cookbook => 'openldap' %>} after", @template_context) do |tmp|
        tmp.open.read.should == "before {We could be diving for pearls!\n} after"
      end
    end

    it "should render using the source argument if provided" do
      begin
        tf = Tempfile.new("partial")
        tf.puts "test"
        tf.rewind

        @content_provider.render_template("before {<%= render 'something', :local => true, :source => '#{tf.path}' %>} after", @template_context) do |tmp|
          tmp.open.read.should == "before {test\n} after"
        end
      ensure
        tf.close
      end
    end

    it "should pass the node to partials" do
      @node.normal[:slappiness] = "happiness"

      @content_provider.render_template("before {<%= render 'openldap_stuff.conf.erb' %>} after", @template_context) do |tmp|
        tmp.open.read.should == "before {slappiness is happiness} after"
      end
    end

    it "should pass the original variables to partials" do
      @template_context[:secret] = 'candy'

      @content_provider.render_template("before {<%= render 'openldap_variable_stuff.conf.erb' %>} after", @template_context) do |tmp|
        tmp.open.read.should == "before {super secret is candy} after"
      end
    end

    it "should pass variables to partials" do
      @content_provider.render_template("before {<%= render 'openldap_variable_stuff.conf.erb', :variables => {:secret => 'whatever' } %>} after", @template_context) do |tmp|
        tmp.open.read.should == "before {super secret is whatever} after"
      end
    end

    it "should pass variables to partials even if they are named the same" do
      @template_context[:secret] = 'one'

      @content_provider.render_template("before {<%= render 'openldap_variable_stuff.conf.erb', :variables => {:secret => 'two' } %>} after <%= @secret %>", @template_context) do |tmp|
        tmp.open.read.should == "before {super secret is two} after one"
      end
    end

    it "should pass nil for missing variables in partials" do
      @content_provider.render_template("before {<%= render 'openldap_variable_stuff.conf.erb', :variables => {} %>} after", @template_context) do |tmp|
        tmp.open.read.should == "before {super secret is } after"
      end

      @content_provider.render_template("before {<%= render 'openldap_variable_stuff.conf.erb' %>} after", @template_context) do |tmp|
        tmp.open.read.should == "before {super secret is } after"
      end
    end

    it "should render nested partials" do
      path = File.expand_path(File.join(CHEF_SPEC_DATA, "partial_one.erb"))

      @content_provider.render_template("before {<%= render '#{path}', :local => true %>} after", @template_context) do |tmp|
        tmp.open.read.should == "before {partial one We could be diving for pearls!\n calling home\n} after"
      end
    end

    describe "when customizing the template context" do

      it "extends the context to include modules" do
        mod = Module.new do
          def hello
            "ohai"
          end
        end
        @template_context._extend_modules([mod])
        @content_provider.render_template("<%=hello%>", @template_context) do |tmp|
          tmp.open.read.should == "ohai"
        end
      end

      it "emits a warning when overriding 'core' methods" do
        mod = Module.new do
          def render
          end
          def node
          end
        end
        expected_node_warning = Regexp.escape("Core template method `node' overridden by extension module")
        Chef::Log.should_receive(:warn).with(/^#{expected_node_warning}/)

        expected_render_warning = Regexp.escape("Core template method `render' overridden by extension module")
        Chef::Log.should_receive(:warn).with(/^#{expected_render_warning}/)
        @template_context._extend_modules([mod])
      end
    end

  end

  describe "when an exception is raised in the template" do
    def do_raise
      @context = {:chef => "cool"}
      @template.render_template("foo\nbar\nbaz\n<%= this_is_not_defined %>\nquin\nqunx\ndunno", @context) {|r| r}
    end

    it "should catch and re-raise the exception as a TemplateError" do
      lambda { do_raise }.should raise_error(Chef::Mixin::Template::TemplateError)
    end

    it "should raise an error if an attempt is made to access node but it is nil" do
      lambda {@template.render_template("<%= node %>",{}) {|r| r}}.should raise_error(Chef::Mixin::Template::TemplateError)
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
        @exception.original_exception.should be
        @exception.original_exception.message.should =~ /undefined local variable or method `this_is_not_defined'/
      end

      it "should determine the line number of the exception" do
        @exception.line_number.should == 4
      end

      it "should provide a source listing of the template around the exception" do
        @exception.source_listing.should == "  2: bar\n  3: baz\n  4: <%= this_is_not_defined %>\n  5: quin\n  6: qunx"
      end

      it "should provide the evaluation context of the template" do
        @exception.context.should == @context
      end

      it "should defer the message to the original exception" do
        @exception.message.should =~ /undefined local variable or method `this_is_not_defined'/
      end

      it "should provide a nice source location" do
        @exception.source_location.should == "on line #4"
      end

      it "should create a pretty output for the terminal" do
        @exception.to_s.should =~ /Chef::Mixin::Template::TemplateError/
        @exception.to_s.should =~ /undefined local variable or method `this_is_not_defined'/
        @exception.to_s.should include("  2: bar\n  3: baz\n  4: <%= this_is_not_defined %>\n  5: quin\n  6: qunx")
        @exception.to_s.should include(@exception.original_exception.backtrace.first)
      end
    end
  end
end

