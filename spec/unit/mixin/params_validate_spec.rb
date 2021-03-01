#
# Author:: Adam Jacob (<adam@chef.io>)
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

class TinyClass
  include Chef::Mixin::ParamsValidate

  attr_reader :name

  def music(is_good = true)
    is_good
  end
end

describe Chef::Mixin::ParamsValidate do
  before(:each) do
    @vo = TinyClass.new
  end

  it "should allow a hash and a hash as arguments to validate" do
    expect { @vo.validate({ one: "two" }, {}) }.not_to raise_error
  end

  it "should raise an argument error if validate is called incorrectly" do
    expect { @vo.validate("one", "two") }.to raise_error(ArgumentError)
  end

  it "should require validation map keys to be symbols or strings" do
    expect { @vo.validate({ one: "two" }, { one: true }) }.not_to raise_error
    expect { @vo.validate({ one: "two" }, { "one" => true }) }.not_to raise_error
    expect { @vo.validate({ one: "two" }, { {} => true }) }.to raise_error(ArgumentError)
  end

  it "should allow options to be required with true" do
    expect { @vo.validate({ one: "two" }, { one: true }) }.not_to raise_error
  end

  it "should allow options to be optional with false" do
    expect { @vo.validate({}, { one: false }) }.not_to raise_error
  end

  it "should allow you to check what kind_of? thing an argument is with kind_of" do
    expect do
      @vo.validate(
        { one: "string" },
        {
          one: {
            kind_of: String,
          },
        }
      )
    end.not_to raise_error

    expect do
      @vo.validate(
        { one: "string" },
        {
          one: {
            kind_of: Array,
          },
        }
      )
    end.to raise_error(ArgumentError)
  end

  it "should allow you to specify an argument is required with required" do
    expect do
      @vo.validate(
        { one: "string" },
        {
          one: {
            required: true,
          },
        }
      )
    end.not_to raise_error

    expect do
      @vo.validate(
        { two: "string" },
        {
          one: {
            required: true,
          },
        }
      )
    end.to raise_error(ArgumentError)

    expect do
      @vo.validate(
        { two: "string" },
        {
          one: {
            required: false,
          },
        }
      )
    end.not_to raise_error
  end

  it "should allow you to specify whether an object has a method with respond_to" do
    expect do
      @vo.validate(
        { one: @vo },
        {
          one: {
            respond_to: "validate",
          },
        }
      )
    end.not_to raise_error

    expect do
      @vo.validate(
        { one: @vo },
        {
          one: {
            respond_to: "monkey",
          },
        }
      )
    end.to raise_error(ArgumentError)
  end

  it "should allow you to specify whether an object has all the given methods with respond_to and an array" do
    expect do
      @vo.validate(
        { one: @vo },
        {
          one: {
            respond_to: %w{validate music},
          },
        }
      )
    end.not_to raise_error

    expect do
      @vo.validate(
        { one: @vo },
        {
          one: {
            respond_to: %w{monkey validate},
          },
        }
      )
    end.to raise_error(ArgumentError)
  end

  it "should let you set a default value with default => value" do
    arguments = {}
    @vo.validate(arguments, {
      one: {
        default: "is the loneliest number",
      },
    })
    expect(arguments[:one]).to eq("is the loneliest number")
  end

  it "should let you check regular expressions" do
    expect do
      @vo.validate(
        { one: "is good" },
        {
          one: {
            regex: /^is good$/,
          },
        }
      )
    end.not_to raise_error

    expect do
      @vo.validate(
        { one: "is good" },
        {
          one: {
            regex: /^is bad$/,
          },
        }
      )
    end.to raise_error(ArgumentError)
  end

  it "should let you specify your own callbacks" do
    expect do
      @vo.validate(
        { one: "is good" },
        {
          one: {
            callbacks: {
              "should be equal to is good" => lambda do |a|
                a == "is good"
              end,
            },
          },
        }
      )
    end.not_to raise_error

    expect do
      @vo.validate(
        { one: "is bad" },
        {
          one: {
            callbacks: {
              "should be equal to 'is good'" => lambda do |a|
                a == "is good"
              end,
            },
          },
        }
      )
    end.to raise_error(ArgumentError)
  end

  it "should let you combine checks" do
    args = { one: "is good", two: "is bad" }
    expect do
      @vo.validate(
        args,
        {
          one: {
            kind_of: String,
            respond_to: %i{to_s upcase},
            regex: /^is good/,
            callbacks: {
              "should be your friend" => lambda do |a|
                a == "is good"
              end,
            },
            required: true,
          },
          two: {
            kind_of: String,
            required: false,
          },
          three: { default: "neato mosquito" },
        }
      )
    end.not_to raise_error
    expect(args[:three]).to eq("neato mosquito")
    expect do
      @vo.validate(
        args,
        {
          one: {
            kind_of: String,
            respond_to: %i{to_s upcase},
            regex: /^is good/,
            callbacks: {
              "should be your friend" => lambda do |a|
                a == "is good"
              end,
            },
            required: true,
          },
          two: {
            kind_of: Hash,
            required: false,
          },
          three: { default: "neato mosquito" },
        }
      )
    end.to raise_error(ArgumentError)
  end

  it "should raise an ArgumentError if the validation map has an unknown check" do
    expect do
      @vo.validate(
        { one: "two" },
        {
          one: {
            busted: "check",
          },
        }
      )
    end.to raise_error(ArgumentError)
  end

  it "should accept keys that are strings in the options" do
    expect do
      @vo.validate({ "one" => "two" }, { one: { regex: /^two$/ } })
    end.not_to raise_error
  end

  it "should allow an array to kind_of" do
    expect do
      @vo.validate(
        { one: "string" },
        {
          one: {
            kind_of: [ String, Array ],
          },
        }
      )
    end.not_to raise_error
    expect do
      @vo.validate(
        { one: ["string"] },
        {
          one: {
            kind_of: [ String, Array ],
          },
        }
      )
    end.not_to raise_error
    expect do
      @vo.validate(
        { one: {} },
        {
          one: {
            kind_of: [ String, Array ],
          },
        }
      )
    end.to raise_error(ArgumentError)
  end

  it "asserts that a value returns false from a predicate method" do
    expect do
      @vo.validate({ not_blank: "should pass" },
        { not_blank: { cannot_be: %i{nil empty} } })
    end.not_to raise_error
    expect do
      @vo.validate({ not_blank: "" },
        { not_blank: { cannot_be: %i{nil empty} } })
    end.to raise_error(Chef::Exceptions::ValidationFailed)
  end

  it "allows a custom validation message" do
    expect do
      @vo.validate({ not_blank: "should pass" },
        { not_blank: { cannot_be: %i{nil empty}, validation_message: "my validation message" } })
    end.not_to raise_error
    expect do
      @vo.validate({ not_blank: "" },
        { not_blank: { cannot_be: %i{nil empty}, validation_message: "my validation message" } })
    end.to raise_error(Chef::Exceptions::ValidationFailed, "my validation message")
  end

  it "should set and return a value, then return the same value" do
    value = "meow"
    expect(@vo.set_or_return(:test, value, {}).object_id).to eq(value.object_id)
    expect(@vo.set_or_return(:test, nil, {}).object_id).to eq(value.object_id)
  end

  it "should set and return a default value when the argument is nil, then return a dup of the value" do
    value = "meow"
    expect(@vo.set_or_return(:test, nil, { default: value }).object_id).not_to eq(value.object_id)
    expect(@vo.set_or_return(:test, nil, {}).object_id).not_to eq(value.object_id)
    expect(@vo.set_or_return(:test, nil, {})).to eql(value)
  end

  it "should raise an ArgumentError when argument is nil and required is true" do
    expect do
      @vo.set_or_return(:test, nil, { required: true })
    end.to raise_error(ArgumentError)
  end

  it "should not raise an error when argument is nil and required is false" do
    expect do
      @vo.set_or_return(:test, nil, { required: false })
    end.not_to raise_error
  end

  it "should set and return @name, then return @name for foo when argument is nil" do
    value = "meow"
    expect(@vo.set_or_return(:name, value, {}).object_id).to eq(value.object_id)
    expect(@vo.set_or_return(:foo, nil, { name_attribute: true }).object_id).to eq(value.object_id)
  end

  it "should allow DelayedEvaluator instance to be set for value regardless of restriction" do
    value = Chef::DelayedEvaluator.new { "test" }
    @vo.set_or_return(:test, value, { kind_of: Numeric })
  end

  it "should raise an error when delayed evaluated attribute is not valid" do
    value = Chef::DelayedEvaluator.new { "test" }
    @vo.set_or_return(:test, value, { kind_of: Numeric })
    expect do
      @vo.set_or_return(:test, nil, { kind_of: Numeric })
    end.to raise_error(Chef::Exceptions::ValidationFailed)
  end

  it "should create DelayedEvaluator instance when #lazy is used" do
    @vo.set_or_return(:delayed, @vo.lazy { "test" }, {})
    expect(@vo.instance_variable_get(:@delayed)).to be_a(Chef::DelayedEvaluator)
  end

  it "should execute block on each call when DelayedEvaluator" do
    value = "fubar"
    @vo.set_or_return(:test, @vo.lazy { value }, {})
    expect(@vo.set_or_return(:test, nil, {})).to eq("fubar")
    value = "foobar"
    expect(@vo.set_or_return(:test, nil, {})).to eq("foobar")
    value = "fauxbar"
    expect(@vo.set_or_return(:test, nil, {})).to eq("fauxbar")
  end

  it "should not evaluate non DelayedEvaluator instances" do
    value = lambda { "test" }
    @vo.set_or_return(:test, value, {})
    expect(@vo.set_or_return(:test, nil, {}).object_id).to eq(value.object_id)
    expect(@vo.set_or_return(:test, nil, {})).to be_a(Proc)
  end

end
