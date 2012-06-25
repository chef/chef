require 'chef/client'
require 'singleton'

class Chef

  # Keep track of the filenames that we use in both eager cookbook
  # downloading (during sync_cookbooks) and lazy (during the run
  # itself, through FileVendor). After the run is over, clean up the
  # cache.
  class CookbookCacheCleaner

    # Setup a notification to clear the valid_cache_entries when a Chef client
    # run starts
    Chef::Client.when_run_starts do |run_status|
      instance.reset!
    end

    # Register a notification to cleanup unused files from cookbooks
    Chef::Client.when_run_completes_successfully do |run_status|
      instance.cleanup_file_cache
    end

    include Singleton

    def initialize
      reset!
    end

    def reset!
      @valid_cache_entries = {}
    end

    def mark_file_as_valid(cache_path)
      @valid_cache_entries[cache_path] = true
    end

    def cache
      Chef::FileCache
    end

    def cleanup_file_cache
      unless Chef::Config[:solo]
        # Delete each file in the cache that we didn't encounter in the
        # manifest.
        cache.find(File.join(%w{cookbooks ** *})).each do |cache_filename|
          unless @valid_cache_entries[cache_filename]
            Chef::Log.info("Removing #{cache_filename} from the cache; it is no longer needed by chef-client.")
            cache.delete(cache_filename)
          end
        end
      end
    end

  end

  # Synchronizes the locally cached copies of cookbooks with the files on the
  # server.
  class CookbookSynchronizer
    EAGER_SEGMENTS = Chef::CookbookVersion::COOKBOOK_SEGMENTS.dup
    EAGER_SEGMENTS.delete(:files)
    EAGER_SEGMENTS.delete(:templates)
    EAGER_SEGMENTS.freeze

    def initialize(cookbooks_by_name, events)
      @cookbooks_by_name, @events = cookbooks_by_name, events
    end

    def cache
      Chef::FileCache
    end

    def cookbook_names
      @cookbooks_by_name.keys
    end

    def cookbooks
      @cookbooks_by_name.values
    end

    def cookbook_count
      @cookbooks_by_name.size
    end

    def have_cookbook?(cookbook_name)
      @cookbooks_by_name.key?(cookbook_name)
    end

    # Synchronizes all the cookbooks from the chef-server.
    #)
    # === Returns
    # true:: Always returns true
    def sync_cookbooks
      Chef::Log.info("Loading cookbooks [#{cookbook_names.sort.join(', ')}]")
      Chef::Log.debug("Cookbooks detail: #{cookbooks.inspect}")

      clear_obsoleted_cookbooks

      @events.cookbook_sync_start(cookbook_count)

      # Synchronize each of the node's cookbooks, and add to the
      # valid_cache_entries hash.
      cookbooks.each do |cookbook|
        sync_cookbook(cookbook)
      end

    rescue Exception => e
      @events.cookbook_sync_failed(cookbooks, e)
      raise
    else
      @events.cookbook_sync_complete
      true
    end

    # Iterates over cached cookbooks' files, removing files belonging to
    # cookbooks that don't appear in +cookbook_hash+
    def clear_obsoleted_cookbooks
      @events.cookbook_clean_start
      # Remove all cookbooks no longer relevant to this node
      cache.find(File.join(%w{cookbooks ** *})).each do |cache_file|
        cache_file =~ /^cookbooks\/([^\/]+)\//
        unless have_cookbook?($1)
          Chef::Log.info("Removing #{cache_file} from the cache; its cookbook is no longer needed on this client.")
          cache.delete(cache_file)
          @events.removed_cookbook_file(cache_file)
        end
      end
      @events.cookbook_clean_complete
    end

    # Sync the eagerly loaded files contained by +cookbook+
    #
    # === Arguments
    # cookbook<Chef::Cookbook>:: The cookbook to update
    # valid_cache_entries<Hash>:: Out-param; Added to this hash are the files that
    # were referred to by this cookbook
    def sync_cookbook(cookbook)
      Chef::Log.debug("Synchronizing cookbook #{cookbook.name}")

      # files and templates are lazily loaded, and will be done later.

      EAGER_SEGMENTS.each do |segment|
        segment_filenames = Array.new
        cookbook.manifest[segment].each do |manifest_record|

          cache_filename = sync_file_in_cookbook(cookbook, manifest_record)
          # make the segment filenames a full path.
          full_path_cache_filename = cache.load(cache_filename, false)
          segment_filenames << full_path_cache_filename
        end

        # replace segment filenames with a full-path one.
        if segment.to_sym == :recipes
          cookbook.recipe_filenames = segment_filenames
        elsif segment.to_sym == :attributes
          cookbook.attribute_filenames = segment_filenames
        else
          cookbook.segment_filenames(segment).replace(segment_filenames)
        end
      end
      @events.synchronized_cookbook(cookbook.name)
    end

    # Sync an individual file if needed. If there is an up to date copy
    # locally, nothing is done.
    #
    # === Arguments
    # file_manifest::: A Hash of the form {"path" => 'relative/path', "url" => "location to fetch the file"}
    # === Returns
    # Path to the cached file as a String
    def sync_file_in_cookbook(cookbook, file_manifest)
      cache_filename = File.join("cookbooks", cookbook.name, file_manifest['path'])
      mark_cached_file_valid(cache_filename)

      # If the checksums are different between on-disk (current) and on-server
      # (remote, per manifest), do the update. This will also execute if there
      # is no current checksum.
      if !cached_copy_up_to_date?(cache_filename, file_manifest['checksum'])
        download_file(file_manifest['url'], cache_filename)
        @events.updated_cookbook_file(cookbook.name, cache_filename)
      else
        Chef::Log.debug("Not storing #{cache_filename}, as the cache is up to date.")
      end

      cache_filename
    end

    def cached_copy_up_to_date?(local_path, expected_checksum)
      if cache.has_key?(local_path)
        current_checksum = CookbookVersion.checksum_cookbook_file(cache.load(local_path, false))
        expected_checksum == current_checksum
      else
        false
      end
    end

    # Unconditionally download the file from the given URL. File will be
    # downloaded to the path +destination+ which is relative to the Chef file
    # cache root.
    def download_file(url, destination)
      raw_file = server_api.get_rest(url, true)

      Chef::Log.info("Storing updated #{destination} in the cache.")
      cache.move_to(raw_file.path, destination)
    end

    # Marks the given file as valid (non-stale).
    def mark_cached_file_valid(cache_filename)
      CookbookCacheCleaner.instance.mark_file_as_valid(cache_filename)
    end

    def server_api
      Chef::REST.new(Chef::Config[:chef_server_url])
    end

  end
end
