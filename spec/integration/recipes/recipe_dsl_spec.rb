require "spec_helper"
require "support/shared/integration/integration_helper"

describe "Recipe DSL methods" do
  include IntegrationSupport

  module Namer
    extend self
    attr_accessor :current_index
  end

  before(:all) { Namer.current_index = 1 }
  before { Namer.current_index += 1 }

  context "with resource 'base_thingy' declared as BaseThingy" do
    before(:each) do

      class BaseThingy < Chef::Resource
        provides :base_thingy
        default_action :create

        class<<self
          attr_accessor :created_name
          attr_accessor :created_resource
          attr_accessor :created_provider
        end

        def provider
          Provider
        end

        class Provider < Chef::Provider
          def load_current_resource; end

          def action_create
            BaseThingy.created_name = new_resource.name
            BaseThingy.created_resource = new_resource.class
            BaseThingy.created_provider = self.class
          end
        end
      end

      # Modules to put stuff in
      module RecipeDSLSpecNamespace; end
      module RecipeDSLSpecNamespace::Bar; end

    end

    before :each do
      BaseThingy.created_resource = nil
      BaseThingy.created_provider = nil
    end

    it "creates base_thingy when you call base_thingy in a recipe" do
      recipe = converge do
        base_thingy("blah") {}
      end
      expect(recipe.logged_warnings).to eq ""
      expect(BaseThingy.created_name).to eq "blah"
      expect(BaseThingy.created_resource).to eq BaseThingy
    end

    it "errors when you call base_thingy do ... end in a recipe" do
      expect_converge do
        base_thingy { ; }
      end.to raise_error(Chef::Exceptions::ValidationFailed)
    end

    context "nameless resources" do
      before(:each) do
        class NamelessThingy < BaseThingy
          provides :nameless_thingy

          property :name, String, default: ""
        end
      end

      it "does not error when not given a name" do
        recipe = converge do
          nameless_thingy {}
        end
        expect(recipe.logged_warnings).to eq ""
        expect(BaseThingy.created_name).to eq ""
        expect(BaseThingy.created_resource).to eq NamelessThingy
      end
    end

    context "Deprecated automatic resource DSL" do
      before do
        Chef::Config[:treat_deprecation_warnings_as_errors] = false
      end

      context "with a resource named RecipeDSLSpecNamespace::Bar::BarThingy" do
        before(:each) do

          class RecipeDSLSpecNamespace::Bar::BarThingy < BaseThingy
          end

        end

        it "bar_thingy does not work" do
          expect_converge do
            bar_thingy("blah") {}
          end.to raise_error(NoMethodError)
        end
      end

      context "with a resource named Chef::Resource::NoNameThingy with resource_name nil" do
        before(:each) do

          class Chef::Resource::NoNameThingy < BaseThingy
            resource_name nil
          end

        end

        it "no_name_thingy does not work" do
          expect_converge do
            no_name_thingy("blah") {}
          end.to raise_error(NoMethodError)
        end
      end

      context "with a resource named AnotherNoNameThingy with resource_name :another_thingy_name" do
        before(:each) do

          class AnotherNoNameThingy < BaseThingy
            provides :another_thingy_name
          end

        end

        it "another_no_name_thingy does not work" do
          expect_converge do
            another_no_name_thingy("blah") {}
          end.to raise_error(NoMethodError)
        end

        it "another_thingy_name works" do
          recipe = converge do
            another_thingy_name("blah") {}
          end
          expect(recipe.logged_warnings).to eq ""
          expect(BaseThingy.created_resource).to eq(AnotherNoNameThingy)
        end
      end

      context "with a resource named AnotherNoNameThingy2 with resource_name :another_thingy_name2; resource_name :another_thingy_name3" do
        before(:each) do

          class AnotherNoNameThingy2 < BaseThingy
            provides :another_thingy_name2
            provides :another_thingy_name3
          end

        end

        it "another_no_name_thingy does not work" do
          expect_converge do
            another_no_name_thingy2("blah") {}
          end.to raise_error(NoMethodError)
        end

        it "another_thingy_name2 works" do
          recipe = converge do
            another_thingy_name2("blah") {}
          end
          expect(recipe.logged_warnings).to eq ""
          expect(BaseThingy.created_resource).to eq(AnotherNoNameThingy2)
        end

        it "yet_another_thingy_name3 works" do
          recipe = converge do
            another_thingy_name3("blah") {}
          end
          expect(recipe.logged_warnings).to eq ""
          expect(BaseThingy.created_resource).to eq(AnotherNoNameThingy2)
        end
      end

      context "provides overriding resource_name" do
        context "with a resource named AnotherNoNameThingy3 with provides :another_no_name_thingy3, os: 'blarghle'" do
          before(:each) do

            class AnotherNoNameThingy3 < BaseThingy
              provides :another_no_name_thingy_3
              provides :another_no_name_thingy3, os: "blarghle"
            end

          end

          it "and os = linux, another_no_name_thingy3 does not work" do
            expect_converge do
              # TODO this is an ugly way to test, make Cheffish expose node attrs
              run_context.node.automatic[:os] = "linux"
              another_no_name_thingy3("blah") {}
            end.to raise_error(Chef::Exceptions::NoSuchResourceType)
          end

          it "and os = blarghle, another_no_name_thingy3 works" do
            recipe = converge do
              # TODO this is an ugly way to test, make Cheffish expose node attrs
              run_context.node.automatic[:os] = "blarghle"
              another_no_name_thingy3("blah") {}
            end
            expect(recipe.logged_warnings).to eq ""
            expect(BaseThingy.created_resource).to eq(AnotherNoNameThingy3)
          end
        end

        context "with a resource named AnotherNoNameThingy4 with two provides" do
          before(:each) do

            class AnotherNoNameThingy4 < BaseThingy
              provides :another_no_name_thingy_4
              provides :another_no_name_thingy4, os: "blarghle"
              provides :another_no_name_thingy4, platform_family: "foo"
            end

          end

          it "and os = linux, another_no_name_thingy4 does not work" do
            expect_converge do
              # TODO this is an ugly way to test, make Cheffish expose node attrs
              run_context.node.automatic[:os] = "linux"
              another_no_name_thingy4("blah") {}
            end.to raise_error(Chef::Exceptions::NoSuchResourceType)
          end

          it "and os = blarghle, another_no_name_thingy4 works" do
            recipe = converge do
              # TODO this is an ugly way to test, make Cheffish expose node attrs
              run_context.node.automatic[:os] = "blarghle"
              another_no_name_thingy4("blah") {}
            end
            expect(recipe.logged_warnings).to eq ""
            expect(BaseThingy.created_resource).to eq(AnotherNoNameThingy4)
          end

          it "and platform_family = foo, another_no_name_thingy4 works" do
            recipe = converge do
              # TODO this is an ugly way to test, make Cheffish expose node attrs
              run_context.node.automatic[:platform_family] = "foo"
              another_no_name_thingy4("blah") {}
            end
            expect(recipe.logged_warnings).to eq ""
            expect(BaseThingy.created_resource).to eq(AnotherNoNameThingy4)
          end
        end

        context "with a resource named AnotherNoNameThingy5, a different resource_name, and a provides with the original resource_name" do
          before(:each) do

            class AnotherNoNameThingy5 < BaseThingy
              provides :another_thingy_name_for_another_no_name_thingy5
              provides :another_no_name_thingy5, os: "blarghle"
            end

          end

          it "and os = linux, another_no_name_thingy5 does not work" do
            expect_converge do
              # this is an ugly way to test, make Cheffish expose node attrs
              run_context.node.automatic[:os] = "linux"
              another_no_name_thingy5("blah") {}
            end.to raise_error(Chef::Exceptions::NoSuchResourceType)
          end

          it "and os = blarghle, another_no_name_thingy5 works" do
            recipe = converge do
              # this is an ugly way to test, make Cheffish expose node attrs
              run_context.node.automatic[:os] = "blarghle"
              another_no_name_thingy5("blah") {}
            end
            expect(recipe.logged_warnings).to eq ""
            expect(BaseThingy.created_resource).to eq(AnotherNoNameThingy5)
          end

          it "the new resource name can be used in a recipe" do
            recipe = converge do
              another_thingy_name_for_another_no_name_thingy5("blah") {}
            end
            expect(recipe.logged_warnings).to eq ""
            expect(BaseThingy.created_resource).to eq(AnotherNoNameThingy5)
          end
        end

        context "with a resource named AnotherNoNameThingy6, a provides with the original resource name, and a different resource_name" do
          before(:each) do

            class AnotherNoNameThingy6 < BaseThingy
              provides :another_no_name_thingy6, os: "blarghle"
              provides :another_thingy_name_for_another_no_name_thingy6
            end

          end

          it "and os = linux, another_no_name_thingy6 does not work" do
            expect_converge do
              # this is an ugly way to test, make Cheffish expose node attrs
              run_context.node.automatic[:os] = "linux"
              another_no_name_thingy6("blah") {}
            end.to raise_error(Chef::Exceptions::NoSuchResourceType)
          end

          it "and os = blarghle, another_no_name_thingy6 works" do
            recipe = converge do
              # this is an ugly way to test, make Cheffish expose node attrs
              run_context.node.automatic[:os] = "blarghle"
              another_no_name_thingy6("blah") {}
            end
            expect(recipe.logged_warnings).to eq ""
            expect(BaseThingy.created_resource).to eq(AnotherNoNameThingy6)
          end

          it "the new resource name can be used in a recipe" do
            recipe = converge do
              another_thingy_name_for_another_no_name_thingy6("blah") {}
            end
            expect(recipe.logged_warnings).to eq ""
            expect(BaseThingy.created_resource).to eq(AnotherNoNameThingy6)
          end
        end

        context "with a resource named AnotherNoNameThingy7, a new resource_name, and provides with that new resource name" do
          before(:each) do

            class AnotherNoNameThingy7 < BaseThingy
              provides :another_thingy_name_for_another_no_name_thingy7
              provides :another_thingy_name_for_another_no_name_thingy7, os: "blarghle"
            end

          end

          it "and os = linux, another_thingy_name_for_another_no_name_thingy7 works" do
            recipe = converge do
              # this is an ugly way to test, make Cheffish expose node attrs
              run_context.node.automatic[:os] = "linux"
              another_thingy_name_for_another_no_name_thingy7("blah") {}
            end
            expect(recipe.logged_warnings).to eq ""
            expect(BaseThingy.created_resource).to eq(AnotherNoNameThingy7)
          end

          it "and os = blarghle, another_thingy_name_for_another_no_name_thingy7 works" do
            recipe = converge do
              # this is an ugly way to test, make Cheffish expose node attrs
              run_context.node.automatic[:os] = "blarghle"
              another_thingy_name_for_another_no_name_thingy7("blah") {}
            end
            expect(recipe.logged_warnings).to eq ""
            expect(BaseThingy.created_resource).to eq(AnotherNoNameThingy7)
          end

          it "the old resource name does not work" do
            expect_converge do
              # this is an ugly way to test, make Cheffish expose node attrs
              run_context.node.automatic[:os] = "linux"
              another_no_name_thingy_7("blah") {}
            end.to raise_error(NoMethodError)
          end
        end

      end
    end

    context "provides" do
      context "when MySupplier provides :hemlock" do
        before(:each) do

          class RecipeDSLSpecNamespace::MySupplier < BaseThingy
            provides :hemlock
          end

        end

        it "my_supplier does not work in a recipe" do
          expect_converge do
            my_supplier("blah") {}
          end.to raise_error(NoMethodError)
        end

        it "hemlock works in a recipe" do
          expect_recipe do
            hemlock("blah") {}
          end.to emit_no_warnings_or_errors
          expect(BaseThingy.created_resource).to eq RecipeDSLSpecNamespace::MySupplier
        end
      end

      context "when Thingy3 has resource_name :thingy3" do
        before(:each) do

          class RecipeDSLSpecNamespace::Thingy3 < BaseThingy
            provides :thingy3
          end

        end

        it "thingy3 works in a recipe" do
          expect_recipe do
            thingy3("blah") {}
          end.to emit_no_warnings_or_errors
          expect(BaseThingy.created_resource).to eq RecipeDSLSpecNamespace::Thingy3
        end

        context "and Thingy4 has resource_name :thingy3" do
          before(:each) do

            class RecipeDSLSpecNamespace::Thingy4 < BaseThingy
              provides :thingy3
            end

          end

          it "thingy3 works in a recipe and yields Thingy4 (the last one)" do
            recipe = converge do
              thingy3("blah") {}
            end
            expect(BaseThingy.created_resource).to eq RecipeDSLSpecNamespace::Thingy4
          end

          it "thingy4 does not work in a recipe" do
            expect_converge do
              thingy4("blah") {}
            end.to raise_error(NoMethodError)
          end

          it "resource_matching_short_name returns Thingy4" do
            expect(Chef::Resource.resource_matching_short_name(:thingy3)).to eq RecipeDSLSpecNamespace::Thingy4
          end
        end
      end

      context "when Thingy5 has resource_name :thingy5 and provides :thingy5reverse, :thingy5_2 and :thingy5_2reverse" do
        before(:each) do

          class RecipeDSLSpecNamespace::Thingy5 < BaseThingy
            provides :thingy5
            provides :thingy5reverse
            provides :thingy5_2
            provides :thingy5_2reverse
          end

        end

        it "thingy5 works in a recipe" do
          expect_recipe do
            thingy5("blah") {}
          end.to emit_no_warnings_or_errors
          expect(BaseThingy.created_resource).to eq RecipeDSLSpecNamespace::Thingy5
        end

        context "and Thingy6 provides :thingy5" do
          before(:each) do

            class RecipeDSLSpecNamespace::Thingy6 < BaseThingy
              provides :thingy6
              provides :thingy5
            end

          end

          it "thingy6 works in a recipe and yields Thingy6" do
            recipe = converge do
              thingy6("blah") {}
            end
            expect(BaseThingy.created_resource).to eq RecipeDSLSpecNamespace::Thingy6
          end

          it "thingy5 works in a recipe and yields Foo::Thingy6 (the last one)" do
            recipe = converge do
              thingy5("blah") {}
            end
            expect(BaseThingy.created_resource).to eq RecipeDSLSpecNamespace::Thingy6
          end

          it "resource_matching_short_name returns Thingy6" do
            expect(Chef::Resource.resource_matching_short_name(:thingy5)).to eq RecipeDSLSpecNamespace::Thingy6
          end

          context "and AThingy5 provides :thingy5reverse" do
            before(:each) do

              class RecipeDSLSpecNamespace::AThingy5 < BaseThingy
                provides :thingy5reverse
              end

            end

            it "thingy5reverse works in a recipe and yields AThingy5 (the alphabetical one)" do
              recipe = converge do
                thingy5reverse("blah") {}
              end
              expect(BaseThingy.created_resource).to eq RecipeDSLSpecNamespace::AThingy5
            end
          end

          context "and ZRecipeDSLSpecNamespace::Thingy5 provides :thingy5_2" do
            before(:each) do

              module ZRecipeDSLSpecNamespace
                class Thingy5 < BaseThingy
                  provides :thingy5_2
                end
              end

            end

            it "thingy5_2 works in a recipe and yields the ZRecipeDSLSpaceNamespace one (the last one)" do
              recipe = converge do
                thingy5_2("blah") {}
              end
              expect(BaseThingy.created_resource).to eq ZRecipeDSLSpecNamespace::Thingy5
            end
          end

          context "and ARecipeDSLSpecNamespace::Thingy5 provides :thingy5_2" do
            before(:each) do

              module ARecipeDSLSpecNamespace
                class Thingy5 < BaseThingy
                  provides :thingy5_2reverse
                end
              end

            end

            it "thingy5_2reverse works in a recipe and yields the ARecipeDSLSpaceNamespace one (the alphabetical one)" do
              recipe = converge do
                thingy5_2reverse("blah") {}
              end
              expect(BaseThingy.created_resource).to eq ARecipeDSLSpecNamespace::Thingy5
            end
          end
        end

        context "when Thingy3 has resource_name :thingy3" do
          before(:each) do

            class RecipeDSLSpecNamespace::Thingy3 < BaseThingy
              provides :thingy3
            end

          end

          it "thingy3 works in a recipe" do
            expect_recipe do
              thingy3("blah") {}
            end.to emit_no_warnings_or_errors
            expect(BaseThingy.created_resource).to eq RecipeDSLSpecNamespace::Thingy3
          end

          context "and Thingy4 has resource_name :thingy3" do
            before(:each) do

              class RecipeDSLSpecNamespace::Thingy4 < BaseThingy
                provides :thingy3
              end

            end

            it "thingy3 works in a recipe and yields Thingy4 (the last one)" do
              recipe = converge do
                thingy3("blah") {}
              end
              expect(BaseThingy.created_resource).to eq RecipeDSLSpecNamespace::Thingy4
            end

            it "thingy4 does not work in a recipe" do
              expect_converge do
                thingy4("blah") {}
              end.to raise_error(NoMethodError)
            end

            it "resource_matching_short_name returns Thingy4" do
              expect(Chef::Resource.resource_matching_short_name(:thingy3)).to eq RecipeDSLSpecNamespace::Thingy4
            end
          end

          context "and Thingy4 has resource_name :thingy3" do
            before(:each) do

              class RecipeDSLSpecNamespace::Thingy4 < BaseThingy
                provides :thingy3
              end

            end

            it "thingy3 works in a recipe and yields Thingy4 (the last one)" do
              recipe = converge do
                thingy3("blah") {}
              end
              expect(BaseThingy.created_resource).to eq RecipeDSLSpecNamespace::Thingy4
            end

            it "thingy4 does not work in a recipe" do
              expect_converge do
                thingy4("blah") {}
              end.to raise_error(NoMethodError)
            end

            it "resource_matching_short_name returns Thingy4" do
              expect(Chef::Resource.resource_matching_short_name(:thingy3)).to eq RecipeDSLSpecNamespace::Thingy4
            end
          end
        end

      end

      context "when Thingy7 provides :thingy8" do
        before(:each) do

          class RecipeDSLSpecNamespace::Thingy7 < BaseThingy
            provides :thingy7
            provides :thingy8
          end

        end

        context "and Thingy8 has resource_name :thingy8" do
          before(:each) do

            class RecipeDSLSpecNamespace::Thingy8 < BaseThingy
              provides :thingy8
            end

          end

          it "thingy7 works in a recipe and yields Thingy7" do
            recipe = converge do
              thingy7("blah") {}
            end
            expect(BaseThingy.created_resource).to eq RecipeDSLSpecNamespace::Thingy7
          end

          it "thingy8 works in a recipe and yields Thingy7 (last)" do
            recipe = converge do
              thingy8("blah") {}
            end
            expect(BaseThingy.created_resource).to eq RecipeDSLSpecNamespace::Thingy8
          end

          it "resource_matching_short_name returns Thingy8" do
            expect(Chef::Resource.resource_matching_short_name(:thingy8)).to eq RecipeDSLSpecNamespace::Thingy8
          end
        end
      end

      context "when Thingy12 provides :thingy12, :twizzle and :twizzle2" do
        before(:each) do

          class RecipeDSLSpecNamespace::Thingy12 < BaseThingy
            provides :thingy12
            provides :twizzle
            provides :twizzle2
          end

        end

        it "thingy12 works in a recipe and yields Thingy12" do
          expect_recipe do
            thingy12("blah") {}
          end.to emit_no_warnings_or_errors
          expect(BaseThingy.created_resource).to eq RecipeDSLSpecNamespace::Thingy12
        end

        it "twizzle works in a recipe and yields Thingy12" do
          expect_recipe do
            twizzle("blah") {}
          end.to emit_no_warnings_or_errors
          expect(BaseThingy.created_resource).to eq RecipeDSLSpecNamespace::Thingy12
        end

        it "twizzle2 works in a recipe and yields Thingy12" do
          expect_recipe do
            twizzle2("blah") {}
          end.to emit_no_warnings_or_errors
          expect(BaseThingy.created_resource).to eq RecipeDSLSpecNamespace::Thingy12
        end
      end

      context "with platform-specific resources 'my_super_thingy_foo' and 'my_super_thingy_bar'" do
        before(:each) do
          class MySuperThingyFoo < BaseThingy
            provides :my_super_thingy_foo
            provides :my_super_thingy, platform: "foo"
          end

          class MySuperThingyBar < BaseThingy
            provides :my_super_thingy_bar
            provides :my_super_thingy, platform: "bar"
          end
        end

        it "A run with platform 'foo' uses MySuperThingyFoo" do
          r = Cheffish::ChefRun.new(chef_config)
          r.client.run_context.node.automatic["platform"] = "foo"
          r.compile_recipe do
            my_super_thingy("blah") {}
          end
          r.converge
          expect(r).to emit_no_warnings_or_errors
          expect(BaseThingy.created_resource).to eq MySuperThingyFoo
        end

        it "A run with platform 'bar' uses MySuperThingyBar" do
          r = Cheffish::ChefRun.new(chef_config)
          r.client.run_context.node.automatic["platform"] = "bar"
          r.compile_recipe do
            my_super_thingy("blah") {}
          end
          r.converge
          expect(r).to emit_no_warnings_or_errors
          expect(BaseThingy.created_resource).to eq MySuperThingyBar
        end

        it "A run with platform 'x' reports that my_super_thingy is not supported" do
          r = Cheffish::ChefRun.new(chef_config)
          r.client.run_context.node.automatic["platform"] = "x"
          expect do
            r.compile_recipe do
              my_super_thingy("blah") {}
            end
          end.to raise_error(Chef::Exceptions::NoSuchResourceType)
        end
      end

      context "when Thingy10 provides :thingy10" do
        before(:each) do
          class RecipeDSLSpecNamespace::Thingy10 < BaseThingy
            provides :thingy10
          end
        end

        it "declaring a resource providing the same :thingy10 with override: true does not produce a warning" do
          expect(Chef::Log).not_to receive(:warn)
          class RecipeDSLSpecNamespace::Thingy10AlternateProvider < BaseThingy
            provides :thingy10, override: true
          end
        end
      end

      context "when Thingy11 provides :thingy11" do
        before(:each) do
          class RecipeDSLSpecNamespace::Thingy11 < BaseThingy
            provides :thingy10
          end
        end

        it "declaring a resource providing the same :thingy11 with os: 'linux' does not produce a warning" do
          expect(Chef::Log).not_to receive(:warn)
          class RecipeDSLSpecNamespace::Thingy11AlternateProvider < BaseThingy
            provides :thingy11, os: "linux"
          end
        end
      end
    end

    context "with a resource named 'B' with resource name :two_classes_one_dsl" do
      let(:two_classes_one_dsl) { :"two_classes_one_dsl#{Namer.current_index}" }
      let(:resource_class) do
        result = Class.new(BaseThingy) do
          def self.name
            "B"
          end

          def self.to_s; name; end

          def self.inspect; name.inspect; end
        end
        result.provides two_classes_one_dsl
        result
      end
      before { resource_class } # pull on it so it gets defined before the recipe runs

      context "and another resource named 'A' with resource_name :two_classes_one_dsl" do
        let(:resource_class_a) do
          result = Class.new(BaseThingy) do
            def self.name
              "A"
            end

            def self.to_s; name; end

            def self.inspect; name.inspect; end
          end
          result.provides two_classes_one_dsl
          result
        end
        before { resource_class_a } # pull on it so it gets defined before the recipe runs

        it "two_classes_one_dsl resolves to A (alphabetically earliest)" do
          temp_two_classes_one_dsl = two_classes_one_dsl
          recipe = converge do
            instance_eval("#{temp_two_classes_one_dsl} 'blah'")
          end
          expect(recipe.logged_warnings).to eq ""
          expect(BaseThingy.created_resource).to eq resource_class_a
        end

        it "resource_matching_short_name returns B" do
          expect(Chef::Resource.resource_matching_short_name(two_classes_one_dsl)).to eq resource_class_a
        end
      end

      context "and another resource named 'Z' with resource_name :two_classes_one_dsl" do
        let(:resource_class_z) do
          result = Class.new(BaseThingy) do
            def self.name
              "Z"
            end

            def self.to_s; name; end

            def self.inspect; name.inspect; end
          end
          result.provides two_classes_one_dsl
          result
        end
        before { resource_class_z } # pull on it so it gets defined before the recipe runs

        it "two_classes_one_dsl resolves to Z (last)" do
          temp_two_classes_one_dsl = two_classes_one_dsl
          recipe = converge do
            instance_eval("#{temp_two_classes_one_dsl} 'blah'")
          end
          expect(recipe.logged_warnings).to eq ""
          expect(BaseThingy.created_resource).to eq resource_class_z
        end

        it "resource_matching_short_name returns Z" do
          expect(Chef::Resource.resource_matching_short_name(two_classes_one_dsl)).to eq resource_class_z
        end

        context "and a priority array [ Z, B ]" do
          before do
            Chef.set_resource_priority_array(two_classes_one_dsl, [ resource_class_z, resource_class ])
          end

          it "two_classes_one_dsl resolves to Z (respects the priority array)" do
            temp_two_classes_one_dsl = two_classes_one_dsl
            recipe = converge do
              instance_eval("#{temp_two_classes_one_dsl} 'blah'")
            end
            expect(recipe.logged_warnings).to eq ""
            expect(BaseThingy.created_resource).to eq resource_class_z
          end

          it "resource_matching_short_name returns Z" do
            expect(Chef::Resource.resource_matching_short_name(two_classes_one_dsl)).to eq resource_class_z
          end
        end

        context "and priority arrays [ B ] and [ Z ]" do
          before do
            Chef.set_resource_priority_array(two_classes_one_dsl, [ resource_class ])
            Chef.set_resource_priority_array(two_classes_one_dsl, [ resource_class_z ])
          end

          it "two_classes_one_dsl resolves to Z (respects the most recent priority array)" do
            temp_two_classes_one_dsl = two_classes_one_dsl
            recipe = converge do
              instance_eval("#{temp_two_classes_one_dsl} 'blah'")
            end
            expect(recipe.logged_warnings).to eq ""
            expect(BaseThingy.created_resource).to eq resource_class_z
          end

          it "resource_matching_short_name returns Z" do
            expect(Chef::Resource.resource_matching_short_name(two_classes_one_dsl)).to eq resource_class_z
          end
        end
      end

      context "and a provider named 'B' which provides :two_classes_one_dsl" do
        before do
          resource_class.send(:define_method, :provider) { nil }
        end

        let(:provider_class) do
          result = Class.new(BaseThingy::Provider) do
            def self.name
              "B"
            end

            def self.to_s; name; end

            def self.inspect; name.inspect; end
          end
          result.provides two_classes_one_dsl
          result
        end
        before { provider_class } # pull on it so it gets defined before the recipe runs

        context "and another provider named 'A'" do
          let(:provider_class_a) do
            result = Class.new(BaseThingy::Provider) do
              def self.name
                "A"
              end

              def self.to_s; name; end

              def self.inspect; name.inspect; end
            end
            result
          end
          context "which provides :two_classes_one_dsl" do
            before { provider_class_a.provides two_classes_one_dsl }

            it "two_classes_one_dsl resolves to A (alphabetically earliest)" do
              temp_two_classes_one_dsl = two_classes_one_dsl
              recipe = converge do
                instance_eval("#{temp_two_classes_one_dsl} 'blah'")
              end
              expect(recipe.logged_warnings).to eq ""
              expect(BaseThingy.created_provider).to eq provider_class_a
            end
          end
          context "which provides(:two_classes_one_dsl) { false }" do
            before { provider_class_a.provides(two_classes_one_dsl) { false } }

            it "two_classes_one_dsl resolves to B (since A declined)" do
              temp_two_classes_one_dsl = two_classes_one_dsl
              recipe = converge do
                instance_eval("#{temp_two_classes_one_dsl} 'blah'")
              end
              expect(recipe.logged_warnings).to eq ""
              expect(BaseThingy.created_provider).to eq provider_class
            end
          end
        end

        context "and another provider named 'Z'" do
          let(:provider_class_z) do
            result = Class.new(BaseThingy::Provider) do
              def self.name
                "Z"
              end

              def self.to_s; name; end

              def self.inspect; name.inspect; end
            end
            result
          end
          before { provider_class_z } # pull on it so it gets defined before the recipe runs

          context "which provides :two_classes_one_dsl" do
            before { provider_class_z.provides two_classes_one_dsl }

            it "two_classes_one_dsl resolves to Z (last)" do
              temp_two_classes_one_dsl = two_classes_one_dsl
              recipe = converge do
                instance_eval("#{temp_two_classes_one_dsl} 'blah'")
              end
              expect(recipe.logged_warnings).to eq ""
              expect(BaseThingy.created_provider).to eq provider_class_z
            end

            context "with a priority array [ Z, B ]" do
              before { Chef.set_provider_priority_array two_classes_one_dsl, [ provider_class_z, provider_class ] }

              it "two_classes_one_dsl resolves to Z (respects the priority map)" do
                temp_two_classes_one_dsl = two_classes_one_dsl
                recipe = converge do
                  instance_eval("#{temp_two_classes_one_dsl} 'blah'")
                end
                expect(recipe.logged_warnings).to eq ""
                expect(BaseThingy.created_provider).to eq provider_class_z
              end
            end
          end

          context "which provides(:two_classes_one_dsl) { false }" do
            before { provider_class_z.provides(two_classes_one_dsl) { false } }

            context "with a priority array [ Z, B ]" do
              before { Chef.set_provider_priority_array two_classes_one_dsl, [ provider_class_z, provider_class ] }

              it "two_classes_one_dsl resolves to B (the next one in the priority map)" do
                temp_two_classes_one_dsl = two_classes_one_dsl
                recipe = converge do
                  instance_eval("#{temp_two_classes_one_dsl} 'blah'")
                end
                expect(recipe.logged_warnings).to eq ""
                expect(BaseThingy.created_provider).to eq provider_class
              end
            end

            context "with priority arrays [ B ] and [ Z ]" do
              before { Chef.set_provider_priority_array two_classes_one_dsl, [ provider_class_z ] }
              before { Chef.set_provider_priority_array two_classes_one_dsl, [ provider_class ] }

              it "two_classes_one_dsl resolves to B (the one in the next priority map)" do
                temp_two_classes_one_dsl = two_classes_one_dsl
                recipe = converge do
                  instance_eval("#{temp_two_classes_one_dsl} 'blah'")
                end
                expect(recipe.logged_warnings).to eq ""
                expect(BaseThingy.created_provider).to eq provider_class
              end
            end
          end
        end
      end

      context "and another resource Blarghle with provides :two_classes_one_dsl, os: 'blarghle'" do
        let(:resource_class_blarghle) do
          result = Class.new(BaseThingy) do
            def self.name
              "Blarghle"
            end

            def self.to_s; name; end

            def self.inspect; name.inspect; end
          end
          result.provides two_classes_one_dsl
          result.provides two_classes_one_dsl, os: "blarghle"
          result
        end
        before { resource_class_blarghle } # pull on it so it gets defined before the recipe runs

        it "on os = blarghle, two_classes_one_dsl resolves to Blarghle" do
          temp_two_classes_one_dsl = two_classes_one_dsl
          recipe = converge do
            # this is an ugly way to test, make Cheffish expose node attrs
            run_context.node.automatic[:os] = "blarghle"
            instance_eval("#{temp_two_classes_one_dsl} 'blah' do; end")
          end
          expect(recipe.logged_warnings).to eq ""
          expect(BaseThingy.created_resource).to eq resource_class_blarghle
        end

        it "on os = linux, two_classes_one_dsl resolves to B" do
          temp_two_classes_one_dsl = two_classes_one_dsl
          recipe = converge do
            # this is an ugly way to test, make Cheffish expose node attrs
            run_context.node.automatic[:os] = "linux"
            instance_eval("#{temp_two_classes_one_dsl} 'blah' do; end")
          end
          expect(recipe.logged_warnings).to eq ""
          expect(BaseThingy.created_resource).to eq resource_class_blarghle
        end
      end
    end

    context "with a resource MyResource" do
      let(:resource_class) do
        Class.new(BaseThingy) do
          def self.called_provides
            @called_provides
          end

          def to_s
            "MyResource"
          end
        end
      end
      let(:my_resource) { :"my_resource#{Namer.current_index}" }
      let(:blarghle_blarghle_little_star) { :"blarghle_blarghle_little_star#{Namer.current_index}" }

      context "with resource_name :my_resource" do
        before do
          resource_class.provides my_resource
        end

        context "with provides? returning true to my_resource" do
          before do
            temp_my_resource = my_resource
            resource_class.define_singleton_method(:provides?) do |node, resource_name|
              @called_provides = true
              resource_name == temp_my_resource
            end
          end

          it "my_resource returns the resource and calls provides?, but does not emit a warning" do
            dsl_name = my_resource
            recipe = converge do
              instance_eval("#{dsl_name} 'foo'")
            end
            expect(recipe.logged_warnings).to eq ""
            expect(BaseThingy.created_resource).to eq resource_class
            expect(resource_class.called_provides).to be_truthy
          end
        end

        context "and a provider" do
          let(:provider_class) do
            Class.new(BaseThingy::Provider) do
              def self.name
                "MyProvider"
              end

              def self.to_s; name; end

              def self.inspect; name.inspect; end

              def self.called_provides
                @called_provides
              end
            end
          end

          before do
            resource_class.send(:define_method, :provider) { nil }
          end

          context "that provides :my_resource" do
            before do
              provider_class.provides my_resource
            end

            context "with supports? returning true" do
              before do
                provider_class.define_singleton_method(:supports?) { |resource, action| true }
              end

              it "my_resource runs the provider and does not emit a warning" do
                temp_my_resource = my_resource
                recipe = converge do
                  instance_eval("#{temp_my_resource} 'foo'")
                end
                expect(recipe.logged_warnings).to eq ""
                expect(BaseThingy.created_provider).to eq provider_class
              end

              context "and another provider supporting :my_resource with supports? false" do
                let(:provider_class2) do
                  Class.new(BaseThingy::Provider) do
                    def self.name
                      "MyProvider2"
                    end

                    def self.to_s; name; end

                    def self.inspect; name.inspect; end

                    def self.called_provides
                      @called_provides
                    end
                    provides my_resource
                    def self.supports?(resource, action)
                      false
                    end
                  end
                end

                it "my_resource runs the first provider" do
                  temp_my_resource = my_resource
                  recipe = converge do
                    instance_eval("#{temp_my_resource} 'foo'")
                  end
                  expect(recipe.logged_warnings).to eq ""
                  expect(BaseThingy.created_provider).to eq provider_class
                end
              end
            end

            context "with supports? returning false" do
              before do
                provider_class.define_singleton_method(:supports?) { |resource, action| false }
              end

              # TODO no warning? ick
              it "my_resource runs the provider anyway" do
                temp_my_resource = my_resource
                recipe = converge do
                  instance_eval("#{temp_my_resource} 'foo'")
                end
                expect(recipe.logged_warnings).to eq ""
                expect(BaseThingy.created_provider).to eq provider_class
              end

              context "and another provider supporting :my_resource with supports? true" do
                let(:provider_class2) do
                  temp_my_resource = my_resource
                  Class.new(BaseThingy::Provider) do
                    def self.name
                      "MyProvider2"
                    end

                    def self.to_s; name; end

                    def self.inspect; name.inspect; end

                    def self.called_provides
                      @called_provides
                    end
                    provides temp_my_resource
                    def self.supports?(resource, action)
                      true
                    end
                  end
                end
                before { provider_class2 } # make sure the provider class shows up

                it "my_resource runs the other provider" do
                  temp_my_resource = my_resource
                  recipe = converge do
                    instance_eval("#{temp_my_resource} 'foo'")
                  end
                  expect(recipe.logged_warnings).to eq ""
                  expect(BaseThingy.created_provider).to eq provider_class2
                end
              end
            end
          end
        end
      end
    end

    context "with UTF-8 provides" do
      before(:each) do
        class UTF8Thingy < BaseThingy
          provides :Straße
          provides :Straße
        end
      end

      it "utf-8 dsl names work" do
        recipe = converge do
          Straße("blah") {} # rubocop: disable Naming/AsciiIdentifiers
        end
        expect(recipe.logged_warnings).to eq ""
        expect(BaseThingy.created_resource).to eq(UTF8Thingy)
      end
    end
  end

  before(:all) { Namer.current_index = 0 }
  before { Namer.current_index += 1 }

  context "with an LWRP that declares actions" do
    let(:run_context) do
      Chef::RunContext.new(Chef::Node.new, {}, Chef::EventDispatch::Dispatcher.new)
    end

    let(:resource_class) do
      Class.new(Chef::Resource::LWRPBase) do
        provides :"recipe_dsl_spec#{Namer.current_index}"
        actions :create
      end
    end
    let(:resource) do
      resource_class.new("blah", run_context)
    end
    it "The actions are part of actions along with :nothing" do
      expect(resource_class.actions).to eq %i{nothing create}
    end
    it "The actions are part of allowed_actions along with :nothing" do
      expect(resource.allowed_actions).to eq %i{nothing create}
    end

    context "and a subclass that declares more actions" do
      let(:subresource_class) do
        Class.new(Chef::Resource::LWRPBase) do
          provides :"recipe_dsl_spec_sub#{Namer.current_index}"
          actions :delete
        end
      end
      let(:subresource) do
        subresource_class.new("subblah", run_context)
      end

      it "The parent class actions are not part of actions" do
        expect(subresource_class.actions).to eq %i{nothing delete}
      end
      it "The parent class actions are not part of allowed_actions" do
        expect(subresource.allowed_actions).to eq %i{nothing delete}
      end
      it "The parent class actions do not change" do
        expect(resource_class.actions).to eq %i{nothing create}
        expect(resource.allowed_actions).to eq %i{nothing create}
      end
    end
  end

end
