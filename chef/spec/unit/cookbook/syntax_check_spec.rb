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

###################################################
# OLD:
###################################################
# def test_ruby(cookbook_dir)
#   cache = Chef::ChecksumCache.instance
#   Dir[File.join(cookbook_dir, '**', '*.rb')].each do |ruby_file|
#     key = cache.generate_key(ruby_file, "chef-test")
#     fstat = File.stat(ruby_file)
#
#     if cache.lookup_checksum(key, fstat)
#       Chef::Log.info("No change in checksum of #{ruby_file}")
#     else
#       Chef::Log.info("Testing #{ruby_file} for syntax errors...")
#       Chef::Mixin::Command.run_command(:command => "ruby -c #{ruby_file}", :output_on_failure => true)
#       cache.generate_checksum(key, ruby_file, fstat)
#     end
#   end
# end
#
#def test_templates(cookbook_dir)
#  cache = Chef::ChecksumCache.instance
#  Dir[File.join(cookbook_dir, '**', '*.erb')].each do |erb_file|
#    key = cache.generate_key(erb_file, "chef-test")
#    fstat = File.stat(erb_file)
#
#    if cache.lookup_checksum(key, fstat)
#      Chef::Log.info("No change in checksum of #{erb_file}")
#    else
#      Chef::Log.info("Testing template #{erb_file} for syntax errors...")
#      Chef::Mixin::Command.run_command(:command => "sh -c 'erubis -x #{erb_file} | ruby -c'", :output_on_failure => true)
#      cache.generate_checksum(key, erb_file, fstat)
#    end
#  end
#end
#

###################################################
# NEW:
###################################################
# def test_template_file(cookbook_dir, erb_file)
#   Chef::Log.debug("Testing template #{erb_file} for syntax errors...")
#   result = shell_out("sh -c 'erubis -x #{erb_file} | ruby -c'")
#   result.error!
# rescue Mixlib::ShellOut::ShellCommandFailed
#   file_relative_path = erb_file[/^#{Regexp.escape(cookbook_dir+File::Separator)}(.*)/, 1]
#   Chef::Log.fatal("Erb template #{file_relative_path} has a syntax error:")
#   result.stderr.each_line { |l| Chef::Log.fatal(l.chomp) }
#   exit(1)
# end
#
# def test_ruby_file(cookbook_dir, ruby_file)
#   Chef::Log.debug("Testing #{ruby_file} for syntax errors...")
#   result = shell_out("ruby -c #{ruby_file}")
#   result.error!
# rescue Mixlib::ShellOut::ShellCommandFailed
#   file_relative_path = ruby_file[/^#{Regexp.escape(cookbook_dir+File::Separator)}(.*)/, 1]
#   Chef::Log.fatal("Cookbook file #{file_relative_path} has a syntax error:")
#   result.stderr.each_line { |l| Chef::Log.fatal(l.chomp) }
#   exit(1)
# end
#

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require "chef/cookbook/syntax_check"

