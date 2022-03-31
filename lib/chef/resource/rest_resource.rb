require_relative "../resource"
require_relative "../dsl/rest_resource"

class Chef
  class Resource
    class RestResource < Chef::Resource
      unified_mode true

      # This is an abstract resource meant to be subclassed; thus no 'provides'

      skip_docs true
      preview_resource true

      description "Generic superclass for all REST API resources"

      default_action :configure
      allowed_actions :configure, :delete

      include Chef::DSL::RestResource
    end
  end
end
