require "support/shared/integration/integration_helper"

describe "Resource::ActionClass#converge_if_changed" do
  include IntegrationSupport

  module Namer
    extend self
    attr_accessor :current_index
    def incrementing_value
      @incrementing_value += 1
      @incrementing_value
    end
    attr_writer :incrementing_value
  end

  before(:all) { Namer.current_index = 1 }
  before { Namer.current_index += 1 }
  before { Namer.incrementing_value = 0 }

  context "when the resource has identity, state and control properties" do
    let(:resource_name) { :"converge_if_changed_dsl#{Namer.current_index}" }
    let(:resource_class) do
      result = Class.new(Chef::Resource) do
        def self.to_s; resource_name.to_s; end

        def self.inspect; resource_name.inspect; end
        property :identity1, identity: true, default: "default_identity1"
        property :control1, desired_state: false, default: "default_control1"
        property :state1, default: "default_state1"
        property :state2, default: "default_state2"
        attr_accessor :converged
        def initialize(*args)
          super
          @converged = 0
        end
      end
      result.resource_name resource_name
      result
    end
    let(:converged_recipe) { converge(converge_recipe) }
    let(:resource) { converged_recipe.resources.first }

    context "and converge_if_changed with no parameters" do
      before :each do
        resource_class.action :create do
          converge_if_changed do
            new_resource.converged += 1
          end
        end
      end

      context "and current_resource with state1=current, state2=current" do
        before :each do
          resource_class.load_current_value do
            state1 "current_state1"
            state2 "current_state2"
          end
        end

        context "and nothing is set" do
          let(:converge_recipe) { "#{resource_name} 'blah'" }

          it "the resource updates nothing" do
            expect(resource.converged).to eq 0
            expect(resource.updated?).to  be_falsey
            expect(converged_recipe.stdout).to eq <<-EOM
* #{resource_name}[blah] action create (up to date)
            EOM
          end
        end

        context "and state1 is set to a new value" do
          let(:converge_recipe) do
            <<-EOM
              #{resource_name} 'blah' do
                state1 'new_state1'
              end
            EOM
          end

          it "the resource updates state1" do
            expect(resource.converged).to eq 1
            expect(resource.updated?).to  be_truthy
            expect(converged_recipe.stdout).to eq <<-EOM
* #{resource_name}[blah] action create
  - update default_identity1
  -   set state1 to "new_state1" (was "current_state1")
              EOM
          end
        end

        context "and state1 and state2 are set to new values" do
          let(:converge_recipe) do
            <<-EOM
              #{resource_name} 'blah' do
                state1 'new_state1'
                state2 'new_state2'
              end
            EOM
          end

          it "the resource updates state1 and state2" do
            expect(resource.converged).to eq 1
            expect(resource.updated?).to  be_truthy
            expect(converged_recipe.stdout).to eq <<-EOM
* #{resource_name}[blah] action create
  - update default_identity1
  -   set state1 to "new_state1" (was "current_state1")
  -   set state2 to "new_state2" (was "current_state2")
EOM
          end
        end

        context "and state1 and state2 are set to new sensitive values" do
          let(:converge_recipe) do
            <<-EOM
              #{resource_name} 'blah' do
                sensitive true
                state1 'new_state1'
                state2 'new_state2'
              end
            EOM
          end

          it "the resource updates state1 and state2" do
            expect(resource.converged).to eq 1
            expect(resource.updated?).to  be_truthy
            expect(converged_recipe.stdout).to eq <<-EOM
* #{resource_name}[blah] action create
  - update default_identity1
  -   set state1 to (suppressed sensitive property)
  -   set state2 to (suppressed sensitive property)
EOM
          end
        end

        context "and state1 is set to its current value but state2 is set to a new value" do
          let(:converge_recipe) do
            <<-EOM
              #{resource_name} 'blah' do
                state1 'current_state1'
                state2 'new_state2'
              end
            EOM
          end

          it "the resource updates state2" do
            expect(resource.converged).to eq 1
            expect(resource.updated?).to  be_truthy
            expect(converged_recipe.stdout).to eq <<-EOM
* #{resource_name}[blah] action create
  - update default_identity1
  -   set state2 to "new_state2" (was "current_state2")
