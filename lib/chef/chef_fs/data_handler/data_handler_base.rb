class Chef
  module ChefFS
    module DataHandler
      class DataHandlerBase
        def minimize(object, *keys)
          default_object = default({}, *keys)
          object.each_pair do |key, value|
            if default_object[key] == value
              object.delete(key)
            end
          end
          object
        end

        def default(*keys)
          normalize({}, *keys)
        end

        def normalize(object, defaults)
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

        def normalize_run_list(run_list)
          run_list.map{|item|
            case item
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
      end
    end
  end
end
