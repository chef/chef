#
# Author:: Adam Jacob (<adam@chef.io>)
# Author:: Tim Hinderliter (<tim@chef.io>)
# Author:: Daniel DeLeo (<dan@chef.io>)
# Author:: John Keiser (<jkeiser@chef.io>)
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

require "knife_spec_helper"

describe Chef::Knife::UI do
  before do
    @out, @err, @in = StringIO.new, StringIO.new, StringIO.new
    @config = {
      verbosity: 0,
      yes: nil,
      format: "summary",
      field_separator: ".",
    }
    @ui = Chef::Knife::UI.new(@out, @err, @in, @config)
  end

  class TestObject < OpenStruct
    def self.from_hash(hsh)
      new(hsh)
    end
  end

  describe "edit" do
    ruby_for_json = { "foo" => "bar" }
    ruby_from_json = TestObject.from_hash(ruby_for_json)
    json_from_ruby = "{\n  \"foo\": \"bar\"\n}"
    json_from_editor = "{\n  \"bar\": \"foo\"\n}"
    ruby_from_editor = TestObject.from_hash({ "bar" => "foo" })
    my_editor = "veeeye"
    temp_path = "/tmp/bar/baz"

    let(:subject) { @ui.edit_data(ruby_for_json, parse_output, object_class: klass) }
    let(:parse_output) { false }
    let(:klass) { nil }

    context "when editing is disabled" do
      before do
        @ui.config[:disable_editing] = true
        stub_const("Tempfile", double) # Tempfiles should never be invoked
      end
      context "when parse_output is false" do
        it "returns pretty json string" do
          expect(subject).to eql(json_from_ruby)
        end
      end
      context "when parse_output is true" do
        let(:parse_output) { true }
        let(:klass) { TestObject }
        it "returns a ruby object" do
          expect(subject).to eql(ruby_from_json)
        end
        context "but no object class is provided" do
          let(:klass) { nil }
          it "raises an error" do
            expect { subject }.to raise_error ArgumentError,
              /Please pass in the object class to hydrate or use #edit_hash/
          end
        end
      end
    end

    context "when editing is enabled" do
      before do
        @ui.config[:disable_editing] = false
        @ui.config[:editor] = my_editor
        @mock = double("Tempfile")
        expect(@mock).to receive(:sync=).with(true)
        expect(@mock).to receive(:puts).with(json_from_ruby)
        expect(@mock).to receive(:close)
        expect(@mock).to receive(:path).at_least(:once).and_return(temp_path)
        expect(Tempfile).to receive(:open).with([ "knife-edit-", ".json" ]).and_yield(@mock)
      end
      context "and the editor works" do
        before do
          expect(@ui).to receive(:system).with("#{my_editor} #{temp_path}").and_return(true)
          expect(IO).to receive(:read).with(temp_path).and_return(json_from_editor)
        end

        context "when parse_output is false" do
          it "returns an edited pretty json string" do
            expect(subject).to eql(json_from_editor)
          end
        end
        context "when parse_output is true" do
          let(:parse_output) { true }
          let(:klass) { TestObject }
          it "returns an edited ruby object" do
            expect(subject).to eql(ruby_from_editor)
          end
        end
      end
      context "when running the editor fails with nil" do
        before do
          expect(@ui).to receive(:system).with("#{my_editor} #{temp_path}").and_return(nil)
          expect(IO).not_to receive(:read)
        end
        it "throws an exception" do
          expect { subject }.to raise_error(RuntimeError)
        end
      end
      context "when running the editor fails with false" do
        before do
          expect(@ui).to receive(:system).with("#{my_editor} #{temp_path}").and_return(false)
          expect(IO).not_to receive(:read)
        end
        it "throws an exception" do
          expect { subject }.to raise_error(RuntimeError)
        end
      end
    end
    context "when editing and not stubbing Tempfile (semi-functional test)" do
      before do
        @ui.config[:disable_editing] = false
        @ui.config[:editor] = my_editor
        @tempfile = Tempfile.new([ "knife-edit-", ".json" ])
        expect(Tempfile).to receive(:open).with([ "knife-edit-", ".json" ]).and_yield(@tempfile)
      end

      context "and the editor works" do
        before do
          expect(@ui).to receive(:system).with("#{my_editor} #{@tempfile.path}").and_return(true)
          expect(IO).to receive(:read).with(@tempfile.path).and_return(json_from_editor)
        end

        context "when parse_output is false" do
          it "returns an edited pretty json string" do
            expect(subject).to eql(json_from_editor)
          end
          it "the tempfile should have mode 0600", :unix_only do
            # XXX: this looks odd because we're really testing Tempfile.new here
            expect(File.stat(@tempfile.path).mode & 0777).to eql(0600)
            expect(subject).to eql(json_from_editor)
          end
        end

        context "when parse_output is true" do
          let(:parse_output) { true }
          let(:klass) { TestObject }
          it "returns an edited ruby object" do
            expect(subject).to eql(ruby_from_editor)
          end
          it "the tempfile should have mode 0600", :unix_only do
            # XXX: this looks odd because we're really testing Tempfile.new here
            expect(File.stat(@tempfile.path).mode & 0777).to eql(0600)
            expect(subject).to eql(ruby_from_editor)
          end
        end
      end
    end
  end

  describe "format_list_for_display" do
    it "should print the full hash if --with-uri is true" do
      @ui.config[:with_uri] = true
      expect(@ui.format_list_for_display({ marcy: :playground })).to eq({ marcy: :playground })
    end

    it "should print only the keys if --with-uri is false" do
      @ui.config[:with_uri] = false
      expect(@ui.format_list_for_display({ marcy: :playground })).to eq([ :marcy ])
    end
  end

  shared_examples "an output mehthod handling IO exceptions" do |method|
    it "should throw Errno::EIO exceptions" do
      allow(@out).to receive(:puts).and_raise(Errno::EIO)
      allow(@err).to receive(:puts).and_raise(Errno::EIO)
      expect { @ui.send(method, "hi") }.to raise_error(Errno::EIO)
    end

    it "should ignore Errno::EPIPE exceptions (CHEF-3516)" do
      allow(@out).to receive(:puts).and_raise(Errno::EPIPE)
      allow(@err).to receive(:puts).and_raise(Errno::EPIPE)
      expect { @ui.send(method, "hi") }.to raise_error(SystemExit)
    end

    it "should throw Errno::EPIPE exceptions with -VV (CHEF-3516)" do
      @config[:verbosity] = 2
      allow(@out).to receive(:puts).and_raise(Errno::EPIPE)
      allow(@err).to receive(:puts).and_raise(Errno::EPIPE)
      expect { @ui.send(method, "hi") }.to raise_error(Errno::EPIPE)
    end
  end

  describe "output" do
    it_behaves_like "an output mehthod handling IO exceptions", :output

    it "formats strings appropriately" do
      @ui.output("hi")
      expect(@out.string).to eq("hi\n")
    end

    it "formats hashes appropriately" do
      @ui.output({ "hi" => "a", "lo" => "b" })
      expect(@out.string).to eq <<~EOM
        hi: a
        lo: b
      EOM
    end

    it "formats empty hashes appropriately" do
      @ui.output({})
      expect(@out.string).to eq("\n")
    end

    it "formats arrays appropriately" do
      @ui.output(%w{a b})
      expect(@out.string).to eq <<~EOM
        a
        b
      EOM
    end

    it "formats empty arrays appropriately" do
      @ui.output([ ])
      expect(@out.string).to eq("\n")
    end

    it "formats single-member arrays appropriately" do
      @ui.output([ "a" ])
      expect(@out.string).to eq("a\n")
    end

    it "formats nested single-member arrays appropriately" do
      @ui.output([ [ "a" ] ])
      expect(@out.string).to eq("a\n")
    end

    it "formats nested arrays appropriately" do
      @ui.output([ %w{a b}, %w{c d}])
      expect(@out.string).to eq <<~EOM
        a
        b

        c
        d
      EOM
    end

    it "formats nested arrays with single- and empty subarrays appropriately" do
      @ui.output([ %w{a b}, [ "c" ], [], %w{d e}])
      expect(@out.string).to eq <<~EOM
        a
        b

        c


        d
        e
      EOM
    end

    it "formats arrays of hashes with extra lines in between for readability" do
      @ui.output([ { "a" => "b", "c" => "d" }, { "x" => "y" }, { "m" => "n", "o" => "p" }])
      expect(@out.string).to eq <<~EOM
        a: b
        c: d

        x: y

        m: n
        o: p
      EOM
    end

    it "formats hashes with empty array members appropriately" do
      @ui.output({ "a" => [], "b" => "c" })
      expect(@out.string).to eq <<~EOM
        a:
        b: c
      EOM
    end

    it "formats hashes with single-member array values appropriately" do
      @ui.output({ "a" => [ "foo" ], "b" => "c" })
      expect(@out.string).to eq <<~EOM
        a: foo
        b: c
      EOM
    end

    it "formats hashes with array members appropriately" do
      @ui.output({ "a" => %w{foo bar}, "b" => "c" })
      expect(@out.string).to eq <<~EOM
        a:
          foo
          bar
        b: c
      EOM
    end

    it "formats hashes with single-member nested array values appropriately" do
      @ui.output({ "a" => [ [ "foo" ] ], "b" => "c" })
      expect(@out.string).to eq <<~EOM
        a:
          foo
        b: c
      EOM
    end

    it "formats hashes with nested array values appropriately" do
      @ui.output({ "a" => [ %w{foo bar}, %w{baz bjork} ], "b" => "c" })
      # XXX: using a HEREDOC at this point results in a line with required spaces which auto-whitespace removal settings
      # on editors will remove and will break this test.
      expect(@out.string).to eq("a:\n  foo\n  bar\n  \n  baz\n  bjork\nb: c\n")
    end

    it "formats hashes with hash values appropriately" do
      @ui.output({ "a" => { "aa" => "bb", "cc" => "dd" }, "b" => "c" })
      expect(@out.string).to eq <<~EOM
        a:
          aa: bb
          cc: dd
        b: c
      EOM
    end

    it "formats hashes with empty hash values appropriately" do
      @ui.output({ "a" => {}, "b" => "c" })
      expect(@out.string).to eq <<~EOM
        a:
        b: c
      EOM
    end
  end

  describe "warn" do
    it_behaves_like "an output mehthod handling IO exceptions", :warn
  end

  describe "error" do
    it_behaves_like "an output mehthod handling IO exceptions", :warn
  end

  describe "fatal" do
    it_behaves_like "an output mehthod handling IO exceptions", :warn
  end

  describe "format_for_display" do
    it "should return the raw data" do
      input = { gi: :go }
      expect(@ui.format_for_display(input)).to eq(input)
    end

    describe "with --attribute passed" do
      it "should return the deeply nested attribute" do
        input = { "gi" => { "go" => "ge" }, "id" => "sample-data-bag-item" }
        @ui.config[:attribute] = "gi.go"
        expect(@ui.format_for_display(input)).to eq({ "sample-data-bag-item" => { "gi.go" => "ge" } })
      end

      it "should return multiple attributes" do
        input = { "gi" => "go", "hi" => "ho", "id" => "sample-data-bag-item" }
        @ui.config[:attribute] = %w{gi hi}
        expect(@ui.format_for_display(input)).to eq({ "sample-data-bag-item" => { "gi" => "go", "hi" => "ho" } })
      end

      it "should handle attributes named the same as methods" do
        input = { "keys" => "values", "hi" => "ho", "id" => "sample-data-bag-item" }
        @ui.config[:attribute] = "keys"
        expect(@ui.format_for_display(input)).to eq({ "sample-data-bag-item" => { "keys" => "values" } })
      end

      it "should handle nested attributes named the same as methods" do
        input = { "keys" => { "keys" => "values" }, "hi" => "ho", "id" => "sample-data-bag-item" }
        @ui.config[:attribute] = "keys.keys"
        expect(@ui.format_for_display(input)).to eq({ "sample-data-bag-item" => { "keys.keys" => "values" } })
      end

      it "should return the name attribute" do
        input = Chef::Node.new
        input.name("chef.localdomain")
        @ui.config[:attribute] = "name"
        expect(@ui.format_for_display(input)).to eq( { "chef.localdomain" => { "name" => "chef.localdomain" } })
      end

      it "should return a 'class' attribute and not the node.class" do
        input = Chef::Node.new
        input.default["class"] = "classy!"
        @ui.config[:attribute] = "class"
        expect(@ui.format_for_display(input)).to eq( { nil => { "class" => "classy!" } } )
      end

      it "should return the chef_environment attribute" do
        input = Chef::Node.new
        input.chef_environment = "production-partner-load-integration-preview-testing"
        @ui.config[:attribute] = "chef_environment"
        expect(@ui.format_for_display(input)).to eq( { nil => { "chef_environment" => "production-partner-load-integration-preview-testing" } } )
      end

      it "works with arrays" do
        input = Chef::Node.new
        input.default["array"] = %w{zero one two}
        @ui.config[:attribute] = "array.1"
        expect(@ui.format_for_display(input)).to eq( { nil => { "array.1" => "one" } } )
      end

      it "returns nil when given an attribute path that isn't a name or attribute" do
        input = { "keys" => { "keys" => "values" }, "hi" => "ho", "id" => "sample-data-bag-item" }
        non_existing_path = "nope.nada.nothingtoseehere"
        @ui.config[:attribute] = non_existing_path
        expect(@ui.format_for_display(input)).to eq({ "sample-data-bag-item" => { non_existing_path => nil } })
      end

      describe "when --field-separator is passed" do
        it "honors that separator" do
          input = { "keys" => { "with spaces" => { "open" => { "doors" => { "with many.dots" => "when asked" } } } } }
          @ui.config[:field_separator] = ";"
          @ui.config[:attribute] = "keys;with spaces;open;doors;with many.dots"
          expect(@ui.format_for_display(input)).to eq({ nil => { "keys;with spaces;open;doors;with many.dots" => "when asked" } })
        end
      end
    end

    describe "with --run-list passed" do
      it "should return the run list" do
        input = Chef::Node.new
        input.name("sample-node")
        input.run_list("role[monkey]", "role[churchmouse]")
        @ui.config[:run_list] = true
        response = @ui.format_for_display(input)
        expect(response["sample-node"]["run_list"][0]).to eq("role[monkey]")
        expect(response["sample-node"]["run_list"][1]).to eq("role[churchmouse]")
      end
    end
  end

  describe "format_cookbook_list_for_display" do
    before(:each) do
      @item = {
        "cookbook_name" => {
          "url" => "http://url/cookbooks/cookbook",
          "versions" => [
            { "version" => "3.0.0", "url" => "http://url/cookbooks/3.0.0" },
            { "version" => "2.0.0", "url" => "http://url/cookbooks/2.0.0" },
            { "version" => "1.0.0", "url" => "http://url/cookbooks/1.0.0" },
          ],
        },
      }
    end

    it "should return an array of the cookbooks with versions" do
      expected_response = [ "cookbook_name   3.0.0  2.0.0  1.0.0" ]
      response = @ui.format_cookbook_list_for_display(@item)
      expect(response).to eq(expected_response)
    end

    describe "with --with-uri" do
      it "should return the URIs" do
        response = {
          "cookbook_name" => {
            "1.0.0" => "http://url/cookbooks/1.0.0",
            "2.0.0" => "http://url/cookbooks/2.0.0",
            "3.0.0" => "http://url/cookbooks/3.0.0" },
        }
        @ui.config[:with_uri] = true
        expect(@ui.format_cookbook_list_for_display(@item)).to eq(response)
      end
    end

    context "when running on Windows" do
      before(:each) do
        stdout = double("StringIO", tty?: true)
        allow(@ui).to receive(:stdout).and_return(stdout)
        allow(ChefUtils).to receive(:windows?) { true }
        Chef::Config.reset
      end

      after(:each) do
        Chef::Config.reset
      end

      it "should have color set to true if knife config has color explicitly set to true" do
        Chef::Config[:color] = true
        @ui.config[:color] = true
        expect(@ui.color?).to eql(true)
      end

      it "should have color set to false if knife config has color explicitly set to false" do
        Chef::Config[:color] = false
        expect(@ui.color?).to eql(false)
      end

      it "should not have color set to false by default" do
        expect(@ui.color?).to eql(false)
      end
    end
  end

  describe "color" do
    context "when ui.color? => true" do
      it "returns colored output" do
        skip "doesn't work on systems that don't correctly have terminals setup for color"
        expect(@ui).to receive(:color?).and_return(true)
        expect(@ui.color("a_bus_is", :yellow)).to eql("\e[33ma_bus_is\e[0m")
      end
    end

    context "when ui.color? => false" do
      it "returns plain output" do
        expect(@ui).to receive(:color?).and_return(false)
        expect(@ui.color("a_bus_is", :yellow)).to eql("a_bus_is")
      end
    end
  end

  describe "confirm" do
    let(:stdout) { StringIO.new }
    let(:output) { stdout.string }

    let(:question) { "monkeys rule" }
    let(:answer) { "y" }

    let(:default_choice) { nil }
    let(:append_instructions) { true }

    def run_confirm
      allow(@ui).to receive(:stdout).and_return(stdout)
      allow(@ui.stdin).to receive(:readline).and_return(answer)
      @ui.confirm(question, append_instructions, default_choice)
    end

    def run_confirm_without_exit
      allow(@ui).to receive(:stdout).and_return(stdout)
      allow(@ui.stdin).to receive(:readline).and_return(answer)
      @ui.confirm_without_exit(question, append_instructions, default_choice)
    end

    shared_examples_for "confirm with positive answer" do
      it "confirm should return true" do
        expect(run_confirm).to be_truthy
      end

      it "confirm_without_exit should return true" do
        expect(run_confirm_without_exit).to be_truthy
      end
    end

    shared_examples_for "confirm with negative answer" do
      it "confirm should exit 3" do
        expect do
          run_confirm
        end.to raise_error(SystemExit) { |e| expect(e.status).to eq(3) }
      end

      it "confirm_without_exit should return false" do
        expect(run_confirm_without_exit).to be_falsey
      end
    end

    describe "with default choice set to true" do
      let(:default_choice) { true }

      it "should show 'Y/n' in the instructions" do
        run_confirm
        expect(output).to include("Y/n")
      end

      describe "with empty answer" do
        let(:answer) { "" }

        it_behaves_like "confirm with positive answer"
      end

      describe "with answer N " do
        let(:answer) { "N" }

        it_behaves_like "confirm with negative answer"
      end
    end

    describe "with default choice set to false" do
      let(:default_choice) { false }

      it "should show 'y/N' in the instructions" do
        run_confirm
        expect(output).to include("y/N")
      end

      describe "with empty answer" do
        let(:answer) { "" }

        it_behaves_like "confirm with negative answer"
      end

      describe "with answer N " do
        let(:answer) { "Y" }

        it_behaves_like "confirm with positive answer"
      end
    end

    %w{Y y}.each do |answer|
      describe "with answer #{answer}" do
        let(:answer) { answer }

        it_behaves_like "confirm with positive answer"
      end
    end

    %w{N n}.each do |answer|
      describe "with answer #{answer}" do
        let(:answer) { answer }

        it_behaves_like "confirm with negative answer"
      end
    end

    describe "with --y or --yes passed" do
      it "should return true" do
        @ui.config[:yes] = true
        expect(run_confirm).to be_truthy
        expect(output).to eq("")
      end
    end
  end

  describe "when asking for free-form user input" do
    it "asks a question and returns the answer provided by the user" do
      out = StringIO.new
      allow(@ui).to receive(:stdout).and_return(out)
      allow(@ui).to receive(:stdin).and_return(StringIO.new("http://mychefserver.example.com\n"))
      expect(@ui.ask_question("your chef server URL?")).to eq("http://mychefserver.example.com")
      expect(out.string).to eq("your chef server URL?")
    end

    it "suggests a default setting and returns the default when the user's response only contains whitespace" do
      out = StringIO.new
      allow(@ui).to receive(:stdout).and_return(out)
      allow(@ui).to receive(:stdin).and_return(StringIO.new(" \n"))
      expect(@ui.ask_question("your chef server URL? ", default: "http://localhost:4000")).to eq("http://localhost:4000")
      expect(out.string).to eq("your chef server URL? [http://localhost:4000] ")
    end
  end

end
