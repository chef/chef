#
# Author:: Richard Manyanza (<liseki@nyikacraftsmen.com>)
# Copyright:: Copyright (c) 2014 Richard Manyanza.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'chef/exceptions'
require 'chef/platform/provider_priority_map'

class Chef
  #
  # Provider Resolution
  # ===================
  #
  # When you type `service 'myservice' { action :restart }` in a recipe, a whole
  # string of events happens eventually leading to convergence.  The overview of
  # that process is described in `Chef::DSL::Recipe`.  Provider resolution is
  # the process of taking a Resource object and an action, and determining the
  # Provider class that should be instantiated to handle the action.
  #
  # The process happens in three steps:
  #
  # Explicit Provider on the Resource
  # ---------------------------------
  # If the resource has its `provider` set, that is used.
  #
  # Dynamic Provider Matches
  # ------------------------
  # In this stage, we call `provides?` to see if the Provider supports the
  # resource on this platform, and then we call `supports?` to determine if it
  # can handle the action.  It's a little more complicated than that, though:
  #
  # ### Provider.provides?
  #
  # First, we go through all known provider classes (all descendants of
  # `Chef::Provider`), and call `provides?(node, resource)` to determine if it
  # supports this action for this resource on this OS.  We get a list of all
  # matches.
  #
  # #### Defining provides
  #
  # The typical way of getting `provides?` is for the Provider class to call
  # `provides :name`.
  #
  # The Provider may pass the OS, platform family, platform, and platform version
  # to `provides`, and they will be matched against the values in the `node`
  # object.  The Provider may also pass a block, which allows for custom logic
  # to decide whether it provides the resource or not.
  #
  # Some Providers also override `provides?` with custom logic.
  #
  # ### Provider.supports?
  #
  # Once we have the list of willing providers, we filter it by calling their
  # `supports?(resource, action)` method to see if they support the specific
  # action (`:create`, `:delete`) or not.
  #
  # If no provider supports the specific action, we fall back to the full list
  # of matches from step 1.  (TODO The comment says it's for why run.  I'm not
  # sure what that means specifically yet.)
  #
  # ### Priority lists: Chef.get_provider_priority_array
  #
  # Once we have the list of matches, we look at `Chef.get_provider_priority_array(node, resource)`
  # to see if anyone has set a *priority list*.  This method takes
  # the the first matching priority list for this OS (which is the last list
  # that was registered).
  #
  # If any of our matches are on the priority list, we take the first one.
  #
  # If there is no priority list or no matches on it, we take the first result
  # alphabetically by class name.
  #
  # Chef::Platform Provider Map
  # ---------------------------
  # If we still have no matches, we try `Chef::Platform.find_provider_for_node(node, resource)`.
  # This does two new things:
  #
  # ### System Provider Map
  #
  # The system provider map is a large Hash loaded during `require` time,
  # which shows system-specific providers by os/platform, and platform_version.
  # It keys off of `node[:platform] || node[:os]`, and `node[:platform_version]
  # || node[:os_version] || node[:os_release]`.  The version uses typical gem
  # constraints like > and <=.
  #
  # The first platform+version match wins over the first platform-only match,
  # which wins over the default.
  #
  # ### Chef::Provider::FooBar
  #
  # As a last resort, if there are *still* no classes, the system transforms the
  # DSL name `foo_bar` into `Chef::Provider::FooBar`, and returns the class if
  # it is there and descends from `Chef::Provider`.
  #
  # NOTE: this behavior is now deprecated.
  #
  class ProviderResolver

    attr_reader :node
    attr_reader :resource
    attr_reader :action

    def initialize(node, resource, action)
      @node = node
      @resource = resource
      @action = action
    end

    # return a deterministically sorted list of Chef::Provider subclasses
    def providers
      @providers ||= Chef::Provider.descendants
    end

    def resolve
      maybe_explicit_provider(resource) ||
        maybe_dynamic_provider_resolution(resource, action) ||
        maybe_chef_platform_lookup(resource)
    end

    # this cut looks at if the provider can handle the resource type on the node
    def enabled_handlers
      @enabled_handlers ||=
        providers.select do |klass|
          # NB: this is different from resource_resolver which must pass a resource_name
          # FIXME: deprecate this and normalize on passing resource_name here
          klass.provides?(node, resource)
        end.sort {|a,b| a.to_s <=> b.to_s }
    end

    # this cut looks at if the provider can handle the specific resource and action
    def supported_handlers
      @supported_handlers ||=
        enabled_handlers.select do |klass|
          klass.supports?(resource, action)
        end
    end

    private

    # if resource.provider is set, just return one of those objects
    def maybe_explicit_provider(resource)
      return nil unless resource.provider
      resource.provider
    end

    # try dynamically finding a provider based on querying the providers to see what they support
    def maybe_dynamic_provider_resolution(resource, action)
      # log this so we know what providers will work for the generic resource on the node (early cut)
      Chef::Log.debug "providers for generic #{resource.resource_name} resource enabled on node include: #{enabled_handlers}"

      # what providers were excluded by machine state (late cut)
      Chef::Log.debug "providers that refused resource #{resource} were: #{enabled_handlers - supported_handlers}"
      Chef::Log.debug "providers that support resource #{resource} include: #{supported_handlers}"

      # if none of the providers specifically support the resource, we still need to pick one of the providers that are
      # enabled on the node to handle the why-run use case.
      handlers = supported_handlers.empty? ? enabled_handlers : supported_handlers
      Chef::Log.debug "no providers supported the resource, falling back to enabled handlers" if supported_handlers.empty?

      if handlers.count >= 2
        # this magic stack ranks the providers by where they appear in the provider_priority_map, it is mostly used
        # to pick amongst N different ways to start init scripts on different debian/ubuntu systems.
        priority_list = [ get_priority_array(node, resource.resource_name) ].flatten.compact
        handlers = handlers.sort_by { |x| i = priority_list.index x; i.nil? ? Float::INFINITY : i }
        if priority_list.index(handlers.first).nil?
          # if we had more than one and we picked one with a precidence of infinity that means that the resource_priority_map
          # entry for this resource is missing -- we should probably raise here and force resolution of the ambiguity.
          Chef::Log.warn "Ambiguous provider precedence: #{handlers}, please use Chef.set_provider_priority_array to provide determinism"
        end
        handlers = [ handlers.first ]
      end

      Chef::Log.debug "providers that survived replacement include: #{handlers}"

      raise Chef::Exceptions::AmbiguousProviderResolution.new(resource, handlers) if handlers.count >= 2

      Chef::Log.debug "dynamic provider resolver FAILED to resolve a provider" if handlers.empty?

      return nil if handlers.empty?

      handlers[0]
    end

    # try the old static lookup of providers by platform
    def maybe_chef_platform_lookup(resource)
      Chef::Platform.find_provider_for_node(node, resource)
    end

    # dep injection hooks
    def get_priority_array(node, resource_name)
      provider_priority_map.get_priority_array(node, resource_name)
    end

    def provider_priority_map
      Chef::Platform::ProviderPriorityMap.instance
    end
  end
end
