require "singleton"
require "chef/platform/priority_map"

class Chef
  class Platform
    # @api private
    class ProviderPriorityMap < Chef::Platform::PriorityMap
      include Singleton
    end
  end
end
