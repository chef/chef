# Helper module to track the load order of library files.
# Used by `cookbook_compiler_spec.rb`
#
# This module must be loaded for any tests that load the cookbook
# data/run_context/cookbooks/test to succeed.
module LibraryLoadOrder
  extend self

  def load_order
    @load_order ||= []
  end

  def reset!
    @load_order = nil
  end

  def record(file)
    load_order << file
  end
end
