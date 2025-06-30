# Helper library for Ohai plugin management in Chef
#
# This library provides an improved mechanism for loading and reloading
# custom Ohai plugins, addressing the issues in Chef 18+ where the standard
# ohai resource may fail to properly reload custom plugins.

require_relative 'ohai_plugin_loader'

module ChefExtensions
  module OhaiHelper
    class << self
      # Find a plugin by name in all known plugin paths
      #
      # @param plugin_name [String] Name of the plugin to find
      # @return [String, nil] Path to the plugin file if found, nil otherwise
      def find_plugin_by_name(plugin_name)
        require 'ohai'
        
        # Check in all configured plugin paths
        Ohai::Config[:plugin_path].each do |path|
          # Skip if path doesn't exist
          next unless ::File.directory?(path)
          
          # Look for plugin files in this path
          Dir.glob("#{path}/**/*.rb").each do |file|
            # Check if file contains the plugin name in a provides or plugin declaration
            if ::File.read(file) =~ /plugin\s*\(\s*:#{plugin_name}\s*\)/i || 
               ::File.read(file) =~ /provides\s*['"]#{plugin_name}['"]/i
              return file
            end
          end
        end
        
        nil
      end
      
      # Registers all custom Ohai plugins in a cookbook with the Ohai system
      # Delegates to the OhaiPluginLoader for the actual implementation
      #
      # @param run_context [Chef::RunContext] The run context
      # @param cookbook_name [String] The cookbook name containing plugins
      # @param plugin_path [String] Path to plugins, relative to cookbook root (default: 'ohai')
      # @return [void]
      def register_cookbook_plugins(run_context, cookbook_name, plugin_path = 'ohai')
        # Delegate to the more robust OhaiPluginLoader implementation
        # Note: When integrated into Chef codebase, this would be Chef::Extensions::OhaiPluginLoader
        OhaiPluginLoader.register_cookbook_plugins(run_context, cookbook_name, plugin_path)
      end

      # Reload a specific Ohai plugin file and merge its data into node attributes
      #
      # @param plugin_file [String] Full path to the plugin file
      # @param node [Chef::Node] The node object to update (optional)
      # @return [Ohai::System] The Ohai system instance with loaded plugins
      def reload_plugin_file(plugin_file, node = nil)
        require 'ohai'
        require 'chef/log'
        
        # Create a new Ohai system
        ohai = Ohai::System.new
        
        # Load all plugins first to establish the plugin registry
        ohai.load_plugins
        
        # Run only the specific plugin file
        ohai.run_additional_plugins(plugin_file)
        
        # Merge into node attributes if node is provided
        if node && ohai.data.any?
          node.automatic_attrs.merge!(ohai.data)
          Chef::Log.info("Ohai plugin reloaded: #{plugin_file}")
          Chef::Log.debug("Plugin data: #{ohai.data.keys.join(', ')}")
        end
        
        ohai
      end

      # Reload all Ohai plugins from a particular path
      #
      # @param plugin_path [String] Path containing Ohai plugins
      # @param node [Chef::Node] The node object to update (optional)
      # @return [Ohai::System] The Ohai system instance with loaded plugins
      def reload_all_plugins_in_path(plugin_path, node = nil)
        require 'ohai'
        require 'chef/log'
        
        return unless File.directory?(plugin_path)
        
        # Add to Ohai plugin path if not already added
        Ohai::Config[:plugin_path] ||= []
        Ohai::Config[:plugin_path] << plugin_path unless Ohai::Config[:plugin_path].include?(plugin_path)
        
        # Create a new Ohai system
        ohai = Ohai::System.new
        
        # Load and run all plugins 
        ohai.load_plugins
        ohai.run_plugins(true)
        
        # Merge into node attributes if node is provided
        if node && ohai.data.any?
          node.automatic_attrs.merge!(ohai.data)
          Chef::Log.info("All Ohai plugins reloaded from: #{plugin_path}")
        end
        
        ohai
      end
      
      # Reload a specific Ohai plugin by name
      #
      # @param plugin_name [String] Name of the plugin to reload
      # @param node [Chef::Node] The node object to update (optional)
      # @return [Ohai::System, nil] The Ohai system instance if plugin found, nil otherwise
      def reload_plugin_by_name(plugin_name, node = nil)
        require 'ohai'
        require 'chef/log'
        
        # Try to find the plugin file
        plugin_file = find_plugin_by_name(plugin_name)
        return nil unless plugin_file
        
        # If we found the file, reload it
        Chef::Log.info("Found plugin #{plugin_name} at #{plugin_file}")
        reload_plugin_file(plugin_file, node)
      end
    end
  end
end

# Define a custom resource that extends the built-in ohai resource
class Chef
  class Resource
    class OhaiPlugin < Chef::Resource
      provides :ohai_plugin
      
      description "Enhanced version of the ohai resource that properly handles custom plugins"
      
      property :plugin, String,
               description: "The specific plugin to reload by name (e.g., 'myplugin')"
      
      property :plugin_file, String,
               description: "Path to the Ohai plugin file to reload"
                
      property :plugin_path, String,
               description: "Path to a directory of Ohai plugins to reload"
                
      property :plugin_cookbook, String,
               description: "Name of the cookbook containing Ohai plugins to reload"
                
      property :cookbook_plugin_path, String,
               default: 'ohai',
               description: "Path within the cookbook to the Ohai plugins directory" 

      action :reload do
        converge_by("reload Ohai plugins") do
          # Keep track if we successfully reloaded anything
          reload_succeeded = false

          # First try the specific approaches that are more likely to work with custom plugins
          if new_resource.plugin_file && ::File.exist?(new_resource.plugin_file)
            ChefExtensions::OhaiHelper.reload_plugin_file(new_resource.plugin_file, node)
            reload_succeeded = true
          elsif new_resource.plugin_path && ::File.directory?(new_resource.plugin_path)
            ChefExtensions::OhaiHelper.reload_all_plugins_in_path(new_resource.plugin_path, node)
            reload_succeeded = true
          elsif new_resource.plugin_cookbook
            ChefExtensions::OhaiHelper.register_cookbook_plugins(run_context, new_resource.plugin_cookbook, new_resource.cookbook_plugin_path)
            reload_succeeded = true
          end

          # If we have a specific plugin name but haven't reloaded anything yet, try the manual approach
          if new_resource.plugin && !reload_succeeded
            logger.info("Attempting to manually reload plugin: #{new_resource.plugin}")
            begin
              # First try our helper method to find and reload the plugin by name
              if ChefExtensions::OhaiHelper.reload_plugin_by_name(new_resource.plugin, node)
                plugin_found = true
              else
                # If our helper couldn't find it, try one more approach with a fresh Ohai instance
                logger.info("Could not find plugin directly, trying with all_plugins(#{new_resource.plugin})")
                ohai = ::Ohai::System.new
                ohai.all_plugins(new_resource.plugin)
                node.automatic_attrs.merge!(ohai.data)
              end
              
              reload_succeeded = true
            rescue => e
              logger.warn("Error reloading plugin #{new_resource.plugin}: #{e.message}")
            end
          end
          
          # As a last resort, reload all plugins
          unless reload_succeeded
            logger.info("Using fallback approach: reloading all Ohai plugins")
            ohai = ::Ohai::System.new
            ohai.all_plugins
            node.automatic_attrs.merge!(ohai.data)
          end
          
          logger.info("#{new_resource} reloaded Ohai plugins")
        end
      end
    end
  end
end

# Register the OhaiHelper methods in the Recipe DSL
Chef::DSL::Recipe.include ChefExtensions::OhaiHelper
