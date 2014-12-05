# This code comes from https://github.com/rspec/rspec-core/blob/master/spec/spec_helper.rb and
# https://github.com/rspec/rspec-core/blob/master/spec/support/sandboxing.rb

# To leverage the sandboxing use an `around` block:
# around(:each) do |ex|
#   Sandboxing.sandboxed { ex.run }
# end

# rspec-core did not include a license on Github

# This is necessary, otherwise
class << RSpec
  attr_writer :configuration, :world
end

class NullObject
  private
  def method_missing(method, *args, &block)
    # ignore
  end
end

module Sandboxing
  def self.sandboxed(&block)
    orig_load_path = $LOAD_PATH.dup
    orig_config = RSpec.configuration
    orig_world  = RSpec.world
    orig_example = RSpec.current_example
    new_config = RSpec::Core::Configuration.new
    new_config.expose_dsl_globally = false
    new_config.expecting_with_rspec = true
    new_world  = RSpec::Core::World.new(new_config)
    RSpec.configuration = new_config
    RSpec.world = new_world
    object = Object.new
    object.extend(RSpec::Core::SharedExampleGroup)

    (class << RSpec::Core::ExampleGroup; self; end).class_exec do
      alias_method :orig_run, :run
      def run(reporter=nil)
        RSpec.current_example = nil
        orig_run(reporter || NullObject.new)
      end
    end

    RSpec::Mocks.with_temporary_scope do
      object.instance_exec(&block)
    end
  ensure
    (class << RSpec::Core::ExampleGroup; self; end).class_exec do
      remove_method :run
      alias_method :run, :orig_run
      remove_method :orig_run
    end

    RSpec.configuration = orig_config
    RSpec.world = orig_world
    RSpec.current_example = orig_example
    $LOAD_PATH.replace(orig_load_path)
  end
end
