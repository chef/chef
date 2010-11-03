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

# Fixtures for subcommand loading live in this namespace
module KnifeSpecs
end

require File.expand_path(File.join(File.dirname(__FILE__), "..", "spec_helper"))

describe Chef::Knife do
  before(:each) do
    Chef::Log.logger = Logger.new(StringIO.new)

    Chef::Config[:node_name]  = "webmonkey.example.com"
    @knife = Chef::Knife.new
    @knife.stub!(:puts)
    @knife.stub!(:print)
    Chef::Knife.stub!(:puts)
  end

  it "builds a list of the core subcommand file require paths" do
    Chef::Knife::DEFAULT_SUBCOMMAND_FILES.should_not be_empty
    Chef::Knife::DEFAULT_SUBCOMMAND_FILES.each do |require_path|
      require_path.should match(%w{chef knife .*}.join(Regexp.escape(File::SEPARATOR)))
    end
  end

  describe "after loading a subcommand" do
    before do
      Chef::Knife.reset_subcommands!
 
      if KnifeSpecs.const_defined?(:TestNameMapping)
        KnifeSpecs.send(:remove_const, :TestNameMapping)
      end

      if KnifeSpecs.const_defined?(:TestExplicitCategory)
        KnifeSpecs.send(:remove_const, :TestExplicitCategory)
      end

      Kernel.load(File.join(CHEF_SPEC_DATA, 'knife_subcommand', 'test_name_mapping.rb'))
      Kernel.load(File.join(CHEF_SPEC_DATA, 'knife_subcommand', 'test_explicit_category.rb'))
    end

    it "has a category based on its name" do
      KnifeSpecs::TestNameMapping.subcommand_category.should == 'test'
    end

    it "has an explictly defined category if set" do
      KnifeSpecs::TestExplicitCategory.subcommand_category.should == 'cookbook site'
    end

    it "can reference the subcommand by its snake cased name" do
      Chef::Knife.subcommands['test_name_mapping'].should equal(KnifeSpecs::TestNameMapping)
    end

    it "lists subcommands by category" do
      Chef::Knife.subcommands_by_category['test'].should include('test_name_mapping')
    end

    it "lists subcommands by category when the subcommands have explicit categories" do
      Chef::Knife.subcommands_by_category['cookbook site'].should include('test_explicit_category')
    end

  end

  describe "after loading all subcommands" do
    before do
      Chef::Knife.reset_subcommands!
      Chef::Knife.load_commands
    end

    it "references a subcommand class by its snake cased name" do
      class SuperAwesomeCommand < Chef::Knife
      end

      Chef::Knife.load_commands
      
      Chef::Knife.subcommands.should have_key("super_awesome_command")
      Chef::Knife.subcommands["super_awesome_command"].should == SuperAwesomeCommand
    end

    it "lists all of the commands" do
      pending "post UI refactor"
      Chef::Knife.list_commands
    end

    it "guesses a category from a given ARGV" do
      Chef::Knife.subcommands_by_category["cookbook"] << :cookbook
      Chef::Knife.subcommands_by_category["cookbook site"] << :cookbook_site
      Chef::Knife.guess_category(%w{cookbook foo bar baz}).should == 'cookbook'
      Chef::Knife.guess_category(%w{cookbook site foo bar baz}).should == 'cookbook site'
      Chef::Knife.guess_category(%w{cookbook site --help}).should == 'cookbook site'
    end

    it "finds a subcommand class based on ARGV" do
      Chef::Knife.subcommands["cookbook_site_vendor"] = :CookbookSiteVendor
      Chef::Knife.subcommands["cookbook"] = :Cookbook
      Chef::Knife.subcommand_class_from(%w{cookbook site vendor --help foo bar baz}).should == :CookbookSiteVendor
    end

  end

  describe "when running a command" do
    before(:each) do
      if KnifeSpecs.const_defined?(:TestYourself)
        KnifeSpecs.send :remove_const, :TestYourself
      end
      Kernel.load(File.join(CHEF_SPEC_DATA, 'knife_subcommand', 'test_yourself.rb'))
      Chef::Knife.subcommands.each { |name, klass| Chef::Knife.subcommands.delete(name) unless klass.kind_of?(Class) }
    end

    it "merges the global knife CLI options" do
      extra_opts = {}
      extra_opts[:editor] = {:long=>"--editor EDITOR",
                             :description=>"Set the editor to use for interactive commands",
                             :short=>"-e EDITOR",
                             :default=>"/usr/bin/vim"}

      # there is special hackery to return the subcommand instance going on here.
      command = Chef::Knife.run(%w{test yourself}, extra_opts)
      editor_opts = command.options[:editor]
      editor_opts[:long].should         == "--editor EDITOR"
      editor_opts[:description].should  == "Set the editor to use for interactive commands"
      editor_opts[:short].should        == "-e EDITOR"
      editor_opts[:default].should      == "/usr/bin/vim"
    end

    it "creates an instance of the subcommand and runs it" do
      command = Chef::Knife.run(%w{test yourself})
      command.should be_an_instance_of(KnifeSpecs::TestYourself)
      command.ran.should be_true
    end

    it "passes the command specific args to the subcommand" do
      command = Chef::Knife.run(%w{test yourself with some args})
      command.name_args.should == %w{with some args}
    end

    it "excludes the command name from the name args when parts are joined with underscores" do
      command = Chef::Knife.run(%w{test_yourself with some args})
      command.name_args.should == %w{with some args}
    end

    it "exits if no subcommand matches the CLI args" do
      lambda {Chef::Knife.run(%w{fuuu uuuu fuuuu})}.should raise_error(SystemExit) { |e| e.status.should_not == 0 }
    end

  end

  describe "when first created" do
    before do
      unless KnifeSpecs.const_defined?(:TestYourself)
        Kernel.load(File.join(CHEF_SPEC_DATA, 'knife_subcommand', 'test_yourself.rb'))
      end
      @knife = KnifeSpecs::TestYourself.new(%w{with some args -s scrogramming})
    end

    it "it parses the options passed to it" do
      @knife.config[:scro].should == 'scrogramming'
    end

    it "extracts its command specific args from the full arg list" do
      @knife.name_args.should == %w{with some args}
    end

  end

  describe "format_list_for_display" do
    it "should print the full hash if --with-uri is true" do
      @knife.config[:with_uri] = true
      @knife.format_list_for_display({ :marcy => :playground }).should == { :marcy => :playground }
    end

    it "should print only the keys if --with-uri is false" do
      @knife.config[:with_uri] = false
      @knife.format_list_for_display({ :marcy => :playground }).should == [ :marcy ]
    end
  end

  describe "format_for_display" do
    it "should return the raw data" do
      input = { :gi => :go }
      @knife.format_for_display(input).should == input
    end

    describe "with a data bag item" do
      it "should use the raw data" do
        dbi = mock(Chef::DataBagItem, :kind_of? => true)
        dbi.should_receive(:raw_data).and_return({ "monkey" => "soup" })
        @knife.format_for_display(dbi).should == { "monkey" => "soup" }
      end
    end

    describe "with --attribute passed" do
      it "should return the deeply nested attribute" do
        input = { "gi" => { "go" => "ge" } }
        @knife.config[:attribute] = "gi.go"
        @knife.format_for_display(input).should == { "gi.go" => "ge" }
      end
    end

    describe "with --run-list passed" do
      it "should return the run list" do
        input = Chef::Node.new
        input.run_list("role[monkey]", "role[churchmouse]")
        @knife.config[:run_list] = true
        response = @knife.format_for_display(input)
        response["run_list"][0].should == "role[monkey]"
        response["run_list"][1].should == "role[churchmouse]"
      end
    end
  end

  describe "confirm" do
    before(:each) do
      @question = "monkeys rule"
      @stdout = StringIO.new
      @knife.stub(:stdout).and_return(@stdout)
      STDIN.stub!(:readline).and_return("y")
    end

    it "should return true if you answer Y" do
      STDIN.stub!(:readline).and_return("Y")
      @knife.confirm(@question).should == true
    end

    it "should return true if you answer y" do
      STDIN.stub!(:readline).and_return("y")
      @knife.confirm(@question).should == true
    end

    it "should exit 3 if you answer N" do
      STDIN.stub!(:readline).and_return("N")
      lambda {
        @knife.confirm(@question)
      }.should raise_error(SystemExit) { |e| e.status.should == 3 }
    end

    it "should exit 3 if you answer n" do
      STDIN.stub!(:readline).and_return("n")
      lambda {
        @knife.confirm(@question)
      }.should raise_error(SystemExit) { |e| e.status.should == 3 }
    end

    describe "with --y or --yes passed" do
      it "should return true" do
        @knife.config[:yes] = true
        @knife.confirm(@question).should == true
      end
    end

    describe "when asking for free-form user input" do
      it "asks a question and returns the answer provided by the user" do
        out = StringIO.new
        @knife.stub!(:stdout).and_return(out)
        @knife.stub!(:stdin).and_return(StringIO.new("http://mychefserver.example.com\n"))
        @knife.ask_question("your chef server URL?").should == "http://mychefserver.example.com"
        out.string.should == "your chef server URL?"
      end

      it "suggests a default setting and returns the default when the user's response only contains whitespace" do
        out = StringIO.new
        @knife.stub!(:stdout).and_return(out)
        @knife.stub!(:stdin).and_return(StringIO.new(" \n"))
        @knife.ask_question("your chef server URL? ", :default => 'http://localhost:4000').should == "http://localhost:4000"
        out.string.should == "your chef server URL? [http://localhost:4000] "
      end
    end

  end

end

