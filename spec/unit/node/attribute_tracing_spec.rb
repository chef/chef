require 'spec_helper'
require 'spec/unit/node/tracing_spec_helper'
require 'chef/node'
require 'chef/node/attribute'

describe "Chef::Node::Attribute Tracing" do

  #================================================#
  #              Attribute Fixtures
  #================================================#

  OHAI_MIN_ATTRS = {
    'platform' => 'wfw',
    'platform_version' => '3.11',
  }

  OHAI_TEST_ATTRS = {
    'platform' => 'wfw',
    'platform_version' => '3.11',
    'foo' => 'bar',
    'deep' => { 'deeper' => 'still' },
    'bicycle' => 'ohai',
    'oryx' => { 'crake' => 'snowman' },
    'array' => [ 'thing1', 'thing2', {'thing3' => 'value'} ],
  }
  CLI_TEST_ATTRS = {
    'foo' => 'bar',
    'bicycle' => 'command-line-json',
    'oryx' => { 'crake' => 'snowman' },
    'array' => [ 'thing1', 'thing2', {'thing3' => 'value'} ],
  }

  #================================================#
  #              Reusable Examples
  #================================================#

  shared_examples "silent" do |tags|
    describe "the log output" do
      it "should not contain any trace messages" do
        if @log_buffer
          traces = @log_buffer.string.split("\n").grep(/Attribute Trace/)
          expect(traces).to be_empty
        end
      end
    end

    describe "the node attribute trace object" do
      it "should be empty", :attr_trace, :attr_trace_none, *tags  do
        expect(@node.attributes.trace_log).to be_empty
      end
    end
  end

  shared_examples "contains trace" do |tags, path, component, offset, location_checks|

    describe "the log output" do      
      it "should contain trace messages for #{path} at #{component}", :attr_trace, :attr_trace_hit, :attr_trace_messages, *tags do
        if @log_buffer
          traces = @log_buffer.string.split("\n").grep(/Attribute Trace/)
          expect(traces.find_all { |t| t.include?('path:' + path) }.find_all { |t| t.include?('precedence:' + component.to_s) }).not_to be_empty
        end
      end
    end

    describe "the node attribute trace object" do
      it "should contain trace entry objects for #{path}", :attr_trace, :attr_trace_hit, :attr_trace_objects, *tags do
        expect(@node.attributes.trace_log[path]).not_to be_nil
      end
      entry = nil
      it "should contain trace entry objects for #{path} at #{component} at offset #{offset}", :attr_trace, :attr_trace_hit, :attr_trace_objects, *tags do
        entries = @node.attributes.trace_log[path].find_all {|t| t.component == component}
        expect(entries).not_to be_empty
        entry = entries[offset]
        expect(entry).not_to be_nil
      end      
      location_checks.each do |key, value|
        it "should have source_location detail '#{key}' equal to '#{value}'" do
          expect(entry.source_location[key]).to eql value
        end
      end
    end
  end

  shared_examples "does not contain trace" do |tags, path|
    describe "the log output" do
      it "should not contain any trace messages at #{path}" do
        if @log_buffer
          traces = @log_buffer.string.split("\n").grep(/Attribute Trace/)
          expect(traces.find_all { |t| t.include?('path:' + path) }).to be_empty
        end
      end
    end

    describe "the node attribute trace object" do
      it "should not contain trace entry objects for #{path}", :attr_trace, :attr_trace_miss, *tags  do
        expect(@node.attributes.trace_log[path]).to be_nil
      end
    end
  end

  #================================================#
  #          Tests: Trace Log Accessor
  #================================================#
  describe "the trace data structure accessor" do
    context "when the node is newly created" do
      it "should be an empty hash", :attr_trace, :attr_trace_internals do
        expect(Chef::Node.new.attributes.trace_log).to be_a_kind_of(Hash)
        expect(Chef::Node.new.attributes.trace_log).to be_empty        
      end
    end
  end

  #================================================#
  #        Tests: Pathfinder
  #================================================#
  describe "the path finding mechanism" do
    before(:all) { @cna = Chef::Node::Attribute.new({},{},{},{}) }

    context "when setting a string value using default[:foo][:bar]" do
      it "should not error", :attr_trace, :attr_trace_path_finder do
        expect { @cna.default[:foo][:bar] = 'baz' }.not_to raise_error
      end
      it "should find the right path to default ", :attr_trace, :attr_trace_path_finder do
        path, comp = @cna.find_path_to_entry(@cna.default)
        expect(path).to eql '/'
      end

      it "should find the right path to default[:foo] ", :attr_trace, :attr_trace_path_finder do
        path, comp = @cna.find_path_to_entry(@cna.default[:foo])
        expect(path).to eql '/foo'
      end
      it "should find the right path to default[:foo][:bar] ", :attr_trace, :attr_trace_path_finder do
        path, comp = @cna.find_path_to_entry(@cna.default[:foo][:bar])
        expect(path).to eql '/foo/bar'
      end
    end

    context "when setting a string value using override[:foo][:bar]" do
      it "should not error", :attr_trace, :attr_trace_path_finder do
        expect { @cna.override[:foo][:bar] = 'baz' }.not_to raise_error
      end
      it "should find the right path to override ", :attr_trace, :attr_trace_path_finder do
        path, comp = @cna.find_path_to_entry(@cna.override)
        expect(path).to eql '/'
      end

      it "should find the right path to override[:foo] ", :attr_trace, :attr_trace_path_finder do
        path, comp = @cna.find_path_to_entry(@cna.override[:foo])
        expect(path).to eql '/foo'
      end
      it "should find the right path to override[:foo][:bar] ", :attr_trace, :attr_trace_path_finder do
        path, comp = @cna.find_path_to_entry(@cna.override[:foo][:bar])
        expect(path).to eql '/foo/bar'
      end
      it "should find the right component", :attr_trace, :attr_trace_path_finder do
        path, comp = @cna.find_path_to_entry(@cna.override[:foo])
        expect(comp).to eql :override
      end
    end

    context "when clearing the entire component" do      
      it "should not error", :attr_trace, :attr_trace_path_finder do
        expect { @cna.automatic = { :platform => 'wfw'} }.not_to raise_error
      end

      it "should correctly detect new attributes set in clobber mode", :attr_trace, :attr_trace_path_finder do
        @cna.automatic = { :clobber => 'girl' }
        path, comp = @cna.find_path_to_entry(@cna.automatic[:clobber])
        expect(path).to eql '/clobber'
      end
    end

    context "when creating an array by a single assignment operation" do
      it "should not error", :attr_trace, :attr_trace_path_finder, :attr_trace_array do
        expect { @cna.default[:array] = [ 'thing1', 'thing2', { 'thing3' => 'value' } ] }.not_to raise_error
      end

      it "should find the right path to node[:array] ", :attr_trace, :attr_trace_path_finder, :attr_trace_array do
        path, comp = @cna.find_path_to_entry(@cna.default[:array])
        expect(path).to eql '/array'
      end
      it "should find the right path to node[:array][0] ", :attr_trace, :attr_trace_path_finder, :attr_trace_array do
        path, comp = @cna.find_path_to_entry(@cna.default[:array][0])
        expect(path).to eql '/array/0'
      end

      # NOTE: if we split out the array element upgrade issue into a separate ticket, this will fail without that patch
      it "should find the path to node[:array][2][:thing3]", :attr_trace, :attr_trace_path_finder, :attr_trace_array do
        path, comp = @cna.find_path_to_entry(@cna.default[:array][2][:thing3])
        expect(path).to eql '/array/2/thing3'
      end
    end

    context "when creating an array by repeated whole-array assignment" do
      it "should not error", :attr_trace, :attr_trace_path_finder, :attr_trace_array do
        expect do 
          @cna.default[:array_clobber] = [ 'thing1' ]
          @cna.default[:array_clobber] = [ 'thing2' ]
          @cna.default[:array_clobber] = [ { 'thing3' => 'value' } ] 
        end.not_to raise_error
      end

      it "should find the right path to node[:array] ", :attr_trace, :attr_trace_path_finder, :attr_trace_array do
        path, comp = @cna.find_path_to_entry(@cna.default[:array_clobber])
        expect(path).to eql '/array_clobber'
      end
      it "should find the right path to node[:array][0] ", :attr_trace, :attr_trace_path_finder, :attr_trace_array do
        path, comp = @cna.find_path_to_entry(@cna.default[:array_clobber][0])
        expect(path).to eql '/array_clobber/0'
      end

      # Note that this array construction method REPLACES the entire array - no merge, no append
      # So we're looking for index 0, not index 2.
      # NOTE: if we split out the array element upgrade issue into a separate ticket, this will fail without that patch
      it "should find the path to node[:array][0][:thing3]", :attr_trace, :attr_trace_path_finder, :attr_trace_array do
        path, comp = @cna.find_path_to_entry(@cna.default[:array_clobber][0][:thing3])
        expect(path).to eql '/array_clobber/0/thing3'
      end

    end

    context "when creating an array by repeated append" do
      it "should not error", :attr_trace, :attr_trace_path_finder, :attr_trace_array do
        expect do 
          @cna.default[:array_app] = [ 'thing1' ]
          @cna.default[:array_app] << 'thing2'
          @cna.default[:array_app] << { 'thing3' => 'value' }
        end.not_to raise_error
      end

      it "should find the right path to node[:array] ", :attr_trace, :attr_trace_path_finder, :attr_trace_array do
        path, comp = @cna.find_path_to_entry(@cna.default[:array_app])
        expect(path).to eql '/array_app'
      end
      it "should find the right path to node[:array][0] ", :attr_trace, :attr_trace_path_finder, :attr_trace_array do
        path, comp = @cna.find_path_to_entry(@cna.default[:array_app][0])
        expect(path).to eql '/array_app/0'
      end

      # Note that this array construction method APPENDS TO the array
      # So we're looking for index 2, not index 0.
      # NOTE: if we split out the array element upgrade issue into a separate ticket, this will fail without that patch
      it "should find the path to node[:array][2][:thing3]", :attr_trace, :attr_trace_path_finder, :attr_trace_array do
        path, comp = @cna.find_path_to_entry(@cna.default[:array_app][2][:thing3])
        expect(path).to eql '/array_app/2/thing3'
      end
    end

  end

  #================================================#
  #        Tests: Tracing Off
  #================================================#
  describe "the tracing mode" do
    context "when tracing mode is none" do
      before do
        Chef::Config.trace_attributes = 'none'
      end
      context "when loading from ohai" do
        before(:all) do 
          @node = Chef::Node.new()
          @node.consume_external_attrs(OHAI_TEST_ATTRS,{}) 
        end
        include_examples "silent", [:attr_trace_none, :attr_trace_ohai]
      end
      context "when loading from command-line json" do
        before(:all) do 
          @node = Chef::Node.new()
          @node.consume_external_attrs(OHAI_TEST_ATTRS,{}) 
        end
        include_examples "silent", [:attr_trace_none, :attr_trace_cli]
      end

      context "when loading from chef-server normal node attributes" do
        before(:all) do
          @fixtures = {
            'node' => {
              'default' => { 'node_default' => 'node_default', },
              'normal' => { 'node_normal' => 'node_normal', },
              'override' => { 'node_override' => 'node_override', },
            }
          }
          (@node, @log_buffer) = AttributeTracingHelpers.chef_zero_client_run(@fixtures)
        end
        include_examples "silent", [:attr_trace_none, :attr_trace_node, :attr_trace_needs_chef_zero]
      end

      context "when loading from cookbook attributes" do
        before(:all) do
          @fixtures = {
            'node' => { 'run_list' => [ 'recipe[bloodsmasher]' ] },
            'cookbooks' => { 'bloodsmasher-0.2.0' => AttributeTracingHelpers.canned_fixtures[:cookbooks]['bloodsmasher-0.2.0'] },
          }
          (@node, @log_buffer) = AttributeTracingHelpers.chef_zero_client_run(@fixtures)
        end        
        include_examples "silent", [:attr_trace_none, :attr_trace_cookbook ]
      end

      context "when loading from a role" do
        before(:all) do
          @fixtures = {
            'node' => { 'run_list' => [ "role[alpha]" ], },
            'roles' => { 'alpha' => AttributeTracingHelpers.canned_fixtures[:roles][:alpha] },
          }
          (@node, @log_buffer) = AttributeTracingHelpers.chef_zero_client_run(@fixtures)
        end
        include_examples "silent", [:attr_trace_none, :attr_trace_role, :attr_trace_needs_chef_zero]
      end


      context "when loading from an environment" do
        before(:all) do
          @fixtures = {
            'environments' => { 'pure_land' => AttributeTracingHelpers.canned_fixtures[:environments][:pure_land] },
            'node' => { 'chef_environment' => 'pure_land', }
          }
          (@node, @log_buffer) = AttributeTracingHelpers.chef_zero_client_run(@fixtures)
        end
        include_examples "silent", [:attr_trace_none, :attr_trace_env ]
      end

      context "when being set by a cookbook recipe" do
        before(:all) do          
          @fixtures = {
            'node' => { 'run_list' => [ 'recipe[burgers]' ] },
            'cookbooks' => { 'burgers-0.1.7' => AttributeTracingHelpers.canned_fixtures[:cookbooks]['burgers-0.1.7'] },
          }
          (@node, @log_buffer) = AttributeTracingHelpers.chef_zero_client_run(@fixtures)
        end
        include_examples "silent", [:attr_trace_none, :attr_trace_cookbook ]        
      end
    end


    #================================================#
    #       Tests: Tracing Everything
    #================================================#

    context "when tracing mode is all" do

      context "when loading from ohai" do
        before(:all) do 
          Chef::Config.trace_attributes = 'all'
          @node = Chef::Node.new()
          @node.consume_external_attrs(OHAI_TEST_ATTRS,{})
        end
        include_examples "contains trace", [:attr_trace_all, :attr_trace_ohai], "/foo", :automatic, 0, { :mechanism => :ohai }
        include_examples "contains trace", [:attr_trace_all, :attr_trace_ohai], "/deep/deeper", :automatic, 0, { :mechanism => :ohai }
        include_examples "contains trace", [:attr_trace_all, :attr_trace_ohai, :attr_trace_array], "/array/0", :automatic, 0, { :mechanism => :ohai }
        include_examples "contains trace", [:attr_trace_all, :attr_trace_ohai, :attr_trace_array], "/array/2/thing3", :automatic, 0, { :mechanism => :ohai }
      end

      context "when loading from command-line json" do
        before(:all) do 
          Chef::Config.trace_attributes = 'all'
          # This is gross, but application/client and config_fetcher make this kind of hard to test
          @old_argv = ARGV.dup()
          ARGV.delete_if { |a| true }
          ARGV.concat(['-j', 'dummy.json'])

          @node = Chef::Node.new()
          @node.consume_external_attrs(OHAI_MIN_ATTRS,CLI_TEST_ATTRS)          
        end
        after(:all) do 
          ARGV.delete_if { |a| true }
          ARGV.concat(@old_argv)
        end
          
        include_examples("contains trace", [:attr_trace_all, :attr_trace_cli], "/foo", :normal, 0, 
                         { 
                           :mechanism => :'command-line-json', 
                           :explanation => 'attributes loaded from command-line using -j json',
                           :json_file => 'dummy.json',
                         })
        include_examples("contains trace", [:attr_trace_all, :attr_trace_cli], "/oryx", :normal, 0,
                         { 
                           :mechanism => :'command-line-json', 
                           :explanation => 'attributes loaded from command-line using -j json', 
                           :json_file => 'dummy.json',
                         })
        include_examples("contains trace", [:attr_trace_all, :attr_trace_cli, :attr_trace_array], "/array/0", :normal, 0, {:mechanism => :'command-line-json'})
        include_examples("contains trace", [:attr_trace_all, :attr_trace_cli, :attr_trace_array], "/array/2/thing3", :normal, 0, {:mechanism => :'command-line-json'})
      end

      context "when loading from chef-server normal node attributes" do
        before(:all) do
          Chef::Config.trace_attributes = 'all'
          @fixtures = {
            'node' => {
              'default' => { 'node_default' => 'node_default', },
              'normal' => { 
                'node_normal' => 'node_normal', 
                'deep' => {
                  'deeper' => 'yup',
                }, 
                'array' => [ 'thing1', 'thing2', {'thing3' => 'value'} ],                  
              },
              'override' => { 'node_override' => 'node_override', },
            }
          }
          (@node, @log_buffer) = AttributeTracingHelpers.chef_zero_client_run(@fixtures)
        end

        include_examples("contains trace", [:attr_trace_all, :attr_trace_node], "/node_normal", :normal, 0,
                         { 
                           :mechanism => :node, 
                           :explanation => 'setting attributes from the node record obtained from the server',
                           :server => 'http://localhost:19090',
                           :node_name => 'hostname.example.org',
                         })
        include_examples("contains trace", [:attr_trace_all, :attr_trace_node], "/deep/deeper", :normal, 0,
                         { 
                           :mechanism => :node, 
                           :explanation => 'setting attributes from the node record obtained from the server',
                           :server => 'http://localhost:19090',
                           :node_name => 'hostname.example.org',
                         })
        include_examples("contains trace", [:attr_trace_all, :attr_trace_node, :attr_trace_array], "/array/0", :normal, 0, { :mechanism => :node })
        include_examples("contains trace", [:attr_trace_all, :attr_trace_node, :attr_trace_array], "/array/2/thing3", :normal, 0, { :mechanism => :node })

      end

      context "when loading from cookbook attributes" do
        before(:all) do          
          Chef::Config.trace_attributes = 'all'
          @fixtures = {
            'node' => { 'run_list' => [ 'recipe[bloodsmasher]' ] },
            'cookbooks' => { 'bloodsmasher-0.2.0' => AttributeTracingHelpers.canned_fixtures[:cookbooks]['bloodsmasher-0.2.0'] },
          }
          (@node, @log_buffer) = AttributeTracingHelpers.chef_zero_client_run(@fixtures)
        end

        include_examples("contains trace", [:attr_trace_all, :attr_trace_cookbook], "/goofin/on/elvis", :default, 0, 
                         { 
                           :mechanism => :'cookbook-attributes',
                           :explanation => "An attribute was touched by a cookbook's attribute file",
                           :cookbook => 'bloodsmasher', 
                           :cookbook_version => '0.2.0',
                           :line => 2, 
                           :file => 'bloodsmasher/attributes/default.rb',
                         })
        include_examples("contains trace", [:attr_trace_all, :attr_trace_cookbook, :attr_trace_array], "/array/0", :default, 0, { :mechanism => :'cookbook-attributes' })
        include_examples("contains trace", [:attr_trace_all, :attr_trace_cookbook, :attr_trace_array], "/array/2/thing3", :default, 0, { :mechanism => :'cookbook-attributes' })
        
      end

      context "when loading from a role" do
        before(:all) do
          Chef::Config.trace_attributes = 'all'
          @fixtures = {
            'node' => { 'run_list' => [ "role[alpha]" ], },
            'roles' => { 'alpha' => AttributeTracingHelpers.canned_fixtures[:roles][:alpha] },
          }
          (@node, @log_buffer) = AttributeTracingHelpers.chef_zero_client_run(@fixtures)
        end

        include_examples("contains trace", [:attr_trace_all, :attr_trace_role], "/role_default", :role_default, 0,
                         { 
                           :mechanism => :'role', 
                           :explanation => 'Applying attributes from loading a role',
                           :role_name => 'alpha',
                         })        
        include_examples("contains trace", [:attr_trace_all, :attr_trace_role], "/role_default", :role_default, -1,
                         { 
                           :mechanism => :'chef-internal', 
                           :explanation => "Having merged all role attributes into an 'expansion', the chef run is now importing the expansion into the node object.",
                         })        
        include_examples("contains trace", [:attr_trace_all, :attr_trace_role], "/role_override", :role_override, 0,
                          { 
                            :mechanism => :'role', 
                            :explanation => 'Applying attributes from loading a role',
                            :role_name => 'alpha',
                          })
        include_examples("contains trace", [:attr_trace_all, :attr_trace_role], "/role_override", :role_override, -1,
                         { 
                           :mechanism => :'chef-internal', 
                           :explanation => "Having merged all role attributes into an 'expansion', the chef run is now importing the expansion into the node object.",
                         })        

        include_examples("contains trace", [:attr_trace_all, :attr_trace_role, :attr_trace_array], "/array/0", :role_default, 0, { :mechanism => :role })
        include_examples("contains trace", [:attr_trace_all, :attr_trace_role, :attr_trace_array], "/array/0", :role_default, -1, { :mechanism => :'chef-internal' })
        include_examples("contains trace", [:attr_trace_all, :attr_trace_role, :attr_trace_array], "/array/2/thing3", :role_default, 0, { :mechanism => :role })
        include_examples("contains trace", [:attr_trace_all, :attr_trace_role, :attr_trace_array], "/array/2/thing3", :role_default, -1, { :mechanism => :'chef-internal' })

      end

      context "when loading from an environment" do
        before(:all) do
          Chef::Config.trace_attributes = 'all'
          @fixtures = {
            'environments' => { 'pure_land' => AttributeTracingHelpers.canned_fixtures[:environments][:pure_land] },
            'node' => { 'chef_environment' => 'pure_land', }
          }
          (@node, @log_buffer) = AttributeTracingHelpers.chef_zero_client_run(@fixtures)
        end

        include_examples("contains trace", [:attr_trace_all, :attr_trace_env], "/env_default", :env_default, 0,
                         { 
                           :mechanism => :environment,
                           :explanation => 'Applying attributes from loading an environment',
                           :server => 'http://localhost:19090',
                           :environment_name => 'pure_land',
                         })
        include_examples("contains trace", [:attr_trace_all, :attr_trace_env], "/env_override", :env_override, 0,
                         {
                           :mechanism => :environment, 
                           :explanation => 'Applying attributes from loading an environment',
                           :server => 'http://localhost:19090',
                           :environment_name => 'pure_land',
                         })
        include_examples("contains trace", [:attr_trace_all, :attr_trace_env, :attr_trace_array], "/array/0", :env_default, 0, { :mechanism => :environment })
        include_examples("contains trace", [:attr_trace_all, :attr_trace_env, :attr_trace_array], "/array/2/thing3", :env_default, 0, { :mechanism => :environment })

      end

      context "when being set by a cookbook recipe" do
        before(:all) do          
          Chef::Config.trace_attributes = 'all'
          @fixtures = {
            'node' => { 'run_list' => [ 'recipe[burgers]' ] },
            'cookbooks' => { 'burgers-0.1.7' => AttributeTracingHelpers.canned_fixtures[:cookbooks]['burgers-0.1.7'] },
          }
          (@node, @log_buffer) = AttributeTracingHelpers.chef_zero_client_run(@fixtures)
        end

        include_examples("contains trace", [:attr_trace_all, :attr_trace_cookbook], "/ham/mustard", :normal, 0, 
                         { 
                           :mechanism => :'cookbook-recipe-compile-time',
                           :explanation => "An attribute was set in a cookbook recipe, outside of a resource.",
                           :cookbook => 'burgers', 
                           :cookbook_version => '0.1.7',
                           :line => 2, 
                           :file => 'burgers/recipes/default.rb',
                         })
        include_examples("contains trace", [:attr_trace_all, :attr_trace_cookbook], "/ham/relish", :normal, 0, 
                         { 
                           :mechanism => :'cookbook-recipe-converge-time',
                           :explanation => "An attribute was set in a cookbook recipe during convergence time (while a resource was being executed, probably a ruby_block).",
                           :cookbook => 'burgers', 
                           # :cookbook_version => '0.1.7', # Currently cannot detect cookbook version when the event occurs at converge time
                           :line => 6, 
                           :file => 'burgers/recipes/default.rb',
                         })
        include_examples("contains trace", [:attr_trace_all, :attr_trace_cookbook], "/ham/cole_slaw", :normal, 0, 
                         { 
                           :mechanism => :'cookbook-recipe-compile-time',
                           :explanation => "An attribute was set in a cookbook recipe, outside of a resource.",
                           :cookbook => 'burgers', 
                           :cookbook_version => '0.1.7',
                           :line => 2, 
                           :file => 'burgers/recipes/kansas.rb',
                         })
        include_examples("contains trace", [:attr_trace_all, :attr_trace_cookbook, :attr_trace_array], "/array/0", :normal, 0, { :mechanism => :'cookbook-recipe-compile-time' })
        include_examples("contains trace", [:attr_trace_all, :attr_trace_cookbook, :attr_trace_array], "/array/2/thing3", :normal, 0, { :mechanism => :'cookbook-recipe-compile-time' })
        
      end
    end

    #================================================#
    #       Tests: Tracing a Specific Path
    #================================================#
    
    context "when tracing mode is an extant path /oryx/crake" do
      context "when loading from ohai" do
        before(:all) do 
          Chef::Config.trace_attributes = '/oryx/crake'
          @node = Chef::Node.new()
          @node.consume_external_attrs(OHAI_TEST_ATTRS,{})
        end
        include_examples "contains trace", [:attr_trace_path, :attr_trace_ohai], "/oryx/crake", :automatic, 0, { :mechanism => :ohai }
        include_examples "does not contain trace", [:attr_trace_path, :attr_trace_ohai], "/deep/deeper"
      end

      context "when loading from command-line json" do
        before(:all) do 
          Chef::Config.trace_attributes = '/oryx/crake'
          # This is gross, but application/client and config_fetcher make this kind of hard to test
          @old_argv = ARGV.dup()
          ARGV.delete_if { |a| true }
          ARGV.concat(['-j', 'dummy.json'])

          @node = Chef::Node.new()
          @node.consume_external_attrs(OHAI_MIN_ATTRS,CLI_TEST_ATTRS)
        end
        after(:all) do 
          ARGV.delete_if { |a| true }
          ARGV.concat(@old_argv)
        end
          
        include_examples("contains trace", [:attr_trace_path, :attr_trace_cli], "/oryx/crake", :normal, 0, 
                         { 
                           :mechanism => :'command-line-json', 
                         })

        include_examples("does not contain trace", [:attr_trace_path, :attr_trace_cli], "/deep/deeper")
      end

      context "when loading from chef-server normal node attributes" do
        before(:all) do
          Chef::Config.trace_attributes = '/oryx/crake'
          @fixtures = {
            'node' => {
              'normal' => { 
                'node_normal' => 'node_normal', 
                'deep' => { 'deeper' => 'yup', },
                'oryx' => { 'crake' => 'snowman' },
              },
            }
          }
          (@node, @log_buffer) = AttributeTracingHelpers.chef_zero_client_run(@fixtures)
        end

        include_examples("contains trace", [:attr_trace_path, :attr_trace_node], "/oryx/crake", :normal, 0, { :mechanism => :node })
        include_examples("does not contain trace", [:attr_trace_path, :attr_trace_node], "/deep/deeper")
      end

      context "when loading from cookbook attributes" do
        before(:all) do          
          Chef::Config.trace_attributes = '/oryx/crake'
          @fixtures = {
            'node' => { 'run_list' => [ 'recipe[bloodsmasher]' ] },
            'cookbooks' => { 'bloodsmasher-0.2.0' => AttributeTracingHelpers.canned_fixtures[:cookbooks]['bloodsmasher-0.2.0'] },
          }
          (@node, @log_buffer) = AttributeTracingHelpers.chef_zero_client_run(@fixtures)
        end

        include_examples("contains trace", [:attr_trace_path, :attr_trace_cookbook], "/oryx/crake", :default, 0, { :mechanism => :'cookbook-attributes' })
        include_examples("does not contain trace", [:attr_trace_path, :attr_trace_cookbook], "/goofin/on/elvis")
      end

      context "when loading from a role" do
        before(:all) do
          Chef::Config.trace_attributes = '/oryx/crake'
          @fixtures = {
            'node' => { 'run_list' => [ "role[alpha]" ], },
            'roles' => { 'alpha' => AttributeTracingHelpers.canned_fixtures[:roles][:alpha] },
          }
          (@node, @log_buffer) = AttributeTracingHelpers.chef_zero_client_run(@fixtures)
        end

        include_examples("contains trace", [:attr_trace_path, :attr_trace_role], "/oryx/crake", :role_default, 0, { :mechanism => :role })
        include_examples("does not contain trace", [:attr_trace_path, :attr_trace_role], "/role_default")

      end

      context "when loading from an environment" do
        before(:all) do
          Chef::Config.trace_attributes = '/oryx/crake'
          @fixtures = {
            'environments' => { 'pure_land' => AttributeTracingHelpers.canned_fixtures[:environments][:pure_land] },
            'node' => { 'chef_environment' => 'pure_land', }
          }
          (@node, @log_buffer) = AttributeTracingHelpers.chef_zero_client_run(@fixtures)
        end

        include_examples("contains trace", [:attr_trace_path, :attr_trace_env], "/oryx/crake", :env_default, 0, { :mechanism => :environment })
        include_examples("does not contain trace", [:attr_trace_path, :attr_trace_env], "/env_override")
      end

      context "when being set by a cookbook recipe" do
        before(:all) do          
          Chef::Config.trace_attributes = '/oryx/crake'
          @fixtures = {
            'node' => { 'run_list' => [ 'recipe[burgers]' ] },
            'cookbooks' => { 'burgers-0.1.7' => AttributeTracingHelpers.canned_fixtures[:cookbooks]['burgers-0.1.7'] },
          }
          (@node, @log_buffer) = AttributeTracingHelpers.chef_zero_client_run(@fixtures)
        end

        include_examples("contains trace", [:attr_trace_path, :attr_trace_cookbook], "/oryx/crake", :normal, 0, { :mechanism => :'cookbook-recipe-compile-time' })
        include_examples("does not contain trace", [:attr_trace_path, :attr_trace_cookbook], "/ham/cole_slaw")
      end
    end
  end

  #================================================#
  #       Tests: Nastier Interactions
  #================================================#
  
  describe "the more awkward moments" do
    context "when a recipe reloads attributes" do
      before(:all) do          
        Chef::Config.trace_attributes = 'all'
        @fixtures = {
          'node' => { 'run_list' => [ 'recipe[burgers]' ] },
          'cookbooks' => { 'burgers-0.1.7' => AttributeTracingHelpers.canned_fixtures[:cookbooks]['burgers-0.1.7'] },
        }
        (@node, @log_buffer) = AttributeTracingHelpers.chef_zero_client_run(@fixtures)
      end

      include_examples("contains trace", [:attr_trace_all, :attr_trace_nasty ], "/lim", :default, 0, 
                       { 
                         :mechanism => :'cookbook-attributes',
                         :file => 'burgers/attributes/default.rb',
                       })
      include_examples("contains trace", [:attr_trace_all, :attr_trace_nasty ], "/lim", :default, 1, 
                       { 
                         :mechanism => :'cookbook-recipe-compile-time',
                         :file => 'burgers/recipes/default.rb',
                       })
      include_examples("contains trace", [:attr_trace_all, :attr_trace_nasty ], "/lim", :default, 2, 
                       { 
                         :mechanism => :'cookbook-attributes-reload',
                         :explanation => "An attribute was reloaded from a cookbook attribute file by a recipe",
                         :line => 1,
                         :file => 'burgers/attributes/default.rb',
                         :reloaded_by_file => 'burgers/recipes/default.rb',
                         :reloaded_by_line => 16,
                       })

    end
  end

  # TODO: add actions? eg set, clear (eg override to [] or {}), append, arrayclobber, hashclobber?
  # TODO: test delete
  # TODO: consider writing low-level testing for VividMash mutators
  # TODO: consider writing low-level testing for AttrArray mutators

end
