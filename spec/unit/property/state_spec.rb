require "support/shared/integration/integration_helper"

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
    return "<nothing>" if values.size == 0
    return values[0].inspect if values.size == 1
    "#{values[0..-2].map { |v| v.inspect }.join(", ")} and #{values[-1].inspect}"
  end

  def self.with_property(*properties, &block)
    tags_index = properties.find_index { |p| !p.is_a?(String) }
    if tags_index
      properties, tags = properties[0..tags_index - 1], properties[tags_index..-1]
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
  context "Chef::Resource#identity_properties" do
    with_property ":x" do
      it "name is the default identity" do
        expect(resource_class.identity_properties).to eq [ Chef::Resource.properties[:name] ]
        expect(Chef::Resource.properties[:name].identity?).to be_falsey
        expect(resource.name).to eq "blah"
        expect(resource.identity).to eq "blah"
      end

      it "identity_properties :x changes the identity" do
        expect(resource_class.identity_properties :x).to eq [ resource_class.properties[:x] ]
        expect(resource_class.identity_properties).to eq [ resource_class.properties[:x] ]
        expect(Chef::Resource.properties[:name].identity?).to be_falsey
        expect(resource_class.properties[:x].identity?).to be_truthy

        expect(resource.x "woo").to eq "woo"
        expect(resource.x).to eq "woo"

        expect(resource.name).to eq "blah"
        expect(resource.identity).to eq "woo"
      end

      with_property ":y, identity: true" do
        context "and identity_properties :x" do
          before do
            resource_class.class_eval do
              identity_properties :x
            end
          end

          it "only returns :x as identity" do
            resource.x "foo"
            resource.y "bar"
            expect(resource_class.identity_properties).to eq [ resource_class.properties[:x] ]
            expect(resource.identity).to eq "foo"
          end
          it "does not flip y.desired_state off" do
            resource.x "foo"
            resource.y "bar"
            expect(resource_class.state_properties).to eq [
              resource_class.properties[:x],
              resource_class.properties[:y],
            ]
            expect(resource.state_for_resource_reporter).to eq(x: "foo", y: "bar")
          end
        end
      end

      context "With a subclass" do
        let(:subresource_class) do
          new_resource_name = self.class.new_resource_name
          Class.new(resource_class) do
            resource_name new_resource_name
          end
        end
        let(:subresource) do
          subresource_class.new("sub")
        end

        it "name is the default identity on the subclass" do
          expect(subresource_class.identity_properties).to eq [ Chef::Resource.properties[:name] ]
          expect(Chef::Resource.properties[:name].identity?).to be_falsey
          expect(subresource.name).to eq "sub"
          expect(subresource.identity).to eq "sub"
        end

        context "With identity_properties :x on the superclass" do
          before do
            resource_class.class_eval do
              identity_properties :x
            end
          end

          it "The subclass inherits :x as identity" do
            expect(subresource_class.identity_properties).to eq [ subresource_class.properties[:x] ]
            expect(Chef::Resource.properties[:name].identity?).to be_falsey
            expect(subresource_class.properties[:x].identity?).to be_truthy

            subresource.x "foo"
            expect(subresource.identity).to eq "foo"
          end

          context "With property :y, identity: true on the subclass" do
            before do
              subresource_class.class_eval do
                property :y, identity: true
              end
            end
            it "The subclass's identity includes both x and y" do
              expect(subresource_class.identity_properties).to eq [
                subresource_class.properties[:x],
                subresource_class.properties[:y],
              ]
              subresource.x "foo"
              subresource.y "bar"
              expect(subresource.identity).to eq(x: "foo", y: "bar")
            end
          end

          with_property ":y, String" do
            context "With identity_properties :y on the subclass" do
              before do
                subresource_class.class_eval do
                  identity_properties :y
                end
              end
              it "y is part of state" do
                subresource.x "foo"
                subresource.y "bar"
                expect(subresource.state_for_resource_reporter).to eq(x: "foo", y: "bar")
                expect(subresource_class.state_properties).to eq [
                  subresource_class.properties[:x],
                  subresource_class.properties[:y],
                ]
              end
              it "y is the identity" do
                expect(subresource_class.identity_properties).to eq [ subresource_class.properties[:y] ]
                subresource.x "foo"
                subresource.y "bar"
                expect(subresource.identity).to eq "bar"
              end
              it "y still has validation" do
                expect { subresource.y 12 }.to raise_error Chef::Exceptions::ValidationFailed
              end
            end
          end
        end
      end
    end

    with_property ":string_only, String, identity: true", ":string_only2, String" do
      it "identity_properties does not change validation" do
        resource_class.identity_properties :string_only
        expect { resource.string_only 12 }.to raise_error Chef::Exceptions::ValidationFailed
        expect { resource.string_only2 12 }.to raise_error Chef::Exceptions::ValidationFailed
      end
    end

    with_property ":x, desired_state: false" do
      it "identity_properties does not change desired_state" do
        resource_class.identity_properties :x
        resource.x "hi"
        expect(resource.identity).to eq "hi"
        expect(resource_class.properties[:x].desired_state?).to be_falsey
        expect(resource_class.state_properties).to eq []
        expect(resource.state_for_resource_reporter).to eq({})
      end
    end

    context "With custom property custom_property defined only as methods, using different variables for storage" do
      before do
        resource_class.class_eval do
          def custom_property
            @blarghle ? @blarghle * 3 : nil
          end

          def custom_property=(x)
            @blarghle = x * 2
          end
        end
      end

      context "And identity_properties :custom_property" do
        before do
          resource_class.class_eval do
            identity_properties :custom_property
          end
        end

        it "identity_properties comes back as :custom_property" do
          expect(resource_class.properties[:custom_property].identity?).to be_truthy
          expect(resource_class.identity_properties).to eq [ resource_class.properties[:custom_property] ]
        end
        it "custom_property becomes part of desired_state" do
          resource.custom_property = 1
          expect(resource.state_for_resource_reporter).to eq(custom_property: 6)
          expect(resource_class.properties[:custom_property].desired_state?).to be_truthy
          expect(resource_class.state_properties).to eq [
            resource_class.properties[:custom_property],
          ]
        end
        it "identity_properties does not change custom_property's getter or setter" do
          resource.custom_property = 1
          expect(resource.custom_property).to eq 6
        end
        it "custom_property is returned as the identity" do
          expect(resource.identity).to be_nil
          resource.custom_property = 1
          expect(resource.identity).to eq 6
        end
      end
    end
  end

  context "Property#identity" do
    with_property ":x, identity: true" do
      it "name is only part of the identity if an identity attribute is defined" do
        expect(resource_class.identity_properties).to eq [ resource_class.properties[:x] ]
        resource.x "woo"
        expect(resource.identity).to eq "woo"
      end
    end

    with_property ":x, identity: true, default: 'xxx'",
                  ":y, identity: true, default: 'yyy'",
                  ":z, identity: true, default: 'zzz'" do
      it "identity_property raises an error if multiple identity values are defined" do
        expect { resource_class.identity_property }.to raise_error Chef::Exceptions::MultipleIdentityError
      end
      it "identity_attr raises an error if multiple identity values are defined" do
        expect { resource_class.identity_attr }.to raise_error Chef::Exceptions::MultipleIdentityError
      end
      it "identity returns all identity values in a hash if multiple are defined" do
        resource.x "foo"
        resource.y "bar"
        resource.z "baz"
        expect(resource.identity).to eq(x: "foo", y: "bar", z: "baz")
      end
      it "identity returns all values whether any value is set or not" do
        expect(resource.identity).to eq(x: "xxx", y: "yyy", z: "zzz")
      end
      it "identity_properties wipes out any other identity attributes if multiple are defined" do
        resource_class.identity_properties :y
        resource.x "foo"
        resource.y "bar"
        resource.z "baz"
        expect(resource.identity).to eq "bar"
      end
    end

    with_property ":x, identity: true, name_property: true" do
      it "identity when x is not defined returns the value of x" do
        expect(resource.identity).to eq "blah"
      end
      it "state when x is not defined returns the value of x" do
        expect(resource.state_for_resource_reporter).to eq(x: "blah")
      end
    end
  end

  # state_properties
  context "Chef::Resource#state_properties" do
    it "state_properties is empty by default" do
      expect(Chef::Resource.state_properties).to eq []
      expect(resource.state_for_resource_reporter).to eq({})
    end

    with_property ":x", ":y", ":z" do
      it "x, y and z are state attributes" do
        resource.x 1
        resource.y 2
        resource.z 3
        expect(resource_class.state_properties).to eq [
          resource_class.properties[:x],
          resource_class.properties[:y],
          resource_class.properties[:z],
        ]
        expect(resource.state_for_resource_reporter).to eq(x: 1, y: 2, z: 3)
      end
      it "values that are not set are not included in state" do
        resource.x 1
        expect(resource.state_for_resource_reporter).to eq(x: 1)
      end
      it "when no values are set, nothing is included in state" do
      end
    end

    with_property ":x", ":y, desired_state: false", ":z, desired_state: true" do
      it "x and z are state attributes, and y is not" do
        resource.x 1
        resource.y 2
        resource.z 3
        expect(resource_class.state_properties).to eq [
          resource_class.properties[:x],
          resource_class.properties[:z],
        ]
        expect(resource.state_for_resource_reporter).to eq(x: 1, z: 3)
      end
    end

    with_property ":x, name_property: true" do
      # it "Unset values with name_property are included in state" do
      #   expect(resource.state_for_resource_reporter).to eq({ x: 'blah' })
      # end
      it "Set values with name_property are included in state" do
        resource.x 1
        expect(resource.state_for_resource_reporter).to eq(x: 1)
      end
    end

    with_property ":x, default: 1" do
      it "Unset values with defaults are not included in state" do
        expect(resource.state_for_resource_reporter).to eq({})
      end
      it "Set values with defaults are included in state" do
        resource.x 1
        expect(resource.state_for_resource_reporter).to eq(x: 1)
      end
    end

    context "With a class with a normal getter and setter" do
      before do
        resource_class.class_eval do
          def x
            @blah * 3
          end

          def x=(value)
            @blah = value * 2
          end
        end
      end
      it "state_properties(:x) causes the value to be included in properties" do
        resource_class.state_properties(:x)
        resource.x = 1

        expect(resource.x).to eq 6
        expect(resource.state_for_resource_reporter).to eq(x: 6)
      end
    end

    context "When state_properties happens before properties are declared" do
      before do
        resource_class.class_eval do
          state_properties :x
          property :x
        end
      end
      it "the property works and is in state_properties" do
        expect(resource_class.state_properties).to include(resource_class.properties[:x])
        resource.x = 1
        expect(resource.x).to eq 1
        expect(resource.state_for_resource_reporter).to eq(x: 1)
      end
    end

    with_property ":x, Integer, identity: true" do
      it "state_properties(:x) leaves the property in desired_state" do
        resource_class.state_properties(:x)
        resource.x 10

        expect(resource_class.properties[:x].desired_state?).to be_truthy
        expect(resource_class.state_properties).to eq [
          resource_class.properties[:x],
        ]
        expect(resource.state_for_resource_reporter).to eq(x: 10)
      end
      it "state_properties(:x) does not turn off validation" do
        resource_class.state_properties(:x)
        expect { resource.x "ouch" }.to raise_error Chef::Exceptions::ValidationFailed
      end
      it "state_properties(:x) does not turn off identity" do
        resource_class.state_properties(:x)
        resource.x 10

        expect(resource_class.identity_properties).to eq [ resource_class.properties[:x] ]
        expect(resource_class.properties[:x].identity?).to be_truthy
        expect(resource.identity).to eq 10
      end
    end

    with_property ":x, Integer, identity: true, desired_state: false" do
      before do
        resource_class.class_eval do
          def y
            20
          end
        end
      end

      it "state_properties(:x) leaves x identical" do
        old_value = resource_class.properties[:y]
        resource_class.state_properties(:x)
        resource.x 10

        expect(resource_class.properties[:y].object_id).to eq old_value.object_id

        expect(resource_class.properties[:x].desired_state?).to be_truthy
        expect(resource_class.properties[:x].identity?).to be_truthy
        expect(resource_class.identity_properties).to eq [
          resource_class.properties[:x],
        ]
        expect(resource.identity).to eq(10)
        expect(resource_class.state_properties).to eq [
          resource_class.properties[:x],
        ]
        expect(resource.state_for_resource_reporter).to eq(x: 10)
      end

      it "state_properties(:y) adds y to desired state" do
        old_value = resource_class.properties[:x]
        resource_class.state_properties(:y)
        resource.x 10

        expect(resource_class.properties[:x].object_id).to eq old_value.object_id
        expect(resource_class.properties[:x].desired_state?).to be_falsey
        expect(resource_class.properties[:y].desired_state?).to be_truthy
        expect(resource_class.state_properties).to eq [
          resource_class.properties[:y],
        ]
        expect(resource.state_for_resource_reporter).to eq(y: 20)
      end

      context "With a subclassed resource" do
        let(:subresource_class) do
          new_resource_name = self.class.new_resource_name
          Class.new(resource_class) do
            resource_name new_resource_name
          end
        end
        let(:subresource) do
          subresource_class.new("blah")
        end

        it "state_properties(:x) adds x to desired state" do
          old_value = resource_class.properties[:y]
          subresource_class.state_properties(:x)
          subresource.x 10

          expect(subresource_class.properties[:y].object_id).to eq old_value.object_id

          expect(subresource_class.properties[:x].desired_state?).to be_truthy
          expect(subresource_class.properties[:x].identity?).to be_truthy
          expect(subresource_class.identity_properties).to eq [
            subresource_class.properties[:x],
          ]
          expect(subresource.identity).to eq(10)
          expect(subresource_class.state_properties).to eq [
            subresource_class.properties[:x],
          ]
          expect(subresource.state_for_resource_reporter).to eq(x: 10)
        end

        it "state_properties(:y) adds y to desired state" do
          old_value = resource_class.properties[:x]
          subresource_class.state_properties(:y)
          subresource.x 10

          expect(subresource_class.properties[:x].object_id).to eq old_value.object_id
          expect(subresource_class.properties[:y].desired_state?).to be_truthy
          expect(subresource_class.state_properties).to eq [
            subresource_class.properties[:y],
          ]
          expect(subresource.state_for_resource_reporter).to eq(y: 20)

          expect(subresource_class.properties[:x].identity?).to be_truthy
          expect(subresource_class.identity_properties).to eq [
            subresource_class.properties[:x],
          ]
          expect(subresource.identity).to eq(10)
        end
      end
    end
  end

end
