require 'support/shared/integration/integration_helper'

describe "Resource.action" do
  include IntegrationSupport

  shared_context "ActionJackson" do
    it "the default action is the first declared action" do
      converge <<-EOM, __FILE__, __LINE__+1
        #{resource_dsl} 'hi' do
          foo 'foo!'
        end
      EOM
      expect(ActionJackson.ran_action).to eq :access_recipe_dsl
      expect(ActionJackson.succeeded).to eq true
    end

    it "the action can access recipe DSL" do
      converge <<-EOM, __FILE__, __LINE__+1
        #{resource_dsl} 'hi' do
          foo 'foo!'
          action :access_recipe_dsl
        end
      EOM
      expect(ActionJackson.ran_action).to eq :access_recipe_dsl
      expect(ActionJackson.succeeded).to eq true
    end

    it "the action can access attributes" do
      converge <<-EOM, __FILE__, __LINE__+1
        #{resource_dsl} 'hi' do
          foo 'foo!'
          action :access_attribute
        end
      EOM
      expect(ActionJackson.ran_action).to eq :access_attribute
      expect(ActionJackson.succeeded).to eq 'foo!'
    end

    it "the action can access public methods" do
      converge <<-EOM, __FILE__, __LINE__+1
        #{resource_dsl} 'hi' do
          foo 'foo!'
          action :access_method
        end
      EOM
      expect(ActionJackson.ran_action).to eq :access_method
      expect(ActionJackson.succeeded).to eq 'foo_public!'
    end

    it "the action can access protected methods" do
      converge <<-EOM, __FILE__, __LINE__+1
        #{resource_dsl} 'hi' do
          foo 'foo!'
          action :access_protected_method
        end
      EOM
      expect(ActionJackson.ran_action).to eq :access_protected_method
      expect(ActionJackson.succeeded).to eq 'foo_protected!'
    end

    it "the action cannot access private methods" do
      expect {
        converge(<<-EOM, __FILE__, __LINE__+1)
          #{resource_dsl} 'hi' do
            foo 'foo!'
            action :access_private_method
          end
        EOM
      }.to raise_error(NameError)
      expect(ActionJackson.ran_action).to eq :access_private_method
    end

    it "the action cannot access resource instance variables" do
      converge <<-EOM, __FILE__, __LINE__+1
        #{resource_dsl} 'hi' do
          foo 'foo!'
          action :access_instance_variable
        end
      EOM
      expect(ActionJackson.ran_action).to eq :access_instance_variable
      expect(ActionJackson.succeeded).to be_nil
    end

    it "the action does not compile until the prior resource has converged" do
      converge <<-EOM, __FILE__, __LINE__+1
        ruby_block 'wow' do
          block do
            ActionJackson.ruby_block_converged = 'ruby_block_converged!'
          end
        end

        #{resource_dsl} 'hi' do
          foo 'foo!'
          action :access_class_method
        end
      EOM
      expect(ActionJackson.ran_action).to eq :access_class_method
      expect(ActionJackson.succeeded).to eq 'ruby_block_converged!'
    end

    it "the action's resources converge before the next resource converges" do
      converge <<-EOM, __FILE__, __LINE__+1
        #{resource_dsl} 'hi' do
          foo 'foo!'
          action :access_attribute
        end

        ruby_block 'wow' do
          block do
            ActionJackson.ruby_block_converged = ActionJackson.succeeded
          end
        end
      EOM
      expect(ActionJackson.ran_action).to eq :access_attribute
      expect(ActionJackson.succeeded).to eq 'foo!'
      expect(ActionJackson.ruby_block_converged).to eq 'foo!'
    end
  end

  context "With resource 'action_jackson'" do
    before(:context) {
      class ActionJackson < Chef::Resource
        use_automatic_resource_name
        def foo(value=nil)
          @foo = value if value
          @foo
        end
        def blarghle(value=nil)
          @blarghle = value if value
          @blarghle
        end

        class <<self
          attr_accessor :ran_action
          attr_accessor :succeeded
          attr_accessor :ruby_block_converged
        end

        public
        def foo_public
          'foo_public!'
        end
        protected
        def foo_protected
          'foo_protected!'
        end
        private
        def foo_private
          'foo_private!'
        end

        public
        action :access_recipe_dsl do
          ActionJackson.ran_action = :access_recipe_dsl
          ruby_block 'hi there' do
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
      end
    }
    before(:each) {
      ActionJackson.ran_action = :error
      ActionJackson.succeeded = :error
      ActionJackson.ruby_block_converged = :error
    }

    it_behaves_like "ActionJackson" do
      let(:resource_dsl) { :action_jackson }
    end

    it "Can retrieve ancestors of action class without crashing" do
      converge { action_jackson 'hi' }
      expect { ActionJackson.action_class.ancestors.join(",") }.not_to raise_error
    end

    context "And 'action_jackgrandson' inheriting from ActionJackson and changing nothing" do
      before(:context) {
        class ActionJackgrandson < ActionJackson
          use_automatic_resource_name
        end
      }

      it_behaves_like "ActionJackson" do
        let(:resource_dsl) { :action_jackgrandson }
      end
    end

    context "And 'action_jackalope' inheriting from ActionJackson with an extra attribute, action and custom method" do
      before(:context) {
        class ActionJackalope < ActionJackson
          use_automatic_resource_name

          def foo(value=nil)
            @foo = "#{value}alope" if value
            @foo
          end
          def bar(value=nil)
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
        end
      }
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
        converge {
          action_jackalope 'hi' do
            foo 'foo!'
            bar 'bar!'
          end
        }
        expect(ActionJackson.ran_action).to eq :access_recipe_dsl
        expect(ActionJackson.succeeded).to eq true
      end

      it "new actions run, and can access overridden, new, and overridden attributes" do
        converge {
          action_jackalope 'hi' do
            foo 'foo!'
            bar 'bar!'
            blarghle 'blarghle!'
            action :access_jackalope
          end
        }
        expect(ActionJackalope.jackalope_ran).to eq :access_jackalope
        expect(ActionJackalope.succeeded).to eq "foo!alope blarghle! bar!alope"
      end

      it "overridden actions run, call super, and can access overridden, new, and overridden attributes" do
        converge {
          action_jackalope 'hi' do
            foo 'foo!'
            bar 'bar!'
            blarghle 'blarghle!'
            action :access_attribute
          end
        }
        expect(ActionJackson.ran_action).to eq :access_attribute
        expect(ActionJackson.succeeded).to eq "foo!alope blarghle! bar!alope"
        expect(ActionJackalope.jackalope_ran).to eq :access_attribute
        expect(ActionJackalope.succeeded).to eq "foo!alope blarghle! bar!alope"
      end

      it "non-overridden actions run and can access overridden and non-overridden variables (but not necessarily new ones)" do
        converge {
          action_jackalope 'hi' do
            foo 'foo!'
            bar 'bar!'
            blarghle 'blarghle!'
            action :access_attribute2
          end
        }
        expect(ActionJackson.ran_action).to eq :access_attribute2
        expect(ActionJackson.succeeded).to eq("foo!alope blarghle! bar!alope").or(eq("foo!alope blarghle!"))
      end
    end
  end

  context "With a resource with no actions" do
    before(:context) {
      class NoActionJackson < Chef::Resource
        use_automatic_resource_name

        def foo(value=nil)
          @foo = value if value
          @foo
        end

        class <<self
          attr_accessor :action_was
        end
      end
    }
    it "the default action is :nothing" do
      converge {
        no_action_jackson 'hi' do
          foo 'foo!'
          NoActionJackson.action_was = action
        end
      }
      expect(NoActionJackson.action_was).to eq [:nothing]
    end
  end

  context "With a resource with action a-b-c d" do
    before(:context) {
      class WeirdActionJackson < Chef::Resource
        use_automatic_resource_name

        class <<self
          attr_accessor :action_was
        end

        action "a-b-c d" do
          WeirdActionJackson.action_was = action
        end
      end
    }

    it "Running the action works" do
      expect_recipe {
        weird_action_jackson 'hi'
      }.to be_up_to_date
      expect(WeirdActionJackson.action_was).to eq :"a-b-c d"
    end
  end
end
