require "support/shared/integration/integration_helper"

describe "Chef::Resource.property" do
  include IntegrationSupport

  module Namer
    @i = 0
    def self.next_resource_name
      "chef_resource_property_spec_#{@i += 1}"
    end

    def self.reset_index
      @current_index = 0
    end

    def self.current_index
      @current_index
    end

    def self.next_index
      @current_index += 1
    end
  end

  def lazy(&block)
    Chef::DelayedEvaluator.new(&block)
  end

  before do
    Namer.reset_index
  end

  def self.new_resource_name
    Namer.next_resource_name
  end

  let(:resource_class) do
    new_resource_name = self.class.new_resource_name
    Class.new(Chef::Resource) do
      resource_name new_resource_name
      def next_index
        Namer.next_index
      end
    end
  end

  let(:resource) do
    resource_class.new("blah")
  end

  def self.english_join(values)
    return "<nothing>" if values.size == 0
    return values[0].inspect if values.size == 1

    "#{values[0..-2].map(&:inspect).join(", ")} and #{values[-1].inspect}"
  end

  def self.with_property(*properties, &block)
    tags_index = properties.find_index { |p| !p.is_a?(String) }
    if tags_index
      properties, tags = properties[0..tags_index - 1], properties[tags_index..-1]
    else
      tags = []
    end
    if properties.size == 1
      description = "With property #{properties.first}"
    else
      description = "With properties #{english_join(properties.map { |property| (property.inspect).to_s })}"
    end
    context description, *tags do
      before do
        properties.each do |property_str|
          resource_class.class_eval("property #{property_str}", __FILE__, __LINE__)
        end
      end
      instance_eval(&block)
    end
  end

  # Basic properties
  with_property ":bare_property" do
    it "can be set" do
      expect(resource.bare_property 10).to eq 10
      expect(resource.bare_property).to eq 10
    end
    it "nil does a set" do
      expect(resource.bare_property 10).to eq 10
      expect(resource.bare_property nil).to eq nil
      expect(resource.bare_property).to eq nil
    end
    it "can be updated" do
      expect(resource.bare_property 10).to eq 10
      expect(resource.bare_property 20).to eq 20
      expect(resource.bare_property).to eq 20
    end
    it "can be set with =" do
      expect(resource.bare_property = 10).to eq 10
      expect(resource.bare_property).to eq 10
    end
    it "can be set to nil with =" do
      expect(resource.bare_property 10).to eq 10
      expect(resource.bare_property = nil).to be_nil
      expect(resource.bare_property).to be_nil
    end
    it "can be updated with =" do
      expect(resource.bare_property 10).to eq 10
      expect(resource.bare_property = 20).to eq 20
      expect(resource.bare_property).to eq 20
    end
  end

  with_property ":Straße" do
    it "properties with UTF-8 in their name work" do
      expect(resource.Straße).to eql(nil) # rubocop: disable Naming/AsciiIdentifiers
      expect(resource.Straße "foo").to eql("foo") # rubocop: disable Naming/AsciiIdentifiers
      expect(resource.Straße).to eql("foo") # rubocop: disable Naming/AsciiIdentifiers
      expect(resource.Straße = "bar").to eql("bar") # rubocop: disable Naming/AsciiIdentifiers
      expect(resource.Straße).to eql("bar") # rubocop: disable Naming/AsciiIdentifiers
    end
  end

  context "deprecated properties" do
    it "does not create a deprecation warning on definition" do
      expect { resource_class.class_eval { property :x, String, deprecated: 10 } }.not_to raise_error
    end

    with_property ":x, deprecated: 'a deprecated property'" do
      it "deprecated properties emit a deprecation warning" do
        expect(Chef).to receive(:deprecated).with(:property, "a deprecated property")
        expect(resource.x 10).to eq 10
      end
    end
  end

  with_property ":x, name_property: true" do
    context "and subclass" do
      let(:subresource_class) do
        new_resource_name = self.class.new_resource_name
        Class.new(resource_class) do
          resource_name new_resource_name
        end
      end
      let(:subresource) do
        subresource_class.new("blah")
      end

      context "with property :x on the subclass" do
        before do
          subresource_class.class_eval do
            property :x
          end
        end

        it "x is still name_property" do
          expect(subresource.x).to eq "blah"
        end
      end

      context "with property :x, name_attribute: false on the subclass" do
        before do
          subresource_class.class_eval do
            property :x, name_attribute: false
          end
        end

        it "x is no longer name_property" do
          expect(subresource.x).to be_nil
        end
      end

      context "with property :x, default: 10 on the subclass" do
        before do
          subresource_class.class_eval do
            property :x, default: 10
          end
        end

        it "x is no longer name_property" do
          expect(subresource.x).to eq(10)
        end
      end
    end
  end

  with_property ":x, Integer" do
    context "and subclass" do
      let(:subresource_class) do
        new_resource_name = self.class.new_resource_name
        Class.new(resource_class) do
          resource_name new_resource_name
        end
      end
      let(:subresource) do
        subresource_class.new("blah")
      end

      it "x is inherited" do
        expect(subresource.x 10).to eq 10
        expect(subresource.x).to eq 10
        expect(subresource.x = 20).to eq 20
        expect(subresource.x).to eq 20
        expect(subresource_class.properties[:x]).not_to be_nil
      end

      it "x's validation is inherited" do
        expect { subresource.x "ohno" }.to raise_error Chef::Exceptions::ValidationFailed
      end

      context "with property :y on the subclass" do
        before do
          subresource_class.class_eval do
            property :y
          end
        end

        it "x is still there" do
          expect(subresource.x 10).to eq 10
          expect(subresource.x).to eq 10
          expect(subresource.x = 20).to eq 20
          expect(subresource.x).to eq 20
          expect(subresource_class.properties[:x]).not_to be_nil
        end
        it "y is there" do
          expect(subresource.y 10).to eq 10
          expect(subresource.y).to eq 10
          expect(subresource.y = 20).to eq 20
          expect(subresource.y).to eq 20
          expect(subresource_class.properties[:y]).not_to be_nil
        end
        it "y is not on the superclass" do
          expect { resource_class.y 10 }.to raise_error NoMethodError
          expect(resource_class.properties[:y]).to be_nil
        end
      end

      context "with property :x on the subclass" do
        before do
          subresource_class.class_eval do
            property :x
          end
        end

        it "x is still there" do
          expect(subresource.x 10).to eq 10
          expect(subresource.x).to eq 10
          expect(subresource.x = 20).to eq 20
          expect(subresource.x).to eq 20
          expect(subresource_class.properties[:x]).not_to be_nil
          expect(subresource_class.properties[:x]).not_to eq resource_class.properties[:x]
        end

        it "x's validation is inherited" do
          expect { subresource.x "ohno" }.to raise_error Chef::Exceptions::ValidationFailed
        end
      end

      context "with property :x, default: 80 on the subclass" do
        before do
          subresource_class.class_eval do
            property :x, default: 80
          end
        end

        it "x is still there" do
          expect(subresource.x 10).to eq 10
          expect(subresource.x).to eq 10
          expect(subresource.x = 20).to eq 20
          expect(subresource.x).to eq 20
          expect(subresource_class.properties[:x]).not_to be_nil
          expect(subresource_class.properties[:x]).not_to eq resource_class.properties[:x]
        end

        it "x defaults to 80" do
          expect(subresource.x).to eq 80
        end

        it "x's validation is inherited" do
          expect { subresource.x "ohno" }.to raise_error Chef::Exceptions::ValidationFailed
        end
      end

      context "with property :x, String on the subclass" do
        before do
          subresource_class.class_eval do
            property :x, String
          end
        end

        it "x is still there" do
          expect(subresource.x "10").to eq "10"
          expect(subresource.x).to eq "10"
          expect(subresource.x = "20").to eq "20"
          expect(subresource.x).to eq "20"
          expect(subresource_class.properties[:x]).not_to be_nil
          expect(subresource_class.properties[:x]).not_to eq resource_class.properties[:x]
        end

        it "x's validation is overwritten" do
          expect { subresource.x 10 }.to raise_error Chef::Exceptions::ValidationFailed
          expect(subresource.x "ohno").to eq "ohno"
          expect(subresource.x).to eq "ohno"
        end

        it "the superclass's validation for x is still there" do
          expect { resource.x "ohno" }.to raise_error Chef::Exceptions::ValidationFailed
          expect(resource.x 10).to eq 10
          expect(resource.x).to eq 10
        end
      end
    end
  end

  context "Chef::Resource::Property#reset_property" do
    it "when a resource is newly created, reset_property(:name) sets property to nil" do
      expect(resource.property_is_set?(:name)).to be_truthy
      resource.reset_property(:name)
      expect(resource.property_is_set?(:name)).to be_falsey
      expect { resource.name }.to raise_error Chef::Exceptions::ValidationFailed
    end

    it "when referencing an undefined property, reset_property(:x) raises an error" do
      expect { resource.reset_property(:x) }.to raise_error(ArgumentError)
    end

    with_property ":x" do
      it "when the resource is newly created, reset_property(:x) does nothing" do
        expect(resource.property_is_set?(:x)).to be_falsey
        resource.reset_property(:x)
        expect(resource.property_is_set?(:x)).to be_falsey
        expect(resource.x).to be_nil
      end
      it "when x is set, reset_property resets it" do
        resource.x 10
        expect(resource.property_is_set?(:x)).to be_truthy
        resource.reset_property(:x)
        expect(resource.property_is_set?(:x)).to be_falsey
        expect(resource.x).to be_nil
      end
    end

    with_property ":x, Integer" do
      it "when the resource is newly created, reset_property(:x) does nothing" do
        expect(resource.property_is_set?(:x)).to be_falsey
        resource.reset_property(:x)
        expect(resource.property_is_set?(:x)).to be_falsey
        expect(resource.x).to be_nil
      end
      it "when x is set, reset_property resets it even though `nil` is technically invalid" do
        resource.x 10
        expect(resource.property_is_set?(:x)).to be_truthy
        resource.reset_property(:x)
        expect(resource.property_is_set?(:x)).to be_falsey
        expect(resource.x).to be_nil
      end
    end

    with_property ":x, default: 10" do
      it "when the resource is newly created, reset_property(:x) does nothing" do
        expect(resource.property_is_set?(:x)).to be_falsey
        resource.reset_property(:x)
        expect(resource.property_is_set?(:x)).to be_falsey
        expect(resource.x).to eq 10
      end
      it "when x is set, reset_property resets it and it returns the default" do
        resource.x 20
        resource.reset_property(:x)
        expect(resource.property_is_set?(:x)).to be_falsey
        expect(resource.x).to eq 10
      end
    end

    with_property ":x, default: lazy { 10 }" do
      it "when the resource is newly created, reset_property(:x) does nothing" do
        expect(resource.property_is_set?(:x)).to be_falsey
        resource.reset_property(:x)
        expect(resource.property_is_set?(:x)).to be_falsey
        expect(resource.x).to eq 10
      end
      it "when x is set, reset_property resets it and it returns the default" do
        resource.x 20
        resource.reset_property(:x)
        expect(resource.property_is_set?(:x)).to be_falsey
        expect(resource.x).to eq 10
      end
    end
  end

  context "Chef::Resource::Property#property_is_set?" do
    it "when a resource is newly created, property_is_set?(:name) is true" do
      expect(resource.property_is_set?(:name)).to be_truthy
    end

    it "when referencing an undefined property, property_is_set?(:x) raises an error" do
      expect { resource.property_is_set?(:x) }.to raise_error(ArgumentError)
    end

    with_property ":x" do
      it "when the resource is newly created, property_is_set?(:x) is false" do
        expect(resource.property_is_set?(:x)).to be_falsey
      end
      it "when x is set, property_is_set?(:x) is true" do
        resource.x 10
        expect(resource.property_is_set?(:x)).to be_truthy
      end
      it "when x is set with =, property_is_set?(:x) is true" do
        resource.x = 10
        expect(resource.property_is_set?(:x)).to be_truthy
      end
      it "when x is set to a lazy value, property_is_set?(:x) is true" do
        resource.x lazy { 10 }
        expect(resource.property_is_set?(:x)).to be_truthy
      end
      it "when x is retrieved, property_is_set?(:x) is false" do
        resource.x
        expect(resource.property_is_set?(:x)).to be_falsey
      end
    end

    with_property ":x, default: 10" do
      it "when the resource is newly created, property_is_set?(:x) is false" do
        expect(resource.property_is_set?(:x)).to be_falsey
      end
      it "when x is set, property_is_set?(:x) is true" do
        resource.x 10
        expect(resource.property_is_set?(:x)).to be_truthy
      end
      it "when x is set with =, property_is_set?(:x) is true" do
        resource.x = 10
        expect(resource.property_is_set?(:x)).to be_truthy
      end
      it "when x is set to a lazy value, property_is_set?(:x) is true" do
        resource.x lazy { 10 }
        expect(resource.property_is_set?(:x)).to be_truthy
      end
      it "when x is retrieved, property_is_set?(:x) is false" do
        resource.x
        expect(resource.property_is_set?(:x)).to be_falsey
      end
    end

    with_property ":x, default: nil" do
      it "when the resource is newly created, property_is_set?(:x) is false" do
        expect(resource.property_is_set?(:x)).to be_falsey
      end
      it "when x is set, property_is_set?(:x) is true" do
        resource.x 10
        expect(resource.property_is_set?(:x)).to be_truthy
      end
      it "when x is set with =, property_is_set?(:x) is true" do
        resource.x = 10
        expect(resource.property_is_set?(:x)).to be_truthy
      end
      it "when x is set to a lazy value, property_is_set?(:x) is true" do
        resource.x lazy { 10 }
        expect(resource.property_is_set?(:x)).to be_truthy
      end
      it "when x is retrieved, property_is_set?(:x) is false" do
        resource.x
        expect(resource.property_is_set?(:x)).to be_falsey
      end
    end

    with_property ":x, default: lazy { 10 }" do
      it "when the resource is newly created, property_is_set?(:x) is false" do
        expect(resource.property_is_set?(:x)).to be_falsey
      end
      it "when x is set, property_is_set?(:x) is true" do
        resource.x 10
        expect(resource.property_is_set?(:x)).to be_truthy
      end
      it "when x is set with =, property_is_set?(:x) is true" do
        resource.x = 10
        expect(resource.property_is_set?(:x)).to be_truthy
      end
      it "when x is retrieved, property_is_set?(:x) is false" do
        resource.x
        expect(resource.property_is_set?(:x)).to be_falsey
      end
    end
  end

  context "Chef::Resource::Property#default" do
    with_property ":x, default: 10" do
      it "when x is set, it returns its value" do
        expect(resource.x 20).to eq 20
        expect(resource.property_is_set?(:x)).to be_truthy
        expect(resource.x).to eq 20
      end
      it "when x is not set, it returns 10" do
        expect(resource.x).to eq 10
      end
      it "when x is not set, it is not included in state" do
        expect(resource.state_for_resource_reporter).to eq({})
      end
      it "when x is set to nil, it returns nil" do
        resource.instance_eval { @x = nil }
        expect(resource.x).to be_nil
      end

      context "With a subclass" do
        let(:subresource_class) do
          new_resource_name = self.class.new_resource_name
          Class.new(resource_class) do
            resource_name new_resource_name
          end
        end
        let(:subresource) { subresource_class.new("blah") }
        it "The default is inherited" do
          expect(subresource.x).to eq 10
        end
      end
    end

    with_property ":x, default: 10, identity: true" do
      it "when x is not set, it is included in identity" do
        expect(resource.identity).to eq(10)
      end
    end

    with_property ":x, default: 1, identity: true", ":y, default: 2, identity: true" do
      it "when x is not set, it is still included in identity" do
        resource.y 20
        expect(resource.identity).to eq(x: 1, y: 20)
      end
    end

    with_property ":x, default: nil" do
      it "when x is not set, it returns nil" do
        expect(resource.x).to be_nil
      end
    end

    with_property ":x" do
      it "when x is not set, it returns nil" do
        expect(resource.x).to be_nil
      end
    end

    context "string default" do
      with_property ":x, default: ''" do
        it "when x is not set, it returns ''" do
          expect(resource.x).to eq ""
        end
        it "setting x does not mutate the default" do
          expect(resource.x).to eq ""
          resource.x << "foo"
          expect(resource.x).to eq "foo"
          expect(resource_class.new("other").x).to eq ""
        end
      end

      with_property ":x, default: lazy { '' }" do
        it "setting x does not mutate the default" do
          expect(resource.x).to eq ""
          resource.x << "foo"
          expect(resource.x).to eq "foo"
          expect(resource_class.new("other").x).to eq ""
        end
      end
    end

    context "hash default" do
      with_property ":x, default: {}" do
        it "when x is not set, it returns {}" do
          expect(resource.x).to eq({})
        end
        it "setting x does not mutate the default" do
          expect(resource.x).to eq({})
          resource.x["plants"] = "zombies"
          expect(resource.x).to eq({ "plants" => "zombies" })
          expect(resource_class.new("other").x).to eq({})
        end
        it "Multiple instances of x receive different values" do
          expect(resource.x.object_id).not_to eq(resource_class.new("blah2").x.object_id)
        end
      end

      with_property ":x, default: lazy { {} }" do
        it "when x is not set, it returns {}" do
          expect(resource.x).to eq({})
        end
        it "The value is the same each time it is called" do
          value = resource.x
          expect(value).to eq({})
          expect(resource.x.object_id).to eq(value.object_id)
        end
        it "Multiple instances of x receive different values" do
          expect(resource.x.object_id).not_to eq(resource_class.new("blah2").x.object_id)
        end
      end
    end

    context "complex, nested default" do
      with_property ":x, default: [{foo: 'bar'}]" do
        it "when x is not set, it returns [{foo: 'bar'}]" do
          expect(resource.x).to eq([{ foo: "bar" }])
        end
        it "setting x does not mutate the default" do
          expect(resource.x).to eq([{ foo: "bar" }])
          resource.x[0][:foo] << "baz"
          expect(resource.x).to eq([{ foo: "barbaz" }])
          expect(resource_class.new("other").x).to eq([{ foo: "bar" }])
        end
        it "Multiple instances of x receive different values" do
          expect(resource.x.object_id).not_to eq(resource_class.new("blah2").x.object_id)
        end
      end
    end

    context "with a class with 'blah' as both class and instance methods" do
      before do
        resource_class.class_eval do
          def self.blah
            "class"
          end

          def blah
            "#{name}#{next_index}"
          end
        end
      end

      with_property ":x, default: lazy { blah }" do
        it "x is run in context of the instance" do
          expect(resource.x).to eq "blah1"
        end
        it "x is run in the context of each instance it is run in" do
          expect(resource.x).to eq "blah1"
          expect(resource_class.new("another").x).to eq "another2"
        end
      end

      with_property ':x, default: lazy { |x| "#{blah}#{x.blah}" }' do
        it "x is run in context of the class (where it was defined) and passed the instance" do
          expect(resource.x).to eq "classblah1"
        end
        it "x is passed the value of each instance it is run in" do
          expect(resource.x).to eq "classblah1"
          expect(resource_class.new("another").x).to eq "classanother2"
        end
      end
    end

    context "validation of defaults" do
      it "When a class is declared with property :x, String, default: 10, it immediately fails validation" do
        expect { resource_class.class_eval { property :x, String, default: 10 } }.to raise_error Chef::Exceptions::ValidationFailed
      end

      with_property ":x, String, default: lazy { Namer.next_index }" do
        it "when the resource is created, no error is raised" do
          resource
        end
        it "when x is set, no error is raised" do
          expect(resource.x "hi").to eq "hi"
          expect(resource.x).to eq "hi"
        end
        it "when x is retrieved, it fails validation" do
          expect { resource.x }.to raise_error Chef::Exceptions::ValidationFailed
          expect(Namer.current_index).to eq 1
        end
      end

      with_property ":x, default: lazy { Namer.next_index.to_s }, is: proc { |v| Namer.next_index; true }" do
        it "coercion and validation is only run the first time" do
          expect(resource.x).to eq "1"
          expect(Namer.current_index).to eq 2
          expect(resource.x).to eq "1"
          expect(Namer.current_index).to eq 2
        end
      end

      with_property ":x, default: lazy { Namer.next_index.to_s.freeze }, is: proc { |v| Namer.next_index; true }" do
        it "coercion and validation is run each time" do
          expect(resource.x).to eq "1"
          expect(Namer.current_index).to eq 2
          expect(resource.x).to eq "3"
          expect(Namer.current_index).to eq 4
        end
      end
    end

    context "coercion of defaults" do
      # Frozen default, non-frozen coerce
      with_property ':x, coerce: proc { |v| "#{v}#{next_index}" }, default: 10' do
        it "when the resource is created, the proc is not yet run" do
          resource
          expect(Namer.current_index).to eq 0
        end
        it "when x is set, coercion is run" do
          expect(resource.x "hi").to eq "hi1"
          expect(resource.x).to eq "hi1"
          expect(Namer.current_index).to eq 1
        end
        it "when x is retrieved, coercion is run exactly once" do
          expect(resource.x).to eq "101"
          expect(resource.x).to eq "101"
          expect(Namer.current_index).to eq 1
        end
      end

      # Frozen default, frozen coerce
      with_property ':x, coerce: proc { |v| "#{v}#{next_index}".freeze }, default: 10' do
        it "when the resource is created, the proc is not yet run" do
          resource
          expect(Namer.current_index).to eq 0
        end
        it "when x is set, coercion is run" do
          expect(resource.x "hi").to eq "hi1"
          expect(resource.x).to eq "hi1"
          expect(Namer.current_index).to eq 1
        end
        it "when x is retrieved, coercion is run exactly once" do
          expect(resource.x).to eq "101"
          expect(resource.x).to eq "101"
          expect(Namer.current_index).to eq 1
        end
      end

      # Frozen lazy default, non-frozen coerce
      with_property ':x, coerce: proc { |v| "#{v}#{next_index}" }, default: lazy { 10 }' do
        it "when the resource is created, the proc is not yet run" do
          resource
          expect(Namer.current_index).to eq 0
        end
        it "when x is set, coercion is run" do
          expect(resource.x "hi").to eq "hi1"
          expect(resource.x).to eq "hi1"
          expect(Namer.current_index).to eq 1
        end
        it "when x is retrieved, coercion is run exactly once" do
          expect(resource.x).to eq "101"
          expect(resource.x).to eq "101"
          expect(Namer.current_index).to eq 1
        end
      end

      # Non-frozen lazy default, frozen coerce
      with_property ':x, coerce: proc { |v| "#{v}#{next_index}".freeze }, default: lazy { "10" }' do
        it "when the resource is created, the proc is not yet run" do
          resource
          expect(Namer.current_index).to eq 0
        end
        it "when x is set, coercion is run" do
          expect(resource.x "hi").to eq "hi1"
          expect(resource.x).to eq "hi1"
          expect(Namer.current_index).to eq 1
        end
        it "when x is retrieved, coercion is run each time" do
          expect(resource.x).to eq "101"
          expect(resource.x).to eq "102"
          expect(Namer.current_index).to eq 2
        end
      end

      with_property ':x, proc { |v| Namer.next_index; true }, coerce: proc { |v| "#{v}#{next_index}" }, default: lazy { 10 }' do
        it "coercion and validation is only run the first time x is retrieved" do
          expect(Namer.current_index).to eq 0
          expect(resource.x).to eq "101"
          expect(Namer.current_index).to eq 2
          expect(resource.x).to eq "101"
          expect(Namer.current_index).to eq 2
        end
      end

      context "validation and coercion of defaults" do
        with_property ':x, String, coerce: proc { |v| "#{v}#{next_index}" }, default: 10' do
          it "when x is retrieved, it is coerced before validating and passes" do
            expect(resource.x).to eq "101"
          end
        end
        with_property ':x, Integer, coerce: proc { |v| "#{v}#{next_index}" }, default: 10' do
          it "when x is retrieved, it is coerced and fails validation" do
            expect { resource.x }.to raise_error Chef::Exceptions::ValidationFailed
          end
        end
        with_property ':x, String, coerce: proc { |v| "#{v}#{next_index}" }, default: lazy { 10 }' do
          it "when x is retrieved, it is coerced before validating and passes" do
            expect(resource.x).to eq "101"
          end
        end
        with_property ':x, Integer, coerce: proc { |v| "#{v}#{next_index}" }, default: lazy { 10 }' do
          it "when x is retrieved, it is coerced and fails validation" do
            expect { resource.x }.to raise_error Chef::Exceptions::ValidationFailed
          end
        end
        with_property ':x, proc { |v| Namer.next_index; true }, coerce: proc { |v| "#{v}#{next_index}" }, default: lazy { 10 }' do
          it "coercion is only run the first time x is retrieved, and validation is run" do
            expect(Namer.current_index).to eq 0
            expect(resource.x).to eq "101"
            expect(Namer.current_index).to eq 2
            expect(resource.x).to eq "101"
            expect(Namer.current_index).to eq 2
          end
        end
      end
    end
  end

  context "Chef::Resource#lazy" do
    with_property ":x" do
      it "setting x to a lazy value does not run it immediately" do
        resource.x lazy { Namer.next_index }
        expect(Namer.current_index).to eq 0
      end
      it "you can set x to a lazy value in the instance" do
        resource.instance_eval do
          x lazy { Namer.next_index }
        end
        expect(resource.x).to eq 1
        expect(Namer.current_index).to eq 1
      end
      it "retrieving a lazy value pops it open" do
        resource.x lazy { Namer.next_index }
        expect(resource.x).to eq 1
        expect(Namer.current_index).to eq 1
      end
      it "retrieving a lazy value twice evaluates it twice" do
        resource.x lazy { Namer.next_index }
        expect(resource.x).to eq 1
        expect(resource.x).to eq 2
        expect(Namer.current_index).to eq 2
      end
      it "setting the same lazy value on two different instances runs it on each instances" do
        resource2 = resource_class.new("blah2")
        l = lazy { Namer.next_index }
        resource.x l
        resource2.x l
        expect(resource2.x).to eq 1
        expect(resource.x).to eq 2
        expect(resource2.x).to eq 3
      end

      context "when the class has a class and instance method named blah" do
        before do
          resource_class.class_eval do
            def self.blah
              "class"
            end

            def blah
              "#{name}#{Namer.next_index}"
            end
          end
        end
        def blah
          "example"
        end
        # it "retrieving lazy { blah } gets the instance variable" do
        #   resource.x lazy { blah }
        #   expect(resource.x).to eq "blah1"
        # end
        # it "retrieving lazy { blah } from two different instances gets two different instance variables" do
        #   resource2 = resource_class.new("another")
        #   l = lazy { blah }
        #   resource2.x l
        #   resource.x l
        #   expect(resource2.x).to eq "another1"
        #   expect(resource.x).to eq "blah2"
        #   expect(resource2.x).to eq "another3"
        # end
        it 'retrieving lazy { |x| "#{blah}#{x.blah}" } gets the example and instance variables' do
          resource.x lazy { |x| "#{blah}#{x.blah}" }
          expect(resource.x).to eq "exampleblah1"
        end
        it 'retrieving lazy { |x| "#{blah}#{x.blah}" } from two different instances gets two different instance variables' do
          resource2 = resource_class.new("another")
          l = lazy { |x| "#{blah}#{x.blah}" }
          resource2.x l
          resource.x l
          expect(resource2.x).to eq "exampleanother1"
          expect(resource.x).to eq "exampleblah2"
          expect(resource2.x).to eq "exampleanother3"
        end
      end
    end

    with_property ':x, coerce: proc { |v| "#{v}#{Namer.next_index}" }' do
      it "lazy values are not coerced on set" do
        resource.x lazy { Namer.next_index }
        expect(Namer.current_index).to eq 0
      end
      it "lazy values are coerced on get" do
        resource.x lazy { Namer.next_index }
        expect(resource.x).to eq "12"
        expect(Namer.current_index).to eq 2
      end
      it "lazy values are coerced on each access" do
        resource.x lazy { Namer.next_index }
        expect(resource.x).to eq "12"
        expect(Namer.current_index).to eq 2
        expect(resource.x).to eq "34"
        expect(Namer.current_index).to eq 4
      end
    end

    with_property ":x, String" do
      it "lazy values are not validated on set" do
        resource.x lazy { Namer.next_index }
        expect(Namer.current_index).to eq 0
      end
      it "lazy values are validated on get" do
        resource.x lazy { Namer.next_index }
        expect { resource.x }.to raise_error Chef::Exceptions::ValidationFailed
        expect(Namer.current_index).to eq 1
      end
    end

    with_property ":x, is: proc { |v| Namer.next_index; true }" do
      it "lazy values are validated on each access" do
        resource.x lazy { Namer.next_index }
        expect(resource.x).to eq 1
        expect(Namer.current_index).to eq 2
        expect(resource.x).to eq 3
        expect(Namer.current_index).to eq 4
      end
    end

    with_property ':x, Integer, coerce: proc { |v| "#{v}#{Namer.next_index}" }' do
      it "lazy values are not validated or coerced on set" do
        resource.x lazy { Namer.next_index }
        expect(Namer.current_index).to eq 0
      end
      it "lazy values are coerced before being validated, which fails" do
        resource.x lazy { Namer.next_index }
        expect(Namer.current_index).to eq 0
        expect { resource.x }.to raise_error Chef::Exceptions::ValidationFailed
        expect(Namer.current_index).to eq 2
      end
    end

    with_property ':x, coerce: proc { |v| "#{v}#{Namer.next_index}" }, is: proc { |v| Namer.next_index; true }' do
      it "lazy values are coerced and validated exactly once" do
        resource.x lazy { Namer.next_index }
        expect(resource.x).to eq "12"
        expect(Namer.current_index).to eq 3
        expect(resource.x).to eq "45"
        expect(Namer.current_index).to eq 6
      end
    end

    with_property ':x, String, coerce: proc { |v| "#{v}#{Namer.next_index}" }' do
      it "lazy values are coerced before being validated, which succeeds" do
        resource.x lazy { Namer.next_index }
        expect(resource.x).to eq "12"
        expect(Namer.current_index).to eq 2
      end
    end
  end

  context "Chef::Resource::Property#coerce" do
    with_property ':x, coerce: proc { |v| "#{v}#{Namer.next_index}" }' do
      it "coercion runs on set" do
        expect(resource.x 10).to eq "101"
        expect(Namer.current_index).to eq 1
      end
      it "does not emit a deprecation warning if set to nil" do
        # nil is never coerced
        expect(resource.x nil).to be_nil
      end
      it "coercion sets the value (and coercion does not run on get)" do
        expect(resource.x 10).to eq "101"
        expect(resource.x).to eq "101"
        expect(Namer.current_index).to eq 1
      end
      it "coercion runs each time set happens" do
        expect(resource.x 10).to eq "101"
        expect(Namer.current_index).to eq 1
        expect(resource.x 10).to eq "102"
        expect(Namer.current_index).to eq 2
      end
    end
    with_property ":x, coerce: proc { |x| x }" do
      it "does not emit a deprecation warning if set to nil" do
        expect(resource.x nil).to be_nil
      end
    end
    with_property ':x, coerce: proc { |x| Namer.next_index; raise "hi" if x == 10; x }, is: proc { |x| Namer.next_index; x != 10 }' do
      it "failed coercion fails to set the value" do
        resource.x 20
        expect(resource.x).to eq 20
        expect(Namer.current_index).to eq 2
        expect { resource.x 10 }.to raise_error "hi"
        expect(resource.x).to eq 20
        expect(Namer.current_index).to eq 3
      end
      it "validation does not run if coercion fails" do
        expect { resource.x 10 }.to raise_error "hi"
        expect(Namer.current_index).to eq 1
      end
    end
  end

  context "Chef::Resource::Property validation" do
    with_property ":x, is: proc { |v| Namer.next_index; v.is_a?(Integer) }" do
      it "validation runs on set" do
        expect(resource.x 10).to eq 10
        expect(Namer.current_index).to eq 1
      end
      it "validation sets the value (and validation does not run on get)" do
        expect(resource.x 10).to eq 10
        expect(resource.x).to eq 10
        expect(Namer.current_index).to eq 1
      end
      it "validation runs each time set happens" do
        expect(resource.x 10).to eq 10
        expect(Namer.current_index).to eq 1
        expect(resource.x 10).to eq 10
        expect(Namer.current_index).to eq 2
      end
      it "failed validation fails to set the value" do
        expect(resource.x 10).to eq 10
        expect(Namer.current_index).to eq 1
        expect { resource.x "blah" }.to raise_error Chef::Exceptions::ValidationFailed
        expect(resource.x).to eq 10
        expect(Namer.current_index).to eq 2
      end
    end
  end

  %w{name_attribute name_property}.each do |name|
    context "Chef::Resource::Property##{name}" do
      with_property ":x, #{name}: true" do
        it "defaults x to resource.name" do
          expect(resource.x).to eq "blah"
        end
        it "defaults to being part of the identity if there is no other identity" do
          expect(resource.identity).to eq "blah"
        end
        it "does not pick up resource.name if set" do
          expect(resource.x 10).to eq 10
          expect(resource.x).to eq 10
        end
        it "binds to the latest resource.name when run" do
          resource.name "foo"
          expect(resource.x).to eq "foo"
        end
        it "caches resource.name" do
          expect(resource.x).to eq "blah"
          resource.name "foo"
          expect(resource.x).to eq "blah"
        end
      end

      with_property ":x, #{name}: false" do
        it "defaults to nil" do
          expect(resource.x).to be_nil
        end
      end

      with_property ":x, #{name}: nil" do
        it "defaults to nil" do
          expect(resource.x).to be_nil
        end
      end

      context "default ordering deprecation warnings" do
        it "emits an error for property :x, default: 10, #{name}: true" do
          expect { resource_class.property :x, :default => 10, name.to_sym => true }.to raise_error ArgumentError,
            %r{A property cannot be both a name_property/name_attribute and have a default value. Use one or the other on property x of resource chef_resource_property_spec_(\d+)}
        end
        it "emits an error for property :x, default: nil, #{name}: true" do
          expect { resource_class.property :x, :default => nil, name.to_sym => true }.to raise_error ArgumentError,
            %r{A property cannot be both a name_property/name_attribute and have a default value. Use one or the other on property x of resource chef_resource_property_spec_(\d+)}
        end
        it "emits an error for property :x, #{name}: true, default: 10" do
          expect { resource_class.property :x, name.to_sym => true, :default => 10 }.to raise_error ArgumentError,
            %r{A property cannot be both a name_property/name_attribute and have a default value. Use one or the other on property x of resource chef_resource_property_spec_(\d+)}
        end
        it "emits an error for property :x, #{name}: true, default: nil" do
          expect { resource_class.property :x, name.to_sym => true, :default => nil }.to raise_error ArgumentError,
            %r{A property cannot be both a name_property/name_attribute and have a default value. Use one or the other on property x of resource chef_resource_property_spec_(\d+)}
        end
      end
    end
  end

  it "raises an error if both name_property and name_attribute are specified" do
    expect { resource_class.property :x, name_property: false, name_attribute: 1 }.to raise_error ArgumentError,
      /name_attribute and name_property are functionally identical and both cannot be specified on a property at once. Use just one on property x of resource chef_resource_property_spec_(\d+)/
    expect { resource_class.property :x, name_property: false, name_attribute: nil }.to raise_error ArgumentError,
      /name_attribute and name_property are functionally identical and both cannot be specified on a property at once. Use just one on property x of resource chef_resource_property_spec_(\d+)/
    expect { resource_class.property :x, name_property: false, name_attribute: false }.to raise_error ArgumentError,
      /name_attribute and name_property are functionally identical and both cannot be specified on a property at once. Use just one on property x of resource chef_resource_property_spec_(\d+)/
    expect { resource_class.property :x, name_property: true, name_attribute: true }.to raise_error ArgumentError,
      /name_attribute and name_property are functionally identical and both cannot be specified on a property at once. Use just one on property x of resource chef_resource_property_spec_(\d+)/
  end

  context "property_type" do
    it "property_types validate their defaults" do
      expect do
        module ::PropertySpecPropertyTypes
          include Chef::Mixin::Properties
          property_type(is: %i{a b}, default: :c)
        end
      end.to raise_error(Chef::Exceptions::ValidationFailed)
      expect do
        module ::PropertySpecPropertyTypes
          include Chef::Mixin::Properties
          property_type(is: %i{a b}, default: :b)
        end
      end.not_to raise_error
    end

    context "With property_type ABType (is: [:a, :b]) and CDType (is: [:c, :d])" do
      before :all do
        module ::PropertySpecPropertyTypes
          include Chef::Mixin::Properties
          ABType = property_type(is: %i{a b})
          CDType = property_type(is: %i{c d})
        end
      end

      with_property ":x, [PropertySpecPropertyTypes::ABType, nil, PropertySpecPropertyTypes::CDType]" do
        it "The property can be set to nil without triggering a warning" do
          expect(resource.x nil).to be_nil
          expect(resource.x).to be_nil
        end
        it "The property can be set to :a" do
          expect(resource.x :a).to eq(:a)
          expect(resource.x).to eq(:a)
        end
        it "The property can be set to :c" do
          expect(resource.x :c).to eq(:c)
          expect(resource.x).to eq(:c)
        end
        it "The property cannot be set to :z" do
          expect { resource.x :z }.to raise_error(Chef::Exceptions::ValidationFailed, /Property x must be one of/)
        end
      end

      with_property ":x, [nil, PropertySpecPropertyTypes::ABType, PropertySpecPropertyTypes::CDType]" do
        it "The property can be set to nil without triggering a warning" do
          expect(resource.x nil).to be_nil
          expect(resource.x).to be_nil
        end
        it "The property can be set to :a" do
          expect(resource.x :a).to eq(:a)
          expect(resource.x).to eq(:a)
        end
        it "The property can be set to :c" do
          expect(resource.x :c).to eq(:c)
          expect(resource.x).to eq(:c)
        end
        it "The property cannot be set to :z" do
          expect { resource.x :z }.to raise_error(Chef::Exceptions::ValidationFailed, /Property x must be one of/)
        end
      end

      with_property ":x, [PropertySpecPropertyTypes::ABType, nil], default: nil" do
        it "The value defaults to nil" do
          expect(resource.x).to be_nil
        end
      end

      with_property ":x, [PropertySpecPropertyTypes::ABType, nil], default: lazy { nil }" do
        it "The value defaults to nil" do
          expect(resource.x).to be_nil
        end
      end
    end

  end

  context "with aliased properties" do
    with_property ":real, Integer" do
      it "should set the real property and emit a deprecation message" do
        expect(Chef).to receive(:deprecated).with(:property, "we don't like the deprecated property no more")
        resource_class.class_eval { deprecated_property_alias :deprecated, :real, "we don't like the deprecated property no more" }
        resource.deprecated 10
        expect(resource.real).to eq 10
      end
    end
  end

  context "redefining Object methods" do
    it "disallows redefining Object methods" do
      expect { resource_class.class_eval { property :hash } }.to raise_error(ArgumentError)
    end

    it "disallows redefining Chef::Resource methods" do
      expect { resource_class.class_eval { property :action } }.to raise_error(ArgumentError)
    end

    it "allows redefining properties on Chef::Resource" do
      expect { resource_class.class_eval { property :sensitive } }.not_to raise_error
    end
  end

  context "with a custom property type" do
    class CustomPropertyType < Chef::Property
    end

    with_property ":x, CustomPropertyType.new" do
      it "creates x with the given type" do
        expect(resource_class.properties[:x]).to be_kind_of(CustomPropertyType)
      end

      context "and a subclass" do
        let(:subresource_class) do
          new_resource_name = self.class.new_resource_name
          Class.new(resource_class) do
            resource_name new_resource_name
          end
        end
        let(:subresource) do
          subresource_class.new("blah")
        end

        context "with property :x, default: 10 on the subclass" do
          before do
            subresource_class.class_eval do
              property :x, default: 10
            end
          end

          it "x has the given type and default on the subclass" do
            expect(subresource_class.properties[:x]).to be_kind_of(CustomPropertyType)
            expect(subresource_class.properties[:x].default).to eq(10)
          end

          it "x does not have the default on the superclass" do
            expect(resource_class.properties[:x]).to be_kind_of(CustomPropertyType)
            expect(resource_class.properties[:x].default).to be_nil
          end
        end
      end
    end

    with_property ":x, CustomPropertyType.new, default: 10" do
      it "passes the default to the custom property type" do
        expect(resource_class.properties[:x]).to be_kind_of(CustomPropertyType)
        expect(resource_class.properties[:x].default).to eq(10)
      end
    end
  end

  context "#copy_properties_from" do
    let(:events) { Chef::EventDispatch::Dispatcher.new }
    let(:node) { Chef::Node.new }
    let(:run_context) { Chef::RunContext.new(node, {}, events) }

    let(:thing_one_class) do
      Class.new(Chef::Resource) do
        resource_name :thing_one
        provides :thing_two
        property :foo, String
        property :bar, String
      end
    end

    let(:thing_two_class) do
      Class.new(Chef::Resource) do
        resource_name :thing_two
        provides :thing_two
        property :foo, String
        property :bar, String
      end
    end

    let(:thing_three_class) do
      Class.new(Chef::Resource) do
        resource_name :thing_three
        provides :thing_three
        property :foo, String
        property :bar, String
        property :baz, String
      end
    end

    let(:thing_one_resource) do
      thing_one_class.new("name_one", run_context)
    end

    let(:thing_two_resource) do
      thing_two_class.new("name_two", run_context)
    end

    let(:thing_three_resource) do
      thing_three_class.new("name_three", run_context)
    end

    it "copies foo and bar" do
      thing_one_resource.foo "foo"
      thing_one_resource.bar "bar"
      thing_two_resource.copy_properties_from thing_one_resource
      expect(thing_two_resource.name).to eql("name_two")
      expect(thing_two_resource.foo).to eql("foo")
      expect(thing_two_resource.bar).to eql("bar")
    end

    it "copies only foo when it is only included" do
      thing_one_resource.foo "foo"
      thing_one_resource.bar "bar"
      thing_two_resource.copy_properties_from(thing_one_resource, :foo)
      expect(thing_two_resource.name).to eql("name_two")
      expect(thing_two_resource.foo).to eql("foo")
      expect(thing_two_resource.bar).to eql(nil)
    end

    it "copies foo and name when bar is excluded" do
      thing_one_resource.foo "foo"
      thing_one_resource.bar "bar"
      thing_two_resource.copy_properties_from(thing_one_resource, exclude: [ :bar ])
      expect(thing_two_resource.name).to eql("name_one")
      expect(thing_two_resource.foo).to eql("foo")
      expect(thing_two_resource.bar).to eql(nil)
    end

    it "copies only foo when bar and name are excluded" do
      thing_one_resource.foo "foo"
      thing_one_resource.bar "bar"
      thing_two_resource.copy_properties_from(thing_one_resource, exclude: %i{name bar})
      expect(thing_two_resource.name).to eql("name_two")
      expect(thing_two_resource.foo).to eql("foo")
      expect(thing_two_resource.bar).to eql(nil)
    end

    it "blows up if the target resource does not implement a set property" do
      thing_three_resource.baz "baz"
      expect { thing_two_resource.copy_properties_from(thing_three_resource) }.to raise_error(NoMethodError)
    end

    it "does not blow up if blows up if the target resource does not implement a set properly" do
      thing_three_resource.foo "foo"
      thing_three_resource.bar "bar"
      thing_two_resource.copy_properties_from(thing_three_resource)
    end
  end
end
