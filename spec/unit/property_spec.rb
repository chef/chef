require 'support/shared/integration/integration_helper'

describe "Chef::Resource.property" do
  include IntegrationSupport

  class Namer
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
    return '<nothing>' if values.size == 0
    return values[0].inspect if values.size == 1
    "#{values[0..-2].map { |v| v.inspect }.join(", ")} and #{values[-1].inspect}"
  end

  def self.with_property(*properties, &block)
    tags_index = properties.find_index { |p| !p.is_a?(String)}
    if tags_index
      properties, tags = properties[0..tags_index-1], properties[tags_index..-1]
    else
      tags = []
    end
    properties = properties.map { |property| "property #{property}" }
    context "With properties #{english_join(properties)}", *tags do
      before do
        properties.each do |property_str|
          resource_class.class_eval(property_str, __FILE__, __LINE__)
        end
      end
      instance_eval(&block)
    end
  end

  # Basic properties
  with_property ':bare_property' do
    it "can be set" do
      expect(resource.bare_property 10).to eq 10
      expect(resource.bare_property).to eq 10
    end
    # it "emits a deprecation warning and does a get, if set to nil" do
    it "emits a deprecation warning and does a get, if set to nil" do
      expect(resource.bare_property 10).to eq 10
      # expect { resource.bare_property nil }.to raise_error Chef::Exceptions::DeprecatedFeatureError
      # Chef::Config[:treat_deprecation_warnings_as_errors] = false
      expect(resource.bare_property nil).to eq 10
      expect(resource.bare_property).to eq 10
    end
    it "can be updated" do
      expect(resource.bare_property 10).to eq 10
      expect(resource.bare_property 20).to eq 20
      expect(resource.bare_property).to eq 20
    end
    it "can be set with =" do
      expect(resource.bare_property 10).to eq 10
      expect(resource.bare_property).to eq 10
    end
    # it "can be set to nil with =" do
    #   expect(resource.bare_property 10).to eq 10
    #   expect(resource.bare_property = nil).to be_nil
    #   expect(resource.bare_property).to be_nil
    # end
    it "can be updated with =" do
      expect(resource.bare_property 10).to eq 10
      expect(resource.bare_property = 20).to eq 20
      expect(resource.bare_property).to eq 20
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
        subresource_class.new('blah')
      end

      it "x is inherited" do
        expect(subresource.x 10).to eq 10
        expect(subresource.x).to eq 10
        expect(subresource.x = 20).to eq 20
        expect(subresource.x).to eq 20
        # expect(subresource_class.properties[:x]).not_to be_nil
      end

      it "x's validation is inherited" do
        expect { subresource.x 'ohno' }.to raise_error Chef::Exceptions::ValidationFailed
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
          # expect(subresource_class.properties[:x]).not_to be_nil
        end
        it "y is there" do
          expect(subresource.y 10).to eq 10
          expect(subresource.y).to eq 10
          expect(subresource.y = 20).to eq 20
          expect(subresource.y).to eq 20
          # expect(subresource_class.properties[:y]).not_to be_nil
        end
        it "y is not on the superclass" do
          expect { resource_class.y 10 }.to raise_error
          # expect(resource_class.properties[:y]).to be_nil
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
          # expect(subresource_class.properties[:x]).not_to be_nil
          # expect(subresource_class.properties[:x]).not_to eq resource_class.properties[:x]
        end

        it "x's validation is overwritten" do
          expect(subresource.x 'ohno').to eq 'ohno'
          expect(subresource.x).to eq 'ohno'
        end

        it "the superclass's validation for x is still there" do
          expect { resource.x 'ohno' }.to raise_error Chef::Exceptions::ValidationFailed
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
          # expect(subresource_class.properties[:x]).not_to be_nil
          # expect(subresource_class.properties[:x]).not_to eq resource_class.properties[:x]
        end

        it "x's validation is overwritten" do
          expect { subresource.x 10 }.to raise_error Chef::Exceptions::ValidationFailed
          expect(subresource.x 'ohno').to eq 'ohno'
          expect(subresource.x).to eq 'ohno'
        end

        it "the superclass's validation for x is still there" do
          expect { resource.x 'ohno' }.to raise_error Chef::Exceptions::ValidationFailed
          expect(resource.x 10).to eq 10
          expect(resource.x).to eq 10
        end
      end
    end
  end

  context "Chef::Resource::PropertyType#property_is_set?" do
    it "when a resource is newly created, property_is_set?(:name) is true" do
      expect(resource.property_is_set?(:name)).to be_truthy
    end

    # it "when referencing an undefined property, property_is_set?(:x) raises an error" do
    #   expect { resource.property_is_set?(:x) }.to raise_error(ArgumentError)
    # end

    with_property ':x' do
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

    with_property ':x, default: 10' do
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
      it "when x is retrieved, property_is_set?(:x) is true" do
        resource.x
        expect(resource.property_is_set?(:x)).to be_truthy
      end
    end

    with_property ':x, default: nil' do
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
      it "when x is retrieved, property_is_set?(:x) is true" do
        resource.x
        expect(resource.property_is_set?(:x)).to be_truthy
      end
    end

    with_property ':x, default: lazy { 10 }' do
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
      it "when x is retrieved, property_is_set?(:x) is true" do
        resource.x
        expect(resource.property_is_set?(:x)).to be_truthy
      end
    end
  end

  context "Chef::Resource::PropertyType#default" do
    with_property ':x, default: 10' do
      it "when x is set, it returns its value" do
        expect(resource.x 20).to eq 20
        expect(resource.property_is_set?(:x)).to be_truthy
        expect(resource.x).to eq 20
      end
      it "when x is not set, it returns 10" do
        expect(resource.x).to eq 10
      end
      it "when x is not set, it is not included in state" do
        expect(resource.state).to eq({})
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
        let(:subresource) { subresource_class.new('blah') }
        it "The default is inherited" do
          expect(subresource.x).to eq 10
        end
      end
    end

    with_property ':x, default: 10, identity: true' do
      it "when x is not set, it is not included in identity" do
        expect(resource.state).to eq({})
      end
    end

    with_property ':x, default: nil' do
      it "when x is not set, it returns nil" do
        expect(resource.x).to be_nil
      end
    end

    with_property ':x' do
      it "when x is not set, it returns nil" do
        expect(resource.x).to be_nil
      end
    end

    context "hash default" do
      with_property ':x, default: {}' do
        it "when x is not set, it returns {}" do
          expect(resource.x).to eq({})
        end
        it "The same exact value is returned multiple times in a row" do
          value = resource.x
          expect(value).to eq({})
          expect(resource.x.object_id).to eq(value.object_id)
        end
        it "Multiple instances of x receive the exact same value" do
          # TODO this isn't really great behavior, but it's noted here so we find out
          # if it changed.
          expect(resource.x.object_id).to eq(resource_class.new('blah2').x.object_id)
        end
      end

      with_property ':x, default: lazy { {} }' do
        it "when x is not set, it returns {}" do
          expect(resource.x).to eq({})
        end
        # it "The value is different each time it is called" do
        #   value = resource.x
        #   expect(value).to eq({})
        #   expect(resource.x.object_id).not_to eq(value.object_id)
        # end
        it "Multiple instances of x receive different values" do
          expect(resource.x.object_id).not_to eq(resource_class.new('blah2').x.object_id)
        end
      end
    end

    context "with a class with 'blah' as both class and instance methods" do
      before do
        resource_class.class_eval do
          def self.blah
            'class'
          end
          def blah
            "#{name}#{next_index}"
          end
        end
      end

      with_property ':x, default: lazy { blah }' do
        it "x is run in context of the instance" do
          expect(resource.x).to eq "blah1"
        end
        it "x is run in the context of each instance it is run in" do
          expect(resource.x).to eq "blah1"
          expect(resource_class.new('another').x).to eq "another2"
          # expect(resource.x).to eq "blah3"
        end
      end

      with_property ':x, default: lazy { |x| "#{blah}#{x.blah}" }' do
        it "x is run in context of the class (where it was defined) and passed the instance" do
          expect(resource.x).to eq "classblah1"
        end
        it "x is passed the value of each instance it is run in" do
          expect(resource.x).to eq "classblah1"
          expect(resource_class.new('another').x).to eq "classanother2"
          # expect(resource.x).to eq "classblah3"
        end
      end
    end

    context "validation of defaults" do
      with_property ':x, String, default: 10' do
        it "when the resource is created, no error is raised" do
          resource
        end
        it "when x is set, no error is raised" do
          expect(resource.x 'hi').to eq 'hi'
          expect(resource.x).to eq 'hi'
        end
        it "when x is retrieved, a validation error is raised" do
          expect { resource.x }.to raise_error Chef::Exceptions::ValidationFailed
        end
      end

      with_property ":x, String, default: lazy { Namer.next_index }" do
        it "when the resource is created, no error is raised" do
          resource
        end
        it "when x is set, no error is raised" do
          expect(resource.x 'hi').to eq 'hi'
          expect(resource.x).to eq 'hi'
        end
        # it "when x is retrieved, a validation error is raised" do
        #   expect { resource.x }.to raise_error Chef::Exceptions::ValidationFailed
        #   expect(Namer.current_index).to eq 1
        # end
      end

      # with_property ":x, default: lazy { Namer.next_index }, is: proc { |v| Namer.next_index; true }" do
      #   it "when x is retrieved, validation is run each time" do
      #     expect(resource.x).to eq 1
      #     expect(Namer.current_index).to eq 2
      #     expect(resource.x).to eq 3
      #     expect(Namer.current_index).to eq 4
      #   end
      # end
    end

    # context "coercion of defaults" do
    #   with_property ':x, coerce: proc { |v| "#{v}#{next_index}" }, default: 10' do
    #     it "when the resource is created, the proc is not yet run" do
    #       resource
    #       expect(Namer.current_index).to eq 0
    #     end
    #     it "when x is set, coercion is run" do
    #       expect(resource.x 'hi').to eq 'hi1'
    #       expect(resource.x).to eq 'hi1'
    #       expect(Namer.current_index).to eq 1
    #     end
    #     it "when x is retrieved, coercion is run, no more than once" do
    #       expect(resource.x).to eq '101'
    #       expect(resource.x).to eq '101'
    #       expect(Namer.current_index).to eq 1
    #     end
    #   end
    #
    #   with_property ':x, coerce: proc { |v| "#{v}#{next_index}" }, default: lazy { 10 }' do
    #     it "when the resource is created, the proc is not yet run" do
    #       resource
    #       expect(Namer.current_index).to eq 0
    #     end
    #     it "when x is set, coercion is run" do
    #       expect(resource.x 'hi').to eq 'hi1'
    #       expect(resource.x).to eq 'hi1'
    #       expect(Namer.current_index).to eq 1
    #     end
    #   end
    #
    #   with_property ':x, coerce: proc { |v| "#{v}#{next_index}" }, default: lazy { 10 }, is: proc { |v| Namer.next_index; true }' do
    #     it "when x is retrieved, coercion is run each time" do
    #       expect(resource.x).to eq '101'
    #       expect(Namer.current_index).to eq 2
    #       expect(resource.x).to eq '103'
    #       expect(Namer.current_index).to eq 4
    #     end
    #   end
    #
    #   context "validation and coercion of defaults" do
    #     with_property ':x, String, coerce: proc { |v| "#{v}#{next_index}" }, default: 10' do
    #       it "when x is retrieved, it is coerced before validating and passes" do
    #         expect(resource.x).to eq '101'
    #       end
    #     end
    #     with_property ':x, Integer, coerce: proc { |v| "#{v}#{next_index}" }, default: 10' do
    #       it "when x is retrieved, it is coerced before validating and fails" do
    #         expect { resource.x }.to raise_error Chef::Exceptions::ValidationFailed
    #       end
    #     end
    #     with_property ':x, String, coerce: proc { |v| "#{v}#{next_index}" }, default: lazy { 10 }' do
    #       it "when x is retrieved, it is coerced before validating and passes" do
    #         expect(resource.x).to eq '101'
    #       end
    #     end
    #     with_property ':x, Integer, coerce: proc { |v| "#{v}#{next_index}" }, default: lazy { 10 }' do
    #       it "when x is retrieved, it is coerced before validating and fails" do
    #         expect { resource.x }.to raise_error Chef::Exceptions::ValidationFailed
    #       end
    #     end
    #     with_property ':x, coerce: proc { |v| "#{v}#{next_index}" }, default: lazy { 10 }, is: proc { |v| Namer.next_index; true }' do
    #       it "when x is retrieved, coercion and validation is run on each access" do
    #         expect(resource.x).to eq '101'
    #         expect(Namer.current_index).to eq 2
    #         expect(resource.x).to eq '103'
    #         expect(Namer.current_index).to eq 4
    #       end
    #     end
    #   end
    # end
  end

  context "Chef::Resource#lazy" do
    with_property ':x' do
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
      it "setting the same lazy value on two different instances runs it on each instancee" do
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

    with_property ':x, String' do
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

    with_property ':x, is: proc { |v| Namer.next_index; true }' do
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

  context "Chef::Resource::PropertyType#coerce" do
    with_property ':x, coerce: proc { |v| "#{v}#{Namer.next_index}" }' do
      it "coercion runs on set" do
        expect(resource.x 10).to eq "101"
        expect(Namer.current_index).to eq 1
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
    with_property ':x, coerce: proc { |x| Namer.next_index; raise "hi" if x == 10; x }, is: proc { |x| Namer.next_index; x != 10 }' do
      it "failed coercion fails to set the value" do
        resource.x 20
        expect(resource.x).to eq 20
        expect(Namer.current_index).to eq 2
        expect { resource.x 10 }.to raise_error 'hi'
        expect(resource.x).to eq 20
        expect(Namer.current_index).to eq 3
      end
      it "validation does not run if coercion fails" do
        expect { resource.x 10 }.to raise_error 'hi'
        expect(Namer.current_index).to eq 1
      end
    end
  end

  context "Chef::Resource::PropertyType validation" do
    with_property ':x, is: proc { |v| Namer.next_index; v.is_a?(Integer) }' do
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
        expect { resource.x 'blah' }.to raise_error Chef::Exceptions::ValidationFailed
        expect(resource.x).to eq 10
        expect(Namer.current_index).to eq 2
      end
    end
  end

  [ 'name_attribute', 'name_property' ].each do |name|
    context "Chef::Resource::PropertyType##{name}" do
      with_property ":x, #{name}: true" do
        it "defaults x to resource.name" do
          expect(resource.x).to eq 'blah'
        end
        it "does not pick up resource.name if set" do
          expect(resource.x 10).to eq 10
          expect(resource.x).to eq 10
        end
        it "binds to the latest resource.name when run" do
          resource.name 'foo'
          expect(resource.x).to eq 'foo'
        end
        it "caches resource.name" do
          expect(resource.x).to eq 'blah'
          resource.name 'foo'
          expect(resource.x).to eq 'blah'
        end
      end
      with_property ":x, default: 10, #{name}: true" do
        it "chooses default over #{name}" do
          expect(resource.x).to eq 10
        end
      end
      # with_property ":x, #{name}: true, default: 10" do
      #   it "chooses default over #{name}" do
      #     # expect(resource.x).to eq 10
      #     expect(resource.x).to eq 10
      #   end
      # end
    end
  end
end
