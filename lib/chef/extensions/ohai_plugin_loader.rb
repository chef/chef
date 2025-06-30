# ohai_plugin_loader.rb
#
# This library enhances Chef's Ohai plugin loading mechanism to ensure custom
# plugins are properly loaded and registered before they're needed.
#
# It addresses a known issue in Chef 18+ where the standard ohai resource
# may fail to properly reload custom plugins.

require 'chef/log'

# Register our custom configuration at the earliest possible point
Ohai::Config[:plugin_path] ||= []

# Use a cleaner, platform-neutral name for the module
module ChefExtensions
  module OhaiHelper
    # Used by the OhaiPluginLoader - just forwards the calls
    def self.register_cookbook_plugins(run_context, cookbook_name, plugin_path = 'ohai')
      OhaiPluginLoader.register_cookbook_plugins(run_context, cookbook_name, plugin_path)
    end
  end
end

# Create a custom class to patch Ohai plugin detection and loading
module OhaiPluginLoader
  class << self
    # Get all plugin paths
    def all_plugin_paths
      paths = []
      
      # Get all cookbook paths from the run context if available
      if defined?(Chef.run_context) && Chef.run_context && Chef.run_context.cookbook_collection
        Chef.run_context.cookbook_collection.each do |cookbook_name, cookbook|
          # Check for the ohai directory
          ohai_dir = File.join(cookbook.root_dir, 'ohai')
          paths << ohai_dir if Dir.exist?(ohai_dir)
          
          # Check for files/default/plugins directory
          plugins_dir = File.join(cookbook.root_dir, 'files', 'default', 'plugins')
          paths << plugins_dir if Dir.exist?(plugins_dir)
        end
      end
      
      # Add any additional paths from ohai config
      paths += Ohai::Config[:plugin_path] if Ohai::Config[:plugin_path].is_a?(Array)
      
      # Add the file_cache_path/plugins if it exists
      cache_plugins = File.join(Chef::Config[:file_cache_path], 'plugins') if defined?(Chef::Config)
      paths << cache_plugins if cache_plugins && Dir.exist?(cache_plugins)
      
      # Return unique paths
      paths.uniq
    end
    
    # Register all custom plugin paths with Ohai
    def register_plugin_paths
      # Get all plugin paths
      paths = all_plugin_paths
      
      # Add them to Ohai config if not already present
      paths.each do |path|
        Ohai::Config[:plugin_path] << path unless Ohai::Config[:plugin_path].include?(path)
      end
      
      # Log the registered paths
      Chef::Log.info("Registered Ohai plugin paths: #{Ohai::Config[:plugin_path].join(', ')}")
    end
    
    # Find a plugin file by name
    def find_plugin_file(plugin_name)
      # Search all plugin paths for a matching plugin
      all_plugin_paths.each do |path|
        # Skip if path doesn't exist
        next unless Dir.exist?(path)
        
        # First look for files that match the plugin name directly
        Dir.glob("#{path}/**/#{plugin_name}.rb").each do |file|
          Chef::Log.info("Found potential plugin file by name: #{file}")
          return file
        end
        
        # If not found by filename, look for content matches
        Dir.glob("#{path}/**/*.rb").each do |file|
          begin
            content = File.read(file)
            # Check if file contains the plugin name in the expected format
            if content =~ /plugin\s*\(\s*:#{plugin_name.capitalize}\s*\)/i ||
               content =~ /plugin\s*\(\s*:#{plugin_name}\s*\)/i ||
               content =~ /provides\s*['"]#{plugin_name}['"]/i
              Chef::Log.info("Found plugin #{plugin_name} by content match in: #{file}")
              return file
            end
          rescue => e
            Chef::Log.warn("Error reading plugin file #{file}: #{e.message}")
          end
        end
      end
      
      nil
    end
    
    # Register all plugins in a specific cookbook
    def register_cookbook_plugins(run_context, cookbook_name, plugin_path = 'ohai')
      # Skip if run_context or cookbook_collection is not available
      return unless run_context && run_context.cookbook_collection
      
      # Get the cookbook
      cookbook = run_context.cookbook_collection[cookbook_name]
      return unless cookbook
      
      # Find the ohai directory in the cookbook
      cookbook_root = cookbook.root_dir
      cookbook_plugin_path = File.join(cookbook_root, plugin_path)
      
      # Skip if the path doesn't exist
      return unless Dir.exist?(cookbook_plugin_path)
      
      # Add to Ohai plugin path if not already added
      Ohai::Config[:plugin_path] ||= []
      Ohai::Config[:plugin_path] << cookbook_plugin_path unless Ohai::Config[:plugin_path].include?(cookbook_plugin_path)
      
      # Process each plugin file
      Dir.glob("#{cookbook_plugin_path}/**/*.rb").each do |file|
        Chef::Log.info("Registering Ohai plugin from cookbook #{cookbook_name}: #{file}")
      end
      
      # Return the path that was registered
      cookbook_plugin_path
    end
    
    # Force load all plugins from all paths
    def force_load_all_plugins
      # Create a new Ohai system
      ohai = Ohai::System.new
      
      # Register all plugin paths
      register_plugin_paths
      
      # Load all plugins
      ohai.load_plugins
      
      # Run all plugins
      ohai.all_plugins
      
      # Return the Ohai instance
      ohai
    end
    
    # Reload a specific plugin by name
    def reload_plugin(plugin_name, node = nil)
      # Create a fresh Ohai instance
      ohai = Ohai::System.new
      
      # Make sure all our plugin paths are registered
      register_plugin_paths
      
      # First try to find the plugin file
      plugin_file = find_plugin_file(plugin_name)
      
      if plugin_file
        # Load all plugins first to establish the provides map
        ohai.load_plugins
        
        # Then run just our specific plugin
        Chef::Log.info("Found plugin #{plugin_name} at #{plugin_file}")
        ohai.run_additional_plugins(plugin_file)
      else
        # If we can't find the file by name, run all plugins
        # This is safer than specifying the plugin name which might trigger the AttributeNotFound error
        Chef::Log.info("Plugin file for #{plugin_name} not found, loading all plugins")
        ohai.load_plugins
        ohai.all_plugins
        
        # Check if our plugin's data was loaded
        if ohai.data.key?(plugin_name)
          Chef::Log.info("Plugin #{plugin_name} data was found after loading all plugins")
        else
          Chef::Log.warn("Plugin #{plugin_name} data was not found after loading all plugins")
        end
      end
      
      # Merge data into node if provided
      if node && ohai.data.any?
        node.automatic_attrs.merge!(ohai.data)
        if ohai.data.key?(plugin_name)
          Chef::Log.info("Merged plugin data for #{plugin_name} into node attributes: #{ohai.data[plugin_name].inspect}")
        else
          Chef::Log.info("Plugin #{plugin_name} data was not found in the Ohai data")
        end
      end
      
      # Return the Ohai instance
      ohai
    end
  end
end

# Add some helpers to the OhaiPluginLoader
module OhaiPluginLoader
  class << self
    # Safe version of reload_plugin that handles AttributeNotFound errors
    def safe_reload_plugin(plugin_name, node = nil)
      begin
        return reload_plugin(plugin_name, node)
      rescue Ohai::Exceptions::AttributeNotFound => e
        Chef::Log.warn("AttributeNotFound error for plugin #{plugin_name}: #{e.message}")
        Chef::Log.info("Falling back to full Ohai reload to work around AttributeNotFound")
        return force_load_all_plugins
      end
    end
  end
end

# Patch the Chef::Resource::Ohai class to enhance plugin reloading
class Chef
  class Resource
    class Ohai < Chef::Resource
      # Override the reload action to use our enhanced functionality
      action :reload do
        converge_by("re-run ohai to reload plugin data") do
          begin
            if new_resource.plugin
              # Reload only the specified plugin using our enhanced loader that handles errors
              Chef::Log.info("Reloading Ohai plugin: #{new_resource.plugin}")
              ohai = OhaiPluginLoader.safe_reload_plugin(new_resource.plugin, node)
            else
              # Reload all plugins
              Chef::Log.info("Reloading all Ohai plugins")
              ohai = OhaiPluginLoader.force_load_all_plugins
              node.automatic_attrs.merge!(ohai.data)
            end
            
            logger.info("#{new_resource} reloaded")
          rescue => e
            if new_resource.ignore_failure
              Chef::Log.error("Failed to reload Ohai plugin: #{e.class}: #{e.message}")
              Chef::Log.error("Ignoring failure and continuing.")
            else
              raise
            end
          end
        end
      end
    end
  end
end

# Register our plugin paths at library loading time
OhaiPluginLoader.register_plugin_paths
