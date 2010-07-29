require 'chef/mixin/deep_merge'
require 'chef-server-webui/version'

module Merb
  module ApplicationHelper

    def chef_version
      ::ChefServerWebui::VERSION
    end

  end
end
