require 'spec_helper'
require 'chef/node'
require 'chef/node/attribute'

describe "Chef::Node::Attribute Tracing" do

  shared_examples "silent" do
    describe "the log output" do
      it "should not contain trace messages"
    end
    describe "the node attribute trace object" do
      it "should be empty" do
        expect(node.attribute_trace_log).to be_empty
      end
    end
  end

  shared_examples "contains trace" do |path, level, origin_type|
    describe "the log output" do
      it "should contain trace messages for #{path} at #{level} from #{origin_type}"
    end
    describe "the node attribute trace object" do
      it "should contain trace messages for #{path} at #{level} from #{origin_type}" do
        expect(node.attribute_trace_log[path]).not_to be_nil
        expect(node.attribute_trace_log[path].find {|t| t.type == origin_type && t.precedence == level}).not_to be_nil
      end
    end
  end

  shared_examples "does not contain trace" do |path, level, origin_type|
    describe "the log output" do
      it "should not contain trace messages for #{path} at #{level} from #{origin_type}"
    end
    describe "the node attribute trace object" do
      it "should not contain trace messages for #{path} at #{level} from #{origin_type}"
    end
  end

  shared_examples "contains cookbook trace" do |path, level, cookbook_name, filename, line_num|
    describe "the log output" do
      it "should contain a trace message for cookbook #{cookbook_name}, attribute file #{filename}:#{line_num}"
    end
    describe "the node attribute trace object" do
      it "should contain a trace for cookbook #{cookbook_name}, attribute file #{filename}:#{line_num}"
    end
  end

  shared_examples "contains role/env trace" do |path, level, origin_type, origin_name|
    describe "the log output" do
      it "should contain a trace message for #{path} at level #{level} in #{origin_type} #{origin_name}"
    end
    describe "the node attribute trace object" do
      it "should contain a trace message for #{path} at level #{level} in #{origin_type} #{origin_name}"
    end
  end

  describe "the trace data structure accessor" do
    context "when the node is newly created" do
      it "should be an empty hash" do
        expect(Chef::Node.new.attribute_trace_log).to be_a_kind_of(Hash)
        expect(Chef::Node.new.attribute_trace_log).to be_empty        
      end
    end
  end

  describe "the tracing mode" do
    context "when tracing mode is none" do
      context "when loading from ohai" do
        include_examples "silent"
      end
      context "when loading from command-line json" do
        include_examples "silent"
      end
      context "when loading from chef-server normal node attributes" do
        include_examples "silent"
      end
      context "when loading from cookbook attributes" do
        include_examples "silent"
      end
      context "when loading from a role" do
        include_examples "silent"
      end
      context "when loading from an environment" do
        include_examples "silent"
      end
    end

    context "when tracing mode is all" do
      context "when loading from ohai" do
        include_examples "contains trace", "/foo/bar", "automatic/ohai"
        include_examples "contains trace", "/oryx/crake", "automatic/ohai"
      end
      context "when loading from command-line json" do
        include_examples "contains trace", "/foo/bar", "normal/command-line-json"
        include_examples "contains trace", "/oryx/crake", "normal/command-line-json"
      end
      context "when loading from chef-server normal node attributes" do
        include_examples "contains trace", "/foo/bar", "normal/chef-server"
        include_examples "contains trace", "/oryx/crake", "normal/chef-server"      
      end
      context "when loading from cookbook attributes" do
        include_examples "contains trace", "/foo/bar", "default/cookbook"
        include_examples "contains trace", "/oryx/crake", "default/cookbook"
      end
      context "when loading from a role" do
        include_examples "contains trace", "/foo/bar", "default/role"
        include_examples "contains trace", "/oryx/crake", "default/role"
      end
      context "when loading from an environment" do
        include_examples "contains trace", "/foo/bar", "default/environment"
        include_examples "contains trace", "/oryx/crake", "default/environment"
      end
    end

    context "when tracing mode is an extant path /oryx/crake" do
      context "when loading from ohai" do
        include_examples "does not contain trace", "/foo/bar", "automatic/ohai"
        include_examples "contains trace", "/oryx/crake", "automatic/ohai"
      end
      context "when loading from command-line json" do
        include_examples "does not contain trace", "/foo/bar", "normal/command-line-json"
        include_examples "contains trace", "/oryx/crake", "normal/command-line-json"
      end
      context "when loading from chef-server normal node attributes" do
        include_examples "does not contain trace", "/foo/bar", "normal/chef-server"
        include_examples "contains trace", "/oryx/crake", "normal/chef-server"      
      end
      context "when loading from cookbook attributes" do
        include_examples "does not contain trace", "/foo/bar", "default/cookbook"
        include_examples "contains trace", "/oryx/crake", "default/cookbook"
      end
      context "when loading from a role" do
        include_examples "does not contain trace", "/foo/bar", "default/role"
        include_examples "contains trace", "/oryx/crake", "default/role"
      end
      context "when loading from an environment" do
        include_examples "does not contain trace", "/foo/bar", "default/environment"
        include_examples "contains trace", "/oryx/crake", "default/environment"
      end
    end
  end

  describe "the file tracing feature" do
    context "when loading from cookbook attributes" do
      include_examples "contains cookbook trace", "/oryx/crake", "default", "atwood", "default.rb", "12"
      include_examples "contains cookbook trace", "/oryx/crake", "default", "atwood", "funnyname.rb", "1"
    end

    context "when loading from a role" do
      include_examples "contains role/env trace", "/oryx/crake", "default", "role", "author"
    end

    context "when loading from an environment" do
      include_examples "contains role/env trace", "/oryx/crake", "default", "environment", "postapocalyptic"
    end
  end

  describe "different-precedence handling, same file" do
    context "when loading from cookbook attributes" do
      include_examples "contains cookbook trace", "/oryx/crake", "default", "cookbook", "atwood", "default.rb", "12"
      include_examples "contains cookbook trace", "/oryx/crake", "override", "cookbook", "atwood", "default.rb", "13"
    end

    context "when loading from a role" do
      include_examples "contains role/env trace", "/oryx/crake", "default", "role", "author"
      include_examples "contains role/env trace", "/oryx/crake", "override", "role", "author"
    end

    context "when loading from an environment" do
      include_examples "contains role/env trace", "/oryx/crake", "default", "environment", "postapocalyptic"
      include_examples "contains role/env trace", "/oryx/crake", "override", "environment", "postapocalyptic"
    end
  end

  describe "mixed-precedence handling, different files" do
    include_examples "contains cookbook trace", "/oryx/crake", "default", "cookbook", "atwood", "default.rb", "12"
    include_examples "contains cookbook trace", "/oryx/crake", "override", "cookbook", "another", "default.rb", "2"
    include_examples "contains role/env trace", "/oryx/crake", "default", "role", "author"
    include_examples "contains role/env trace", "/oryx/crake", "override", "role", "poet"
    include_examples "contains role/env trace", "/oryx/crake", "default", "environment", "postapocalyptic"
    include_examples "contains role/env trace", "/oryx/crake", "override", "environment", "postapocalyptic"
  end

  # TODO: add actions? eg set, clear (eg override to [] or {}), append, arrayclobber, hashclobber?

end
