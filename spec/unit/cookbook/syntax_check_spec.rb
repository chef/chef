#
# Author:: Daniel DeLeo (<dan@opscode.com>)
# Copyright:: Copyright (c) 2010 Opscode, Inc.
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
require "chef/cookbook/syntax_check"

describe Chef::Cookbook::SyntaxCheck do

  let(:cookbook_path) { File.join(CHEF_SPEC_DATA, 'cookbooks', 'openldap') }
  let(:syntax_check) { Chef::Cookbook::SyntaxCheck.new(cookbook_path) }

  before do
    Chef::Log.logger = Logger.new(StringIO.new)
    Chef::Log.level = :warn # suppress "Syntax OK" messages


    @attr_files = %w{default.rb smokey.rb}.map { |f| File.join(cookbook_path, 'attributes', f) }
    @defn_files = %w{client.rb server.rb}.map { |f| File.join(cookbook_path, 'definitions', f)}
    @recipes = %w{default.rb gigantor.rb one.rb}.map { |f| File.join(cookbook_path, 'recipes', f) }
    @ruby_files = @attr_files + @defn_files + @recipes

    @template_files = %w{openldap_stuff.conf.erb openldap_variable_stuff.conf.erb test.erb}.map { |f| File.join(cookbook_path, 'templates', 'default', f)}

  end

  it "creates a syntax checker given the cookbook name when Chef::Config.cookbook_path is set" do
    Chef::Config[:cookbook_path] = File.dirname(cookbook_path)
    syntax_check = Chef::Cookbook::SyntaxCheck.for_cookbook(:openldap)
    syntax_check.cookbook_path.should == cookbook_path
  end

  describe "when first created" do
    it "has the path to the cookbook to syntax check" do
      syntax_check.cookbook_path.should == cookbook_path
    end

    it "lists the ruby files in the cookbook" do
      syntax_check.ruby_files.sort.should == @ruby_files.sort
    end

    it "lists the erb templates in the cookbook" do
      syntax_check.template_files.sort.should == @template_files.sort
    end

  end

  describe "when validating cookbooks" do
    let(:cache_path) { Dir.mktmpdir }

    before do
      Chef::Config[:syntax_check_cache_path] = cache_path
    end

    after do
      FileUtils.rm_rf(cache_path) if File.exist?(cache_path)
      Chef::Config[:syntax_check_cache_path] = nil
    end

    describe "and the files have not been syntax checked previously" do
      it "shows that all ruby files require a syntax check" do
        syntax_check.untested_ruby_files.sort.should == @ruby_files.sort
      end

      it "shows that all template files require a syntax check" do
        syntax_check.untested_template_files.sort.should == @template_files.sort
      end

      it "removes a ruby file from the list of untested files after it is marked as validated" do
        recipe = File.join(cookbook_path, 'recipes', 'default.rb')
        syntax_check.validated(recipe)
        syntax_check.untested_ruby_files.should_not include(recipe)
      end

      it "removes a template file from the list of untested files after it is marked as validated" do
        template = File.join(cookbook_path, 'templates', 'default', 'test.erb')
        syntax_check.validated(template)
        syntax_check.untested_template_files.should_not include(template)
      end

      it "validates all ruby files" do
        syntax_check.validate_ruby_files.should be_true
        syntax_check.untested_ruby_files.should be_empty
      end

      it "validates all templates" do
        syntax_check.validate_templates.should be_true
        syntax_check.untested_template_files.should be_empty
      end

      describe "and a file has a syntax error" do
        before do
          cookbook_path = File.join(CHEF_SPEC_DATA, 'cookbooks', 'borken')
          syntax_check.cookbook_path.replace(cookbook_path)
        end

        it "it indicates that a ruby file has a syntax error" do
          syntax_check.validate_ruby_files.should be_false
        end

        it "does not remove the invalid file from the list of untested files" do
          syntax_check.untested_ruby_files.should include(File.join(cookbook_path, 'recipes', 'default.rb'))
          lambda { syntax_check.validate_ruby_files }.should_not change(syntax_check, :untested_ruby_files)
        end

        it "indicates that a template file has a syntax error" do
          syntax_check.validate_templates.should be_false
        end

        it "does not remove the invalid template from the list of untested templates" do
          syntax_check.untested_template_files.should include(File.join(cookbook_path, 'templates', 'default', 'borken.erb'))
          lambda {syntax_check.validate_templates}.should_not change(syntax_check, :untested_template_files)
        end

      end

    end

    describe "and the files have been syntax checked previously" do
      before do
        syntax_check.untested_ruby_files.each { |f| syntax_check.validated(f) }
        syntax_check.untested_template_files.each { |f| syntax_check.validated(f) }
      end

      it "does not syntax check ruby files" do
        syntax_check.should_not_receive(:shell_out)
        syntax_check.validate_ruby_files.should be_true
      end

      it "does not syntax check templates" do
        syntax_check.should_not_receive(:shell_out)
        syntax_check.validate_templates.should be_true
      end
    end
  end
end
