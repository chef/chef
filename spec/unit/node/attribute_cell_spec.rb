require 'spec_helper'

require 'chef/node/attribute_constants'
require 'chef/node/attribute_cell'

include Chef::Node::AttributeConstants

def initializer_has_arg_for(precedence_level)
  describe "for precdence level #{precedence_level}" do
    let(:cell) { Chef::Node::AttributeCell.new(precedence_level => 'foo') }

    it "initializer should pass args for #{precedence_level} correctly" do
      expect( cell.send(precedence_level) ).to eql('foo')
      expect( cell.instance_variable_get(:"@#{precedence_level}") ).to eql('foo')
    end

    COMPONENTS_AS_SYMBOLS.reject { |c| c == precedence_level }.each do |level|
      it "should set #{level} to nil" do
        expect( cell.send(level) ).to be nil
        expect( cell.instance_variable_get(:"@#{level}") ).to be nil
      end
    end
  end
end

def components_as_symbols_before(level)
  COMPONENTS_AS_SYMBOLS[1,COMPONENTS_AS_SYMBOLS.index(level)-1] || []
end

describe Chef::Node::AttributeCell do
  let(:cell) { Chef::Node::AttributeCell.new() }

  context "#initialize" do
    COMPONENTS_AS_SYMBOLS.each do |component|
      initializer_has_arg_for(component)
    end
  end

  context "individual setters" do
    let(:component) { Chef::Node::AttributeCell.new() }
    COMPONENTS_AS_SYMBOLS.each do |level|
      it "should set #{level} correctly" do
        expect( cell.send(:"#{level}=", 'foo') ).to eql('foo')
        expect( cell.send(level) ).to eql('foo')
        expect( cell.instance_variable_get(:"@#{level}") ).to eql('foo')
      end
    end
  end

  context "#is_a?" do
    COMPONENTS_AS_SYMBOLS.each do |level|
      it "is an Array when #{level} is higest precedence and is an Array" do
        components_as_symbols_before(level).each do |lower_level|
          cell.send(:"#{lower_level}=", {})
        end
        cell.send(:"#{level}=", [])
        expect(cell.send(:highest_precedence)).to eql([])
        expect(cell.is_a?(Array)).to be true
        expect(cell.is_a?(Hash)).to be false
        expect(cell.is_a?(Chef::Node::AttributeCell)).to be true
      end
    end

    COMPONENTS_AS_SYMBOLS.each do |level|
      it "is a Hash when #{level} is higest precedence and is a Hash" do
        components_as_symbols_before(level).each do |lower_level|
          cell.send(:"#{lower_level}=", [])
        end
        cell.send(:"#{level}=", {})
        expect(cell.send(:highest_precedence)).to eql({})
        expect(cell.is_a?(Array)).to be false
        expect(cell.is_a?(Hash)).to be true
        expect(cell.is_a?(Chef::Node::AttributeCell)).to be true
      end
    end
  end

  context "array merging helpers" do

    describe "#merged_default_zipped_array" do
      it "merges default level arrays" do
        cell.default = %w{a}
        cell.env_default = %w{b c}
        cell.role_default = %w{d}
        cell.force_default = %w{e f}
        expect(cell.send(:merged_default_zipped_array)).to eql([
          { level: :default, value: 'a' },
          { level: :env_default, value: 'b' },
          { level: :env_default, value: 'c' },
          { level: :role_default, value: 'd' },
          { level: :force_default, value: 'e' },
          { level: :force_default, value: 'f' },
        ])
      end

      it "returns nil when no default level is an Array" do
        cell.default = {}
        cell.env_default = :foo
        cell.role_default = 'bar'
        cell.force_default = 1234
        expect(cell.send(:merged_default_zipped_array)).to be nil
      end
    end

    describe "#merged_override_zipped_array" do
      it "merges override level arrays" do
        cell.override = %w{a}
        cell.role_override = %w{d}
        cell.env_override = %w{b c}
        cell.force_override = %w{e f}
        expect(cell.send(:merged_override_zipped_array)).to eql([
          { level: :override, value: 'a' },
          { level: :role_override, value: 'd' },
          { level: :env_override, value: 'b' },
          { level: :env_override, value: 'c' },
          { level: :force_override, value: 'e' },
          { level: :force_override, value: 'f' },
        ])
      end

      it "returns nil when no override level is an Array" do
        cell.override = {}
        cell.env_override = :foo
        cell.role_override = 'bar'
        cell.force_override = 1234
        expect(cell.send(:merged_override_zipped_array)).to be nil
      end
    end

    describe "#merged_normal_zipped_array" do
      it "returns nil when normal is not an Array" do
        cell.normal = {}
        expect(cell.send(:merged_normal_zipped_array)).to be nil
        cell.normal = :foo
        expect(cell.send(:merged_normal_zipped_array)).to be nil
        cell.normal = 'bar'
        expect(cell.send(:merged_normal_zipped_array)).to be nil
        cell.normal = 1234
        expect(cell.send(:merged_normal_zipped_array)).to be nil
      end

      it "returns the array with the correct annotated level" do
        cell.normal = %w{a b c}
        expect(cell.send(:merged_normal_zipped_array)).to eql([
          {:level=>:normal, :value=>"a"},
          {:level=>:normal, :value=>"b"},
          {:level=>:normal, :value=>"c"},
        ])
      end
    end

    describe "#merged_automatic_zipped_array" do
      it "returns nil when automatic is not an Array" do
        cell.automatic = {}
        expect(cell.send(:merged_automatic_zipped_array)).to be nil
        cell.automatic = :foo
        expect(cell.send(:merged_automatic_zipped_array)).to be nil
        cell.automatic = 'bar'
        expect(cell.send(:merged_automatic_zipped_array)).to be nil
        cell.automatic = 1234
        expect(cell.send(:merged_automatic_zipped_array)).to be nil
      end

      it "returns the array with the correct annotated level" do
        cell.automatic = %w{a b c}
        expect(cell.send(:merged_automatic_zipped_array)).to eql([
          {:level=>:automatic, :value=>"a"},
          {:level=>:automatic, :value=>"b"},
          {:level=>:automatic, :value=>"c"},
        ])
      end
    end
  end

  describe "#[] on Hash-like" do
    it "when multiple precedence levels have the key and contain containers, maintains them all" do
      cell.default = { 'foo' => [ 'foo' ] }
      cell.normal = { 'foo' => [ 'bar' ] }
      cell.override = { 'foo' => [ 'baz' ] }
      cell.automatic = { 'foo' => [ 'qux' ] }
      expect( cell['foo'].default ).to eql( [ 'foo' ] )
      expect( cell['foo'].normal ).to eql( [ 'bar' ] )
      expect( cell['foo'].override ).to eql( [ 'baz' ] )
      expect( cell['foo'].automatic ).to eql( [ 'qux' ] )
    end

    it "when the highest precedence level is a simple object, returns it" do
      cell.default = { 'foo' => [ 'foo' ] }
      cell.normal = { 'foo' => [ 'bar' ] }
      cell.override = { 'foo' => [ 'baz' ] }
      cell.automatic = { 'foo' => 'bar' }
      expect( cell['foo'] ).to eql( 'bar' )
      expect( cell['foo'] ).not_to be_a(Chef::Node::AttributeCell)
    end

    it "when it doesn't exist" do
      cell.default = { 'foo' => 'bar' }
      expect( cell['baz'] ).to be nil
    end

    it "when you wander way off the end" do
      # this is a method trainwreck error, we can't fix this
      cell.default = { 'foo' => 'bar' }
      expect{ cell['baz']['qux'] }.to raise_error(NoMethodError)
    end

    it "when a lower precedence level has the key it finds it" do
      cell.default = { 'foo' => 'bar' }
      cell.override = { 'baz' => 'qux' }
      expect( cell['foo'] ).to eql('bar')
    end
  end

  describe "#[] on Array-like" do
    it "preserves precedence order when merging default" do
      cell.default = [ 1 ]
      cell.env_default = [ 0 ]
      cell.role_default = [ 2 ]
      cell.force_default = [ 3 ]
      expect(cell[0]).to eql(1)
      expect(cell[1]).to eql(0)
      expect(cell[2]).to eql(2)
      expect(cell[3]).to eql(3)
    end

    it "preserves precedence order when merging overrides" do
      cell.override = [ 1 ]
      cell.role_override = [ 2 ]
      cell.env_override = [ 0 ]
      cell.force_override = [ 3 ]
      expect(cell[0]).to eql(1)
      expect(cell[1]).to eql(2)
      expect(cell[2]).to eql(0)
      expect(cell[3]).to eql(3)
    end

    it "does not merge between default and normal" do
      cell.default = [ 1 ]
      cell.role_default = [ 2 ]
      cell.env_default = [ 3 ]
      cell.force_default = [ 4 ]
      cell.normal = [ 5 ]
      expect(cell[0]).to eql(5)
    end

    it "does not merge between default, normal and override" do
      cell.default = [ 1 ]
      cell.role_default = [ 2 ]
      cell.env_default = [ 3 ]
      cell.force_default = [ 4 ]
      cell.normal = [ 5 ]
      cell.override = [ 6 ]
      cell.role_override = [ 7 ]
      cell.env_override = [ 8 ]
      cell.force_override = [ 9 ]
      expect(cell[0]).to eql(6)
      expect(cell[1]).to eql(7)
      expect(cell[2]).to eql(8)
      expect(cell[3]).to eql(9)
    end

    it "automatic takes precedence" do
      cell.default = [ 1 ]
      cell.role_default = [ 2 ]
      cell.env_default = [ 3 ]
      cell.force_default = [ 4 ]
      cell.normal = [ 5 ]
      cell.override = [ 6 ]
      cell.role_override = [ 7 ]
      cell.env_override = [ 8 ]
      cell.force_override = [ 9 ]
      cell.automatic = [ 10 ]
      expect(cell[0]).to eql(10)
    end

    it "returns bare objects when the result is a bare object" do
      cell.default = [ 0 ]
      expect(cell[0]).not_to be_a(Chef::Node::AttributeCell)
    end

    it "returns decorated objects when the result is a Hash" do
      cell.default = [ { "foo" => "bar" } ]
      expect(cell[0]).to be_a(Chef::Node::AttributeCell)
    end

    it "returns decorated objects when the result is a Array" do
      cell.default = [ [1, 2, 3] ]
      expect(cell[0]).to be_a(Chef::Node::AttributeCell)
    end
  end

  describe "#each as a Hash" do
    COMPONENTS_AS_SYMBOLS.each do |component|
      it "returns a single #{component} value" do
        cell.send(:"#{component}=", { 'foo' => 'bar' })
        seen = {}
        cell.each { |key, value| seen[key] = value }
        expect(seen).to eql({ 'foo' => 'bar' })
      end

      it "returns the merged hash as is return value" do
        cell.send(:"#{component}=", { 'foo' => 'bar' })
        expect(cell.each { |key, value| nil }).to eql({ 'foo' => 'bar' })
      end
    end
  end

  describe "#map" do
    COMPONENTS_AS_SYMBOLS.each do |component|
      it "returns a single #{component} value" do
        cell.send(:"#{component}=", { 'port' => [ 80 ] })
        expect( cell['port'].send(:highest_precedence_zipped_array) ).to eql([
          {level: component, value: 80}
        ])
        expect( cell['port'].send(:highest_precedence_array) ).to eql([80])
        expect( cell['port'].map { |p| p } ).to eql([80])
      end
    end

    it "merges across defaults" do
      cell.default = { 'port' => [ 80 ] }
      cell.env_default = { 'port' => [ 443 ] }
      cell.role_default = { 'port' => [ 8080 ] }
      cell.force_default = { 'port' => [ 8443 ] }
      expect( cell['port'].send(:merged_default_zipped_array) ).to eql([
        {:level=>:default, :value=>80},
        {:level=>:env_default, :value=>443},
        {:level=>:role_default, :value=>8080},
        {:level=>:force_default, :value=>8443},
      ])
      expect( cell['port'].map { |p| p } ).to eql([80, 443, 8080, 8443])
    end

    it "merges across overrides" do
      cell.override = { 'port' => [ 80 ] }
      cell.role_override = { 'port' => [ 8080 ] }
      cell.env_override = { 'port' => [ 443 ] }
      cell.force_override = { 'port' => [ 8443 ] }
      expect( cell['port'].send(:merged_override_zipped_array) ).to eql([
        {:level=>:override, :value=>80},
        {:level=>:role_override, :value=>8080},
        {:level=>:env_override, :value=>443},
        {:level=>:force_override, :value=>8443}
      ])
      expect( cell['port'].map { |p| p } ).to eql([80, 8080, 443, 8443])
    end
  end

  describe "#method_missing as an Array" do
    it "has a #length method" do
      cell.default = [ 1 ]
      expect( cell.length ).to eql(1)
      expect( cell.respond_to?(:length) ).to be true
    end

    it "has a #zip method" do
      cell.default = [ 1 ]
      cell.role_default = [ 2, 3 ]
      expect( cell.zip([4,5,6]) ).to eql([[1, 4], [2, 5], [3, 6]])
      expect( cell.respond_to?(:zip) ).to be true
    end

    # it has a bunch more methods as well, but this should prove it works

    it "raises a useful exception when calling a method that does not exist" do
      cell.default = [ 1 ]
      expect{ cell.supercalifragilisticexpealidocious }.to raise_error(NoMethodError)
      expect( cell.respond_to?(:supercalifragilisticexpealidocious) ).to be false
    end
  end

  describe "#method_missing as a non-container" do
    it "works even though maybe it should not?" do
      cell.default = 1
      expect( cell.odd? ).to eql(true)
      expect( cell.respond_to?(:odd?) ).to be true
    end
  end

  describe "#eql?" do
    it "works" do
      cell.default = [1, 2, 3]
      expect(cell.eql?([1,2,3])).to be true
      expect(cell).to eql([1,2,3])
    end

    it "also works" do
      cell.default = { 'a' => 'b' }
      expect(cell.eql?({ 'a' => 'b' })).to be true
      expect(cell).to eql( { 'a' => 'b' } )
    end
  end

  describe "#==" do
  end

  describe "#===" do
  end

  describe "converting values" do
    it "works" do
      # need some kind of convert_value() that recursively injests decorators and converts to
      # underlying bare hash/array values.  Cells are the lowest level and should not decorate
      # decorators (at least i don't think so right now).
      pending "right now it does not work"
      ports = Chef::Node::AttributeCell.new(default: [ 80, 443 ])
      cell.default = { 'ports' => ports }
      expect(cell.default['ports']).not_to be_a(Chef::Node::AttributeCell)
    end
  end

  describe "immutability" do
    context "when the cell is an Array" do
      before do
        cell.default = [ 0 ]
      end

      it "raises error on #clear" do
        expect { cell.clear }.to raise_error
      end

      it "raises an error on #[]=" do
        expect { cell[0] = 2 }.to raise_error
      end

      it "returns frozen values" do
        expect( cell[0] ).to be_frozen
      end

      it "returns frozen values in #each" do
        ret = false
        cell.each { |i| ret = i.frozen? }
        expect( ret ).to be true
      end

      it "returns a deep-dup'd mutable array from #to_a" do
        cell.default = [[[0]]]
        cell.to_a[0][0][0] = 1
        expect(cell[0][0][0]).to eql(0)
      end
    end

    context "when the cell is a Hash" do
      before do
        cell.default = { 'foo' => 'bar' }
      end

      it "raises error on #clear" do
        expect { cell.clear }.to raise_error
      end

      it "raises an error on #[]=" do
        expect { cell['baz'] = 'qux' }.to raise_error
      end

      it "returns frozen values" do
        expect( cell['foo'] ).to be_frozen
      end

      it "returns frozen keys in #each" do
        ret = false
        cell.each { |k, v| ret = k.frozen? }
        expect( ret ).to be true
      end

      it "returns frozen values in #each" do
        ret = false
        cell.each { |k, v| ret = v.frozen? }
        expect( ret ).to be true
      end

      it "returns a deep-dup'd mutable hash from #to_hash" do
        cell.default = { 'foo' => { 'bar' => { 'baz' => 'qux' }}}
        cell.to_hash['foo']['bar']['baz'] = 'quux'
        expect(cell['foo']['bar']['baz']).to eql('qux')
      end
    end
  end
end
