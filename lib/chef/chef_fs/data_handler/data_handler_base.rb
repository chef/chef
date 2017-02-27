class Chef
  module ChefFS
    module DataHandler
      #
      # The base class for all *DataHandlers.
      #
      # DataHandlers' job is to know the innards of Chef objects and manipulate
      # JSON for them, adding defaults and formatting them.
      #
      class DataHandlerBase
        #
        # Remove all default values from a Chef object's JSON so that the only
        # thing you see are the values that have been explicitly set.
        # Achieves this by calling normalize({}, entry) to get the list of
        # defaults, and subtracting anything that is the same.
        #
        def minimize(object, entry)
          default_object = default(entry)
          object.each_pair do |key, value|
            if default_object[key] == value && !preserve_key?(key)
              object.delete(key)
            end
          end
          object
        end

        def remove_file_extension(name, ext = ".*")
          if %w{ .rb .json }.include?(File.extname(name))
            File.basename(name, ext)
          else
            name
          end
        end
        alias_method :remove_dot_json, :remove_file_extension

        #
        # Return true if minimize() should preserve a key even if it is the same
        # as the default.  Often used for ids and names.
        #
        def preserve_key?(key)
          false
        end

        #
        # Get the default value for an entry.  Calls normalize({}, entry).
        #
        def default(entry)
          normalize({}, entry)
        end

        #
        # Utility function to help subclasses do normalize().  Pass in a hash
        # and a list of keys with defaults, and normalize will:
        #
        # 1. Fill in the defaults
        # 2. Put the actual values in the order of the defaults
        # 3. Move any other values to the end
        #
        # == Example
        #
        #   normalize_hash({x: 100, c: 2, a: 1}, { a: 10, b: 20, c: 30})
        #   -> { a: 1, b: 20, c: 2, x: 100}
        #
        def normalize_hash(object, defaults)
          # Make a normalized result in the specified order for diffing
          result = {}
          defaults.each_pair do |key, default|
            result[key] = object.has_key?(key) ? object[key] : default
          end
          object.each_pair do |key, value|
            result[key] = value if !result.has_key?(key)
          end
          result
        end

        # Specialized function to normalize an object before POSTing it, since
        # some object types want slightly different values on POST.
        # If not overridden, this just calls normalize()
        def normalize_for_post(object, entry)
          normalize(object, entry)
        end

        # Specialized function to normalize an object before PUTing it, since
        # some object types want slightly different values on PUT.
        # If not overridden, this just calls normalize().
        def normalize_for_put(object, entry)
          normalize(object, entry)
        end

        #
        # normalize a run list (an array of run list items).
        # Leaves recipe[name] and role[name] alone, and translates
        # name to recipe[name].  Then calls uniq on the result.
        #
        def normalize_run_list(run_list)
          run_list.map do |item|
            case item.to_s
            when /^recipe\[.*\]$/
              item # explicit recipe
            when /^role\[.*\]$/
              item # explicit role
            else
              "recipe[#{item}]"
            end
          end.uniq
        end

        #
        # Bring in an instance of this object from Ruby.  (Like roles/x.rb)
        #
        def from_ruby(path)
          r = chef_class.new
          r.from_file(path)
          r.to_hash
        end

        #
        # Turn a JSON hash into a bona fide Chef object (like Chef::Node).
        #
        def chef_object(object)
          chef_class.from_hash(object)
        end

        #
        # Write out the Ruby file for this instance.  (Like roles/x.rb)
        #
        def to_ruby(object)
          raise NotImplementedError
        end

        #
        # Get the class for instances of this type.  Must be overridden.
        #
        def chef_class
          raise NotImplementedError
        end

        #
        # Helper to write out a Ruby file for a JSON hash.  Writes out only
        # the keys specified in "keys"; anything else must be emitted by the
        # caller.
        #
        # == Example
        #
        #   to_ruby_keys({"name" => "foo", "environment" => "desert", "foo": "bar"}, [ "name", "environment" ])
        #   ->
        #   'name "foo"
        #   environment "desert"'
        #
        def to_ruby_keys(object, keys)
          result = ""
          keys.each do |key|
            if object[key]
              if object[key].is_a?(Hash)
                if object[key].size > 0
                  result << key
                  first = true
                  object[key].each_pair do |k, v|
                    if first
                      first = false
                    else
                      result << " " * key.length
                    end
                    result << " #{k.inspect} => #{v.inspect}\n"
                  end
                end
              elsif object[key].is_a?(Array)
                if object[key].size > 0
                  result << key
                  first = true
                  object[key].each do |value|
                    if first
                      first = false
                    else
                      result << ", "
                    end
                    result << value.inspect
                  end
                  result << "\n"
                end
              elsif !object[key].nil?
                result << "#{key} #{object[key].inspect}\n"
              end
            end
          end
          result
        end

        # Verify that the JSON hash for this type has a key that matches its name.
        #
        # @param object [Object] JSON hash of the object
        # @param entry [Chef::ChefFS::FileSystem::BaseFSObject] filesystem object we are verifying
        # @yield  [s] callback to handle errors
        # @yieldparam [s<string>] error message
        def verify_integrity(object, entry)
          base_name = remove_file_extension(entry.name)
          if object["name"] != base_name
            yield("Name must be '#{base_name}' (is '#{object['name']}')")
          end
        end

      end # class DataHandlerBase
    end
  end
end
