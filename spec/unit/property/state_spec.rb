require 'support/shared/integration/integration_helper'

describe "Chef::Resource#identity and #state" do
  include IntegrationSupport

  class NewResourceNamer
    @i = 0
    def self.next
      "chef_resource_property_spec_#{@i += 1}"
    end
  end

  def self.new_resource_name
    NewResourceNamer.next
  end

  let(:resource_class) do
    new_resource_name = self.class.new_resource_name
    Class.new(Chef::Resource) do
      resource_name new_resource_name
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

  # identity
  context "Chef::Resource#identity_attr" do
    with_property ":x" do
      # it "name is the default identity" do
      #   expect(resource_class.identity_attr).to eq :name
      #   expect(resource_class.properties[:name].identity?).to be_falsey
      #   expect(resource.name).to eq 'blah'
      #   expect(resource.identity).to eq 'blah'
      # end

      it "identity_attr :x changes the identity" do
        expect(resource_class.identity_attr :x).to eq :x
        expect(resource_class.identity_attr).to eq :x
        # expect(resource_class.properties[:name].identity?).to be_falsey
        # expect(resource_class.properties[:x].identity?).to be_truthy

        expect(resource.x 'woo').to eq 'woo'
        expect(resource.x).to eq 'woo'

        expect(resource.name).to eq 'blah'
        expect(resource.identity).to eq 'woo'
      end

      # with_property ":y, identity: true" do
      #   context "and identity_attr :x" do
      #     before do
      #       resource_class.class_eval do
      #         identity_attr :x
      #       end
      #     end
      #
      #     it "only returns :x as identity" do
      #       resource.x 'foo'
      #       resource.y 'bar'
      #       expect(resource_class.identity_attr).to eq :x
      #       expect(resource.identity).to eq 'foo'
      #     end
      #     it "does not flip y.desired_state off" do
      #       resource.x 'foo'
      #       resource.y 'bar'
      #       expect(resource_class.state_attrs).to eq [ :x, :y ]
      #       expect(resource.state).to eq({ x: 'foo', y: 'bar' })
      #     end
      #   end
      # end

      context "With a subclass" do
        let(:subresource_class) do
          new_resource_name = self.class.new_resource_name
          Class.new(resource_class) do
            resource_name new_resource_name
          end
        end
        let(:subresource) do
          subresource_class.new('sub')
        end

        it "name is the default identity on the subclass" do
          # expect(subresource_class.identity_attr).to eq :name
          # expect(subresource_class.properties[:name].identity?).to be_falsey
          expect(subresource.name).to eq 'sub'
          expect(subresource.identity).to eq 'sub'
        end

        context "With identity_attr :x on the superclass" do
          before do
            resource_class.class_eval do
              identity_attr :x
            end
          end

          it "The subclass inherits :x as identity" do
            expect(subresource_class.identity_attr).to eq :x
            # expect(subresource_class.properties[:name].identity?).to be_falsey
            # expect(subresource_class.properties[:x].identity?).to be_truthy

            subresource.x 'foo'
            expect(subresource.identity).to eq 'foo'
          end

          # context "With property :y, identity: true on the subclass" do
          #   before do
          #     subresource_class.class_eval do
          #       property :y, identity: true
          #     end
          #   end
          #   it "The subclass's identity includes both x and y" do
          #     expect(subresource_class.identity_attr).to eq :x
          #     subresource.x 'foo'
          #     subresource.y 'bar'
          #     expect(subresource.identity).to eq({ x: 'foo', y: 'bar' })
          #   end
          # end

          with_property ":y, String" do
            context "With identity_attr :y on the subclass" do
              before do
                subresource_class.class_eval do
                  identity_attr :y
                end
              end
              # it "y is part of state" do
              #   subresource.x 'foo'
              #   subresource.y 'bar'
              #   expect(subresource.state).to eq({ x: 'foo', y: 'bar' })
              #   expect(subresource_class.state_attrs).to eq [ :x, :y ]
              # end
              it "y is the identity" do
                expect(subresource_class.identity_attr).to eq :y
                subresource.x 'foo'
                subresource.y 'bar'
                expect(subresource.identity).to eq 'bar'
              end
              it "y still has validation" do
                expect { subresource.y 12 }.to raise_error Chef::Exceptions::ValidationFailed
              end
            end
          end
        end
      end
    end

    # with_property ":string_only, String, identity: true", ":string_only2, String" do
    #   it "identity_attr does not change validation" do
    #     resource_class.identity_attr :string_only
    #     expect { resource.string_only 12 }.to raise_error Chef::Exceptions::ValidationFailed
    #     expect { resource.string_only2 12 }.to raise_error Chef::Exceptions::ValidationFailed
    #   end
    # end
    #
    # with_property ":x, desired_state: false" do
    #   it "identity_attr does not flip on desired_state" do
    #     resource_class.identity_attr :x
    #     resource.x 'hi'
    #     expect(resource.identity).to eq 'hi'
    #     # expect(resource_class.properties[:x].desired_state?).to be_falsey
    #     expect(resource_class.state_attrs).to eq []
    #     expect(resource.state).to eq({})
    #   end
    # end

    context "With custom property custom_property defined only as methods, using different variables for storage" do
      before do
        resource_class.class_eval do
          def custom_property
            @blarghle*3
          end
          def custom_property=(x)
            @blarghle = x*2
          end
        end

        context "And identity_attr :custom_property" do
          before do
            resource_class.class_eval do
              identity_attr :custom_property
            end
          end

          it "identity_attr comes back as :custom_property" do
            # expect(resource_class.properties[:custom_property].identity?).to be_truthy
            expect(resource_class.identity_attr).to eq :custom_property
          end
          it "custom_property becomes part of desired_state" do
            # expect(resource_class.properties[:custom_property].desired_state?).to be_truthy
            expect(resource_class.state_attrs).to eq [ :custom_property ]
          end
          it "identity_attr does not change custom_property's getter or setter" do
            expect(resource.custom_property = 1).to eq 2
            expect(resource.custom_property).to eq 6
          end
          it "custom_property is returned as the identity" do
            expect(resource_class.identity_attr).to
            expect(resource.identity).to be_nil
            resource.custom_property = 1
            expect(resource.identity).to eq 6
          end
          it "custom_property is part of desired state" do
            resource.custom_property = 1
            expect(resource.state).to eq({ custom_property: 6 })
          end
          it "property_is_set?(:custom_property) returns true even if it hasn't been set" do
            expect(resource.property_is_set?(:custom_property)).to be_truthy
          end
        end
      end
    end
  end

  # context "PropertyType#identity" do
  #   with_property ":x, identity: true" do
  #     it "name is only part of the identity if an identity attribute is defined" do
  #       expect(resource_class.identity_attr).to eq :x
  #       resource.x 'woo'
  #       expect(resource.identity).to eq 'woo'
  #     end
  #   end
  #
  #   with_property ":x, identity: true, default: 'xxx'",
  #                 ":y, identity: true, default: 'yyy'",
  #                 ":z, identity: true, default: 'zzz'" do
  #     it "identity_attr returns the first identity attribute if multiple are defined" do
  #       expect(resource_class.identity_attr).to eq :x
  #     end
  #     it "identity returns all identity values in a hash if multiple are defined" do
  #       resource.x 'foo'
  #       resource.y 'bar'
  #       resource.z 'baz'
  #       expect(resource.identity).to eq({ x: 'foo', y: 'bar', z: 'baz' })
  #     end
  #     it "identity returns only identity values that are set, and does not include defaults" do
  #       resource.x 'foo'
  #       resource.z 'baz'
  #       expect(resource.identity).to eq({ x: 'foo', z: 'baz' })
  #     end
  #     it "identity returns only set identity values in a hash, if there is only one set identity value" do
  #       resource.x 'foo'
  #       expect(resource.identity).to eq({ x: 'foo' })
  #     end
  #     it "identity returns an empty hash if no identity values are set" do
  #       expect(resource.identity).to eq({})
  #     end
  #     it "identity_attr wipes out any other identity attributes if multiple are defined" do
  #       resource_class.identity_attr :y
  #       resource.x 'foo'
  #       resource.y 'bar'
  #       resource.z 'baz'
  #       expect(resource.identity).to eq 'bar'
  #     end
  #   end
  #
  #   with_property ":x, identity: true, name_property: true" do
  #     it "identity when x is not defined returns the value of x" do
  #       expect(resource.identity).to eq 'blah'
  #     end
  #     it "state when x is not defined returns the value of x" do
  #       expect(resource.state).to eq({ x: 'blah' })
  #     end
  #   end
  # end

  # state_attrs
  context "Chef::Resource#state_attrs" do
    it "name is not part of state_attrs" do
      expect(Chef::Resource.state_attrs).to eq []
      expect(resource_class.state_attrs).to eq []
      expect(resource.state).to eq({})
    end

    # with_property ":x", ":y", ":z" do
    #   it "x, y and z are state attributes" do
    #     resource.x 1
    #     resource.y 2
    #     resource.z 3
    #     expect(resource_class.state_attrs).to eq [ :x, :y, :z ]
    #     expect(resource.state).to eq(x: 1, y: 2, z: 3)
    #   end
    #   it "values that are not set are not included in state" do
    #     resource.x 1
    #     expect(resource.state).to eq(x: 1)
    #   end
    #   it "when no values are set, nothing is included in state" do
    #   end
    # end
    #
    # with_property ":x", ":y, desired_state: false", ":z, desired_state: true" do
    #   it "x and z are state attributes, and y is not" do
    #     resource.x 1
    #     resource.y 2
    #     resource.z 3
    #     expect(resource_class.state_attrs).to eq [ :x, :z ]
    #     expect(resource.state).to eq(x: 1, z: 3)
    #   end
    # end

    # with_property ":x, name_property: true" do
    #   it "Unset values with name_property are included in state" do
    #     expect(resource.state).to eq(x: 'blah')
    #   end
    #   it "Set values with name_property are included in state" do
    #     resource.x 1
    #     expect(resource.state).to eq(x: 1)
    #   end
    # end

    # with_property ":x, default: 1" do
    #   it "Unset values with defaults are not included in state" do
    #     expect(resource.state).to eq({})
    #   end
    #   it "Set values with defaults are included in state" do
    #     resource.x 1
    #     expect(resource.state).to eq(x: 1)
    #   end
    # end

    context "With a class with a normal getter and setter" do
      before do
        resource_class.class_eval do
          def x
            @blah*3
          end
          def x=(value)
            @blah = value*2
          end
        end
      end
      it "state_attrs(:x) causes the value to be included in properties" do
        resource_class.state_attrs(:x)
        resource.x = 1

        expect(resource.x).to eq 6
        expect(resource.state).to eq(x: 6)
      end
    end

    # with_property ":x, Integer, identity: true" do
    #   it "state_attrs(:x) leaves the property in desired_state" do
    #     resource_class.state_attrs(:x)
    #     resource.x 10
    #
    #     # expect(resource_class.properties[:x].desired_state?).to be_truthy
    #     expect(resource_class.state_attrs).to eq [ :x ]
    #     expect(resource.state).to eq(x: 10)
    #   end
    #   it "state_attrs(:x) does not turn off validation" do
    #     resource_class.state_attrs(:x)
    #     expect { resource.x 'ouch' }.to raise_error Chef::Exceptions::ValidationFailed
    #   end
    #   it "state_attrs(:x) does not turn off identity" do
    #     resource_class.state_attrs(:x)
    #     resource.x 10
    #
    #     expect(resource_class.identity_attr).to eq :x
    #     # expect(resource_class.properties[:x].identity?).to be_truthy
    #     expect(resource.identity).to eq 10
    #   end
    # end

    # with_property ":x, Integer, identity: true, desired_state: false" do
    #   before do
    #     resource_class.class_eval do
    #       def y
    #         20
    #       end
    #     end
    #   end
    #   it "state_attrs(:x) sets the property in desired_state" do
    #     resource_class.state_attrs(:x)
    #     resource.x 10
    #
    #     # expect(resource_class.properties[:x].desired_state?).to be_truthy
    #     expect(resource_class.state_attrs).to eq [ :x ]
    #     expect(resource.state).to eq(x: 10)
    #   end
    #   it "state_attrs(:x) does not turn off validation" do
    #     resource_class.state_attrs(:x)
    #     expect { resource.x 'ouch' }.to raise_error Chef::Exceptions::ValidationFailed
    #   end
    #   it "state_attrs(:x) does not turn off identity" do
    #     resource_class.state_attrs(:x)
    #     resource.x 10
    #
    #     expect(resource_class.identity_attr).to eq :x
    #     # expect(resource_class.properties[:x].identity?).to be_truthy
    #     expect(resource.identity).to eq 10
    #   end
    #   it "state_attrs(:y) adds y and removes x from desired state" do
    #     resource_class.state_attrs(:y)
    #     resource.x 10
    #
    #     # expect(resource_class.properties[:x].desired_state?).to be_falsey
    #     # expect(resource_class.properties[:y].desired_state?).to be_truthy
    #     expect(resource_class.state_attrs).to eq [ :y ]
    #     expect(resource.state).to eq(y: 20)
    #   end
    #   it "state_attrs(:y) does not turn off validation" do
    #     resource_class.state_attrs(:y)
    #
    #     expect { resource.x 'ouch' }.to raise_error Chef::Exceptions::ValidationFailed
    #   end
    #   it "state_attrs(:y) does not turn off identity" do
    #     resource_class.state_attrs(:y)
    #     resource.x 10
    #
    #     expect(resource_class.identity_attr).to eq :x
    #     # expect(resource_class.properties[:x].identity?).to be_truthy
    #     expect(resource.identity).to eq 10
    #   end
    #
    #   context "With a subclassed resource" do
    #     let(:resource_subclass) do
    #       new_resource_name = self.class.new_resource_name
    #       Class.new(resource_class) do
    #         resource_name new_resource_name
    #       end
    #     end
    #     let(:subresource) do
    #       resource_subclass.new('blah')
    #     end
    #     it "state_attrs(:x) sets the property in desired_state" do
    #       resource_subclass.state_attrs(:x)
    #       subresource.x 10
    #
    #       # expect(resource_subclass.properties[:x].desired_state?).to be_truthy
    #       expect(resource_subclass.state_attrs).to eq [ :x ]
    #       expect(subresource.state).to eq(x: 10)
    #     end
    #     it "state_attrs(:x) does not turn off validation" do
    #       resource_subclass.state_attrs(:x)
    #       expect { subresource.x 'ouch' }.to raise_error Chef::Exceptions::ValidationFailed
    #     end
    #     it "state_attrs(:x) does not turn off identity" do
    #       resource_subclass.state_attrs(:x)
    #       subresource.x 10
    #
    #       expect(resource_subclass.identity_attr).to eq :x
    #       # expect(resource_subclass.properties[:x].identity?).to be_truthy
    #       expect(subresource.identity).to eq 10
    #     end
    #     it "state_attrs(:y) adds y and removes x from desired state" do
    #       resource_subclass.state_attrs(:y)
    #       subresource.x 10
    #
    #       # expect(resource_subclass.properties[:x].desired_state?).to be_falsey
    #       # expect(resource_subclass.properties[:y].desired_state?).to be_truthy
    #       expect(resource_subclass.state_attrs).to eq [ :y ]
    #       expect(subresource.state).to eq(y: 20)
    #     end
    #     it "state_attrs(:y) does not turn off validation" do
    #       resource_subclass.state_attrs(:y)
    #
    #       expect { subresource.x 'ouch' }.to raise_error Chef::Exceptions::ValidationFailed
    #     end
    #     it "state_attrs(:y) does not turn off identity" do
    #       resource_subclass.state_attrs(:y)
    #       subresource.x 10
    #
    #       expect(resource_subclass.identity_attr).to eq :x
    #       # expect(resource_subclass.properties[:x].identity?).to be_truthy
    #       expect(subresource.identity).to eq 10
    #     end
    #   end
    # end
  end

end
