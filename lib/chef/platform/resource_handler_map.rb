require 'singleton'
require 'chef/platform/handler_map'

class Chef
  class Platform
    # @api private
    class ResourceHandlerMap < Chef::Platform::HandlerMap
      include Singleton
    end
  end
end
