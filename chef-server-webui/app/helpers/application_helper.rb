require 'chef/mixin/deep_merge'
require 'chef-server-webui/version'

module Merb
  module ApplicationHelper

    def chef_version
      ::ChefServerWebui::VERSION
    end

    def class_for_run_list_item(item)
      item.type == 'role' ? 'ui-state-highlight' : 'ui-state-default'
    end

  end
end
