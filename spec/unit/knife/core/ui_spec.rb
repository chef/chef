#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Tim Hinderliter (<tim@opscode.com>)
# Author:: Daniel DeLeo (<dan@opscode.com>)
# Author:: John Keiser (<jkeiser@opscode.com>)
# Copyright:: Copyright (c) 2008, 2011, 2012 Opscode, Inc.
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

describe Chef::Knife::UI do
  before do
    @out, @err, @in = StringIO.new, StringIO.new, StringIO.new
    @config = {
      :verbosity => 0,
      :yes => nil,
      :format => "summary",
    }
    @ui = Chef::Knife::UI.new(@out, @err, @in, @config)
  end

  describe "edit" do
    ruby_for_json = { 'foo' => 'bar' }
    json_from_ruby = "{\n  \"foo\": \"bar\"\n}"
    json_from_editor = "{\n  \"bar\": \"foo\"\n}"
    ruby_from_editor = { 'bar' => 'foo' }
    my_editor = "veeeye"
    temp_path = "/tmp/bar/baz"

    let(:subject) { @ui.edit_data(ruby_for_json, parse_output) }
    let(:parse_output) { false }

    context "when editing is disabled" do
      before do
        @ui.config[:disable_editing] = true
        stub_const("Tempfile", double)  # Tempfiles should never be invoked
      end
      context "when parse_output is false" do
        it "returns pretty json string" do
          expect(subject).to eql(json_from_ruby)
        end
      end
      context "when parse_output is true" do
        let(:parse_output) { true }
        it "returns a ruby object" do
          expect(subject).to eql(ruby_for_json)
        end
      end

    end

    context "when editing is enabled" do
      before do
        @ui.config[:disable_editing] = false
        @ui.config[:editor] = my_editor
        @mock = double('Tempfile')
        @mock.should_receive(:sync=).with(true)
        @mock.should_receive(:puts).with(json_from_ruby)
        @mock.should_receive(:close)
        @mock.should_receive(:path).at_least(:once).and_return(temp_path)
        Tempfile.should_receive(:open).with([ 'knife-edit-', '.json' ]).and_yield(@mock)
      end
      context "and the editor works" do
        before do
          @ui.should_receive(:system).with("#{my_editor} #{temp_path}").and_return(true)
          IO.should_receive(:read).with(temp_path).and_return(json_from_editor)
        end

        context "when parse_output is false" do
          it "returns an edited pretty json string" do
            expect(subject).to eql(json_from_editor)
          end
        end
        context "when parse_output is true" do
          let(:parse_output) { true }
          it "returns an edited ruby object" do
            expect(subject).to eql(ruby_from_editor)
          end
        end
      end
      context "when running the editor fails with nil" do
        before do
          @ui.should_receive(:system).with("#{my_editor} #{temp_path}").and_return(nil)
          IO.should_not_receive(:read)
        end
        it "throws an exception" do
          expect{ subject }.to raise_error(RuntimeError)
        end
      end
      context "when running the editor fails with false" do
        before do
          @ui.should_receive(:system).with("#{my_editor} #{temp_path}").and_return(false)
          IO.should_not_receive(:read)
        end
        it "throws an exception" do
          expect{ subject }.to raise_error(RuntimeError)
        end
      end
    end
    context "when editing and not stubbing Tempfile (semi-functional test)" do
      before do
        @ui.config[:disable_editing] = false
        @ui.config[:editor] = my_editor
        @tempfile = Tempfile.new([ 'knife-edit-', '.json' ])
        Tempfile.should_receive(:open).with([ 'knife-edit-', '.json' ]).and_yield(@tempfile)
      end

      context "and the editor works" do
        before do
          @ui.should_receive(:system).with("#{my_editor} #{@tempfile.path}").and_return(true)
          IO.should_receive(:read).with(@tempfile.path).and_return(json_from_editor)
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
      @ui.format_list_for_display({ :marcy => :playground }).should == { :marcy => :playground }
    end

    it "should print only the keys if --with-uri is false" do
      @ui.config[:with_uri] = false
      @ui.format_list_for_display({ :marcy => :playground }).should == [ :marcy ]
    end
  end

  shared_examples "an output mehthod handling IO exceptions" do |method|
    it "should throw Errno::EIO exceptions" do
      @out.stub(:puts).and_raise(Errno::EIO)
      @err.stub(:puts).and_raise(Errno::EIO)
      lambda {@ui.send(method, "hi")}.should raise_error(Errno::EIO)
    end

    it "should ignore Errno::EPIPE exceptions (CHEF-3516)" do
      @out.stub(:puts).and_raise(Errno::EPIPE)
      @err.stub(:puts).and_raise(Errno::EPIPE)
      lambda {@ui.send(method, "hi")}.should raise_error(SystemExit)
    end

    it "should throw Errno::EPIPE exceptions with -VV (CHEF-3516)" do
      @config[:verbosity] = 2
      @out.stub(:puts).and_raise(Errno::EPIPE)
      @err.stub(:puts).and_raise(Errno::EPIPE)
      lambda {@ui.send(method, "hi")}.should raise_error(Errno::EPIPE)
    end
  end

  describe "output" do
    it_behaves_like "an output mehthod handling IO exceptions", :output

    it "formats strings appropriately" do
      @ui.output("hi")
      @out.string.should == "hi\n"
    end

    it "formats hashes appropriately" do
      @ui.output({'hi' => 'a', 'lo' => 'b' })
      @out.string.should == <<EOM