EOM
          end
        end

        context "and state1 and state2 are set to their current values" do
          let(:converge_recipe) do
            <<-EOM
              #{resource_name} 'blah' do
                state1 'current_state1'
                state2 'current_state2'
              end
            EOM
          end

          it "the resource updates nothing" do
            expect(resource.converged).to eq 0
            expect(resource.updated?).to  be_falsey
            expect(converged_recipe.stdout).to eq <<-EOM
* #{resource_name}[blah] action create (up to date)
EOM
          end
        end

        context "and identity1 and control1 are set to new values" do
          let(:converge_recipe) do
            <<-EOM
              #{resource_name} 'blah' do
                identity1 'new_identity1'
                control1 'new_control1'
              end
            EOM
          end

          # Because the identity value is copied over to the new resource, by
          # default they do not register as "changed"
          it "the resource updates nothing" do
            expect(resource.converged).to eq 0
            expect(resource.updated?).to  be_falsey
            expect(converged_recipe.stdout).to eq <<-EOM
* #{resource_name}[blah] action create (up to date)
EOM
          end
        end
      end

      context "and current_resource with identity1=current, control1=current" do
        before :each do
          resource_class.load_current_value do
            identity1 "current_identity1"
            control1 "current_control1"
          end
        end

        context "and identity1 and control1 are set to new values" do
          let(:converge_recipe) do
            <<-EOM
              #{resource_name} 'blah' do
                identity1 'new_identity1'
                control1 'new_control1'
              end
            EOM
          end

          # Control values are not desired state and are therefore not considered
          # a reason for converging.
          it "the resource updates identity1" do
            expect(resource.converged).to eq 1
            expect(resource.updated?).to  be_truthy
            expect(converged_recipe.stdout).to eq <<-EOM
* #{resource_name}[blah] action create
  - update current_identity1
  -   set identity1 to "new_identity1" (was "current_identity1")
            EOM
          end
        end
      end

      context "and has no current_resource" do
        before :each do
          resource_class.load_current_value do
            current_value_does_not_exist!
          end
        end

        context "and nothing is set" do
          let(:converge_recipe) { "#{resource_name} 'blah'" }

          it "the resource is created" do
            expect(resource.converged).to eq 1
            expect(resource.updated?).to  be_truthy
            expect(converged_recipe.stdout).to eq <<-EOM
* #{resource_name}[blah] action create
  - create default_identity1
  -   set identity1 to "default_identity1" (default value)
  -   set state1    to "default_state1" (default value)
  -   set state2    to "default_state2" (default value)
EOM
          end
        end

        context "and state1 and state2 are set" do
          let(:converge_recipe) do
            <<-EOM
              #{resource_name} 'blah' do
                state1 'new_state1'
                state2 'new_state2'
              end
            EOM
          end

          it "the resource is created" do
            expect(resource.converged).to eq 1
            expect(resource.updated?).to  be_truthy
            expect(converged_recipe.stdout).to eq <<-EOM
* #{resource_name}[blah] action create
  - create default_identity1
  -   set identity1 to "default_identity1" (default value)
  -   set state1    to "new_state1"
  -   set state2    to "new_state2"
EOM
          end
        end

        context "and state1 and state2 are set with sensitive property" do
          let(:converge_recipe) do
            <<-EOM
              #{resource_name} 'blah' do
                sensitive true
                state1 'new_state1'
                state2 'new_state2'
              end
            EOM
          end

          it "the resource is created" do
            expect(resource.converged).to eq 1
            expect(resource.updated?).to  be_truthy
            expect(converged_recipe.stdout).to eq <<-EOM
* #{resource_name}[blah] action create
  - create default_identity1
  -   set identity1 to (suppressed sensitive property) (default value)
  -   set state1    to (suppressed sensitive property)
  -   set state2    to (suppressed sensitive property)
EOM
          end
        end
      end
    end

    context "and separate converge_if_changed :state1 and converge_if_changed :state2" do
      before :each do
        resource_class.action :create do
          converge_if_changed :state1 do
            new_resource.converged += 1
          end
          converge_if_changed :state2 do
            new_resource.converged += 1
          end
        end
      end

      context "and current_resource with state1=current, state2=current" do
        before :each do
          resource_class.load_current_value do
            state1 "current_state1"
            state2 "current_state2"
          end
        end

        context "and nothing is set" do
          let(:converge_recipe) { "#{resource_name} 'blah'" }

          it "the resource updates nothing" do
            expect(resource.converged).to eq 0
            expect(resource.updated?).to  be_falsey
            expect(converged_recipe.stdout).to eq <<-EOM
