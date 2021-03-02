#
# This is a helper for functional tests to embed the recipe DSL directly into the rspec example blocks using
# unified mode.
#
# If you wind up wanting to stub/expect on internal details of the resource/provider you are not testing the
# public API and are trying to write a unit test, which this is not designed for.
#
# If you want to start writing full recipes and testing them, doing notifies/subscribes/etc then you are writing
# an integration test, and not a functional single-resource test, which this is not designed for.
#
# Examples:
#
# it "creates a file" do
#   FileUtils.rm_f("/tmp/foo.xyz")
#   file "/tmp/foo.xyz" do           # please use proper tmpdir though
#     content "whatever"
#   end.should_be_updated
#   expect(IO.read("/tmp/foo.xyz").to eql("content")
# end
#
# it "is idempotent" do
#   FileUtils.rm_f("/tmp/foo.xyz")
#   file "/tmp/foo.xyz" do           # please use proper tmpdir though
#     content "whatever"
#   end.should_be_updated
#   file "/tmp/foo.xyz" do           # please use proper tmpdir though
#     content "whatever"
#   end.should_not_be_updated
#   expect(IO.read("/tmp/foo.xyz").to eql("content")
# end
#
# it "has a failure" do
#   FileUtils.rm_f("/tmp/foo.xyz")
#   expect { file "/tmp/lksjdflksjdf/foo.xyz" do
#     content "whatever"
#   end }.to raise_error(Chef::Exception::EnclosingDirectoryDoesNotExist)
# end
#
module RecipeDSLHelper
  include Chef::DSL::Recipe
  def event_dispatch
    @event_dispatch ||= Chef::EventDispatch::Dispatcher.new
  end

  def node
    @node ||= Chef::Node.new.tap do |n|
      # clone the global ohai data to keep tests fast but reasonably isolated
      n.consume_external_attrs(OHAI_SYSTEM.data.dup, {})
    end
  end

  def run_context
    @run_context ||= Chef::RunContext.new(node, {}, event_dispatch).tap do |rc|
      rc.resource_collection.unified_mode = true
      Chef::Runner.new(rc)
    end
  end

  def cookbook_name
    "rspec"
  end

  def recipe_name
    "default"
  end

  def declare_resource(type, name, created_at: nil, run_context: self.run_context, &resource_attrs_block)
    created_at = caller[0]
    rspec_context = self
    # we slightly abuse the "enclosing_provider" method_missing magic to send methods to the rspec example block so that
    # rspec `let` methods work as arguments to resource properties
    resource = super(type, name, created_at: created_at, run_context: run_context, enclosing_provider: rspec_context, &resource_attrs_block)
    # we also inject these methods to make terse expression of checking the updated status (so it is more readiable and
    # therefore should get used more -- even though it is "should" vs. "expect")
    resource.define_singleton_method(:should_be_updated) do
      rspec_context.expect(self).to be_updated
    end
    resource.define_singleton_method(:should_not_be_updated) do
      rspec_context.expect(self).not_to be_updated
    end
    resource
  end
end
