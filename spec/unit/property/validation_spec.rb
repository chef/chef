require 'support/shared/integration/integration_helper'

describe "Chef::Resource.property validation" do
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
      def blah
        Namer.next_index
      end
      def self.blah
        "class#{Namer.next_index}"
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

  def self.validation_test(validation, success_values, failure_values, getter_values=[])
    with_property ":x, #{validation}" do
      success_values.each do |v|
        it "value #{v.inspect} is valid" do
          expect(resource.x v).to eq v
        end
      end
      failure_values.each do |v|
        it "value #{v.inspect} is invalid" do
          expect { resource.x v }.to raise_error Chef::Exceptions::ValidationFailed
        end
      end
      getter_values.each do |v|
        it "setting value to #{v.inspect} does not change the value" do
          Chef::Config[:treat_deprecation_warnings_as_errors] = false
          resource.x success_values.first
          expect(resource.x v).to eq success_values.first
          expect(resource.x).to eq success_values.first
        end
      end
    end
  end

  # Bare types
  context "bare types" do
    validation_test 'String',
      [ 'hi' ],
      [ 10, nil ]

    validation_test ':a',
      [ :a ],
      [ :b, nil ]

    validation_test ':a, is: :b',
      [ :a, :b ],
      [ :c, nil ]

    validation_test ':a, is: [ :b, :c ]',
      [ :a, :b, :c ],
      [ :d, nil ]

    validation_test '[ :a, :b ], is: :c',
      [ :a, :b, :c ],
      [ :d, nil ]

    validation_test '[ :a, :b ], is: [ :c, :d ]',
      [ :a, :b, :c, :d ],
      [ :e, nil ]

    validation_test 'nil',
      [ nil ],
      [ :a ]

    validation_test '[ nil ]',
      [ nil ],
      [ :a ]

    validation_test '[]',
      [],
      [ :a, nil ]
  end

  # is
  context "is" do
    # Class
    validation_test 'is: String',
      [ 'a', '' ],
      [ nil, :a, 1 ]

    # Value
    validation_test 'is: :a',
      [ :a ],
      [ :b, nil ]

    validation_test 'is: [ :a, :b ]',
      [ :a, :b ],
      [ [ :a, :b ], nil ]

    validation_test 'is: [ [ :a, :b ] ]',
      [ [ :a, :b ] ],
      [ :a, :b, nil ]

    # Regex
    validation_test 'is: /abc/',
      [ 'abc', 'wowabcwow' ],
      [ '', 'abac', nil ]

    # PropertyType
    # validation_test 'is: PropertyType.new(is: :a)',
    #   [ :a ],
    #   [ :b, nil ]

    # RSpec Matcher
    class Globalses
      extend RSpec::Matchers
    end

    validation_test "is: Globalses.eq(10)",
      [ 10 ],
      [ 1, nil ]

    # Proc
    validation_test 'is: proc { |x| x }',
      [ true, 1 ],
      [ false, nil ]

    validation_test 'is: proc { |x| x > blah }',
      [ 10 ],
      [ -1 ]

    validation_test 'is: nil',
      [ nil ],
      [ 'a' ]

    validation_test 'is: [ String, nil ]',
      [ 'a', nil ],
      [ :b ]

    validation_test 'is: []',
      [],
      [ :a, nil ]
  end

  # Combination
  context "combination" do
    validation_test 'kind_of: String, equal_to: "a"',
      [ 'a' ],
      [ 'b' ],
      [ nil ]
  end

  # equal_to
  context "equal_to" do
    # Value
    validation_test 'equal_to: :a',
      [ :a ],
      [ :b ],
      [ nil ]

    validation_test 'equal_to: [ :a, :b ]',
      [ :a, :b ],
      [ [ :a, :b ] ],
      [ nil ]

    validation_test 'equal_to: [ [ :a, :b ] ]',
      [ [ :a, :b ] ],
      [ :a, :b ],
      [ nil ]

    validation_test 'equal_to: nil',
      [ nil ],
      [ 'a' ]

    validation_test 'equal_to: [ "a", nil ]',
      [ 'a', nil ],
      [ 'b' ]

    validation_test 'equal_to: [ nil, "a" ]',
      [ 'a', nil ],
      [ 'b' ]

    validation_test 'equal_to: []',
      [],
      [ :a ],
      [ nil ]
  end

  # kind_of
  context "kind_of" do
    validation_test 'kind_of: String',
      [ 'a' ],
      [ :b ],
      [ nil ]

    validation_test 'kind_of: [ String, Symbol ]',
      [ 'a', :b ],
      [ 1 ],
      [ nil ]

    validation_test 'kind_of: [ Symbol, String ]',
      [ 'a', :b ],
      [ 1 ],
      [ nil ]

    validation_test 'kind_of: NilClass',
      [ nil ],
      [ 'a' ]

    validation_test 'kind_of: [ NilClass, String ]',
      [ nil, 'a' ],
      [ :a ]

    validation_test 'kind_of: []',
      [],
      [ :a ],
      [ nil ]

    validation_test 'kind_of: nil',
      [],
      [ :a ],
      [ nil ]
  end

  # regex
  context "regex" do
    validation_test 'regex: /abc/',
      [ 'xabcy' ],
      [ 'gbh', 123 ],
      [ nil ]

    validation_test 'regex: [ /abc/, /z/ ]',
      [ 'xabcy', 'aza' ],
      [ 'gbh', 123 ],
      [ nil ]

    validation_test 'regex: [ /z/, /abc/ ]',
      [ 'xabcy', 'aza' ],
      [ 'gbh', 123 ],
      [ nil ]

    validation_test 'regex: []',
      [],
      [ :a ],
      [ nil ]

    validation_test 'regex: nil',
      [],
      [ :a ],
      [ nil ]
  end

  # callbacks
  context "callbacks" do
    validation_test 'callbacks: { "a" => proc { |x| x > 10 }, "b" => proc { |x| x%2 == 0 } }',
      [ 12 ],
      [ 11, 4 ]

    validation_test 'callbacks: { "a" => proc { |x| x%2 == 0 }, "b" => proc { |x| x > 10 } }',
      [ 12 ],
      [ 11, 4 ]

    validation_test 'callbacks: { "a" => proc { |x| x.nil? } }',
      [ nil ],
      [ 'a' ]

    validation_test 'callbacks: {}',
      [ :a ],
      [],
      [ nil ]
  end

  # respond_to
  context "respond_to" do
    validation_test 'respond_to: :split',
      [ 'hi' ],
      [ 1 ],
      [ nil ]

    validation_test 'respond_to: "split"',
      [ 'hi' ],
      [ 1 ],
      [ nil ]

    validation_test 'respond_to: [ :split, :to_s ]',
      [ 'hi' ],
      [ 1 ],
      [ nil ]

    validation_test 'respond_to: %w(split to_s)',
      [ 'hi' ],
      [ 1 ],
      [ nil ]

    validation_test 'respond_to: [ :to_s, :split ]',
      [ 'hi' ],
      [ 1, ],
      [ nil ]

    validation_test 'respond_to: []',
      [ :a ],
      [],
      [ nil ]

    validation_test 'respond_to: nil',
      [ :a ],
      [],
      [ nil ]
  end

  context "cannot_be" do
    validation_test 'cannot_be: :empty',
      [ nil, 1, [1,2], { a: 10 } ],
      [ [] ]

    validation_test 'cannot_be: "empty"',
      [ nil, 1, [1,2], { a: 10 } ],
      [ [] ]

    validation_test 'cannot_be: [ :empty, :nil ]',
      [ 1, [1,2], { a: 10 } ],
      [ [], nil ],
      [ nil ]

    validation_test 'cannot_be: [ "empty", "nil" ]',
      [ 1, [1,2], { a: 10 } ],
      [ [], nil ],
      [ nil ]

    validation_test 'cannot_be: [ :nil, :empty ]',
      [ 1, [1,2], { a: 10 } ],
      [ [], nil ],
      [ nil ]

    validation_test 'cannot_be: [ :empty, :nil, :blahblah ]',
      [ 1, [1,2], { a: 10 } ],
      [ [], nil ],
      [ nil ]

    validation_test 'cannot_be: []',
      [ :a ],
      [],
      [ nil ]

    validation_test 'cannot_be: nil',
      [ :a ],
      [],
      [ nil ]

  end

  context "required" do
    with_property ':x, required: true' do
      it "if x is not specified, retrieval fails" do
        expect { resource.x }.to raise_error Chef::Exceptions::ValidationFailed
      end
      it "value nil is invalid" do
        Chef::Config[:treat_deprecation_warnings_as_errors] = false
        expect { resource.x nil }.to raise_error Chef::Exceptions::ValidationFailed
      end
      it "value 1 is valid" do
        expect(resource.x 1).to eq 1
        expect(resource.x).to eq 1
      end
    end

    with_property ':x, [String, nil], required: true' do
      it "if x is not specified, retrieval fails" do
        expect { resource.x }.to raise_error Chef::Exceptions::ValidationFailed
      end
      # it "value nil is valid" do
      #   expect(resource.x nil).to be_nil
      #   expect(resource.x).to be_nil
      # end
      it "value '1' is valid" do
        expect(resource.x '1').to eq '1'
        expect(resource.x).to eq '1'
      end
      it "value 1 is invalid" do
        expect { resource.x 1 }.to raise_error Chef::Exceptions::ValidationFailed
      end
    end

    # with_property ':x, name_property: true, required: true' do
    with_property ':x, required: true, name_property: true' do
      it "if x is not specified, retrieval fails" do
        expect { resource.x }.to raise_error Chef::Exceptions::ValidationFailed
      end
      it "value nil is invalid" do
        expect { resource.x nil }.to raise_error Chef::Exceptions::ValidationFailed
      end
      it "value 1 is valid" do
        expect(resource.x 1).to eq 1
        expect(resource.x).to eq 1
      end
    end

    # with_property ':x, default: 10, required: true' do
    with_property ':x, required: true, default: 10' do
      it "if x is not specified, retrieval fails" do
        expect { resource.x }.to raise_error Chef::Exceptions::ValidationFailed
      end
      it "value nil is invalid" do
        expect { resource.x nil }.to raise_error Chef::Exceptions::ValidationFailed
      end
      it "value 1 is valid" do
        expect(resource.x 1).to eq 1
        expect(resource.x).to eq 1
      end
    end
  end

  context "custom validators (def _pv_blarghle)" do
    before do
      Chef::Config[:treat_deprecation_warnings_as_errors] = false
    end

    with_property ':x, blarghle: 1' do
      context "and a class that implements _pv_blarghle" do
        before do
          resource_class.class_eval do
            def _pv_blarghle(opts, key, value)
              if _pv_opts_lookup(opts, key) != value
                raise Chef::Exceptions::ValidationFailed, "ouch"
              end
            end
          end
        end

        # it "getting the value causes a deprecation warning" do
        #   Chef::Config[:treat_deprecation_warnings_as_errors] = true
        #   expect { resource.x }.to raise_error Chef::Exceptions::DeprecatedFeatureError
        # end

        it "value 1 is valid" do
          expect(resource.x 1).to eq 1
          expect(resource.x).to eq 1
        end

        it "value '1' is invalid" do
          Chef::Config[:treat_deprecation_warnings_as_errors] = false
          expect { resource.x '1' }.to raise_error Chef::Exceptions::ValidationFailed
        end

        it "value nil is invalid" do
          Chef::Config[:treat_deprecation_warnings_as_errors] = false
          expect { resource.x nil }.to raise_error Chef::Exceptions::ValidationFailed
        end
      end
    end

    with_property ':x, blarghle: 1' do
      context "and a class that implements _pv_blarghle" do
        before do
          resource_class.class_eval do
            def _pv_blarghle(opts, key, value)
              if _pv_opts_lookup(opts, key) != value
                raise Chef::Exceptions::ValidationFailed, "ouch"
              end
            end
          end
        end

        it "value 1 is valid" do
          expect(resource.x 1).to eq 1
          expect(resource.x).to eq 1
        end

        it "value '1' is invalid" do
          expect { resource.x '1' }.to raise_error Chef::Exceptions::ValidationFailed
        end

        it "value nil is invalid" do
          expect { resource.x nil }.to raise_error Chef::Exceptions::ValidationFailed
        end
      end
    end
  end
end
