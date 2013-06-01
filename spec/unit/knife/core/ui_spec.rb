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
    @config = {}
    @ui = Chef::Knife::UI.new(@out, @err, @in, @config)
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
      lambda {@ui.send(method, "hi")}.should_not raise_error(Errno::EPIPE)
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
      @out.string.should == <<EOM
a:
  foo
  bar
  
  baz
  bjork
b: c
EOM
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
  end

  describe "confirm" do
    before(:each) do
      @question = "monkeys rule"
      @stdout = StringIO.new
      @ui.stub(:stdout).and_return(@stdout)
      @ui.stdin.stub!(:readline).and_return("y")
    end

    it "should return true if you answer Y" do
      @ui.stdin.stub!(:readline).and_return("Y")
      @ui.confirm(@question).should == true
    end

    it "should return true if you answer y" do
      @ui.stdin.stub!(:readline).and_return("y")
      @ui.confirm(@question).should == true
    end

    it "should exit 3 if you answer N" do
      @ui.stdin.stub!(:readline).and_return("N")
      lambda {
        @ui.confirm(@question)
      }.should raise_error(SystemExit) { |e| e.status.should == 3 }
    end

    it "should exit 3 if you answer n" do
      @ui.stdin.stub!(:readline).and_return("n")
      lambda {
        @ui.confirm(@question)
      }.should raise_error(SystemExit) { |e| e.status.should == 3 }
    end

    describe "with --y or --yes passed" do
      it "should return true" do
        @ui.config[:yes] = true
        @ui.confirm(@question).should == true
      end
    end

    describe "when asking for free-form user input" do
      it "asks a question and returns the answer provided by the user" do
        out = StringIO.new
        @ui.stub!(:stdout).and_return(out)
        @ui.stub!(:stdin).and_return(StringIO.new("http://mychefserver.example.com\n"))
        @ui.ask_question("your chef server URL?").should == "http://mychefserver.example.com"
        out.string.should == "your chef server URL?"
      end

      it "suggests a default setting and returns the default when the user's response only contains whitespace" do
        out = StringIO.new
        @ui.stub!(:stdout).and_return(out)
        @ui.stub!(:stdin).and_return(StringIO.new(" \n"))
        @ui.ask_question("your chef server URL? ", :default => 'http://localhost:4000').should == "http://localhost:4000"
        out.string.should == "your chef server URL? [http://localhost:4000] "
      end
    end

  end
end
