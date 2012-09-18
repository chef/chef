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

describe Chef::Formatters::ErrorInspectors::ResourceFailureInspector do
  include Chef::Mixin::RecipeDefinitionDSLCore

  def run_context
    node = Chef::Node.new
    node[:platform] = "ubuntu"
    node[:platform_version] = "10.04"
    Chef::RunContext.new(node, {}, nil)
  end

  def cookbook_name
    "rspec-example"
  end

  before do
    @description = Chef::Formatters::ErrorDescription.new("Error Converging Resource:")
    @outputter = Chef::Formatters::Outputter.new(StringIO.new, STDERR)
    #@outputter = Chef::Formatters::Outputter.new(STDOUT, STDERR)

    Chef::Config.stub!(:cookbook_path).and_return([ "/var/chef/cache" ])
  end

  describe "when explaining an error converging a resource" do
    before do
      source_line = caller(0)[0]
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
        "/usr/local/lib/ruby/gems/chef/lib/chef/client.rb:123:in `run'" # should not display
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

      @inspector.filtered_bt.should == @expected_filtered_trace
    end

    it "prints a pretty message" do
      @description.display(@outputter)
    end

    describe "recipe_snippet" do
      before do
        # fake code to run through #recipe_snippet
        source_file = [ "if true", "var = non_existant", "end" ]
        IO.stub!(:readlines).and_return(source_file)
      end

      it "parses a Windows path" do
        source_line = "C:/Users/btm/chef/chef/spec/unit/fake_file.rb:2: undefined local variable or method `non_existant' for main:Object (NameError)"
        @resource.source_line = source_line
        @inspector = Chef::Formatters::ErrorInspectors::ResourceFailureInspector.new(@resource, :create, @exception)
        @inspector.recipe_snippet.should match(/^# In C:\/Users\/btm/)
      end

      it "parses a unix path" do
        source_line = "/home/btm/src/chef/chef/spec/unit/fake_file.rb:2: undefined local variable or method `non_existant' for main:Object (NameError)"
        @resource.source_line = source_line
        @inspector = Chef::Formatters::ErrorInspectors::ResourceFailureInspector.new(@resource, :create, @exception)
        @inspector.recipe_snippet.should match(/^# In \/home\/btm/)
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
        @inspector.add_explanation(@description)
      end

      it "does not generate an error" do
        @description.display(@outputter)
      end
    end

  end


end
