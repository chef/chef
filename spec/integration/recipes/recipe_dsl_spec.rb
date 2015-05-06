require 'support/shared/integration/integration_helper'

describe "Recipe DSL methods" do
  include IntegrationSupport

  context "With resource 'base_thingy' declared as BaseThingy" do
    before(:context) {

      class BaseThingy < Chef::Resource
        def initialize(*args, &block)
          super
          @resource_name = 'base_thingy'
          @allowed_actions = [ :create ]
          @action = :create
        end

        class<<self
          attr_accessor :created_resource
          attr_accessor :created_provider
        end

        def provider
          Provider
        end
        class Provider < Chef::Provider
          def load_current_resource
          end
          def action_create
            BaseThingy.created_resource = new_resource.class
            BaseThingy.created_provider = self.class
          end
        end
      end

      # Modules to put stuff in
      module Foo; end
      module Foo::Bar; end

    }

    before :each do
      BaseThingy.created_resource = nil
      BaseThingy.created_provider = nil
    end

    context "Deprecated automatic resource DSL" do
      before do
        Chef::Config[:treat_deprecation_warnings_as_errors] = false
      end

      context "With a resource 'backcompat_thingy' declared in Chef::Resource and Chef::Provider" do
        before(:context) {

          class Chef::Resource::BackcompatThingy < Chef::Resource
            def initialize(*args, &block)
              super
              @resource_name = 'backcompat_thingy'
              @allowed_actions = [ :create ]
              @action = :create
            end
          end
          class Chef::Provider::BackcompatThingy < Chef::Provider
            def load_current_resource
            end
            def action_create
              BaseThingy.created_resource = new_resource.class
              BaseThingy.created_provider = self.class
            end
          end

        }

        it "backcompat_thingy creates a Chef::Resource::BackcompatThingy" do
          recipe = converge {
            backcompat_thingy 'blah' do; end
          }
          expect(recipe.logged_warnings).to match /Class Chef::Resource::BackcompatThingy does not declare 'provides :backcompat_thingy'/i
          expect(BaseThingy.created_resource).to eq Chef::Resource::BackcompatThingy
          expect(BaseThingy.created_provider).to eq Chef::Provider::BackcompatThingy
        end

        context "And another resource 'backcompat_thingy' in BackcompatThingy with 'provides'" do
          before(:context) {

            class Foo::BackcompatThingy < BaseThingy
              provides :backcompat_thingy
            end

          }

          it "backcompat_thingy creates a BackcompatThingy" do
            recipe = converge {
              backcompat_thingy 'blah' do; end
            }
            expect(recipe.logged_warnings).to eq ''
            expect(BaseThingy.created_resource).not_to be_nil
          end
        end
      end

      context "With a resource named Foo::Bar::Thingy" do
        before(:context) {

          class Foo::Bar::Thingy < BaseThingy; end

        }

        it "thingy does not work" do
          expect_converge {
            thingy 'blah' do; end
          }.to raise_error(NoMethodError)
        end
      end
    end

    context "provides" do
      context "When MySupplier provides :hemlock" do
        before(:context) {

          class Foo::MySupplier < BaseThingy
            provides :hemlock
          end

        }

        it "my_supplier does not work in a recipe" do
          expect_converge {
            my_supplier 'blah' do; end
          }.to raise_error(NoMethodError)
        end

        it "hemlock works in a recipe" do
          expect_recipe {
            hemlock 'blah' do; end
          }.to emit_no_warnings_or_errors
          expect(BaseThingy.created_resource).to eq Foo::MySupplier
        end
      end

      context "When Thingy3 provides :thingy3" do
        before(:context) {

          class Foo::Thingy3 < BaseThingy
            provides :thingy3
          end

        }

        it "thingy3 works in a recipe" do
          expect_recipe {
            thingy3 'blah' do; end
          }.to emit_no_warnings_or_errors
          expect(BaseThingy.created_resource).to eq Foo::Thingy3
        end

        context "And Thingy4 provides :thingy3" do
          before(:context) {

            class Foo::Thingy4 < BaseThingy
              provides :thingy3
            end

          }

          it "thingy3 works in a recipe and yields Foo::Thingy4 (the explicit one)" do
            recipe = converge {
              thingy3 'blah' do; end
            }
            expect(BaseThingy.created_resource).to eq Foo::Thingy4
          end

          it "thingy4 does not work in a recipe" do
            expect_converge {
              thingy4 'blah' do; end
            }.to raise_error(NoMethodError)
          end
        end
      end

      context "When Thingy5 provides :thingy5, :twizzle and :twizzle2" do
        before(:context) {

          class Foo::Thingy5 < BaseThingy
            provides :thingy5
            provides :twizzle
            provides :twizzle2
          end

        }

        it "thingy5 works in a recipe and yields Thingy5" do
          expect_recipe {
            thingy5 'blah' do; end
          }.to emit_no_warnings_or_errors
          expect(BaseThingy.created_resource).to eq Foo::Thingy5
        end

        it "twizzle works in a recipe and yields Thingy5" do
          expect_recipe {
            twizzle 'blah' do; end
          }.to emit_no_warnings_or_errors
          expect(BaseThingy.created_resource).to eq Foo::Thingy5
        end

        it "twizzle2 works in a recipe and yields Thingy5" do
          expect_recipe {
            twizzle2 'blah' do; end
          }.to emit_no_warnings_or_errors
          expect(BaseThingy.created_resource).to eq Foo::Thingy5
        end
      end

      context "With platform-specific resources 'my_super_thingy_foo' and 'my_super_thingy_bar'" do
        before(:context) {
          class MySuperThingyFoo < BaseThingy
            provides :my_super_thingy, platform: 'foo'
          end

          class MySuperThingyBar < BaseThingy
            provides :my_super_thingy, platform: 'bar'
          end
        }

        it "A run with platform 'foo' uses MySuperThingyFoo" do
          r = Cheffish::ChefRun.new(chef_config)
          r.client.run_context.node.automatic['platform'] = 'foo'
          r.compile_recipe {
            my_super_thingy 'blah' do; end
          }
          r.converge
          expect(r).to emit_no_warnings_or_errors
          expect(BaseThingy.created_resource).to eq MySuperThingyFoo
        end

        it "A run with platform 'bar' uses MySuperThingyBar" do
          r = Cheffish::ChefRun.new(chef_config)
          r.client.run_context.node.automatic['platform'] = 'bar'
          r.compile_recipe {
            my_super_thingy 'blah' do; end
          }
          r.converge
          expect(r).to emit_no_warnings_or_errors
          expect(BaseThingy.created_resource).to eq MySuperThingyBar
        end

        it "A run with platform 'x' reports that my_super_thingy is not supported" do
          r = Cheffish::ChefRun.new(chef_config)
          r.client.run_context.node.automatic['platform'] = 'x'
          expect {
            r.compile_recipe {
              my_super_thingy 'blah' do; end
            }
          }.to raise_error(Chef::Exceptions::NoSuchResourceType)
        end
      end
    end
  end
end
