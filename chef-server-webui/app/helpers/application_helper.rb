require 'chef/mixin/deep_merge'
require 'chef-server-webui/version'

module Merb
  module ApplicationHelper

    ROLE_STR = "role"
    RECIPE_STR = "recipe"


    def chef_version
      ::ChefServerWebui::VERSION
    end

    def class_for_run_list_item(item)
      case item.type.to_s
      when ROLE_STR
        'ui-state-highlight'
      when RECIPE_STR
        'ui-state-default'
      else
        raise ArgumentError, "Cannot generate UI class for #{item.inspect}"
      end
    end

    def display_run_list_item(item)
      case item.type.to_s
      when ROLE_STR
        item.name
      when RECIPE_STR
        # webui not sophisticated enough for versioned recipes
        # "#{item.name}@#{item.version}"
        item.name
      else
        raise ArgumentError, "can't generate display string for #{item.inspect}"
      end
    end

    def nav_link_item(title, dest)
      name = title.gsub(/ /, "").downcase
      klass = controller_name == name ? 'class="active"' : ""
      link = link_to(title, url(dest))
      "<li #{klass}>#{link}</li>"
    end
  end
end
