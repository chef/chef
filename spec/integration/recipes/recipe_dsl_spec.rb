require 'support/shared/integration/integration_helper'

describe "Recipe DSL methods" do
  include IntegrationSupport

  module Namer
    extend self
    attr_accessor :current_index
  end

  before(:all) { Namer.current_index = 1 }
  before { Namer.current_index += 1 }

  context "With resource 'base_thingy' declared as BaseThingy" do
    before(:context) {

      class BaseThingy < Chef::Resource
        resource_name 'base_thingy'
        default_action :create

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
      module RecipeDSLSpecNamespace; end
      module RecipeDSLSpecNamespace::Bar; end

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
            default_action :create
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
          expect(BaseThingy.created_resource).to eq Chef::Resource::BackcompatThingy
          expect(BaseThingy.created_provider).to eq Chef::Provider::BackcompatThingy
        end

        context "and another resource 'backcompat_thingy' in BackcompatThingy with 'provides'" do
          before(:context) {

            class RecipeDSLSpecNamespace::BackcompatThingy < BaseThingy
              provides :backcompat_thingy
              resource_name :backcompat_thingy
            end

          }

          it "backcompat_thingy creates a BackcompatThingy" do
            recipe = converge {
              backcompat_thingy 'blah' do; end
            }
            expect(recipe.logged_warnings).to match(/Class Chef::Provider::BackcompatThingy does not declare 'resource_name :backcompat_thingy'./)
            expect(BaseThingy.created_resource).not_to be_nil
          end
        end
      end

      context "With a resource named RecipeDSLSpecNamespace::Bar::BarThingy" do
        before(:context) {

          class RecipeDSLSpecNamespace::Bar::BarThingy < BaseThingy
          end

        }

        it "bar_thingy does not work" do
          expect_converge {
            bar_thingy 'blah' do; end
          }.to raise_error(NoMethodError)
        end
      end

      context "With a resource named Chef::Resource::NoNameThingy with resource_name nil" do
        before(:context) {

          class Chef::Resource::NoNameThingy < BaseThingy
            resource_name nil
          end

        }

        it "no_name_thingy does not work" do
          expect_converge {
            no_name_thingy 'blah' do; end
          }.to raise_error(NoMethodError)
        end
      end

      context "With a resource named AnotherNoNameThingy with resource_name :another_thingy_name" do
        before(:context) {

          class AnotherNoNameThingy < BaseThingy
            resource_name :another_thingy_name
          end

        }

        it "another_no_name_thingy does not work" do
          expect_converge {
            another_no_name_thingy 'blah' do; end
          }.to raise_error(NoMethodError)
        end

        it "another_thingy_name works" do
          recipe = converge {
            another_thingy_name 'blah' do; end
          }
          expect(recipe.logged_warnings).to eq ''
          expect(BaseThingy.created_resource).to eq(AnotherNoNameThingy)
        end
      end

      context "With a resource named AnotherNoNameThingy2 with resource_name :another_thingy_name2; resource_name :another_thingy_name3" do
        before(:context) {

          class AnotherNoNameThingy2 < BaseThingy
            resource_name :another_thingy_name2
            resource_name :another_thingy_name3
          end

        }

        it "another_no_name_thingy does not work" do
          expect_converge {
            another_no_name_thingy2 'blah' do; end
          }.to raise_error(NoMethodError)
        end

        it "another_thingy_name2 does not work" do
          expect_converge {
            another_thingy_name2 'blah' do; end
          }.to raise_error(NoMethodError)
        end

        it "yet_another_thingy_name3 works" do
          recipe = converge {
            another_thingy_name3 'blah' do; end
          }
          expect(recipe.logged_warnings).to eq ''
          expect(BaseThingy.created_resource).to eq(AnotherNoNameThingy2)
        end
      end

      context "provides overriding resource_name" do
        context "With a resource named AnotherNoNameThingy3 with provides :another_no_name_thingy3, os: 'blarghle'" do
          before(:context) {

            class AnotherNoNameThingy3 < BaseThingy
              resource_name :another_no_name_thingy_3
              provides :another_no_name_thingy3, os: 'blarghle'
            end

          }

          it "and os = linux, another_no_name_thingy3 does not work" do
            expect_converge {
              # TODO this is an ugly way to test, make Cheffish expose node attrs
              run_context.node.automatic[:os] = 'linux'
              another_no_name_thingy3 'blah' do; end
            }.to raise_error(Chef::Exceptions::NoSuchResourceType)
          end

          it "and os = blarghle, another_no_name_thingy3 works" do
            recipe = converge {
              # TODO this is an ugly way to test, make Cheffish expose node attrs
              run_context.node.automatic[:os] = 'blarghle'
              another_no_name_thingy3 'blah' do; end
            }
            expect(recipe.logged_warnings).to eq ''
            expect(BaseThingy.created_resource).to eq (AnotherNoNameThingy3)
          end
        end

        context "With a resource named AnotherNoNameThingy4 with two provides" do
          before(:context) {

            class AnotherNoNameThingy4 < BaseThingy
              resource_name :another_no_name_thingy_4
              provides :another_no_name_thingy4, os: 'blarghle'
              provides :another_no_name_thingy4, platform_family: 'foo'
            end

          }

          it "and os = linux, another_no_name_thingy4 does not work" do
            expect_converge {
              # TODO this is an ugly way to test, make Cheffish expose node attrs
              run_context.node.automatic[:os] = 'linux'
              another_no_name_thingy4 'blah' do; end
            }.to raise_error(Chef::Exceptions::NoSuchResourceType)
          end

          it "and os = blarghle, another_no_name_thingy4 works" do
            recipe = converge {
              # TODO this is an ugly way to test, make Cheffish expose node attrs
              run_context.node.automatic[:os] = 'blarghle'
              another_no_name_thingy4 'blah' do; end
            }
            expect(recipe.logged_warnings).to eq ''
            expect(BaseThingy.created_resource).to eq (AnotherNoNameThingy4)
          end

          it "and platform_family = foo, another_no_name_thingy4 works" do
            recipe = converge {
              # TODO this is an ugly way to test, make Cheffish expose node attrs
              run_context.node.automatic[:platform_family] = 'foo'
              another_no_name_thingy4 'blah' do; end
            }
            expect(recipe.logged_warnings).to eq ''
            expect(BaseThingy.created_resource).to eq (AnotherNoNameThingy4)
          end
        end

        context "With a resource named AnotherNoNameThingy5, a different resource_name, and a provides with the original resource_name" do
          before(:context) {

            class AnotherNoNameThingy5 < BaseThingy
              resource_name :another_thingy_name_for_another_no_name_thingy5
              provides :another_no_name_thingy5, os: 'blarghle'
            end

          }

          it "and os = linux, another_no_name_thingy5 does not work" do
            expect_converge {
              # this is an ugly way to test, make Cheffish expose node attrs
              run_context.node.automatic[:os] = 'linux'
              another_no_name_thingy5 'blah' do; end
            }.to raise_error(Chef::Exceptions::NoSuchResourceType)
          end

          it "and os = blarghle, another_no_name_thingy5 works" do
            recipe = converge {
              # this is an ugly way to test, make Cheffish expose node attrs
              run_context.node.automatic[:os] = 'blarghle'
              another_no_name_thingy5 'blah' do; end
            }
            expect(recipe.logged_warnings).to eq ''
            expect(BaseThingy.created_resource).to eq (AnotherNoNameThingy5)
          end

          it "the new resource name can be used in a recipe" do
            recipe = converge {
              another_thingy_name_for_another_no_name_thingy5 'blah' do; end
            }
            expect(recipe.logged_warnings).to eq ''
            expect(BaseThingy.created_resource).to eq (AnotherNoNameThingy5)
          end
        end

        context "With a resource named AnotherNoNameThingy6, a provides with the original resource name, and a different resource_name" do
          before(:context) {

            class AnotherNoNameThingy6 < BaseThingy
              provides :another_no_name_thingy6, os: 'blarghle'
              resource_name :another_thingy_name_for_another_no_name_thingy6
            end

          }

          it "and os = linux, another_no_name_thingy6 does not work" do
            expect_converge {
              # this is an ugly way to test, make Cheffish expose node attrs
              run_context.node.automatic[:os] = 'linux'
              another_no_name_thingy6 'blah' do; end
            }.to raise_error(Chef::Exceptions::NoSuchResourceType)
          end

          it "and os = blarghle, another_no_name_thingy6 works" do
            recipe = converge {
              # this is an ugly way to test, make Cheffish expose node attrs
              run_context.node.automatic[:os] = 'blarghle'
              another_no_name_thingy6 'blah' do; end
            }
            expect(recipe.logged_warnings).to eq ''
            expect(BaseThingy.created_resource).to eq (AnotherNoNameThingy6)
          end

          it "the new resource name can be used in a recipe" do
            recipe = converge {
              another_thingy_name_for_another_no_name_thingy6 'blah' do; end
            }
            expect(recipe.logged_warnings).to eq ''
            expect(BaseThingy.created_resource).to eq (AnotherNoNameThingy6)
          end
        end

        context "With a resource named AnotherNoNameThingy7, a new resource_name, and provides with that new resource name" do
          before(:context) {

            class AnotherNoNameThingy7 < BaseThingy
              resource_name :another_thingy_name_for_another_no_name_thingy7
              provides :another_thingy_name_for_another_no_name_thingy7, os: 'blarghle'
            end

          }

          it "and os = linux, another_thingy_name_for_another_no_name_thingy7 does not work" do
            expect_converge {
              # this is an ugly way to test, make Cheffish expose node attrs
              run_context.node.automatic[:os] = 'linux'
              another_thingy_name_for_another_no_name_thingy7 'blah' do; end
            }.to raise_error(Chef::Exceptions::NoSuchResourceType)
          end

          it "and os = blarghle, another_thingy_name_for_another_no_name_thingy7 works" do
            recipe = converge {
              # this is an ugly way to test, make Cheffish expose node attrs
              run_context.node.automatic[:os] = 'blarghle'
              another_thingy_name_for_another_no_name_thingy7 'blah' do; end
            }
            expect(recipe.logged_warnings).to eq ''
            expect(BaseThingy.created_resource).to eq (AnotherNoNameThingy7)
          end

          it "the old resource name does not work" do
            expect_converge {
              # this is an ugly way to test, make Cheffish expose node attrs
              run_context.node.automatic[:os] = 'linux'
              another_no_name_thingy_7 'blah' do; end
            }.to raise_error(NoMethodError)
          end
        end

        # opposite order from the previous test (provides, then resource_name)
        context "With a resource named AnotherNoNameThingy8, a provides with a new resource name, and resource_name with that new resource name" do
          before(:context) {

            class AnotherNoNameThingy8 < BaseThingy
              provides :another_thingy_name_for_another_no_name_thingy8, os: 'blarghle'
              resource_name :another_thingy_name_for_another_no_name_thingy8
            end

          }

          it "and os = linux, another_thingy_name_for_another_no_name_thingy8 does not work" do
            expect_converge {
              # this is an ugly way to test, make Cheffish expose node attrs
              run_context.node.automatic[:os] = 'linux'
              another_thingy_name_for_another_no_name_thingy8 'blah' do; end
            }.to raise_error(Chef::Exceptions::NoSuchResourceType)
          end

          it "and os = blarghle, another_thingy_name_for_another_no_name_thingy8 works" do
            recipe = converge {
              # this is an ugly way to test, make Cheffish expose node attrs
              run_context.node.automatic[:os] = 'blarghle'
              another_thingy_name_for_another_no_name_thingy8 'blah' do; end
            }
            expect(recipe.logged_warnings).to eq ''
            expect(BaseThingy.created_resource).to eq (AnotherNoNameThingy8)
          end

          it "the old resource name does not work" do
            expect_converge {
              # this is an ugly way to test, make Cheffish expose node attrs
              run_context.node.automatic[:os] = 'linux'
              another_thingy_name8 'blah' do; end
            }.to raise_error(NoMethodError)
          end
        end

        context "With a resource TwoClassesOneDsl" do
          let(:class_name) { "TwoClassesOneDsl#{Namer.current_index}" }
          let(:dsl_method) { :"two_classes_one_dsl#{Namer.current_index}" }

          before {
            eval <<-EOM, nil, __FILE__, __LINE__+1
              class #{class_name} < BaseThingy
                resource_name #{dsl_method.inspect}
              end
            EOM
          }
          context "and resource BlahModule::TwoClassesOneDsl" do
            before {
              eval <<-EOM, nil, __FILE__, __LINE__+1
                module BlahModule
                  class #{class_name} < BaseThingy
                    resource_name #{dsl_method.inspect}
                  end
                end
              EOM
            }
            it "two_classes_one_dsl resolves to BlahModule::TwoClassesOneDsl (alphabetical)" do
              dsl_method = self.dsl_method
              recipe = converge {
                instance_eval("#{dsl_method} 'blah' do; end")
              }
              expect(recipe.logged_warnings).to eq ''
              expect(BaseThingy.created_resource).to eq eval("BlahModule::#{class_name}")
            end
            it "resource_matching_short_name returns BlahModule::TwoClassesOneDsl" do
              expect(Chef::Resource.resource_matching_short_name(dsl_method)).to eq eval("BlahModule::#{class_name}")
            end
          end
          context "and resource BlahModule::TwoClassesOneDsl with resource_name nil" do
            before {
              eval <<-EOM, nil, __FILE__, __LINE__+1
                module BlahModule
                  class BlahModule::#{class_name} < BaseThingy
                    resource_name nil
                  end
                end
              EOM
            }
            it "two_classes_one_dsl resolves to ::TwoClassesOneDsl" do
              dsl_method = self.dsl_method
              recipe = converge {
                instance_eval("#{dsl_method} 'blah' do; end")
              }
              expect(recipe.logged_warnings).to eq ''
              expect(BaseThingy.created_resource).to eq eval("::#{class_name}")
            end
            it "resource_matching_short_name returns ::TwoClassesOneDsl" do
              expect(Chef::Resource.resource_matching_short_name(dsl_method)).to eq eval("::#{class_name}")
            end
          end
          context "and resource BlahModule::TwoClassesOneDsl with resource_name :argh" do
            before {
              eval <<-EOM, nil, __FILE__, __LINE__+1
                module BlahModule
                  class BlahModule::#{class_name} < BaseThingy
                    resource_name :argh
                  end
                end
              EOM
            }
            it "two_classes_one_dsl resolves to ::TwoClassesOneDsl" do
              dsl_method = self.dsl_method
              recipe = converge {
                instance_eval("#{dsl_method} 'blah' do; end")
              }
              expect(recipe.logged_warnings).to eq ''
              expect(BaseThingy.created_resource).to eq eval("::#{class_name}")
            end
            it "resource_matching_short_name returns ::TwoClassesOneDsl" do
              expect(Chef::Resource.resource_matching_short_name(dsl_method)).to eq eval("::#{class_name}")
            end
          end
          context "and resource BlahModule::TwoClassesOneDsl with provides :two_classes_one_dsl, os: 'blarghle'" do
            before {
              eval <<-EOM, nil, __FILE__, __LINE__+1
                module BlahModule
                  class BlahModule::#{class_name} < BaseThingy
                    resource_name #{dsl_method.inspect}
                    provides #{dsl_method.inspect}, os: 'blarghle'
                  end
                end
              EOM
            }

            it "and os = blarghle, two_classes_one_dsl resolves to BlahModule::TwoClassesOneDsl" do
              dsl_method = self.dsl_method
              recipe = converge {
                # this is an ugly way to test, make Cheffish expose node attrs
                run_context.node.automatic[:os] = 'blarghle'
                instance_eval("#{dsl_method} 'blah' do; end")
              }
              expect(recipe.logged_warnings).to eq ''
              expect(BaseThingy.created_resource).to eq eval("BlahModule::#{class_name}")
            end

            it "and os = linux, two_classes_one_dsl resolves to ::TwoClassesOneDsl" do
              dsl_method = self.dsl_method
              recipe = converge {
                # this is an ugly way to test, make Cheffish expose node attrs
                run_context.node.automatic[:os] = 'linux'
                instance_eval("#{dsl_method} 'blah' do; end")
              }
              expect(recipe.logged_warnings).to eq ''
              expect(BaseThingy.created_resource).to eq eval("::#{class_name}")
            end
          end
        end
      end
    end

    context "provides" do
      context "when MySupplier provides :hemlock" do
        before(:context) {

          class RecipeDSLSpecNamespace::MySupplier < BaseThingy
            resource_name :hemlock
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
          expect(BaseThingy.created_resource).to eq RecipeDSLSpecNamespace::MySupplier
        end
      end

      context "when Thingy3 has resource_name :thingy3" do
        before(:context) {

          class RecipeDSLSpecNamespace::Thingy3 < BaseThingy
            resource_name :thingy3
          end

        }

        it "thingy3 works in a recipe" do
          expect_recipe {
            thingy3 'blah' do; end
          }.to emit_no_warnings_or_errors
          expect(BaseThingy.created_resource).to eq RecipeDSLSpecNamespace::Thingy3
        end

        context "and Thingy4 has resource_name :thingy3" do
          before(:context) {

            class RecipeDSLSpecNamespace::Thingy4 < BaseThingy
              resource_name :thingy3
            end

          }

          it "thingy3 works in a recipe and yields Thingy3 (the alphabetical one)" do
            recipe = converge {
              thingy3 'blah' do; end
            }
            expect(BaseThingy.created_resource).to eq RecipeDSLSpecNamespace::Thingy3
          end

          it "thingy4 does not work in a recipe" do
            expect_converge {
              thingy4 'blah' do; end
            }.to raise_error(NoMethodError)
          end

          it "resource_matching_short_name returns Thingy4" do
            expect(Chef::Resource.resource_matching_short_name(:thingy3)).to eq RecipeDSLSpecNamespace::Thingy3
          end
        end
      end

      context "when Thingy5 has resource_name :thingy5 and provides :thingy5reverse, :thingy5_2 and :thingy5_2reverse" do
        before(:context) {

          class RecipeDSLSpecNamespace::Thingy5 < BaseThingy
            resource_name :thingy5
            provides :thingy5reverse
            provides :thingy5_2
            provides :thingy5_2reverse
          end

        }

        it "thingy5 works in a recipe" do
          expect_recipe {
            thingy5 'blah' do; end
          }.to emit_no_warnings_or_errors
          expect(BaseThingy.created_resource).to eq RecipeDSLSpecNamespace::Thingy5
        end

        context "and Thingy6 provides :thingy5" do
          before(:context) {

            class RecipeDSLSpecNamespace::Thingy6 < BaseThingy
              resource_name :thingy6
              provides :thingy5
            end

          }

          it "thingy6 works in a recipe and yields Thingy6" do
            recipe = converge {
              thingy6 'blah' do; end
            }
            expect(BaseThingy.created_resource).to eq RecipeDSLSpecNamespace::Thingy6
          end

          it "thingy5 works in a recipe and yields Foo::Thingy5 (the alphabetical one)" do
            recipe = converge {
              thingy5 'blah' do; end
            }
            expect(BaseThingy.created_resource).to eq RecipeDSLSpecNamespace::Thingy5
          end

          it "resource_matching_short_name returns Thingy5" do
            expect(Chef::Resource.resource_matching_short_name(:thingy5)).to eq RecipeDSLSpecNamespace::Thingy5
          end

          context "and AThingy5 provides :thingy5reverse" do
            before(:context) {

              class RecipeDSLSpecNamespace::AThingy5 < BaseThingy
                resource_name :thingy5reverse
              end

            }

            it "thingy5reverse works in a recipe and yields AThingy5 (the alphabetical one)" do
              recipe = converge {
                thingy5reverse 'blah' do; end
              }
              expect(BaseThingy.created_resource).to eq RecipeDSLSpecNamespace::AThingy5
            end
          end

          context "and ZRecipeDSLSpecNamespace::Thingy5 provides :thingy5_2" do
            before(:context) {

              module ZRecipeDSLSpecNamespace
                class Thingy5 < BaseThingy
                  resource_name :thingy5_2
                end
              end

            }

            it "thingy5_2 works in a recipe and yields the RecipeDSLSpaceNamespace one (the alphabetical one)" do
              recipe = converge {
                thingy5_2 'blah' do; end
              }
              expect(BaseThingy.created_resource).to eq RecipeDSLSpecNamespace::Thingy5
            end
          end

          context "and ARecipeDSLSpecNamespace::Thingy5 provides :thingy5_2" do
            before(:context) {

              module ARecipeDSLSpecNamespace
                class Thingy5 < BaseThingy
                  resource_name :thingy5_2reverse
                end
              end

            }

            it "thingy5_2reverse works in a recipe and yields the ARecipeDSLSpaceNamespace one (the alphabetical one)" do
              recipe = converge {
                thingy5_2reverse 'blah' do; end
              }
              expect(BaseThingy.created_resource).to eq ARecipeDSLSpecNamespace::Thingy5
            end
          end
        end

        context "when Thingy3 has resource_name :thingy3" do
          before(:context) {

            class RecipeDSLSpecNamespace::Thingy3 < BaseThingy
              resource_name :thingy3
            end

          }

          it "thingy3 works in a recipe" do
            expect_recipe {
              thingy3 'blah' do; end
            }.to emit_no_warnings_or_errors
            expect(BaseThingy.created_resource).to eq RecipeDSLSpecNamespace::Thingy3
          end

          context "and Thingy4 has resource_name :thingy3" do
            before(:context) {

              class RecipeDSLSpecNamespace::Thingy4 < BaseThingy
                resource_name :thingy3
              end

            }

            it "thingy3 works in a recipe and yields Thingy3 (the alphabetical one)" do
              recipe = converge {
                thingy3 'blah' do; end
              }
              expect(BaseThingy.created_resource).to eq RecipeDSLSpecNamespace::Thingy3
            end

            it "thingy4 does not work in a recipe" do
              expect_converge {
                thingy4 'blah' do; end
              }.to raise_error(NoMethodError)
            end

            it "resource_matching_short_name returns Thingy4" do
              expect(Chef::Resource.resource_matching_short_name(:thingy3)).to eq RecipeDSLSpecNamespace::Thingy3
            end
          end

          context "and Thingy4 has resource_name :thingy3" do
            before(:context) {

              class RecipeDSLSpecNamespace::Thingy4 < BaseThingy
                resource_name :thingy3
              end

            }

            it "thingy3 works in a recipe and yields Thingy3 (the alphabetical one)" do
              recipe = converge {
                thingy3 'blah' do; end
              }
              expect(BaseThingy.created_resource).to eq RecipeDSLSpecNamespace::Thingy3
            end

            it "thingy4 does not work in a recipe" do
              expect_converge {
                thingy4 'blah' do; end
              }.to raise_error(NoMethodError)
            end

            it "resource_matching_short_name returns Thingy4" do
              expect(Chef::Resource.resource_matching_short_name(:thingy3)).to eq RecipeDSLSpecNamespace::Thingy3
            end
          end
        end

      end

      context "when Thingy7 provides :thingy8" do
        before(:context) {

          class RecipeDSLSpecNamespace::Thingy7 < BaseThingy
            resource_name :thingy7
            provides :thingy8
          end

        }

        context "and Thingy8 has resource_name :thingy8" do
          before(:context) {

            class RecipeDSLSpecNamespace::Thingy8 < BaseThingy
              resource_name :thingy8
            end

          }

          it "thingy7 works in a recipe and yields Thingy7" do
            recipe = converge {
              thingy7 'blah' do; end
            }
            expect(BaseThingy.created_resource).to eq RecipeDSLSpecNamespace::Thingy7
          end

          it "thingy8 works in a recipe and yields Thingy7 (alphabetical)" do
            recipe = converge {
              thingy8 'blah' do; end
            }
            expect(BaseThingy.created_resource).to eq RecipeDSLSpecNamespace::Thingy7
          end

          it "resource_matching_short_name returns Thingy8" do
            expect(Chef::Resource.resource_matching_short_name(:thingy8)).to eq RecipeDSLSpecNamespace::Thingy8
          end
        end
      end

      context "when Thingy12 provides :thingy12, :twizzle and :twizzle2" do
        before(:context) {

          class RecipeDSLSpecNamespace::Thingy12 < BaseThingy
            resource_name :thingy12
            provides :twizzle
            provides :twizzle2
          end

        }

        it "thingy12 works in a recipe and yields Thingy12" do
          expect_recipe {
            thingy12 'blah' do; end
          }.to emit_no_warnings_or_errors
          expect(BaseThingy.created_resource).to eq RecipeDSLSpecNamespace::Thingy12
        end

        it "twizzle works in a recipe and yields Thingy12" do
          expect_recipe {
            twizzle 'blah' do; end
          }.to emit_no_warnings_or_errors
          expect(BaseThingy.created_resource).to eq RecipeDSLSpecNamespace::Thingy12
        end

        it "twizzle2 works in a recipe and yields Thingy12" do
          expect_recipe {
            twizzle2 'blah' do; end
          }.to emit_no_warnings_or_errors
          expect(BaseThingy.created_resource).to eq RecipeDSLSpecNamespace::Thingy12
        end
      end

      context "With platform-specific resources 'my_super_thingy_foo' and 'my_super_thingy_bar'" do
        before(:context) {
          class MySuperThingyFoo < BaseThingy
            resource_name :my_super_thingy_foo
            provides :my_super_thingy, platform: 'foo'
          end

          class MySuperThingyBar < BaseThingy
            resource_name :my_super_thingy_bar
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

      context "when Thingy9 provides :thingy9" do
        before(:context) {
          class RecipeDSLSpecNamespace::Thingy9 < BaseThingy
            resource_name :thingy9
          end
        }

        it "declaring a resource providing the same :thingy9 produces a warning" do
          expect(Chef::Log).to receive(:warn).with("You declared a new resource RecipeDSLSpecNamespace::Thingy9AlternateProvider for resource thingy9, but it comes alphabetically after RecipeDSLSpecNamespace::Thingy9 and has the same filters ({}), so it will not be used. Use override: true if you want to use it for thingy9.")
          class RecipeDSLSpecNamespace::Thingy9AlternateProvider < BaseThingy
            resource_name :thingy9
          end
        end
      end

      context "when Thingy10 provides :thingy10" do
        before(:context) {
          class RecipeDSLSpecNamespace::Thingy10 < BaseThingy
            resource_name :thingy10
          end
        }

        it "declaring a resource providing the same :thingy10 with override: true does not produce a warning" do
          expect(Chef::Log).not_to receive(:warn)
          class RecipeDSLSpecNamespace::Thingy10AlternateProvider < BaseThingy
            provides :thingy10, override: true
          end
        end
      end

      context "when Thingy11 provides :thingy11" do
        before(:context) {
          class RecipeDSLSpecNamespace::Thingy11 < BaseThingy
            resource_name :thingy10
          end
        }

        it "declaring a resource providing the same :thingy11 with os: 'linux' does not produce a warning" do
          expect(Chef::Log).not_to receive(:warn)
          class RecipeDSLSpecNamespace::Thingy11AlternateProvider < BaseThingy
            provides :thingy11, os: 'linux'
          end
        end
      end
    end
  end

  before(:all) { Namer.current_index = 0 }
  before { Namer.current_index += 1 }

  context "with an LWRP that declares actions" do
    let(:resource_class) {
      Class.new(Chef::Resource::LWRPBase) do
        provides :"recipe_dsl_spec#{Namer.current_index}"
        actions :create
      end
    }
    let(:resource) {
      resource_class.new("blah", run_context)
    }
    it "The actions are part of actions along with :nothing" do
      expect(resource_class.actions).to eq [ :nothing, :create ]
    end
    it "The actions are part of allowed_actions along with :nothing" do
      expect(resource.allowed_actions).to eq [ :nothing, :create ]
    end

    context "and a subclass that declares more actions" do
      let(:subresource_class) {
        Class.new(Chef::Resource::LWRPBase) do
          provides :"recipe_dsl_spec_sub#{Namer.current_index}"
          actions :delete
        end
      }
      let(:subresource) {
        subresource_class.new("subblah", run_context)
      }

      it "The parent class actions are not part of actions" do
        expect(subresource_class.actions).to eq [ :nothing, :delete ]
      end
      it "The parent class actions are not part of allowed_actions" do
        expect(subresource.allowed_actions).to eq [ :nothing, :delete ]
      end
      it "The parent class actions do not change" do
        expect(resource_class.actions).to eq [ :nothing, :create ]
        expect(resource.allowed_actions).to eq [ :nothing, :create ]
      end
    end
  end

  context "with a dynamically defined resource and regular provider" do
    before(:context) do
      Class.new(Chef::Resource) do
        resource_name :lw_resource_with_hw_provider_test_case
        default_action :create
        attr_accessor :created_provider
      end
      class Chef::Provider::LwResourceWithHwProviderTestCase < Chef::Provider
        def load_current_resource
        end
        def action_create
          new_resource.created_provider = self.class
        end
      end
    end

    it "looks up the provider in Chef::Provider converting the resource name from snake case to camel case" do
      resource = nil
      recipe = converge {
        resource = lw_resource_with_hw_provider_test_case 'blah' do; end
      }
      expect(resource.created_provider).to eq(Chef::Provider::LwResourceWithHwProviderTestCase)
    end
  end
end
