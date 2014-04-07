require 'spec_helper'
require 'spec/unit/node/tracing_spec_helper'
require 'chef/node'
require 'chef/node/attribute'

# Debug
require 'pry'
require 'pry-debugger'


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
    'oryx' => 'crake',
  }
  CLI_TEST_ATTRS = {
    'foo' => 'bar',
    'bicycle' => 'command-line-json',
    'oryx' => 'crake',
  }

  #================================================#
  #              Reusable Examples
  #================================================#

  shared_examples "silent" do |tags|
    # describe "the log output" do
    #   it "should not contain trace messages"
    # end
    describe "the node attribute trace object" do
      it "should be empty", :attr_trace, :attr_trace_none, *tags  do
        expect(@node.attributes.trace_log).to be_empty
      end
    end
  end

  shared_examples "contains trace" do |tags, path, component, offset, location_checks|
    #describe "the log output" do
    #  it "should contain trace messages for #{path} at #{component}"
    #end
    describe "the node attribute trace object" do
      it "should contain trace messages for #{path} at #{component}", :attr_trace, :attr_trace_hit, *tags do
        expect(@node.attributes.trace_log[path]).not_to be_nil
        entries = @node.attributes.trace_log[path].find_all {|t| t.component == component}
        expect(entries).not_to be_empty
        entry = entries[offset]
        expect(entry).not_to be_nil
        location_checks.each do |key, value|
          expect(entry.source_location[key]).to eql value
        end
      end
    end
  end

  shared_examples "does not contain trace" do |tags, path, level, origin_type|
    #describe "the log output" do
    #  it "should not contain trace messages for #{path} at #{level} from #{origin_type}"
    #end
    describe "the node attribute trace object", :attr_trace, :attr_trace_miss, *tags  do
      it "should not contain trace messages for #{path} at #{level} from #{origin_type}"
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

  end

  #================================================#
  #        Tests: Tracing Mode
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
          @node = AttributeTracingHelpers.chef_zero_client_run(@fixtures)
        end
        include_examples "silent", [:attr_trace_none, :attr_trace_node, :attr_trace_needs_chef_zero]
      end

      context "when loading from cookbook attributes" do
        before(:all) do
          @fixtures = {
            'node' => { 'run_list' => [ 'recipe[bloodsmasher]' ] },
            'cookbooks' => { 'bloodsmasher-0.2.0' => AttributeTracingHelpers.canned_fixtures[:cookbooks]['bloodsmasher-0.2.0'] },
          }
          @node = AttributeTracingHelpers.chef_zero_client_run(@fixtures)
        end        
        include_examples "silent", [:attr_trace_none, :attr_trace_cookbook ]
      end

      context "when loading from a role" do
        before(:all) do
          @fixtures = {
            'node' => { 'run_list' => [ "role[alpha]" ], },
            'roles' => { 'alpha' => AttributeTracingHelpers.canned_fixtures[:roles][:alpha] },
          }
          @node = AttributeTracingHelpers.chef_zero_client_run(@fixtures)
        end
        include_examples "silent", [:attr_trace_none, :attr_trace_role, :attr_trace_needs_chef_zero]
      end

      context "when loading from an environment" do
        # TODO: test load from an environment
        #include_examples "silent"
      end

      # TODO: test being set at compile-time in a recipe
      # TODO: test being set at converge-time in a recipe
    end

    context "when tracing mode is all" do
      before(:all) do
        Chef::Config.trace_attributes = 'all'
      end

      context "when loading from ohai" do
        before(:all) do 
          Chef::Config.trace_attributes = 'all'
          @node = Chef::Node.new()
          @node.consume_external_attrs(OHAI_TEST_ATTRS,{})
        end
        include_examples "contains trace", [:attr_trace_all, :attr_trace_ohai], "/foo", :automatic, 0, { :mechanism => :ohai }
        include_examples "contains trace", [:attr_trace_all, :attr_trace_ohai], "/deep/deeper", :automatic, 0, { :mechanism => :ohai }
      end

      context "when loading from command-line json" do
        before(:all) do 
          Chef::Config.trace_attributes = 'all'
          @node = Chef::Node.new()
          @node.consume_external_attrs(OHAI_MIN_ATTRS,CLI_TEST_ATTRS)
          # binding.pry
        end
        include_examples "contains trace", [:attr_trace_all, :attr_trace_cli], "/foo", :normal, 0, { :mechanism => :'chef-client', :explanation => 'attributes loaded from command-line using -j json' }
        include_examples "contains trace", [:attr_trace_all, :attr_trace_cli], "/oryx", :normal, 0, { :mechanism => :'chef-client', :explanation => 'attributes loaded from command-line using -j json' }
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
                }
              },
              'override' => { 'node_override' => 'node_override', },
            }
          }
          @node = AttributeTracingHelpers.chef_zero_client_run(@fixtures)
        end

        include_examples("contains trace", [:attr_trace_all, :attr_trace_node], "/node_normal", :normal, 0,
                         { 
                           :mechanism => :'node-record', 
                           :explanation => 'setting attributes from the node record obtained from the server',
                           :server => 'http://localhost:19090',
                           :node_name => 'hostname.example.org',
                         })
        include_examples("contains trace", [:attr_trace_all, :attr_trace_node], "/deep/deeper", :normal, 0,
                         { 
                           :mechanism => :'node-record', 
                           :explanation => 'setting attributes from the node record obtained from the server',
                           :server => 'http://localhost:19090',
                           :node_name => 'hostname.example.org',
                         })
      end

      context "when loading from cookbook attributes" do
        before(:all) do          
          Chef::Config.trace_attributes = 'all'
          @fixtures = {
            'node' => { 'run_list' => [ 'recipe[bloodsmasher]' ] },
            'cookbooks' => { 'bloodsmasher-0.2.0' => AttributeTracingHelpers.canned_fixtures[:cookbooks]['bloodsmasher-0.2.0'] },
          }
          @node = AttributeTracingHelpers.chef_zero_client_run(@fixtures)
        end

        include_examples("contains trace", [:attr_trace_all, :attr_trace_cookbook], "/goofin/on/elvis", :default, 0, 
                         { 
                           :mechanism => :'cookbook-attributes',
                           :explanation => "An attribute was touched by a cookbook's attribute file",
                           :cookbook => 'bloodsmasher', 
                           # :version => '0.2.0', # TODO
                           :line => 2, 
                           :file => 'bloodsmasher/attributes/default.rb',
                         })
        
      end

      context "when loading from a role" do
        before(:all) do
          Chef::Config.trace_attributes = 'all'
          @fixtures = {
            'node' => { 'run_list' => [ "role[alpha]" ], },
            'roles' => { 'alpha' => AttributeTracingHelpers.canned_fixtures[:roles][:alpha] },
          }
          @node = AttributeTracingHelpers.chef_zero_client_run(@fixtures)
        end

        include_examples("contains trace", [:attr_trace_all, :attr_trace_role], "/role_default", :role_default, 0,
                         { 
                           :mechanism => :'role', 
                           :explanation => 'Applying attributes from loading a role',
                           :role_name => 'alpha',
                         })        
        include_examples("contains trace", [:attr_trace_all, :attr_trace_role], "/role_default", :role_default, -1,
                         { 
                           :mechanism => :'chef-client', 
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
                           :mechanism => :'chef-client', 
                           :explanation => "Having merged all role attributes into an 'expansion', the chef run is now importing the expansion into the node object.",
                         })        

      end

      context "when loading from an environment" do
        before(:all) do
          Chef::Config.trace_attributes = 'all'
          @fixtures = {
            'environments' => {
              'pure_land' => {
                'name' => 'pure_land',
                'default_attributes' => { 'env_default' => 'env_default', },
                'override_attributes' => { 'env_override' => 'env_override', },
              }              
            },
            'node' => {
              'chef_environment' => 'pure_land',
            }
          }
          @node = AttributeTracingHelpers.chef_zero_client_run(@fixtures)
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
      end

      context "when being set by a cookbook recipe" do
        before(:all) do          
          Chef::Config.trace_attributes = 'all'
          @fixtures = {
            'node' => { 'run_list' => [ 'recipe[burgers]' ] },
            'cookbooks' => { 'burgers-0.1.0' => AttributeTracingHelpers.canned_fixtures[:cookbooks]['burgers-0.1.0'] },
          }
          @node = AttributeTracingHelpers.chef_zero_client_run(@fixtures)
        end

        include_examples("contains trace", [:attr_trace_all, :attr_trace_cookbook], "/ham/mustard", :normal, 0, 
                         { 
                           :mechanism => :'cookbook-recipe-compile-time',
                           :explanation => "An attribute was set in a cookbook recipe, outside of a resource.",
                           :cookbook => 'burgers', 
                           # :version => '0.2.0', # TODO
                           :line => 2, 
                           :file => 'burgers/recipes/default.rb',
                         })
        include_examples("contains trace", [:attr_trace_all, :attr_trace_cookbook], "/ham/relish", :normal, 0, 
                         { 
                           :mechanism => :'cookbook-recipe-converge-time',
                           :explanation => "An attribute was set in a cookbook recipe during convergence time (while a resource was being executed, probably a ruby_block).",
                           :cookbook => 'burgers', 
                           # :version => '0.2.0', # TODO
                           :line => 6, 
                           :file => 'burgers/recipes/default.rb',
                         })
        include_examples("contains trace", [:attr_trace_all, :attr_trace_cookbook], "/ham/cole_slaw", :normal, 0, 
                         { 
                           :mechanism => :'cookbook-recipe-compile-time',
                           :explanation => "An attribute was set in a cookbook recipe, outside of a resource.",
                           :cookbook => 'burgers', 
                           # :version => '0.2.0', # TODO
                           :line => 2, 
                           :file => 'burgers/recipes/kansas.rb',
                         })
        
      end


    end

    # context "when tracing mode is an extant path /oryx/crake" do
    #   before do
    #     Chef::Config.trace_attributes = '/oryx/crake'
    #   end
    #   context "when loading from ohai" do
    #     before(:all) { node = Chef::Node.new().consume_external_attrs(OHAI_TEST_ATTRS,{}) }
    #     #include_examples "does not contain trace", "/foo/bar", "automatic/ohai"
    #     #include_examples "contains trace", "/oryx/crake", "automatic/ohai"
    #   end
    #   context "when loading from command-line json" do
    #     before(:all) { node = Chef::Node.new().consume_external_attrs(OHAI_MIN_ATTRS, CLI_TEST_ATTRS) }
    #     #include_examples "does not contain trace", "/foo/bar", "normal/command-line-json"
    #     #include_examples "contains trace", "/oryx/crake", "normal/command-line-json"
    #   end
    #   context "when loading from chef-server normal node attributes" do
    #     #include_examples "does not contain trace", "/foo/bar", "normal/chef-server"
    #     #include_examples "contains trace", "/oryx/crake", "normal/chef-server"      
    #   end
    #   context "when loading from cookbook attributes" do
    #     #include_examples "does not contain trace", "/foo/bar", "default/cookbook"
    #     #include_examples "contains trace", "/oryx/crake", "default/cookbook"
    #   end
    #   context "when loading from a role" do
    #     #include_examples "does not contain trace", "/foo/bar", "default/role"
    #     #include_examples "contains trace", "/oryx/crake", "default/role"
    #   end
    #   context "when loading from an environment" do
    #     #include_examples "does not contain trace", "/foo/bar", "default/environment"
    #     #include_examples "contains trace", "/oryx/crake", "default/environment"
    #   end
    # end
    #   # TODO: test being set at compile-time in a recipe
    #   # TODO: test being set at converge-time in a recipe

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
          'cookbooks' => { 'burgers-0.1.0' => AttributeTracingHelpers.canned_fixtures[:cookbooks]['burgers-0.1.0'] },
        }
        @node = AttributeTracingHelpers.chef_zero_client_run(@fixtures)
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


  describe "different-precedence handling, same file" do
    context "when loading from cookbook attributes" do
      #include_examples "contains cookbook trace", "/oryx/crake", "default", "cookbook", "atwood", "default.rb", "12"
      #include_examples "contains cookbook trace", "/oryx/crake", "override", "cookbook", "atwood", "default.rb", "13"
    end

    context "when loading from a role" do
      #include_examples "contains role/env trace", "/oryx/crake", "default", "role", "author"
      #include_examples "contains role/env trace", "/oryx/crake", "override", "role", "author"
    end

    context "when loading from an environment" do
      #include_examples "contains role/env trace", "/oryx/crake", "default", "environment", "postapocalyptic"
      #include_examples "contains role/env trace", "/oryx/crake", "override", "environment", "postapocalyptic"
    end
  end

  describe "mixed-precedence handling, different files" do
    #include_examples "contains cookbook trace", "/oryx/crake", "default", "cookbook", "atwood", "default.rb", "12"
    #include_examples "contains cookbook trace", "/oryx/crake", "override", "cookbook", "another", "default.rb", "2"
    #include_examples "contains role/env trace", "/oryx/crake", "default", "role", "author"
    #include_examples "contains role/env trace", "/oryx/crake", "override", "role", "poet"
    #include_examples "contains role/env trace", "/oryx/crake", "default", "environment", "postapocalyptic"
    #include_examples "contains role/env trace", "/oryx/crake", "override", "environment", "postapocalyptic"
  end

  # TODO: add actions? eg set, clear (eg override to [] or {}), append, arrayclobber, hashclobber?
  # TODO: test delete
  # TODO: consider writing low-level testing for VividMash mutators

end