* #{resource_name}[blah] action create (up to date)
EOM
          end
        end

        context "and state1 is set to a new value" do

          let(:converge_recipe) do
            <<-EOM
              #{resource_name} 'blah' do
                state1 'new_state1'
              end
            EOM
          end

          it "the resource updates state1" do
            expect(resource.converged).to eq 1
            expect(resource.updated?).to  be_truthy
            expect(converged_recipe.stdout).to eq <<-EOM
* #{resource_name}[blah] action create
  - update default_identity1
  -   set state1 to "new_state1" (was "current_state1")
EOM
          end
        end

        context "and state1 and state2 are set to new values" do
          let(:converge_recipe) do
            <<-EOM
              #{resource_name} 'blah' do
                state1 'new_state1'
                state2 'new_state2'
              end
            EOM
          end

          it "the resource updates state1 and state2" do
            expect(resource.converged).to eq 2
            expect(resource.updated?).to  be_truthy
            expect(converged_recipe.stdout).to eq <<-EOM
* #{resource_name}[blah] action create
  - update default_identity1
  -   set state1 to "new_state1" (was "current_state1")
  - update default_identity1
  -   set state2 to "new_state2" (was "current_state2")
EOM
          end
        end

        context "and state1 is set to its current value but state2 is set to a new value" do
          let(:converge_recipe) do
            <<-EOM
              #{resource_name} 'blah' do
                state1 'current_state1'
                state2 'new_state2'
              end
            EOM
          end

          it "the resource updates state2" do
            expect(resource.converged).to eq 1
            expect(resource.updated?).to  be_truthy
            expect(converged_recipe.stdout).to eq <<-EOM
* #{resource_name}[blah] action create
  - update default_identity1
  -   set state2 to "new_state2" (was "current_state2")
EOM
          end
        end

        context "and state1 and state2 are set to their current values" do
          let(:converge_recipe) do
            <<-EOM
              #{resource_name} 'blah' do
                state1 'current_state1'
                state2 'current_state2'
              end
            EOM
          end

          it "the resource updates nothing" do
            expect(resource.converged).to eq 0
            expect(resource.updated?).to  be_falsey
            expect(converged_recipe.stdout).to eq <<-EOM
* #{resource_name}[blah] action create (up to date)
EOM
          end
        end
      end

      context "and no current_resource" do
        before :each do
          resource_class.load_current_value do
            current_value_does_not_exist!
          end
        end

        context "and nothing is set" do
          let(:converge_recipe) do
            "#{resource_name} 'blah'"
          end

          it "the resource is created" do
            expect(resource.converged).to eq 2
            expect(resource.updated?).to  be_truthy
            expect(converged_recipe.stdout).to eq <<-EOM
* #{resource_name}[blah] action create
  - create default_identity1
  -   set state1 to "default_state1" (default value)
  - create default_identity1
  -   set state2 to "default_state2" (default value)
EOM
          end
        end

        context "and state1 and state2 are set to new values" do
          let(:converge_recipe) do
            <<-EOM
              #{resource_name} 'blah' do
                state1 'new_state1'
                state2 'new_state2'
              end
            EOM
          end

          it "the resource is created" do
            expect(resource.converged).to eq 2
            expect(resource.updated?).to  be_truthy
            expect(converged_recipe.stdout).to eq <<-EOM
* #{resource_name}[blah] action create
  - create default_identity1
  -   set state1 to "new_state1"
  - create default_identity1
  -   set state2 to "new_state2"
EOM
          end
        end

        context "and state1 and state2 are set to new sensitive values" do
          let(:converge_recipe) do
            <<-EOM
              #{resource_name} 'blah' do
                sensitive true
                state1 'new_state1'
                state2 'new_state2'
              end
            EOM
          end

          it "the resource is created" do
            expect(resource.converged).to eq 2
            expect(resource.updated?).to be_truthy
            expect(converged_recipe.stdout).to eq <<-EOM
* #{resource_name}[blah] action create
  - create default_identity1
  -   set state1 to (suppressed sensitive property)
  - create default_identity1
  -   set state2 to (suppressed sensitive property)
EOM
          end
        end

      end
    end

  end
end
