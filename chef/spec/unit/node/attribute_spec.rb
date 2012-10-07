#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: AJ Christensen (<aj@opscode.com>)
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
require 'chef/node/attribute'

describe Chef::Node::Attribute do 
  before(:each) do
    @attribute_hash = 
      {"dmi"=>{},
        "command"=>{"ps"=>"ps -ef"},
        "platform_version"=>"10.5.7",
        "platform"=>"mac_os_x",
        "ipaddress"=>"192.168.0.117",
        "network"=>
    {"default_interface"=>"en1",
      "interfaces"=>
    {"vmnet1"=>
      {"flags"=>
        ["UP", "BROADCAST", "SMART", "RUNNING", "SIMPLEX", "MULTICAST"],
          "number"=>"1",
          "addresses"=>
        {"00:50:56:c0:00:01"=>{"family"=>"lladdr"},
          "192.168.110.1"=>
        {"broadcast"=>"192.168.110.255",
          "netmask"=>"255.255.255.0",
          "family"=>"inet"}},
          "mtu"=>"1500",
          "type"=>"vmnet",
          "arp"=>{"192.168.110.255"=>"ff:ff:ff:ff:ff:ff"},
          "encapsulation"=>"Ethernet"},
          "stf0"=>
        {"flags"=>[],
          "number"=>"0",
          "addresses"=>{},
          "mtu"=>"1280",
          "type"=>"stf",
          "encapsulation"=>"6to4"},
          "lo0"=>
        {"flags"=>["UP", "LOOPBACK", "RUNNING", "MULTICAST"],
          "number"=>"0",
          "addresses"=>
        {"::1"=>{"scope"=>"Node", "prefixlen"=>"128", "family"=>"inet6"},
          "127.0.0.1"=>{"netmask"=>"255.0.0.0", "family"=>"inet"},
          "fe80::1"=>{"scope"=>"Link", "prefixlen"=>"64", "family"=>"inet6"}},
          "mtu"=>"16384",
          "type"=>"lo",
          "encapsulation"=>"Loopback"},
          "gif0"=>
        {"flags"=>["POINTOPOINT", "MULTICAST"],
          "number"=>"0",
          "addresses"=>{},
          "mtu"=>"1280",
          "type"=>"gif",
          "encapsulation"=>"IPIP"},
          "vmnet8"=>
        {"flags"=>
          ["UP", "BROADCAST", "SMART", "RUNNING", "SIMPLEX", "MULTICAST"],
            "number"=>"8",
            "addresses"=>
          {"192.168.4.1"=>
            {"broadcast"=>"192.168.4.255",
              "netmask"=>"255.255.255.0",
              "family"=>"inet"},
              "00:50:56:c0:00:08"=>{"family"=>"lladdr"}},
              "mtu"=>"1500",
              "type"=>"vmnet",
              "arp"=>{"192.168.4.255"=>"ff:ff:ff:ff:ff:ff"},
              "encapsulation"=>"Ethernet"},
              "en0"=>
            {"status"=>"inactive",
              "flags"=>
            ["UP", "BROADCAST", "SMART", "RUNNING", "SIMPLEX", "MULTICAST"],
              "number"=>"0",
              "addresses"=>{"00:23:32:b0:32:f2"=>{"family"=>"lladdr"}},
              "mtu"=>"1500",
              "media"=>
            {"supported"=>
              {"autoselect"=>{"options"=>[]},
                "none"=>{"options"=>[]},
                "1000baseT"=>
              {"options"=>["full-duplex", "flow-control", "hw-loopback"]},
                "10baseT/UTP"=>
              {"options"=>
                ["half-duplex", "full-duplex", "flow-control", "hw-loopback"]},
                  "100baseTX"=>
                {"options"=>
                  ["half-duplex", "full-duplex", "flow-control", "hw-loopback"]}},
                    "selected"=>{"autoselect"=>{"options"=>[]}}},
                    "type"=>"en",
                    "encapsulation"=>"Ethernet"},
                    "en1"=>
                  {"status"=>"active",
                    "flags"=>
                  ["UP", "BROADCAST", "SMART", "RUNNING", "SIMPLEX", "MULTICAST"],
                    "number"=>"1",
                    "addresses"=>
                  {"fe80::223:6cff:fe7f:676c"=>
                    {"scope"=>"Link", "prefixlen"=>"64", "family"=>"inet6"},
                      "00:23:6c:7f:67:6c"=>{"family"=>"lladdr"},
                      "192.168.0.117"=>
                    {"broadcast"=>"192.168.0.255",
                      "netmask"=>"255.255.255.0",
                      "family"=>"inet"}},
                      "mtu"=>"1500",
                      "media"=>
                    {"supported"=>{"autoselect"=>{"options"=>[]}},
                      "selected"=>{"autoselect"=>{"options"=>[]}}},
                      "type"=>"en",
                      "arp"=>
                    {"192.168.0.72"=>"0:f:ea:39:fa:d5",
                      "192.168.0.1"=>"0:1c:fb:fc:6f:20",
                      "192.168.0.255"=>"ff:ff:ff:ff:ff:ff",
                      "192.168.0.3"=>"0:1f:33:ea:26:9b",
                      "192.168.0.77"=>"0:23:12:70:f8:cf",
                      "192.168.0.152"=>"0:26:8:7d:2:4c"},
                      "encapsulation"=>"Ethernet"},
                      "en2"=>
                    {"status"=>"active",
                      "flags"=>
                    ["UP", "BROADCAST", "SMART", "RUNNING", "SIMPLEX", "MULTICAST"],
                      "number"=>"2",
                      "addresses"=>
                    {"169.254.206.152"=>
                      {"broadcast"=>"169.254.255.255",
                        "netmask"=>"255.255.0.0",
                        "family"=>"inet"},
                        "00:1c:42:00:00:01"=>{"family"=>"lladdr"},
                        "fe80::21c:42ff:fe00:1"=>
                      {"scope"=>"Link", "prefixlen"=>"64", "family"=>"inet6"}},
                        "mtu"=>"1500",
                        "media"=>
                      {"supported"=>{"autoselect"=>{"options"=>[]}},
                        "selected"=>{"autoselect"=>{"options"=>[]}}},
                        "type"=>"en",
                        "encapsulation"=>"Ethernet"},
                        "fw0"=>
                      {"status"=>"inactive",
                        "flags"=>["BROADCAST", "SIMPLEX", "MULTICAST"],
                        "number"=>"0",
                        "addresses"=>{"00:23:32:ff:fe:b0:32:f2"=>{"family"=>"lladdr"}},
                        "mtu"=>"4078",
                        "media"=>
                      {"supported"=>{"autoselect"=>{"options"=>["full-duplex"]}},
                        "selected"=>{"autoselect"=>{"options"=>["full-duplex"]}}},
                        "type"=>"fw",
                        "encapsulation"=>"1394"},
                        "en3"=>
                      {"status"=>"active",
                        "flags"=>
                      ["UP", "BROADCAST", "SMART", "RUNNING", "SIMPLEX", "MULTICAST"],
                        "number"=>"3",
                        "addresses"=>
                      {"169.254.206.152"=>
                        {"broadcast"=>"169.254.255.255",
                          "netmask"=>"255.255.0.0",
                          "family"=>"inet"},
                          "00:1c:42:00:00:00"=>{"family"=>"lladdr"},
                          "fe80::21c:42ff:fe00:0"=>
                        {"scope"=>"Link", "prefixlen"=>"64", "family"=>"inet6"}},
                          "mtu"=>"1500",
                          "media"=>
                        {"supported"=>{"autoselect"=>{"options"=>[]}},
                          "selected"=>{"autoselect"=>{"options"=>[]}}},
                          "type"=>"en",
                          "encapsulation"=>"Ethernet"}}},
                          "fqdn"=>"latte.local",
                          "ohai_time"=>1249065590.90391,
                          "domain"=>"local",
                          "os"=>"darwin",
                          "platform_build"=>"9J61",
                          "os_version"=>"9.7.0",
                          "hostname"=>"latte",
                          "macaddress"=>"00:23:6c:7f:67:6c",
                          "music" => { "jimmy_eat_world" => "nice", "apophis" => false }
    }
    @default_hash = {
      "domain" => "opscode.com",
      "hot" => { "day" => "saturday" },
      "music" => { 
        "jimmy_eat_world" => "is fun!",
        "mastodon" => "rocks",
        "mars_volta" => "is loud and nutty",
        "deeper" => { "gates_of_ishtar" => nil },
        "this" => {"apparatus" => {"must" => "be unearthed"}}
      }
    }
    @override_hash = {
      "macaddress" => "00:00:00:00:00:00",
      "hot" => { "day" => "sunday" },
      "fire" => "still burn",
      "music" => {
        "mars_volta" => "cicatriz"
      }
    }
    @automatic_hash = {"week" => "friday"}
    @attributes = Chef::Node::Attribute.new(@attribute_hash, @default_hash, @override_hash, @automatic_hash)
  end

  describe "initialize" do
    it "should return a Chef::Node::Attribute" do
      @attributes.should be_a_kind_of(Chef::Node::Attribute)
    end

    it "should take an Automatioc, Normal, Default and Override hash" do
      lambda { Chef::Node::Attribute.new({}, {}, {}, {}) }.should_not raise_error
    end

    [ :normal, :default, :override, :automatic ].each do |accessor|
      it "should set #{accessor}" do
        na = Chef::Node::Attribute.new({ :normal => true }, { :default => true }, { :override => true }, { :automatic => true })
        na.send(accessor).should == { accessor.to_s => true } 
      end
    end

    it "should be enumerable" do
      @attributes.should be_is_a(Enumerable)
    end
  end

  describe "[]" do
    it "should return override data if it exists" do
      @attributes["macaddress"].should == "00:00:00:00:00:00"
    end

    it "should return attribute data if it is not overridden" do
      @attributes["platform"].should == "mac_os_x"
    end

    it "should return data that doesn't have corresponding keys in every hash" do
      @attributes["command"]["ps"].should == "ps -ef"
    end

    it "should return default data if it is not overriden or in attribute data" do
      @attributes["music"]["mastodon"].should == "rocks"
    end

    it "should prefer the override data over an available default" do
      @attributes["music"]["mars_volta"].should == "cicatriz"
    end

    it "should prefer the attribute data over an available default" do
      @attributes["music"]["jimmy_eat_world"].should == "nice"
    end

    it "should prefer override data over default data if there is no attribute data" do
      @attributes["hot"]["day"].should == "sunday"
    end

    it "should return the merged hash if all three have values" do
      result = @attributes["music"]
      result["mars_volta"].should == "cicatriz"
      result["jimmy_eat_world"].should == "nice"
      result["mastodon"].should == "rocks"
    end
  end

  describe "[]=" do
    it "should error out when the type of attribute to set has not been specified" do
      @attributes.normal["the_ghost"] = {  }
      lambda { @attributes["the_ghost"]["exterminate"] = false }.should raise_error(Chef::ImmutableAttributeModification)
    end

    it "should let you set an attribute value when another hash has an intermediate value" do
      @attributes.normal["the_ghost"] = { "exterminate" => "the future" }
      lambda { @attributes.normal["the_ghost"]["exterminate"]["tomorrow"] = false }.should_not raise_error(NoMethodError)
    end

    it "should set the attribute value" do
      @attributes.normal["longboard"] = "surfing"
      @attributes.normal["longboard"].should == "surfing"
      @attributes.normal["longboard"].should == "surfing"
    end

    it "should set deeply nested attribute values when a precedence level is specified" do
      @attributes.normal["deftones"]["hunters"]["nap"] = "surfing"
      @attributes.normal["deftones"]["hunters"]["nap"].should == "surfing"
    end

    it "should die if you try and do nested attributes that do not exist without read vivification" do
      lambda { @attributes["foo"]["bar"] = :baz }.should raise_error
    end

    it "should let you set attributes manually without vivification" do
      @attributes.normal["foo"] = Mash.new
      @attributes.normal["foo"]["bar"] = :baz
      @attributes.normal["foo"]["bar"].should == :baz
    end

    it "should optionally skip setting the value if one already exists" do
      @attributes.set_unless_value_present = true
      @attributes.normal["hostname"] = "bar"
      @attributes["hostname"].should == "latte"
    end

    it "does not support ||= when setting" do
      # This is a limitation of auto-vivification.
      # Users who need this behavior can use set_unless and friends
      @attributes.normal["foo"] = Mash.new
      @attributes.normal["foo"]["bar"] ||= "stop the world"
      @attributes.normal["foo"]["bar"].should == {}
    end
  end

  describe "to_hash" do
    it "should convert to a hash" do
      @attributes.to_hash.class.should == Hash
    end

    it "should convert to a hash based on current state" do
      hash = @attributes["hot"].to_hash
      hash.class.should == Hash
      hash["day"].should == "sunday"
    end
  end

  describe "has_key?" do
    it "should return true if an attribute exists" do
      @attributes.has_key?("music").should == true
    end

    it "should return false if an attribute does not exist" do
      @attributes.has_key?("ninja").should == false
    end

    it "should return false if an attribute does not exist using dot notation" do
      @attributes.has_key?("does_not_exist_at_all").should == false
    end

    it "should return true if an attribute exists but is set to nil using dot notation" do
      @attributes.music.deeper.has_key?("gates_of_ishtar").should == true
    end

    it "should return true if an attribute exists but is set to false" do
      @attributes.has_key?("music")
      @attributes["music"].has_key?("apophis").should == true
    end

    it "does not find keys above the current nesting level" do
      @attributes["music"]["this"]["apparatus"].should_not have_key("this")
    end

    it "does not find keys below the current nesting level" do
      @attributes["music"]["this"].should_not have_key("must")
    end

    [:include?, :key?, :member?].each do |method|
      it "should alias the method #{method} to itself" do
        @attributes.should respond_to(method) 
      end

      it "#{method} should behave like has_key?" do
        @attributes.send(method, "music").should == true
      end
    end
  end

  describe "attribute?" do
    it "should return true if an attribute exists" do
      @attributes.attribute?("music").should == true
    end

    it "should return false if an attribute does not exist" do
      @attributes.attribute?("ninja").should == false
    end

  end

  describe "method_missing" do
    it "should behave like a [] lookup" do
      @attributes.music.mastodon.should == "rocks"
    end

    it "should allow the last method to set a value if it has an = sign on the end" do
      @attributes.normal.music.mastodon = [ "dream", "still", "shining" ]
      @attributes.reset
      @attributes.normal.music.mastodon.should == [ "dream", "still", "shining" ]
    end
  end

  describe "keys" do
    before(:each) do
      @attributes = Chef::Node::Attribute.new(
        {
          "one" =>  { "two" => "three" },
          "hut" =>  { "two" => "three" },
          "place" => { }
        },
        {
          "one" =>  { "four" => "five" },
          "snakes" => "on a plane"
        },
        {
          "one" =>  { "six" => "seven" },
          "snack" => "cookies"
        },
        {}
      )
    end

    it "should yield each top level key" do
      collect = Array.new
      @attributes.keys.each do |k|
        collect << k
      end
      collect.include?("one").should == true
      collect.include?("hut").should == true
      collect.include?("snakes").should == true
      collect.include?("snack").should == true
      collect.include?("place").should == true
      collect.length.should == 5 
    end

    it "should yield lower if we go deeper" do
      collect = Array.new
      @attributes.one.keys.each do |k|
        collect << k
      end
      collect.include?("two").should == true
      collect.include?("four").should == true
      collect.include?("six").should == true
      collect.length.should == 3 
    end

    it "should not raise an exception if one of the hashes has a nil value on a deep lookup" do
      lambda { @attributes.place.keys { |k| } }.should_not raise_error(NoMethodError)
    end
  end

  describe "each" do
    before(:each) do
      @attributes = Chef::Node::Attribute.new(
        {
          "one" =>  "two",
          "hut" =>  "three",
        },
        {
          "one" =>  "four",
          "snakes" => "on a plane"
        },
        {
          "one" => "six",
          "snack" => "cookies"
        },
        {}
      )
    end

    it "should yield each top level key and value, post merge rules" do
      collect = Hash.new
      @attributes.each do |k, v|
        collect[k] = v
      end

      collect["one"].should == "six"
      collect["hut"].should == "three"
      collect["snakes"].should == "on a plane"
      collect["snack"].should == "cookies"
    end

    it "should yield as a two-element array" do
      @attributes.each do |a|
        a.should be_an_instance_of(Array)
      end
    end
  end

  describe "each_key" do
    before do
      @attributes = Chef::Node::Attribute.new(
        {
          "one" =>  "two",
          "hut" =>  "three",
        },
        {
          "one" =>  "four",
          "snakes" => "on a plane"
        },
        {
          "one" => "six",
          "snack" => "cookies"
        },
        {}
      )
    end

    it "should respond to each_key" do
      @attributes.should respond_to(:each_key)
    end

    it "should yield each top level key, post merge rules" do
      collect = Array.new
      @attributes.each_key do |k|
        collect << k
      end
     
      collect.should include("one")
      collect.should include("snack")
      collect.should include("hut")
      collect.should include("snakes")
    end
  end

  describe "each_pair" do
    before do
      @attributes = Chef::Node::Attribute.new(
        {
          "one" =>  "two",
          "hut" =>  "three",
        },
        {
          "one" =>  "four",
          "snakes" => "on a plane"
        },
        {
          "one" => "six",
          "snack" => "cookies"
        },
        {}
      )
    end

    it "should respond to each_pair" do
      @attributes.should respond_to(:each_pair)
    end

    it "should yield each top level key and value pair, post merge rules" do
      collect = Hash.new
      @attributes.each_pair do |k, v|
        collect[k] = v
      end

      collect["one"].should == "six"
      collect["hut"].should == "three"
      collect["snakes"].should == "on a plane"
      collect["snack"].should == "cookies"
    end
  end
  
  describe "each_value" do
    before do
      @attributes = Chef::Node::Attribute.new(
        {
          "one" =>  "two",
          "hut" =>  "three",
        },
        {
          "one" =>  "four",
          "snakes" => "on a plane"
        },
        {
          "one" => "six",
          "snack" => "cookies"
        },
        {}
      )
    end

    it "should respond to each_value" do
      @attributes.should respond_to(:each_value)
    end

    it "should yield each value, post merge rules" do
      collect = Array.new
      @attributes.each_value do |v|
        collect << v
      end

      collect.should include("cookies")
      collect.should include("three")
      collect.should include("on a plane")
    end

    it "should yield four elements" do
      collect = Array.new
      @attributes.each_value do |v|
        collect << v
      end

      collect.length.should == 4
    end
  end

  describe "empty?" do
    before do
      @attributes = Chef::Node::Attribute.new(
        {
          "one" =>  "two",
          "hut" =>  "three",
        },
        {
          "one" =>  "four",
          "snakes" => "on a plane"
        },
        {
          "one" => "six",
          "snack" => "cookies"
        },
        {}
      )
      @empty = Chef::Node::Attribute.new({}, {}, {}, {})
    end

    it "should respond to empty?" do
      @attributes.should respond_to(:empty?)
    end

    it "should return true when there are no keys" do
      @empty.empty?.should == true
    end

    it "should return false when there are keys" do
      @attributes.empty?.should == false
    end

  end

  describe "fetch" do
    before do
      @attributes = Chef::Node::Attribute.new(
        {
          "one" =>  "two",
          "hut" =>  "three",
        },
        {
          "one" =>  "four",
          "snakes" => "on a plane"
        },
        {
          "one" => "six",
          "snack" => "cookies"
        },
        {}
      )
    end

    it "should respond to fetch" do
      @attributes.should respond_to(:fetch)
    end

    describe "when the key exists" do
      it "should return the value of the key, post merge (same result as each)" do
        {
          "one" => "six",
          "hut" => "three",
          "snakes" => "on a plane",
          "snack" => "cookies"
        }.each do |k,v|
          @attributes.fetch(k).should == v
        end
      end
    end

    describe "when the key does not exist" do
      describe "and no args are passed" do
        it "should raise an indexerror" do
          lambda { @attributes.fetch("lololol") }.should raise_error(IndexError)
        end
      end

      describe "and a default arg is passed" do
        it "should return the value of the default arg" do
          @attributes.fetch("lol", "blah").should == "blah"
        end
      end

      describe "and a block is passed" do
        it "should run the block and return its value" do
          @attributes.fetch("lol") { |x| "#{x}, blah" }.should == "lol, blah"
        end
      end
    end
  end

  describe "has_value?" do
    before do
      @attributes = Chef::Node::Attribute.new(
        {
          "one" =>  "two",
          "hut" =>  "three",
        },
        {
          "one" =>  "four",
          "snakes" => "on a plane"
        },
        {
          "one" => "six",
          "snack" => "cookies"
        },
        {}
      )
    end

    it "should respond to has_value?" do
      @attributes.should respond_to(:has_value?)
    end

    it "should return true if any key has the value supplied" do
      @attributes.has_value?("cookies").should == true
    end

    it "should return false no key has the value supplied" do
      @attributes.has_value?("lololol").should == false
    end

    it "should alias value?" do
      @attributes.should respond_to(:value?)
    end
  end

  describe "index" do
    before do
      @attributes = Chef::Node::Attribute.new(
        {
          "one" =>  "two",
          "hut" =>  "three",
        },
        {
          "one" =>  "four",
          "snakes" => "on a plane"
        },
        {
          "one" => "six",
          "snack" => "cookies"
        },
        {}
      )
    end

    it "should respond to index" do
      @attributes.should respond_to(:index)
    end

    describe "when the value is indexed" do
      it "should return the index" do
        @attributes.index("six").should == "one"
      end
    end

    describe "when the value is not indexed" do
      it "should return nil" do
        @attributes.index("lolol").should == nil
      end
    end

  end


  describe "values" do
    before do
      @attributes = Chef::Node::Attribute.new(
        {
          "one" =>  "two",
          "hut" =>  "three",
        },
        {
          "one" =>  "four",
          "snakes" => "on a plane"
        },
        {
          "one" => "six",
          "snack" => "cookies"
        },
        {}
      )
    end

    it "should respond to values" do
      @attributes.should respond_to(:values)
    end

    it "should return an array of values" do
      @attributes.values.length.should == 4
    end

    it "should match the values output from each" do
      @attributes.values.should include("six")
      @attributes.values.should include("cookies")
      @attributes.values.should include("three")
      @attributes.values.should include("on a plane")
    end

  end

  describe "select" do
    before do
      @attributes = Chef::Node::Attribute.new(
        {
          "one" =>  "two",
          "hut" =>  "three",
        },
        {
          "one" =>  "four",
          "snakes" => "on a plane"
        },
        {
          "one" => "six",
          "snack" => "cookies"
        },
        {}
      )
    end

    it "should respond to select" do
      @attributes.should respond_to(:select)
    end

    if RUBY_VERSION >= "1.8.7"
      it "should not raise a LocalJumpError if no block is given" do
        lambda { @attributes.select }.should_not raise_error(LocalJumpError)
      end
    else
      it "should raise a LocalJumpError if no block is given" do
        lambda{ @attributes.select }.should raise_error(LocalJumpError)
      end
    end

    it "should return an empty hash/array (ruby-version-dependent) for a block containing nil" do
      @attributes.select { nil }.should == {}.select { nil }
    end

    # sorted for spec clarity
    it "should return a new array of k,v pairs for which the block returns true" do
      @attributes.select { true }.sort.should == (
        [
          ["hut", "three"],
          ["one", "six"],
          ["snack", "cookies"],
          ["snakes", "on a plane"]
        ]
      )
    end
  end

  describe "size" do
    before do
      @attributes = Chef::Node::Attribute.new(
        {
          "one" =>  "two",
          "hut" =>  "three",
        },
        {
          "one" =>  "four",
          "snakes" => "on a plane"
        },
        {
          "one" => "six",
          "snack" => "cookies"
        },
        {}
      )

      @empty = Chef::Node::Attribute.new({},{},{},{})
    end

    it "should respond to size" do
      @attributes.should respond_to(:size)
    end

    it "should alias length to size" do
      @attributes.should respond_to(:length)
    end

    it "should return 0 for an empty attribute" do
      @empty.size.should == 0
    end

    it "should return the number of pairs" do
      @attributes.size.should == 4
    end
  end

  describe "kind_of?" do
    it "should falsely inform you that it is a Hash" do
      @attributes.should be_a_kind_of(Hash)
    end

    it "should falsely inform you that it is a Mash" do
      @attributes.should be_a_kind_of(Mash)
    end

    it "should inform you that it is a Chef::Node::Attribute" do
      @attributes.should be_a_kind_of(Chef::Node::Attribute)
    end

    it "should inform you that it is anything else" do
      @attributes.should_not be_a_kind_of(Chef::Node)
    end
  end

  describe "inspect" do
    it "should be readable" do
      # NOTE: previous implementation hid the values, showing @automatic={...}
      # That is nice and compact, but hides a lot of info, which seems counter
      # to the point of calling #inspect...
      @attributes.inspect.should =~ /@automatic=\{.*\}/
      @attributes.inspect.should =~ /@normal=\{.*\}/
    end
  end

  # For expedience, this test is implementation-heavy.
  describe "when a component attribute is mutated" do
      [
        :clear,
        :shift
      ].each do |mutator|
        it "resets the cache when the mutator #{mutator} is called" do
          @attributes.should_receive(:reset_cache)
          @attributes.default.send(mutator)
        end
      end

      it "resets the cache when the mutator delete is called" do
        @attributes.should_receive(:reset_cache)
        @attributes.default.delete(:music)
      end

      [
        :merge,
        :update,
        :replace
      ].each do |mutator|
        it "resets the cache when the mutator #{mutator} is called" do
          # Implementation of Mash means that this could get called many times. That's okay.
          @attributes.should_receive(:reset_cache).at_least(1).times
          @attributes.default.send(mutator, {:foo => :bar})
        end
      end

      [
        :delete_if,
        :keep_if,
        :reject!,
        :select!,
      ].each do |mutator|
        it "resets the cache when the mutator #{mutator} is called" do
          # Implementation of Mash means that this could get called many times. That's okay.
          @attributes.should_receive(:reset_cache)
          block = lambda {|k,v| true }
          @attributes.default.send(mutator, &block)
        end
      end

  end


  describe "TODO - new behaviors or tests" do
    it "makes values read only for reading" do
      @attributes.reset
      lambda { @attributes[:new_key] = "new value" }.should raise_error(Chef::ImmutableAttributeModification)
    end

    it "detects reads from a no-longer-valid merged attributes sub-tree" do
      pending "write behavior and tests"
      # basic idea: merged attributes are given a freshly created object each
      # time they are generated. whenever the cache is invalidated, "something"
      # happens that indicates that the cache is no longer valid.
      # possible implementation is to increment a serial number on C::N::A,
      # and merged attributes know what their serial number is. Check the
      # serial number before reading.
    end

  end