describe Chef::Cookbook::SyntaxCheck do
  before do
    Chef::Log.logger = Logger.new(StringIO.new)

    @cookbook_path = File.join(CHEF_SPEC_DATA, 'cookbooks', 'openldap')

    @attr_files = %w{default.rb smokey.rb}.map { |f| File.join(@cookbook_path, 'attributes', f) }
    @defn_files = %w{client.rb server.rb}.map { |f| File.join(@cookbook_path, 'definitions', f)}
    @recipes = %w{default.rb gigantor.rb one.rb}.map { |f| File.join(@cookbook_path, 'recipes', f) }
    @ruby_files = @attr_files + @defn_files + @recipes

    @template_files = %w{openldap_stuff.conf.erb test.erb}.map { |f| File.join(@cookbook_path, 'templates', 'default', f)}

    @syntax_check = Chef::Cookbook::SyntaxCheck.new(@cookbook_path)
  end

  it "creates a syntax checker given the cookbook name when Chef::Config.cookbook_path is set" do
    Chef::Config[:cookbook_path] = File.dirname(@cookbook_path)
    syntax_check = Chef::Cookbook::SyntaxCheck.for_cookbook(:openldap)
    syntax_check.cookbook_path.should == @cookbook_path
  end

  describe "when first created" do
    it "has the path to the cookbook to syntax check" do
      @syntax_check.cookbook_path.should == @cookbook_path
    end

    it "has access to the checksum cache" do
      @syntax_check.cache.should equal(Chef::ChecksumCache.instance)
    end

    it "lists the ruby files in the cookbook" do
      @syntax_check.ruby_files.sort.should == @ruby_files.sort
    end

    it "lists the erb templates in the cookbook" do
      @syntax_check.template_files.sort.should == @template_files.sort
    end

  end

  describe "when validating cookbooks" do
    before do
      Chef::Config[:cache_type] = 'Memory'
      @checksum_cache_klass = Class.new(Chef::ChecksumCache)
      @checksum_cache = @checksum_cache_klass.instance
      @checksum_cache.reset!('Memory')
      @syntax_check.stub!(:cache).and_return(@checksum_cache)
      $stdout.stub!(:write)
    end

    describe "and the files have not been syntax checked previously" do
      it "shows that all ruby files require a syntax check" do
        @syntax_check.untested_ruby_files.sort.should == @ruby_files.sort
      end

      it "shows that all template files require a syntax check" do
        @syntax_check.untested_template_files.sort.should == @template_files.sort
      end

      it "removes a ruby file from the list of untested files after it is marked as validated" do
        recipe = File.join(@cookbook_path, 'recipes', 'default.rb')
        @syntax_check.validated(recipe)
        @syntax_check.untested_ruby_files.should_not include(recipe)
      end

      it "removes a template file from the list of untested files after it is marked as validated" do
        template = File.join(@cookbook_path, 'templates', 'default', 'test.erb')
        @syntax_check.validated(template)
        @syntax_check.untested_template_files.should_not include(template)
      end

      it "validates all ruby files" do
        @syntax_check.validate_ruby_files.should be_true
        @syntax_check.untested_ruby_files.should be_empty
      end

      it "validates all templates" do
        @syntax_check.validate_templates.should be_true
        @syntax_check.untested_template_files.should be_empty
      end

      describe "and a file has a syntax error" do
        before do
          @cookbook_path = File.join(CHEF_SPEC_DATA, 'cookbooks', 'borken')
          @syntax_check.cookbook_path.replace(@cookbook_path)
        end

        it "it indicates that a ruby file has a syntax error" do
          @syntax_check.validate_ruby_files.should be_false
        end

        it "does not remove the invalid file from the list of untested files" do
          @syntax_check.untested_ruby_files.should include(File.join(@cookbook_path, 'recipes', 'default.rb'))
          lambda { @syntax_check.validate_ruby_files }.should_not change(@syntax_check, :untested_ruby_files)
        end

        it "indicates that a template file has a syntax error" do
          @syntax_check.validate_templates.should be_false
        end

        it "does not remove the invalid template from the list of untested templates" do
          @syntax_check.untested_template_files.should include(File.join(@cookbook_path, 'templates', 'default', 'borken.erb'))
          lambda {@syntax_check.validate_templates}.should_not change(@syntax_check, :untested_template_files)
        end

      end

    end

    describe "and the files have been syntax checked previously" do
      before do
        @syntax_check.untested_ruby_files.each { |f| @syntax_check.validated(f) }
        @syntax_check.untested_template_files.each { |f| @syntax_check.validated(f) }
      end

      it "does not syntax check ruby files" do
        @syntax_check.should_not_receive(:shell_out)
        @syntax_check.validate_ruby_files.should be_true
      end

      it "does not syntax check templates" do
        @syntax_check.should_not_receive(:shell_out)
        @syntax_check.validate_templates.should be_true
      end
    end
  end
end