hi: a
lo: b
EOM
    end

    it "formats empty hashes appropriately" do
      @ui.output({})
      @out.string.should == "\n"
    end

    it "formats arrays appropriately" do
      @ui.output([ 'a', 'b' ])
      @out.string.should == <<EOM
a
b
EOM
    end

    it "formats empty arrays appropriately" do
      @ui.output([ ])
      @out.string.should == "\n"
    end

    it "formats single-member arrays appropriately" do
      @ui.output([ 'a' ])
      @out.string.should == "a\n"
    end

    it "formats nested single-member arrays appropriately" do
      @ui.output([ [ 'a' ] ])
      @out.string.should == "a\n"
    end

    it "formats nested arrays appropriately" do
      @ui.output([ [ 'a', 'b' ], [ 'c', 'd' ]])
      @out.string.should == <<EOM
a
b

c
d
EOM
    end

    it "formats nested arrays with single- and empty subarrays appropriately" do
      @ui.output([ [ 'a', 'b' ], [ 'c' ], [], [ 'd', 'e' ]])
      @out.string.should == <<EOM
a
b

c


d
e
EOM
    end

    it "formats arrays of hashes with extra lines in between for readability" do
      @ui.output([ { 'a' => 'b', 'c' => 'd' }, { 'x' => 'y' }, { 'm' => 'n', 'o' => 'p' }])
      @out.string.should == <<EOM
a: b
c: d

x: y

m: n
o: p
EOM
    end

    it "formats hashes with empty array members appropriately" do
      @ui.output({ 'a' => [], 'b' => 'c' })
      @out.string.should == <<EOM
a:
b: c
EOM
    end

    it "formats hashes with single-member array values appropriately" do
      @ui.output({ 'a' => [ 'foo' ], 'b' => 'c' })
      @out.string.should == <<EOM
a: foo
b: c
EOM
    end

    it "formats hashes with array members appropriately" do
      @ui.output({ 'a' => [ 'foo', 'bar' ], 'b' => 'c' })
      @out.string.should == <<EOM
a:
  foo
  bar
b: c
EOM
    end

    it "formats hashes with single-member nested array values appropriately" do
      @ui.output({ 'a' => [ [ 'foo' ] ], 'b' => 'c' })
      @out.string.should == <<EOM
a:
  foo
b: c
EOM
    end

    it "formats hashes with nested array values appropriately" do
      @ui.output({ 'a' => [ [ 'foo', 'bar' ], [ 'baz', 'bjork' ] ], 'b' => 'c' })
      # XXX: using a HEREDOC at this point results in a line with required spaces which auto-whitespace removal settings
      # on editors will remove and will break this test.
      @out.string.should == "a:\n  foo\n  bar\n  \n  baz\n  bjork\nb: c\n"
    end

    it "formats hashes with hash values appropriately" do
      @ui.output({ 'a' => { 'aa' => 'bb', 'cc' => 'dd' }, 'b' => 'c' })
      @out.string.should == <<EOM
a:
  aa: bb
  cc: dd
