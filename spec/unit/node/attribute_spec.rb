#
# Author:: Adam Jacob (<adam@chef.io>)
# Author:: AJ Christensen (<aj@chef.io>)
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

require "spec_helper"
require "chef/node/attribute"

describe Chef::Node::Attribute do
  let(:events) { instance_double(Chef::EventDispatch::Dispatcher) }
  let(:run_context) { instance_double(Chef::RunContext, events: events) }
  let(:node) { instance_double(Chef::Node, run_context: run_context) }
  before(:each) do
    allow(events).to receive(:attribute_changed)
    @attribute_hash =
      { "dmi" => {},
        "command" => { "ps" => "ps -ef" },
        "platform_version" => "10.5.7",
        "platform" => "mac_os_x",
        "ipaddress" => "192.168.0.117",
        "network" => { "default_interface" => "en1",
                       "interfaces" => { "vmnet1" => { "flags" => %w{UP BROADCAST SMART RUNNING SIMPLEX MULTICAST},
                                                       "number" => "1",
                                                       "addresses" => { "00:50:56:c0:00:01" => { "family" => "lladdr" },
                                                                        "192.168.110.1" => { "broadcast" => "192.168.110.255",
                                                                                             "netmask" => "255.255.255.0",
                                                                                             "family" => "inet" } },
                                                       "mtu" => "1500",
                                                       "type" => "vmnet",
                                                       "arp" => { "192.168.110.255" => "ff:ff:ff:ff:ff:ff" },
                                                       "encapsulation" => "Ethernet" },
                                         "stf0" => { "flags" => [],
                                                     "number" => "0",
                                                     "addresses" => {},
                                                     "mtu" => "1280",
                                                     "type" => "stf",
                                                     "encapsulation" => "6to4" },
                                         "lo0" => { "flags" => %w{UP LOOPBACK RUNNING MULTICAST},
                                                    "number" => "0",
                                                    "addresses" => { "::1" => { "scope" => "Node", "prefixlen" => "128", "family" => "inet6" },
                                                                     "127.0.0.1" => { "netmask" => "255.0.0.0", "family" => "inet" },
                                                                     "fe80::1" => { "scope" => "Link", "prefixlen" => "64", "family" => "inet6" } },
                                                    "mtu" => "16384",
                                                    "type" => "lo",
                                                    "encapsulation" => "Loopback" },
                                         "gif0" => { "flags" => %w{POINTOPOINT MULTICAST},
                                                     "number" => "0",
                                                     "addresses" => {},
                                                     "mtu" => "1280",
                                                     "type" => "gif",
                                                     "encapsulation" => "IPIP" },
                                         "vmnet8" => { "flags" => %w{UP BROADCAST SMART RUNNING SIMPLEX MULTICAST},
                                                       "number" => "8",
                                                       "addresses" => { "192.168.4.1" => { "broadcast" => "192.168.4.255",
                                                                                           "netmask" => "255.255.255.0",
                                                                                           "family" => "inet" },
                                                                        "00:50:56:c0:00:08" => { "family" => "lladdr" } },
                                                       "mtu" => "1500",
                                                       "type" => "vmnet",
                                                       "arp" => { "192.168.4.255" => "ff:ff:ff:ff:ff:ff" },
                                                       "encapsulation" => "Ethernet" },
                                         "en0" => { "status" => "inactive",
                                                    "flags" => %w{UP BROADCAST SMART RUNNING SIMPLEX MULTICAST},
                                                    "number" => "0",
                                                    "addresses" => { "00:23:32:b0:32:f2" => { "family" => "lladdr" } },
                                                    "mtu" => "1500",
                                                    "media" => { "supported" => { "autoselect" => { "options" => [] },
                                                                                  "none" => { "options" => [] },
                                                                                  "1000baseT" => { "options" => %w{full-duplex flow-control hw-loopback} },
                                                                                  "10baseT/UTP" => { "options" => %w{half-duplex full-duplex flow-control hw-loopback} },
                                                                                  "100baseTX" => { "options" => %w{half-duplex full-duplex flow-control hw-loopback} } },
                                                                 "selected" => { "autoselect" => { "options" => [] } } },
                                                    "type" => "en",
                                                    "encapsulation" => "Ethernet" },
                                         "en1" => { "status" => "active",
                                                    "flags" => %w{UP BROADCAST SMART RUNNING SIMPLEX MULTICAST},
                                                    "number" => "1",
                                                    "addresses" => { "fe80::223:6cff:fe7f:676c" => { "scope" => "Link", "prefixlen" => "64", "family" => "inet6" },
                                                                     "00:23:6c:7f:67:6c" => { "family" => "lladdr" },
                                                                     "192.168.0.117" => { "broadcast" => "192.168.0.255",
                                                                                          "netmask" => "255.255.255.0",
                                                                                          "family" => "inet" } },
                                                    "mtu" => "1500",
                                                    "media" => { "supported" => { "autoselect" => { "options" => [] } },
                                                                 "selected" => { "autoselect" => { "options" => [] } } },
                                                    "type" => "en",
                                                    "arp" => { "192.168.0.72" => "0:f:ea:39:fa:d5",
                                                               "192.168.0.1" => "0:1c:fb:fc:6f:20",
                                                               "192.168.0.255" => "ff:ff:ff:ff:ff:ff",
                                                               "192.168.0.3" => "0:1f:33:ea:26:9b",
                                                               "192.168.0.77" => "0:23:12:70:f8:cf",
                                                               "192.168.0.152" => "0:26:8:7d:2:4c" },
                                                    "encapsulation" => "Ethernet" },
                                         "en2" => { "status" => "active",
                                                    "flags" => %w{UP BROADCAST SMART RUNNING SIMPLEX MULTICAST},
                                                    "number" => "2",
                                                    "addresses" => { "169.254.206.152" => { "broadcast" => "169.254.255.255",
                                                                                            "netmask" => "255.255.0.0",
                                                                                            "family" => "inet" },
                                                                     "00:1c:42:00:00:01" => { "family" => "lladdr" },
                                                                     "fe80::21c:42ff:fe00:1" => { "scope" => "Link", "prefixlen" => "64", "family" => "inet6" } },
                                                    "mtu" => "1500",
                                                    "media" => { "supported" => { "autoselect" => { "options" => [] } },
                                                                 "selected" => { "autoselect" => { "options" => [] } } },
                                                    "type" => "en",
                                                    "encapsulation" => "Ethernet" },
                                         "fw0" => { "status" => "inactive",
                                                    "flags" => %w{BROADCAST SIMPLEX MULTICAST},
                                                    "number" => "0",
                                                    "addresses" => { "00:23:32:ff:fe:b0:32:f2" => { "family" => "lladdr" } },
                                                    "mtu" => "4078",
                                                    "media" => { "supported" => { "autoselect" => { "options" => ["full-duplex"] } },
                                                                 "selected" => { "autoselect" => { "options" => ["full-duplex"] } } },
                                                    "type" => "fw",
                                                    "encapsulation" => "1394" },
                                         "en3" => { "status" => "active",
                                                    "flags" => %w{UP BROADCAST SMART RUNNING SIMPLEX MULTICAST},
                                                    "number" => "3",
                                                    "addresses" => { "169.254.206.152" => { "broadcast" => "169.254.255.255",
                                                                                            "netmask" => "255.255.0.0",
                                                                                            "family" => "inet" },
                                                                     "00:1c:42:00:00:00" => { "family" => "lladdr" },
                                                                     "fe80::21c:42ff:fe00:0" => { "scope" => "Link", "prefixlen" => "64", "family" => "inet6" } },
                                                    "mtu" => "1500",
                                                    "media" => { "supported" => { "autoselect" => { "options" => [] } },
                                                                 "selected" => { "autoselect" => { "options" => [] } } },
                                                    "type" => "en",
                                                    "encapsulation" => "Ethernet" } } },
        "fqdn" => "latte.local",
        "ohai_time" => 1249065590.90391,
        "domain" => "local",
        "os" => "darwin",
        "platform_build" => "9J61",
        "os_version" => "9.7.0",
        "hostname" => "latte",
        "macaddress" => "00:23:6c:7f:67:6c",
        "music" => { "jimmy_eat_world" => "nice", "apophis" => false },
    }
    @default_hash = {
      "domain" => "opscode.com",
      "hot" => { "day" => "saturday" },
      "music" => {
        "jimmy_eat_world" => "is fun!",
        "mastodon" => "rocks",
        "mars_volta" => "is loud and nutty",
        "deeper" => { "gates_of_ishtar" => nil },
        "this" => { "apparatus" => { "must" => "be unearthed" } },
      },
    }
    @override_hash = {
      "macaddress" => "00:00:00:00:00:00",
      "hot" => { "day" => "sunday" },
      "fire" => "still burn",
      "music" => {
        "mars_volta" => "cicatriz",
      },
    }
    @automatic_hash = { "week" => "friday" }
    @attributes = Chef::Node::Attribute.new(@attribute_hash, @default_hash, @override_hash, @automatic_hash, node)
  end

  describe "initialize" do
    it "should return a Chef::Node::Attribute" do
      expect(@attributes).to be_a_kind_of(Chef::Node::Attribute)
    end

    it "should take an Automatic, Normal, Default and Override hash" do
      expect { Chef::Node::Attribute.new({}, {}, {}, {}) }.not_to raise_error
    end

    %i{normal default override automatic}.each do |accessor|
      it "should set #{accessor}" do
        na = Chef::Node::Attribute.new({ normal: true }, { default: true }, { override: true }, { automatic: true })
        expect(na.send(accessor)).to eq({ accessor.to_s => true })
      end
    end

    it "should be enumerable" do
      expect(@attributes).to be_is_a(Enumerable)
    end
  end

  describe "when printing attribute components" do

    it "does not cause a type error" do
      # See CHEF-3799; IO#puts implicitly calls #to_ary on its argument. This
      # is expected to raise a NoMethodError or return an Array. `to_ary` is
      # the "strict" conversion method that should only be implemented by
      # things that are truly Array-like, so NoMethodError is the right choice.
      # (cf. there is no Hash#to_ary).
      expect { @attributes.default.to_ary }.to raise_error(NoMethodError)
    end

  end

  describe "when debugging attributes" do
    it "gives the value at each level of precedence for a path spec" do
      @attributes.default[:foo][:bar] = "default"
      @attributes.env_default[:foo][:bar] = "env_default"
      @attributes.role_default[:foo][:bar] = "role_default"
      @attributes.force_default[:foo][:bar] = "force_default"
      @attributes.normal[:foo][:bar] = "normal"
      @attributes.override[:foo][:bar] = "override"
      @attributes.role_override[:foo][:bar] = "role_override"
      @attributes.env_override[:foo][:bar] = "env_override"
      @attributes.force_override[:foo][:bar] = "force_override"
      @attributes.automatic[:foo][:bar] = "automatic"

      expected = [
        %w{default default},
        %w{env_default env_default},
        %w{role_default role_default},
        %w{force_default force_default},
        %w{normal normal},
        %w{override override},
        %w{role_override role_override},
        %w{env_override env_override},
        %w{force_override force_override},
        %w{automatic automatic},
      ]
      expect(@attributes.debug_value(:foo, :bar)).to eq(expected)
    end

    it "works through arrays" do
      @attributes.default["foo"] = [ { "bar" => "baz" } ]

      expect(@attributes.debug_value(:foo, 0)).to eq(
        [
          ["default", { "bar" => "baz" }],
          ["env_default", :not_present],
          ["role_default", :not_present],
          ["force_default", :not_present],
          ["normal", :not_present],
          ["override", :not_present],
          ["role_override", :not_present],
          ["env_override", :not_present],
          ["force_override", :not_present],
          ["automatic", :not_present],
        ]
      )
    end
  end

  describe "when fetching values based on precedence" do
    before do
      @attributes.default["default"] = "cookbook default"
      @attributes.override["override"] = "cookbook override"
    end

    it "prefers 'forced default' over any other default" do
      @attributes.force_default["default"] = "force default"
      @attributes.role_default["default"] = "role default"
      @attributes.env_default["default"] = "environment default"
      expect(@attributes["default"]).to eq("force default")
    end

    it "prefers role_default over environment or cookbook default" do
      @attributes.role_default["default"] = "role default"
      @attributes.env_default["default"] = "environment default"
      expect(@attributes["default"]).to eq("role default")
    end

    it "prefers environment default over cookbook default" do
      @attributes.env_default["default"] = "environment default"
      expect(@attributes["default"]).to eq("environment default")
    end

    it "returns the cookbook default when no other default values are present" do
      expect(@attributes["default"]).to eq("cookbook default")
    end

    it "prefers 'forced overrides' over role or cookbook overrides" do
      @attributes.force_override["override"] = "force override"
      @attributes.env_override["override"] = "environment override"
      @attributes.role_override["override"] = "role override"
      expect(@attributes["override"]).to eq("force override")
    end

    it "prefers environment overrides over role or cookbook overrides" do
      @attributes.env_override["override"] = "environment override"
      @attributes.role_override["override"] = "role override"
      expect(@attributes["override"]).to eq("environment override")
    end

    it "prefers role overrides over cookbook overrides" do
      @attributes.role_override["override"] = "role override"
      expect(@attributes["override"]).to eq("role override")
    end

    it "returns cookbook overrides when no other overrides are present" do
      expect(@attributes["override"]).to eq("cookbook override")
    end

    it "merges arrays within the default precedence" do
      @attributes.role_default["array"] = %w{role}
      @attributes.env_default["array"] = %w{env}
      expect(@attributes["array"]).to eq(%w{env role})
    end

    it "merges arrays within the override precedence" do
      @attributes.role_override["array"] = %w{role}
      @attributes.env_override["array"] = %w{env}
      expect(@attributes["array"]).to eq(%w{role env})
    end

    it "does not merge arrays between default and normal" do
      @attributes.role_default["array"] = %w{role}
      @attributes.normal["array"] = %w{normal}
      expect(@attributes["array"]).to eq(%w{normal})
    end

    it "does not merge arrays between normal and override" do
      @attributes.normal["array"] = %w{normal}
      @attributes.role_override["array"] = %w{role}
      expect(@attributes["array"]).to eq(%w{role})
    end

    it "merges nested hashes between precedence levels" do
      @attributes = Chef::Node::Attribute.new({}, {}, {}, {})
      @attributes.env_default = { "a" => { "b" => { "default" => "default" } } }
      @attributes.normal = { "a" => { "b" => { "normal" => "normal" } } }
      @attributes.override = { "a" => { "override" => "role" } }
      @attributes.automatic = { "a" => { "automatic" => "auto" } }
      expect(@attributes["a"]).to eq({ "b" => { "default" => "default", "normal" => "normal" },
                                       "override" => "role",
                                       "automatic" => "auto" })
    end
  end

  describe "when reading combined default or override values" do
    before do
      @attributes.default["cd"] = "cookbook default"
      @attributes.role_default["rd"] = "role default"
      @attributes.env_default["ed"] = "env default"
      @attributes.default!["fd"] = "force default"
      @attributes.override["co"] = "cookbook override"
      @attributes.role_override["ro"] = "role override"
      @attributes.env_override["eo"] = "env override"
      @attributes.override!["fo"] = "force override"
    end

    it "merges all types of overrides into a combined override" do
      expect(@attributes.combined_override["co"]).to eq("cookbook override")
      expect(@attributes.combined_override["ro"]).to eq("role override")
      expect(@attributes.combined_override["eo"]).to eq("env override")
      expect(@attributes.combined_override["fo"]).to eq("force override")
    end

    it "merges all types of defaults into a combined default" do
      expect(@attributes.combined_default["cd"]).to eq("cookbook default")
      expect(@attributes.combined_default["rd"]).to eq("role default")
      expect(@attributes.combined_default["ed"]).to eq("env default")
      expect(@attributes.combined_default["fd"]).to eq("force default")
    end

  end

  describe "[]" do
    it "should return override data if it exists" do
      expect(@attributes["macaddress"]).to eq("00:00:00:00:00:00")
    end

    it "should return attribute data if it is not overridden" do
      expect(@attributes["platform"]).to eq("mac_os_x")
    end

    it "should return data that doesn't have corresponding keys in every hash" do
      expect(@attributes["command"]["ps"]).to eq("ps -ef")
    end

    it "should return default data if it is not overridden or in attribute data" do
      expect(@attributes["music"]["mastodon"]).to eq("rocks")
    end

    it "should prefer the override data over an available default" do
      expect(@attributes["music"]["mars_volta"]).to eq("cicatriz")
    end

    it "should prefer the attribute data over an available default" do
      expect(@attributes["music"]["jimmy_eat_world"]).to eq("nice")
    end

    it "should prefer override data over default data if there is no attribute data" do
      expect(@attributes["hot"]["day"]).to eq("sunday")
    end

    it "should return the merged hash if all three have values" do
      result = @attributes["music"]
      expect(result["mars_volta"]).to eq("cicatriz")
      expect(result["jimmy_eat_world"]).to eq("nice")
      expect(result["mastodon"]).to eq("rocks")
    end
  end

  describe "[]=" do
    it "should error out when the type of attribute to set has not been specified" do
      @attributes.normal["the_ghost"] = {}
      expect { @attributes["the_ghost"]["exterminate"] = false }.to raise_error(Chef::Exceptions::ImmutableAttributeModification)
    end

    it "should let you set an attribute value when another hash has an intermediate value" do
      @attributes.normal["the_ghost"] = { "exterminate" => "the future" }
      expect { @attributes.normal["the_ghost"]["eviscerate"]["tomorrow"] = false }.not_to raise_error
    end

    it "should set the attribute value" do
      @attributes.normal["longboard"] = "surfing"
      expect(@attributes.normal["longboard"]).to eq("surfing")
      expect(@attributes.normal["longboard"]).to eq("surfing")
    end

    it "should set deeply nested attribute values when a precedence level is specified" do
      @attributes.normal["deftones"]["hunters"]["nap"] = "surfing"
      expect(@attributes.normal["deftones"]["hunters"]["nap"]).to eq("surfing")
    end

    it "should die if you try and do nested attributes that do not exist without read vivification" do
      expect { @attributes["foo"]["bar"] = :baz }.to raise_error(NoMethodError)
    end

    it "should let you set attributes manually without vivification" do
      @attributes.normal["foo"] = Mash.new
      @attributes.normal["foo"]["bar"] = :baz
      expect(@attributes.normal["foo"]["bar"]).to eq(:baz)
    end

    it "does not support ||= when setting" do
      # This is a limitation of auto-vivification.
      # Users who need this behavior can use set_unless and friends
      @attributes.normal["foo"] = Mash.new
      @attributes.normal["foo"]["bar"] ||= "stop the world"
      expect(@attributes.normal["foo"]["bar"]).to eq({})
    end
  end

  describe "to_hash" do
    it "should convert to a hash" do
      expect(@attributes.to_hash.class).to eq(Hash)
    end

    it "should convert to a hash based on current state" do
      hash = @attributes["hot"].to_hash
      expect(hash.class).to eq(Hash)
      expect(hash["day"]).to eq("sunday")
    end

    it "should create a deep copy of the node attribute" do
      @attributes.default["foo"]["bar"]["baz"] = "fizz"
      hash = @attributes["foo"].to_hash
      expect(hash).to eql({ "bar" => { "baz" => "fizz" } })
      hash["bar"]["baz"] = "buzz"
      expect(hash).to eql({ "bar" => { "baz" => "buzz" } })
      expect(@attributes.default["foo"]).to eql({ "bar" => { "baz" => "fizz" } })
    end

    it "should create a deep copy of arrays in the node attribute" do
      @attributes.default["foo"]["bar"] = ["fizz"]
      hash = @attributes["foo"].to_hash
      expect(hash).to eql({ "bar" => [ "fizz" ] })
      hash["bar"].push("buzz")
      expect(hash).to eql({ "bar" => %w{fizz buzz} })
      expect(@attributes.default["foo"]).to eql({ "bar" => [ "fizz" ] })
    end

    it "mutating strings should not mutate the attributes in a hash" do
      @attributes.default["foo"]["bar"]["baz"] = "fizz"
      hash = @attributes["foo"].to_hash
      expect(hash).to eql({ "bar" => { "baz" => "fizz" } })
      hash["bar"]["baz"] << "buzz"
      expect(hash).to eql({ "bar" => { "baz" => "fizzbuzz" } })
      expect(@attributes.default["foo"]).to eql({ "bar" => { "baz" => "fizz" } })
    end

    it "mutating array elements should not mutate the attributes" do
      @attributes.default["foo"]["bar"] = [ "fizz" ]
      hash = @attributes["foo"].to_hash
      expect(hash).to eql({ "bar" => [ "fizz" ] })
      hash["bar"][0] << "buzz"
      expect(hash).to eql({ "bar" => [ "fizzbuzz" ] })
      expect(@attributes.default["foo"]).to eql({ "bar" => [ "fizz" ] })
    end
  end

  describe "dup" do
    it "array can be duped even if some elements can't" do
      @attributes.default[:foo] = %w{foo bar baz} + Array(1..3) + [nil, true, false, [ "el", 0, nil ] ]
      @attributes.default[:foo].dup
    end

    it "mutating strings should not mutate the attributes in a hash" do
      @attributes.default["foo"]["bar"]["baz"] = "fizz"
      hash = @attributes["foo"].dup
      expect(hash).to eql({ "bar" => { "baz" => "fizz" } })
      hash["bar"]["baz"] << "buzz"
      expect(hash).to eql({ "bar" => { "baz" => "fizzbuzz" } })
      expect(@attributes.default["foo"]).to eql({ "bar" => { "baz" => "fizz" } })
    end

    it "mutating array elements should not mutate the attributes" do
      @attributes.default["foo"]["bar"] = [ "fizz" ]
      hash = @attributes["foo"].dup
      expect(hash).to eql({ "bar" => [ "fizz" ] })
      hash["bar"][0] << "buzz"
      expect(hash).to eql({ "bar" => [ "fizzbuzz" ] })
      expect(@attributes.default["foo"]).to eql({ "bar" => [ "fizz" ] })
    end
  end

  describe "has_key?" do
    it "should return true if an attribute exists" do
      expect(@attributes.key?("music")).to eq(true)
    end

    it "should return false if an attribute does not exist" do
      expect(@attributes.key?("ninja")).to eq(false)
    end

    it "should return false if an attribute does not exist using dot notation" do
      expect(@attributes.key?("does_not_exist_at_all")).to eq(false)
    end

    it "should return true if an attribute exists but is set to false" do
      @attributes.key?("music")
      expect(@attributes["music"].key?("apophis")).to eq(true)
    end

    it "does not find keys above the current nesting level" do
      expect(@attributes["music"]["this"]["apparatus"]).not_to have_key("this")
    end

    it "does not find keys below the current nesting level" do
      expect(@attributes["music"]["this"]).not_to have_key("must")
    end

    %i{include? key? member?}.each do |method|
      it "should alias the method #{method} to itself" do
        expect(@attributes).to respond_to(method)
      end

      it "#{method} should behave like has_key?" do
        expect(@attributes.send(method, "music")).to eq(true)
      end
    end
  end

  describe "attribute?" do
    it "should return true if an attribute exists" do
      expect(@attributes.attribute?("music")).to eq(true)
    end

    it "should return false if an attribute does not exist" do
      expect(@attributes.attribute?("ninja")).to eq(false)
    end

  end

  describe "keys" do
    before(:each) do
      @attributes = Chef::Node::Attribute.new(
        {
          "one" => { "two" => "three" },
          "hut" => { "two" => "three" },
          "place" => {},
        },
        {
          "one" => { "four" => "five" },
          "snakes" => "on a plane",
        },
        {
          "one" => { "six" => "seven" },
          "snack" => "cookies",
        },
        {}
      )
    end

    it "should yield each top level key" do
      collect = []
      @attributes.each_key do |k|
        collect << k
      end
      expect(collect.include?("one")).to eq(true)
      expect(collect.include?("hut")).to eq(true)
      expect(collect.include?("snakes")).to eq(true)
      expect(collect.include?("snack")).to eq(true)
      expect(collect.include?("place")).to eq(true)
      expect(collect.length).to eq(5)
    end

    it "should yield lower if we go deeper" do
      collect = []
      @attributes["one"].each_key do |k|
        collect << k
      end
      expect(collect.include?("two")).to eq(true)
      expect(collect.include?("four")).to eq(true)
      expect(collect.include?("six")).to eq(true)
      expect(collect.length).to eq(3)
    end

    it "should not raise an exception if one of the hashes has a nil value on a deep lookup" do
      expect { @attributes["place"].keys { |k| } }.not_to raise_error
    end
  end

  describe "each" do
    before(:each) do
      @attributes = Chef::Node::Attribute.new(
        {
          "one" => "two",
          "hut" => "three",
        },
        {
          "one" => "four",
          "snakes" => "on a plane",
        },
        {
          "one" => "six",
          "snack" => "cookies",
        },
        {}
      )
    end

    it "should yield each top level key and value, post merge rules" do
      collect = {}
      @attributes.each do |k, v|
        collect[k] = v
      end

      expect(collect["one"]).to eq("six")
      expect(collect["hut"]).to eq("three")
      expect(collect["snakes"]).to eq("on a plane")
      expect(collect["snack"]).to eq("cookies")
    end

    it "should yield as a two-element array" do
      @attributes.each do |a|
        expect(a).to be_an_instance_of(Array)
      end
    end
  end

  describe "each_key" do
    before do
      @attributes = Chef::Node::Attribute.new(
        {
          "one" => "two",
          "hut" => "three",
        },
        {
          "one" => "four",
          "snakes" => "on a plane",
        },
        {
          "one" => "six",
          "snack" => "cookies",
        },
        {}
      )
    end

    it "should respond to each_key" do
      expect(@attributes).to respond_to(:each_key)
    end

    it "should yield each top level key, post merge rules" do
      collect = []
      @attributes.each_key do |k|
        collect << k
      end

      expect(collect).to include("one")
      expect(collect).to include("snack")
      expect(collect).to include("hut")
      expect(collect).to include("snakes")
    end
  end

  describe "each_pair" do
    before do
      @attributes = Chef::Node::Attribute.new(
        {
          "one" => "two",
          "hut" => "three",
        },
        {
          "one" => "four",
          "snakes" => "on a plane",
        },
        {
          "one" => "six",
          "snack" => "cookies",
        },
        {}
      )
    end

    it "should respond to each_pair" do
      expect(@attributes).to respond_to(:each_pair)
    end

    it "should yield each top level key and value pair, post merge rules" do
      collect = {}
      @attributes.each_pair do |k, v|
        collect[k] = v
      end

      expect(collect["one"]).to eq("six")
      expect(collect["hut"]).to eq("three")
      expect(collect["snakes"]).to eq("on a plane")
      expect(collect["snack"]).to eq("cookies")
    end
  end

  describe "each_value" do
    before do
      @attributes = Chef::Node::Attribute.new(
        {
          "one" => "two",
          "hut" => "three",
        },
        {
          "one" => "four",
          "snakes" => "on a plane",
        },
        {
          "one" => "six",
          "snack" => "cookies",
        },
        {}
      )
    end

    it "should respond to each_value" do
      expect(@attributes).to respond_to(:each_value)
    end

    it "should yield each value, post merge rules" do
      collect = []
      @attributes.each_value do |v|
        collect << v
      end

      expect(collect).to include("cookies")
      expect(collect).to include("three")
      expect(collect).to include("on a plane")
    end

    it "should yield four elements" do
      collect = []
      @attributes.each_value do |v|
        collect << v
      end

      expect(collect.length).to eq(4)
    end
  end

  describe "empty?" do
    before do
      @attributes = Chef::Node::Attribute.new(
        {
          "one" => "two",
          "hut" => "three",
        },
        {
          "one" => "four",
          "snakes" => "on a plane",
        },
        {
          "one" => "six",
          "snack" => "cookies",
        },
        {}
      )
      @empty = Chef::Node::Attribute.new({}, {}, {}, {})
    end

    it "should respond to empty?" do
      expect(@attributes).to respond_to(:empty?)
    end

    it "should return true when there are no keys" do
      expect(@empty.empty?).to eq(true)
    end

    it "should return false when there are keys" do
      expect(@attributes.empty?).to eq(false)
    end

  end

  describe "fetch" do
    before do
      @attributes = Chef::Node::Attribute.new(
        {
          "one" => "two",
          "hut" => "three",
        },
        {
          "one" => "four",
          "snakes" => "on a plane",
        },
        {
          "one" => "six",
          "snack" => "cookies",
        },
        {}
      )
    end

    it "should respond to fetch" do
      expect(@attributes).to respond_to(:fetch)
    end

    describe "when the key exists" do
      it "should return the value of the key, post merge (same result as each)" do
        {
          "one" => "six",
          "hut" => "three",
          "snakes" => "on a plane",
          "snack" => "cookies",
        }.each do |k, v|
          expect(@attributes.fetch(k)).to eq(v)
        end
      end
    end

    describe "when the key does not exist" do
      describe "and no args are passed" do
        it "should raise an indexerror" do
          expect { @attributes.fetch("lololol") }.to raise_error(IndexError)
        end
      end

      describe "and a default arg is passed" do
        it "should return the value of the default arg" do
          expect(@attributes.fetch("lol", "blah")).to eq("blah")
        end
      end

      describe "and a block is passed" do
        it "should run the block and return its value" do
          expect(@attributes.fetch("lol") { |x| "#{x}, blah" }).to eq("lol, blah")
        end
      end
    end
  end

  describe "has_value?" do
    before do
      @attributes = Chef::Node::Attribute.new(
        {
          "one" => "two",
          "hut" => "three",
        },
        {
          "one" => "four",
          "snakes" => "on a plane",
        },
        {
          "one" => "six",
          "snack" => "cookies",
        },
        {}
      )
    end

    it "should respond to has_value?" do
      expect(@attributes).to respond_to(:has_value?)
    end

    it "should return true if any key has the value supplied" do
      expect(@attributes.value?("cookies")).to eq(true)
    end

    it "should return false no key has the value supplied" do
      expect(@attributes.value?("lololol")).to eq(false)
    end

    it "should alias value?" do
      expect(@attributes).to respond_to(:value?)
    end
  end

  describe "index", ruby: "< 3.0.0" do
    # Hash#index is deprecated and triggers warnings.
    def silence
      old_verbose = $VERBOSE
      $VERBOSE = nil
      yield
    ensure
      $VERBOSE = old_verbose
    end

    before do
      @attributes = Chef::Node::Attribute.new(
        {
          "one" => "two",
          "hut" => "three",
        },
        {
          "one" => "four",
          "snakes" => "on a plane",
        },
        {
          "one" => "six",
          "snack" => "cookies",
        },
        {}
      )
    end

    it "should respond to index" do
      expect(@attributes).to respond_to(:index)
    end

    describe "when the value is indexed" do
      it "should return the index" do
        silence do
          expect(@attributes.index("six")).to eq("one")
        end
      end
    end

    describe "when the value is not indexed" do
      it "should return nil" do
        silence do
          expect(@attributes.index("lolol")).to eq(nil)
        end
      end
    end

  end

  describe "values" do
    before do
      @attributes = Chef::Node::Attribute.new(
        {
          "one" => "two",
          "hut" => "three",
        },
        {
          "one" => "four",
          "snakes" => "on a plane",
        },
        {
          "one" => "six",
          "snack" => "cookies",
        },
        {}
      )
    end

    it "should respond to values" do
      expect(@attributes).to respond_to(:values)
    end

    it "should return an array of values" do
      expect(@attributes.values.length).to eq(4)
    end

    it "should match the values output from each" do
      expect(@attributes.values).to include("six")
      expect(@attributes.values).to include("cookies")
      expect(@attributes.values).to include("three")
      expect(@attributes.values).to include("on a plane")
    end

  end

  describe "select" do
    before do
      @attributes = Chef::Node::Attribute.new(
        {
          "one" => "two",
          "hut" => "three",
        },
        {
          "one" => "four",
          "snakes" => "on a plane",
        },
        {
          "one" => "six",
          "snack" => "cookies",
        },
        {}
      )
    end

    it "should respond to select" do
      expect(@attributes).to respond_to(:select)
    end

    it "should not raise a LocalJumpError if no block is given" do
      expect { @attributes.select }.not_to raise_error
    end

    it "should return an empty hash/array (ruby-version-dependent) for a block containing nil" do
      expect(@attributes.select { nil }).to eq({}.select { nil })
    end

    # sorted for spec clarity
    it "should return a new array of k,v pairs for which the block returns true" do
      expect(@attributes.select { true }.sort).to eq(
        [
          %w{hut three},
          %w{one six},
          %w{snack cookies},
          ["snakes", "on a plane"],
        ]
      )
    end
  end

  describe "size" do
    before do
      @attributes = Chef::Node::Attribute.new(
        {
          "one" => "two",
          "hut" => "three",
        },
        {
          "one" => "four",
          "snakes" => "on a plane",
        },
        {
          "one" => "six",
          "snack" => "cookies",
        },
        {}
      )

      @empty = Chef::Node::Attribute.new({}, {}, {}, {})
    end

    it "should respond to size" do
      expect(@attributes).to respond_to(:size)
    end

    it "should alias length to size" do
      expect(@attributes).to respond_to(:length)
    end

    it "should return 0 for an empty attribute" do
      expect(@empty.size).to eq(0)
    end

    it "should return the number of pairs" do
      expect(@attributes.size).to eq(4)
    end
  end

  describe "kind_of?" do
    it "should falsely inform you that it is a Hash" do
      expect(@attributes).to be_a_kind_of(Hash)
    end

    it "should falsely inform you that it is a Mash" do
      expect(@attributes).to be_a_kind_of(Mash)
    end

    it "should inform you that it is a Chef::Node::Attribute" do
      expect(@attributes).to be_a_kind_of(Chef::Node::Attribute)
    end

    it "should inform you that it is anything else" do
      expect(@attributes).not_to be_a_kind_of(Chef::Node)
    end
  end

  describe "to_s" do
    it "should output simple attributes" do
      attributes = Chef::Node::Attribute.new(nil, nil, nil, nil)
      expect(attributes.to_s).to eq("{}")
    end

    it "should output merged attributes" do
      default_hash = {
          "a" => 1,
          "b" => 2,
      }
      override_hash = {
          "b" => 3,
          "c" => 4,
      }
      attributes = Chef::Node::Attribute.new(nil, default_hash, override_hash, nil)
      expect(attributes.to_s).to eq('{"a"=>1, "b"=>3, "c"=>4}')
    end
  end

  describe "inspect" do
    it "should be readable" do
      # NOTE: previous implementation hid the values, showing @automatic={...}
      # That is nice and compact, but hides a lot of info, which seems counter
      # to the point of calling #inspect...
      expect(@attributes.inspect).to match(/@automatic=\{.*\}/)
      expect(@attributes.inspect).to match(/@normal=\{.*\}/)
    end
  end

  describe "when not mutated" do

    it "does not reset the cache when dup'd [CHEF-3680]" do
      @attributes.default[:foo][:bar] = "set on original"
      subtree = @attributes[:foo]
      @attributes.default[:foo].dup[:bar] = "set on dup"
      expect(subtree[:bar]).to eq("set on original")
    end

  end

  describe "when setting a component attribute to a new value" do
    it "converts the input in to a VividMash tree (default)" do
      @attributes.default = {}
      @attributes.default["foo"] = "bar"
      expect(@attributes.merged_attributes[:foo]).to eq("bar")
    end

    it "converts the input in to a VividMash tree (normal)" do
      @attributes.normal = {}
      @attributes.normal["foo"] = "bar"
      expect(@attributes.merged_attributes[:foo]).to eq("bar")
    end

    it "converts the input in to a VividMash tree (override)" do
      @attributes.override = {}
      @attributes.override["foo"] = "bar"
      expect(@attributes.merged_attributes[:foo]).to eq("bar")
    end

    it "converts the input in to a VividMash tree (automatic)" do
      @attributes.automatic = {}
      @attributes.automatic["foo"] = "bar"
      expect(@attributes.merged_attributes[:foo]).to eq("bar")
    end
  end

  describe "when deep-merging between precedence levels" do
    it "correctly deep merges hashes and preserves the original contents" do
      @attributes.default = { "arglebargle" => { "foo" => "bar" } }
      @attributes.override = { "arglebargle" => { "fizz" => "buzz" } }
      expect(@attributes.merged_attributes[:arglebargle]).to eq({ "foo" => "bar", "fizz" => "buzz" })
      expect(@attributes.default[:arglebargle]).to eq({ "foo" => "bar" })
      expect(@attributes.override[:arglebargle]).to eq({ "fizz" => "buzz" })
    end

    it "does not deep merge arrays, and preserves the original contents" do
      @attributes.default = { "arglebargle" => [ 1, 2, 3 ] }
      @attributes.override = { "arglebargle" => [ 4, 5, 6 ] }
      expect(@attributes.merged_attributes[:arglebargle]).to eq([ 4, 5, 6 ])
      expect(@attributes.default[:arglebargle]).to eq([ 1, 2, 3 ])
      expect(@attributes.override[:arglebargle]).to eq([ 4, 5, 6 ])
    end

    it "correctly deep merges hashes and preserves the original contents when merging default and role_default" do
      @attributes.default = { "arglebargle" => { "foo" => "bar" } }
      @attributes.role_default = { "arglebargle" => { "fizz" => "buzz" } }
      expect(@attributes.merged_attributes[:arglebargle]).to eq({ "foo" => "bar", "fizz" => "buzz" })
      expect(@attributes.default[:arglebargle]).to eq({ "foo" => "bar" })
      expect(@attributes.role_default[:arglebargle]).to eq({ "fizz" => "buzz" })
    end

    it "correctly deep merges arrays, and preserves the original contents when merging default and role_default" do
      @attributes.default = { "arglebargle" => [ 1, 2, 3 ] }
      @attributes.role_default = { "arglebargle" => [ 4, 5, 6 ] }
      expect(@attributes.merged_attributes[:arglebargle]).to eq([ 1, 2, 3, 4, 5, 6 ])
      expect(@attributes.default[:arglebargle]).to eq([ 1, 2, 3 ])
      expect(@attributes.role_default[:arglebargle]).to eq([ 4, 5, 6 ])
    end
  end

  describe "when attemping to write without specifying precedence" do
    it "raises an error when using []=" do
      expect { @attributes[:new_key] = "new value" }.to raise_error(Chef::Exceptions::ImmutableAttributeModification)
    end
  end

  describe "deeply converting values" do
    it "converts values through an array" do
      @attributes.default[:foo] = [ { bar: true } ]
      expect(@attributes["foo"].class).to eql(Chef::Node::ImmutableArray)
      expect(@attributes["foo"][0].class).to eql(Chef::Node::ImmutableMash)
      expect(@attributes["foo"][0]["bar"]).to be true
    end

    it "converts values through nested arrays" do
      @attributes.default[:foo] = [ [ { bar: true } ] ]
      expect(@attributes["foo"].class).to eql(Chef::Node::ImmutableArray)
      expect(@attributes["foo"][0].class).to eql(Chef::Node::ImmutableArray)
      expect(@attributes["foo"][0][0].class).to eql(Chef::Node::ImmutableMash)
      expect(@attributes["foo"][0][0]["bar"]).to be true
    end

    it "converts values through nested hashes" do
      @attributes.default[:foo] = { baz: { bar: true } }
      expect(@attributes["foo"].class).to eql(Chef::Node::ImmutableMash)
      expect(@attributes["foo"]["baz"].class).to eql(Chef::Node::ImmutableMash)
      expect(@attributes["foo"]["baz"]["bar"]).to be true
    end
  end

  describe "node state" do
    it "sets __root__ correctly" do
      @attributes.default["foo"]["bar"]["baz"] = "quux"
      expect(@attributes["foo"].__root__).to eql(@attributes)
      expect(@attributes["foo"]["bar"].__root__).to eql(@attributes)
      expect(@attributes.default["foo"].__root__).to eql(@attributes)
      expect(@attributes.default["foo"]["bar"].__root__).to eql(@attributes)
    end

    it "sets __node__ correctly" do
      @attributes.default["foo"]["bar"]["baz"] = "quux"
      expect(@attributes["foo"].__node__).to eql(node)
      expect(@attributes["foo"]["bar"].__node__).to eql(node)
      expect(@attributes.default["foo"].__node__).to eql(node)
      expect(@attributes.default["foo"]["bar"].__node__).to eql(node)
    end

    it "sets __path__ correctly" do
      @attributes.default["foo"]["bar"]["baz"] = "quux"
      expect(@attributes["foo"].__path__).to eql(["foo"])
      expect(@attributes["foo"]["bar"].__path__).to eql(%w{foo bar})
      expect(@attributes.default["foo"].__path__).to eql(["foo"])
      expect(@attributes.default["foo"]["bar"].__path__).to eql(%w{foo bar})
    end

    it "sets __precedence__ correctly" do
      @attributes.default["foo"]["bar"]["baz"] = "quux"
      expect(@attributes["foo"].__precedence__).to eql(:merged)
      expect(@attributes["foo"]["bar"].__precedence__).to eql(:merged)
      expect(@attributes.default["foo"].__precedence__).to eql(:default)
      expect(@attributes.default["foo"]["bar"].__precedence__).to eql(:default)
    end

    it "notifies on attribute changes" do
      expect(events).to receive(:attribute_changed).with(:default, ["foo"], {})
      expect(events).to receive(:attribute_changed).with(:default, %w{foo bar}, {})
      expect(events).to receive(:attribute_changed).with(:default, %w{foo bar baz}, "quux")
      @attributes.default["foo"]["bar"]["baz"] = "quux"
    end
  end

  describe "frozen immutable strings" do
    it "strings in hashes should be frozen" do
      @attributes.default["foo"]["bar"]["baz"] = "fizz"
      expect { @attributes["foo"]["bar"]["baz"] << "buzz" }.to raise_error(FrozenError, /can't modify frozen String/)
    end

    it "strings in arrays should be frozen" do
      @attributes.default["foo"]["bar"] = [ "fizz" ]
      expect { @attributes["foo"]["bar"][0] << "buzz" }.to raise_error(FrozenError, /can't modify frozen String/)
    end
  end

  describe "deep merging with nils" do
    it "nils when deep merging between default levels knocks out values" do
      @attributes.default["foo"] = "bar"
      expect(@attributes["foo"]).to eql("bar")
      @attributes.force_default["foo"] = nil
      expect(@attributes["foo"]).to be nil
    end

    it "nils when deep merging between override levels knocks out values" do
      @attributes.override["foo"] = "bar"
      expect(@attributes["foo"]).to eql("bar")
      @attributes.force_override["foo"] = nil
      expect(@attributes["foo"]).to be nil
    end

    it "nils when deep merging between default+override levels knocks out values" do
      @attributes.default["foo"] = "bar"
      expect(@attributes["foo"]).to eql("bar")
      @attributes.override["foo"] = nil
      expect(@attributes["foo"]).to be nil
    end

    it "nils when deep merging between normal+automatic levels knocks out values" do
      @attributes.normal["foo"] = "bar"
      expect(@attributes["foo"]).to eql("bar")
      @attributes.automatic["foo"] = nil
      expect(@attributes["foo"]).to be nil
    end
  end

  describe "to_json" do
    it "should convert to a valid json string" do
      json = @attributes["hot"].to_json
      expect { JSON.parse(json) }.not_to raise_error
    end

    it "should convert to a json based on current state" do
      expect(@attributes["hot"].to_json).to eq("{\"day\":\"sunday\"}")
    end
  end

  describe "to_yaml" do
    it "should convert to a valid yaml format" do
      json = @attributes["hot"].to_yaml
      expect { YAML.parse(json) }.not_to raise_error
    end

    it "should convert to a yaml based on current state" do
      expect(@attributes["hot"].to_yaml).to eq("---\nday: sunday\n")
    end
  end
end
