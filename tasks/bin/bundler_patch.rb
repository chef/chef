# This is a temporary monkey patch to address https://github.com/bundler/bundler/issues/4896
# the heart of the fix is line #18 with the addition of:
# && (possibility.activated - existing_node.payload.activated).empty?
# This ensures we do not mis linux platform gems in some scenarios like ffi in kitchen-test.
# There is a permanent fix to bundler (See https://github.com/bundler/bundler/pull/4836) which
# is due to ship in v1.14. Once we adopt that version, we can remove this file

require "bundler"
require "bundler/vendor/molinillo/lib/molinillo/resolution"

module Bundler::Molinillo
  class Resolver
    # A specific resolution from a given {Resolver}
    class Resolution
      def attempt_to_activate
        debug(depth) { "Attempting to activate " + possibility.to_s }
        existing_node = activated.vertex_named(name)
        if existing_node.payload && (possibility.activated - existing_node.payload.activated).empty?
          debug(depth) { "Found existing spec (#{existing_node.payload})" }
          attempt_to_activate_existing_spec(existing_node)
        else
          attempt_to_activate_new_spec
        end
      end
    end
  end
end