end

describe Chef::ImmutableMash do
  before do
    @data_in = {:top => {:second_level => "some value"},
                "top_level_2" => %w[array of values],
                :top_level_3 => [{:hash_array => 1, :hash_array_b => 2}],
                :top_level_4 => {:level2 => {:key => "value"}}
    }
    @immutable_mash = Chef::ImmutableMash.new(@data_in)
  end

  it "element references like regular hash" do
    @immutable_mash[:top][:second_level].should == "some value"
  end

  it "elelment references like a regular Mash" do
    @immutable_mash[:top_level_2].should == %w[array of values]
  end

  it "converts Hash-like inputs into ImmutableMash's" do
    @immutable_mash[:top].should be_a(Chef::ImmutableMash)
  end

  it "converts array inputs into ImmutableArray's" do
    @immutable_mash[:top_level_2].should be_a(Chef::ImmutableArray)
  end

  it "converts arrays of hashes to ImmutableArray's of ImmutableMashes" do
    @immutable_mash[:top_level_3].first.should be_a(Chef::ImmutableMash)
  end

  it "converts nested hashes to ImmutableMashes" do
    @immutable_mash[:top_level_4].should be_a(Chef::ImmutableMash)
    @immutable_mash[:top_level_4][:level2].should be_a(Chef::ImmutableMash)
  end


  [
    :[]=,
    :clear,
    :default=,
    :default_proc=,
    :delete,
    :delete_if,
    :keep_if,
    :merge!,
    :update,
    :reject!,
    :replace,
    :select!,
    :shift
  ].each do |mutator|
    it "doesn't allow mutation via `#{mutator}'" do
      lambda { @immutable_mash.send(mutator) }.should raise_error(Chef::ImmutableAttributeModification)
    end
  end

  it "returns a mutable version of itself when duped" do
    mutable = @immutable_mash.dup
    mutable[:new_key] = :value
    mutable[:new_key].should == :value
  end

end

describe Chef::ImmutableArray do

  before do
    @immutable_array = Chef::ImmutableArray.new(%w[foo bar baz])
  end

  ##
  # Note: other behaviors, such as immutibilizing input data, are tested along
  # with ImmutableMash, above
  ###

  [
    :<<,
    :[]=,
    :clear,
    :collect!,
    :compact!,
    :default=,
    :default_proc=,
    :delete,
    :delete_at,
    :delete_if,
    :fill,
    :flatten!,
    :insert,
    :keep_if,
    :map!,
    :merge!,
    :pop,
    :push,
    :update,
    :reject!,
    :reverse!,
    :replace,
    :select!,
    :shift,
    :slice!,
    :sort!,
    :sort_by!,
    :uniq!,
    :unshift
  ].each do |mutator|
    it "does not allow mutation via `#{mutator}" do
      lambda { @immutable_array.send(mutator)}.should raise_error(Chef::ImmutableAttributeModification)
    end
  end

  it "returns a mutable version of itself when duped" do
    mutable = @immutable_array.dup
    mutable[0] = :value
    mutable[0].should == :value
  end
end