b: c
EOM
    end

    it "formats hashes with empty hash values appropriately" do
      @ui.output({ 'a' => { }, 'b' => 'c' })
      @out.string.should == <<EOM
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
      input = { :gi => :go }
      @ui.format_for_display(input).should == input
    end

    describe "with --attribute passed" do
      it "should return the deeply nested attribute" do
        input = { "gi" => { "go" => "ge" }, "id" => "sample-data-bag-item" }
        @ui.config[:attribute] = "gi.go"
        @ui.format_for_display(input).should == { "sample-data-bag-item" => { "gi.go" => "ge" } }
      end

      it "should return multiple attributes" do
        input = { "gi" =>  "go", "hi" => "ho", "id" => "sample-data-bag-item" }
        @ui.config[:attribute] = ["gi", "hi"]
        @ui.format_for_display(input).should == { "sample-data-bag-item" => { "gi" => "go", "hi"=> "ho" } }
      end
    end

    describe "with --run-list passed" do
      it "should return the run list" do
        input = Chef::Node.new
        input.name("sample-node")
        input.run_list("role[monkey]", "role[churchmouse]")
        @ui.config[:run_list] = true
        response = @ui.format_for_display(input)
        response["sample-node"]["run_list"][0].should == "role[monkey]"
        response["sample-node"]["run_list"][1].should == "role[churchmouse]"
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
            { "version" => "1.0.0", "url" => "http://url/cookbooks/1.0.0" }
          ]
        }
      }
    end

    it "should return an array of the cookbooks with versions" do
      expected_response = [ "cookbook_name   3.0.0  2.0.0  1.0.0" ]
      response = @ui.format_cookbook_list_for_display(@item)
      response.should == expected_response
    end

    describe "with --with-uri" do
      it "should return the URIs" do
        response = {
          "cookbook_name"=>{
            "1.0.0" => "http://url/cookbooks/1.0.0",
            "2.0.0" => "http://url/cookbooks/2.0.0",
            "3.0.0" => "http://url/cookbooks/3.0.0"}
        }
        @ui.config[:with_uri] = true
        @ui.format_cookbook_list_for_display(@item).should == response
      end
    end

    context "when running on Windows" do
      before(:each) do
        stdout = double('StringIO', :tty? => true)
        @ui.stub(:stdout).and_return(stdout)
        Chef::Platform.stub(:windows?) { true }
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

  describe "confirm" do
    let(:stdout) {StringIO.new}
    let(:output) {stdout.string}

    let(:question) { "monkeys rule" }
    let(:answer) { 'y' }

    let(:default_choice) { nil }
    let(:append_instructions) { true }

    def run_confirm
      @ui.stub(:stdout).and_return(stdout)
      @ui.stdin.stub(:readline).and_return(answer)
      @ui.confirm(question, append_instructions, default_choice)
    end

    def run_confirm_without_exit
      @ui.stub(:stdout).and_return(stdout)
      @ui.stdin.stub(:readline).and_return(answer)
      @ui.confirm_without_exit(question, append_instructions, default_choice)
    end

    shared_examples_for "confirm with positive answer" do
      it "confirm should return true" do
        run_confirm.should be_true
      end

      it "confirm_without_exit should return true" do
        run_confirm_without_exit.should be_true
      end
    end

    shared_examples_for "confirm with negative answer" do
      it "confirm should exit 3" do
        lambda {
          run_confirm
        }.should raise_error(SystemExit) { |e| e.status.should == 3 }
      end

      it "confirm_without_exit should return false" do
        run_confirm_without_exit.should be_false
      end
    end

    describe "with default choice set to true" do
      let(:default_choice) { true }

      it "should show 'Y/n' in the instructions" do
        run_confirm
        output.should include("Y/n")
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
        output.should include("y/N")
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

    ["Y", "y"].each do |answer|
      describe "with answer #{answer}" do
        let(:answer) { answer }

        it_behaves_like "confirm with positive answer"
      end
    end

    ["N", "n"].each do |answer|
      describe "with answer #{answer}" do
        let(:answer) { answer }

        it_behaves_like "confirm with negative answer"
      end
    end

    describe "with --y or --yes passed" do
      it "should return true" do
        @ui.config[:yes] = true
        run_confirm.should be_true
        output.should eq("")
      end
    end
  end

  describe "when asking for free-form user input" do
    it "asks a question and returns the answer provided by the user" do
      out = StringIO.new
      @ui.stub(:stdout).and_return(out)
      @ui.stub(:stdin).and_return(StringIO.new("http://mychefserver.example.com\n"))
      @ui.ask_question("your chef server URL?").should == "http://mychefserver.example.com"
      out.string.should == "your chef server URL?"
    end

    it "suggests a default setting and returns the default when the user's response only contains whitespace" do
      out = StringIO.new
      @ui.stub(:stdout).and_return(out)
      @ui.stub(:stdin).and_return(StringIO.new(" \n"))
      @ui.ask_question("your chef server URL? ", :default => 'http://localhost:4000').should == "http://localhost:4000"
      out.string.should == "your chef server URL? [http://localhost:4000] "
    end
  end

end
