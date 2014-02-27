class Chef
  module ChefFS
    module DataHandler
      class DataHandlerBase
        def minimize(object, entry)
          default_object = default(entry)
          object.each_pair do |key, value|
            if default_object[key] == value && !preserve_key(key)
              object.delete(key)
            end
          end
          object
        end

        def remove_dot_json(name)
          if name.length < 5 || name[-5,5] != ".json"
            raise "Invalid name #{path}: must end in .json"
          end
          name[0,name.length-5]
        end

        def preserve_key(key)
          false
        end

        def default(entry)
          normalize({}, entry)
        end

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

        def normalize_for_post(object, entry)
          normalize(object, entry)
        end

        def normalize_for_put(object, entry)
          normalize(object, entry)
        end

        def normalize_run_list(run_list)
          run_list.map{|item|
            case item.to_s
            when /^recipe\[.*\]$/
              item # explicit recipe
            when /^role\[.*\]$/
              item # explicit role
            else
              "recipe[#{item}]"
            end
          }.uniq
        end

        def from_ruby(ruby)
          chef_class.from_file(ruby).to_hash
        end

        def chef_object(object)
          chef_class.json_create(object)
        end

        def to_ruby(object)
          raise NotImplementedError
        end

        def chef_class
          raise NotImplementedError
        end

        def to_ruby_keys(object, keys)
          result = ''
          keys.each do |key|
            if object[key]
              if object[key].is_a?(Hash)
                if object[key].size > 0
                  result << key
                  first = true
                  object[key].each_pair do |k,v|
                    if first
                      first = false
                    else
                      result << ' '*key.length
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

        def verify_integrity(object, entry, &on_error)
          base_name = remove_dot_json(entry.name)
          if object['name'] != base_name
            on_error.call("Name must be '#{base_name}' (is '#{object['name']}')")
          end
        end

      end # class DataHandlerBase
    end
  end
end
