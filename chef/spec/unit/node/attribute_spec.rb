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

require File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "spec_helper"))
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
                          "music" => { "jimmy_eat_world" => "nice" }
    }
  
    @default_hash = {
      "domain" => "opscode.com",
      "hot" => { "day" => "saturday" },
      "music" => { 
        "jimmy_eat_world" => "is fun!",
        "mastodon" => "rocks",
        "mars_volta" => "is loud and nutty"
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
    @attributes = Chef::Node::Attribute.new(@attribute_hash, @default_hash, @override_hash)
  end

  describe "initialize" do
    it "should return a Chef::Node::Attribute" do
      @attributes.should be_a_kind_of(Chef::Node::Attribute)
    end

    it "should take an Attribute, Default and Override hash" do
      lambda { Chef::Node::Attribute.new({}, {}, {}) }.should_not raise_error
    end

    [ :attribute, :default, :override ].each do |accessor|
      it "should set #{accessor}" do
        na = Chef::Node::Attribute.new({ :attribute => true }, { :default => true }, { :override => true })
        na.send(accessor).should == { accessor => true } 
      end
    end

    it "should set the state to an empty array" do
      @attributes.state.should == []
    end

    it "should allow you to set the initial state" do
      na = Chef::Node::Attribute.new({}, {}, {}, [ "first", "second", "third" ])
      na.state.should == [ "first", "second", "third" ]
    end
  end

  describe "hash_and_not_cna" do
    it "should return false if we pass it a Chef::Node::Attribute" do
      @attributes.hash_and_not_cna?(@attributes).should == false
    end

    it "should return true if we pass it something that responds to has_key?" do
      hashy = mock("Hashlike", :has_key? => true)
      @attributes.hash_and_not_cna?(hashy).should == true
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
      result["mars_volta"] = "cicatriz"
      result["jimmy_eat_world"] = "nice"
      result["mastodon"] = "rocks"
    end
  end

  describe "auto_vivifiy" do
    it "should set the hash key to a mash if it does not exist" do
      @attributes.auto_vivifiy({}, "one")["one"].should be_a_kind_of(Mash)
    end

    it "should raise an exception if the key does exist and does not respond to has_key?" do
      lambda { @attributes.auto_vivifiy({ "one" => "value" }) }.should raise_error(ArgumentError)
    end

    it "should not alter the value if the key exists and responds to has_key?" do
      @attributes.auto_vivifiy({ "one" => { "will" => true } }, "one")["one"].should have_key("will")
    end
  end

  describe "set_value" do
    it "should set the value for a top level key" do
      to_check = {}
      @attributes.set_value(to_check, "one", "some value")
      to_check["one"].should == "some value"
    end

    it "should set the value for a second level key" do
      to_check = {}
      @attributes.state = [ "one" ]
      @attributes.set_value(to_check, "two", "some value")
      to_check["one"]["two"].should == "some value"
    end

    it "should set the value for a very deep key" do
      to_check = {}
      @attributes.state = [ "one", "two", "three", "four", "five" ]
      @attributes.set_value(to_check, "six", "some value")
      to_check["one"]["two"]["three"]["four"]["five"]["six"].should == "some value"
    end
  end

  describe "[]=" do
    it "should set the attribute value" do
      @attributes["longboard"] = "surfing"
      @attributes["longboard"].should == "surfing"
      @attributes.attribute["longboard"].should == "surfing"
      @attributes.override["longboard"].should == "surfing"
    end

    it "should set deeply nested attribute value when auto_vivifiy_on_read is true" do
      @attributes.auto_vivifiy_on_read = true
      @attributes["longboard"]["hunters"]["comics"] = "surfing"
      @attributes["longboard"]["hunters"]["comics"].should == "surfing"
      @attributes.attribute["longboard"]["hunters"]["comics"].should == "surfing"
      @attributes.override["longboard"]["hunters"]["comics"].should == "surfing"
    end

    it "should die if you try and do nested attributes that do not exist without read vivification" do
      lambda { @attributes["foo"]["bar"] = :baz }.should raise_error
    end

    it "should let you set attributes manually without vivification" do
      @attributes["foo"] = Mash.new
      @attributes["foo"]["bar"] = :baz
      @attributes["foo"]["bar"].should == :baz
    end

    it "should optionally skip setting the value if one already exists" do
      @attributes.set_unless_value_present = true
      @attributes["hostname"] = "bar"
      @attributes["hostname"].should == "latte"
    end

    it "should optionally skip setting the value if a default already exists" do
      @attributes.set_unless_value_present = true
      @attributes["music"]["mastodon"] = "slays it"
      @attributes["music"]["mastodon"].should == "rocks"
    end

    it "should optionally skip setting the value if an attibute already exists" do
      @attributes.set_unless_value_present = true
      @attributes["network"]["default_interface"] = "wiz1"
      @attributes["network"]["default_interface"].should == "en1"
    end

    it "should optionally skip setting the value if an override already exists" do
      @attributes.set_unless_value_present = true
      @attributes["fire"] = "secret life"
      @attributes["fire"].should == "still burn"
    end
  end

  describe "get_value" do
    it "should get a value from a top level key" do
      @attributes.get_value(@default_hash, "domain").should == "opscode.com"
    end

    it "should return nil for a top level key that does not exist" do
      @attributes.get_value(@default_hash, "domainz").should == nil
    end

    it "should get a value based on the state of the object" do
      @attributes.auto_vivifiy_on_read = true
      @attributes[:foo][:bar][:baz] = "snack"
      @attributes.get_value(@attribute_hash, :baz).should == "snack"
    end

    it "should return nil based on the state of the object if the key does not exist" do
      @attributes.auto_vivifiy_on_read = true
      @attributes[:foo][:bar][:baz] = "snack"
      @attributes.get_value(@attribute_hash, :baznatch).should == nil
    end
  end

  describe "has_key?" do
    it "should return true if an attribute exists" do
      @attributes.has_key?("music").should == true
    end

    it "should return false if an attribute does not exist" do
      @attributes.has_key?("ninja").should == false
    end

    it "should be looking at the current position of the object" do
      @attributes["music"]
      @attributes.has_key?("mastodon").should == true 
      @attributes.has_key?("whitesnake").should == false
    end
  end

  describe "attribute?" do
    it "should return true if an attribute exists" do
      @attributes.attribute?("music").should == true
    end

    it "should return false if an attribute does not exist" do
      @attributes.attribute?("ninja").should == false
    end

    it "should be looking at the current position of the object" do
      @attributes["music"]
      @attributes.attribute?("mastodon").should == true 
      @attributes.attribute?("whitesnake").should == false
    end
  end

  describe "method_missing" do
    it "should behave like a [] lookup" do
      @attributes.music.mastodon.should == "rocks"
    end

    it "should behave like a []= lookup if the last method has an argument" do
      @attributes.music.mastodon(["dream", "still", "shining"])
      @attributes.reset
      @attributes.music.mastodon.should == ["dream", "still", "shining"]
    end
  end

  describe "each" do
    before(:each) do
      @attributes = Chef::Node::Attribute.new(
        {
          "one" =>  { "two" => "three" },
          "hut" =>  { "two" => "three" },
        },
        {
          "one" =>  { "four" => "five" },
          "snakes" => "on a plane"
        },
        {
          "one" =>  { "six" => "seven" },
          "snack" => "cookies"
        }
      )
    end

    it "should yield each top level key" do
      collect = Array.new
      @attributes.each do |k|
        collect << k
      end
      collect.include?("one").should == true
      collect.include?("hut").should == true
      collect.include?("snakes").should == true
      collect.include?("snack").should == true
      collect.length.should == 4
    end

    it "should yield lower if we go deeper" do
      collect = Array.new
      @attributes.one.each do |k|
        collect << k
      end
      collect.include?("two").should == true
      collect.include?("four").should == true
      collect.include?("six").should == true
      collect.length.should == 3 
    end
  end

  describe "each_attribute" do
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
        }
      )
    end

    it "should yield each top level key and value, post merge rules" do
      collect = Hash.new
      @attributes.each_attribute do |k, v|
        collect[k] = v
      end

      collect["one"].should == "six"
      collect["hut"].should == "three"
      collect["snakes"].should == "on a plane"
      collect["snack"].should == "cookies"
    end
  end

end
