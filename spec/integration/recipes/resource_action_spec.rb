require "spec_helper"
require "support/shared/integration/integration_helper"

class NoActionJackson < Chef::Resource
  provides :no_action_jackson

  def foo(value = nil)
    @foo = value if value
    @foo
  end

  class <<self
    attr_accessor :action_was
  end
end

class WeirdActionJackson < Chef::Resource
  provides :weird_action_jackson

  class <<self
    attr_accessor :action_was
  end

  action :Straße do
    WeirdActionJackson.action_was = action
  end
end

# Houses any classes we declare
module ResourceActionSpec

  describe "Resource.action" do
    include IntegrationSupport

    shared_context "ActionJackson" do
      it "the default action is the first declared action" do
        converge <<-EOM, __FILE__, __LINE__ + 1
          #{resource_dsl} "hi" do
            foo "foo!"
          end
        EOM
        expect(ActionJackson.ran_action).to eq :access_recipe_dsl
        expect(ActionJackson.succeeded).to eq true
      end

      context "when running in whyrun mode" do
        before do
          Chef::Config[:why_run] = true
        end

        it "the default action runs" do
          converge <<-EOM, __FILE__, __LINE__ + 1
            #{resource_dsl} "hi" do
              foo "foo!"
            end
          EOM
          expect(ActionJackson.ran_action).to eq :access_recipe_dsl
          expect(ActionJackson.succeeded).to eq true
        end
      end

      it "the action can access recipe DSL" do
        converge <<-EOM, __FILE__, __LINE__ + 1
          #{resource_dsl} "hi" do
            foo "foo!"
            action :access_recipe_dsl
          end
        EOM
        expect(ActionJackson.ran_action).to eq :access_recipe_dsl
        expect(ActionJackson.succeeded).to eq true
      end

      it "the action can access attributes" do
        converge <<-EOM, __FILE__, __LINE__ + 1
          #{resource_dsl} "hi" do
            foo "foo!"
            action :access_attribute
          end
        EOM
        expect(ActionJackson.ran_action).to eq :access_attribute
        expect(ActionJackson.succeeded).to eq "foo!"
      end

      it "the action can access public methods" do
        converge <<-EOM, __FILE__, __LINE__ + 1
          #{resource_dsl} "hi" do
            foo "foo!"
            action :access_method
          end
        EOM
        expect(ActionJackson.ran_action).to eq :access_method
        expect(ActionJackson.succeeded).to eq "foo_public!"
      end

      it "the action can access protected methods" do
        converge <<-EOM, __FILE__, __LINE__ + 1
          #{resource_dsl} "hi" do
            foo "foo!"
            action :access_protected_method
          end
        EOM
        expect(ActionJackson.ran_action).to eq :access_protected_method
        expect(ActionJackson.succeeded).to eq "foo_protected!"
      end

      it "the action cannot access private methods" do
        expect do
          converge(<<-EOM, __FILE__, __LINE__ + 1)
            #{resource_dsl} "hi" do
              foo "foo!"
              action :access_private_method
            end
          EOM
        end.to raise_error(NameError)
        expect(ActionJackson.ran_action).to eq :access_private_method
      end

      it "the action cannot access resource instance variables" do
        converge <<-EOM, __FILE__, __LINE__ + 1
          #{resource_dsl} "hi" do
            foo "foo!"
            action :access_instance_variable
          end
        EOM
        expect(ActionJackson.ran_action).to eq :access_instance_variable
        expect(ActionJackson.succeeded).to be_nil
      end

      it "the action does not compile until the prior resource has converged" do
        converge <<-EOM, __FILE__, __LINE__ + 1
          ruby_block "wow" do
            block do
              ResourceActionSpec::ActionJackson.ruby_block_converged = "ruby_block_converged!"
            end
          end

          #{resource_dsl} "hi" do
            foo "foo!"
            action :access_class_method
          end
        EOM
        expect(ActionJackson.ran_action).to eq :access_class_method
        expect(ActionJackson.succeeded).to eq "ruby_block_converged!"
      end

      it "the action's resources converge before the next resource converges" do
        converge <<-EOM, __FILE__, __LINE__ + 1
        #{resource_dsl} "hi" do
          foo "foo!"
          action :access_attribute
        end

        ruby_block "wow" do
          block do
            ResourceActionSpec::ActionJackson.ruby_block_converged = ResourceActionSpec::ActionJackson.succeeded
          end
        end
        EOM
        expect(ActionJackson.ran_action).to eq :access_attribute
        expect(ActionJackson.succeeded).to eq "foo!"
        expect(ActionJackson.ruby_block_converged).to eq "foo!"
      end
    end

    context "With resource 'action_jackson'" do
      class ActionJackson < Chef::Resource
        provides :action_jackson

        def foo(value = nil)
          @foo = value if value
          @foo
        end

        def blarghle(value = nil)
          @blarghle = value if value
          @blarghle
        end

        class <<self
          attr_accessor :ran_action
          attr_accessor :succeeded
          attr_accessor :ruby_block_converged
        end

        action :access_recipe_dsl do
          ActionJackson.ran_action = :access_recipe_dsl
          whyrun_safe_ruby_block "hi there" do
            block do
              ActionJackson.succeeded = true
            end
          end
        end
        action :access_attribute do
          ActionJackson.ran_action = :access_attribute
          ActionJackson.succeeded = foo
          ActionJackson.succeeded += " #{blarghle}" if blarghle
          ActionJackson.succeeded += " #{bar}" if respond_to?(:bar)
        end
        action :access_attribute2 do
          ActionJackson.ran_action = :access_attribute2
          ActionJackson.succeeded = foo
          ActionJackson.succeeded += " #{blarghle}" if blarghle
          ActionJackson.succeeded += " #{bar}" if respond_to?(:bar)
        end
        action :access_method do
          ActionJackson.ran_action = :access_method
          ActionJackson.succeeded = foo_public
        end
        action :access_protected_method do
          ActionJackson.ran_action = :access_protected_method
          ActionJackson.succeeded = foo_protected
        end
        action :access_private_method do
          ActionJackson.ran_action = :access_private_method
          ActionJackson.succeeded = foo_private
        end
        action :access_instance_variable do
          ActionJackson.ran_action = :access_instance_variable
          ActionJackson.succeeded = @foo
        end
        action :access_class_method do
          ActionJackson.ran_action = :access_class_method
          ActionJackson.succeeded = ActionJackson.ruby_block_converged
        end

        action :test1, description: "Original description" do
          true
        end

        def foo_public
          "foo_public!"
        end

        protected

        def foo_protected
          "foo_protected!"
        end

        private

        def foo_private
          "foo_private!"
        end
      end

      before(:each) do
        ActionJackson.ran_action = :error
        ActionJackson.succeeded = :error
        ActionJackson.ruby_block_converged = :error
      end

      it_behaves_like "ActionJackson" do
        let(:resource_dsl) { :action_jackson }
      end

      it "Can retrieve ancestors of action class without crashing" do
        converge { action_jackson "hi" }
        expect { ActionJackson.action_class.ancestors.join(",") }.not_to raise_error
      end

      context "And 'action_jackgrandson' inheriting from ActionJackson and changing nothing" do
        before(:each) do
          class ActionJackgrandson < ActionJackson
            provides :action_jackgrandson
          end
        end

        it_behaves_like "ActionJackson" do
          let(:resource_dsl) { :action_jackgrandson }
        end
      end

      context "And 'action_jackalope' inheriting from ActionJackson with an extra attribute, action and custom method" do
        class ActionJackalope < ActionJackson
          provides :action_jackalope

          def foo(value = nil)
            @foo = "#{value}alope" if value
            @foo
          end

          def bar(value = nil)
            @bar = "#{value}alope" if value
            @bar
          end
          class <<self
            attr_accessor :load_current_resource_ran
            attr_accessor :jackalope_ran
          end
          action :access_jackalope do
            ActionJackalope.jackalope_ran = :access_jackalope
            ActionJackalope.succeeded = "#{foo} #{blarghle} #{bar}"
          end
          action :access_attribute do
            super()
            ActionJackalope.jackalope_ran = :access_attribute
            ActionJackalope.succeeded = ActionJackson.succeeded
          end

          action :test1, description: "An old action with a new description" do
            super
          end
        end

        before do
          ActionJackalope.jackalope_ran = nil
          ActionJackalope.load_current_resource_ran = nil
        end

        context "action_jackson still behaves the same" do
          it_behaves_like "ActionJackson" do
            let(:resource_dsl) { :action_jackson }
          end
        end

        it "the default action remains the same even though new actions were specified first" do
          converge do
            action_jackalope "hi" do
              foo "foo!"
              bar "bar!"
            end
          end
          expect(ActionJackson.ran_action).to eq :access_recipe_dsl
          expect(ActionJackson.succeeded).to eq true
        end

        it "new actions run, and can access overridden, new, and overridden attributes" do
          converge do
            action_jackalope "hi" do
              foo "foo!"
              bar "bar!"
              blarghle "blarghle!"
              action :access_jackalope
            end
          end
          expect(ActionJackalope.jackalope_ran).to eq :access_jackalope
          expect(ActionJackalope.succeeded).to eq "foo!alope blarghle! bar!alope"
        end

        it "overridden actions run, call super, and can access overridden, new, and overridden attributes" do
          converge do
            action_jackalope "hi" do
              foo "foo!"
              bar "bar!"
              blarghle "blarghle!"
              action :access_attribute
            end
          end
          expect(ActionJackson.ran_action).to eq :access_attribute
          expect(ActionJackson.succeeded).to eq "foo!alope blarghle! bar!alope"
          expect(ActionJackalope.jackalope_ran).to eq :access_attribute
          expect(ActionJackalope.succeeded).to eq "foo!alope blarghle! bar!alope"
        end

        it "allows overridden action to have a description separate from the action defined in the base resource" do
          expect(ActionJackson.action_description(:test1)).to eql "Original description"
          expect(ActionJackalope.action_description(:test1)).to eql "An old action with a new description"
        end

        it "non-overridden actions run and can access overridden and non-overridden variables (but not necessarily new ones)" do
          converge do
            action_jackalope "hi" do
              foo "foo!"
              bar "bar!"
              blarghle "blarghle!"
              action :access_attribute2
            end
          end
          expect(ActionJackson.ran_action).to eq :access_attribute2
          expect(ActionJackson.succeeded).to eq("foo!alope blarghle! bar!alope").or(eq("foo!alope blarghle!"))
        end
      end
    end

    context "With a resource with no actions" do
      it "the default action is :nothing" do
        converge do
          no_action_jackson "hi" do
            foo "foo!"
            NoActionJackson.action_was = action
          end
        end
        expect(NoActionJackson.action_was).to eq [:nothing]
      end
    end

    context "With a resource with a UTF-8 action" do
      it "Running the action works" do
        expect_recipe do
          weird_action_jackson "hi"
        end.to be_up_to_date
        expect(WeirdActionJackson.action_was).to eq :Straße
      end
    end

    context "With a resource with a set_or_return property named group (same name as a resource)" do
      class ResourceActionSpecWithGroupAction < Chef::Resource
        provides :resource_action_spec_set_group_to_nil
        action :set_group_to_nil do
          # Access x during converge to ensure that we emit no warnings there
          resource_action_spec_with_group "hi" do
            group nil
            action :nothing
          end
        end
      end

      class ResourceActionSpecWithGroup < Chef::Resource
        provides :resource_action_spec_with_group
        def group(value = nil)
          set_or_return(:group, value, {})
        end
      end

      it "Setting group to nil in an action does not emit a warning about it being defined in two places" do
        expect_recipe do
          resource_action_spec_set_group_to_nil "hi" do
            action :set_group_to_nil
          end
        end.to emit_no_warnings_or_errors
      end
    end

    context "When a resource has a property with the same name as another resource" do
      class HasPropertyNamedTemplate < Chef::Resource
        provides :has_property_named_template

        property :template
        action :create do
          template "x" do
            "blah"
          end
        end
      end
    end

    context "When a resource declares methods in action_class" do
      class DeclaresActionClassMethods < Chef::Resource
        provides :declares_action_class_methods

        property :x
        action_class do
          def a
            1
          end
        end
        action_class.class_eval <<-EOM
          def c
            3
          end
        EOM
        action :create do
          new_resource.x = a + c
        end
      end

      it "the methods are not available on the resource" do
        expect { DeclaresActionClassMethods.new("hi").a }.to raise_error(NameError)
        expect { DeclaresActionClassMethods.new("hi").c }.to raise_error(NameError)
      end

      it "the methods are available to the action" do
        r = nil
        expect_recipe do
          r = declares_action_class_methods "hi"
        end.to emit_no_warnings_or_errors
        expect(r.x).to eq(4)
      end

      context "And a subclass overrides a method with an action_class block" do
        class DeclaresActionClassMethodsToo < DeclaresActionClassMethods
          provides :declares_action_class_methods_too

          action_class do
            def a
              5
            end
          end
        end

        it "the methods are not available on the resource" do
          expect { DeclaresActionClassMethods.new("hi").a }.to raise_error(NameError)
          expect { DeclaresActionClassMethods.new("hi").c }.to raise_error(NameError)
        end

        it "the methods are available to the action" do
          r = nil
          expect_recipe do
            r = declares_action_class_methods_too "hi"
          end.to emit_no_warnings_or_errors
          expect(r.x).to eq(8)
        end
      end

      context "And a subclass overrides a method with class_eval" do
        # this tests inheritance with *only* an action_class accessor that does not declare a block
        class DeclaresActionClassMethodsToo < DeclaresActionClassMethods
          provides :declares_action_class_methods_too

          action_class.class_eval <<-EOM
            def a
              5
            end
          EOM
        end

        it "the methods are not available on the resource" do
          expect { DeclaresActionClassMethods.new("hi").a }.to raise_error(NameError)
          expect { DeclaresActionClassMethods.new("hi").c }.to raise_error(NameError)
        end

        it "the methods are available to the action" do
          r = nil
          expect_recipe do
            r = declares_action_class_methods_too "hi"
          end.to emit_no_warnings_or_errors
          expect(r.x).to eq(8)
        end
      end
    end
  end

end
