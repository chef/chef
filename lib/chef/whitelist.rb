
require "chef/exceptions"

class Chef
  class Whitelist

    # filter takes two arguments - the data you want to filter, and a whitelisted array
    # of keys you want included. You can capture a subtree of the data to filter by
    # providing a "/"-delimited string of keys. If some key includes "/"-characters,
    # you must provide an array of keys instead.
    #
    # Whitelist.filter(
    #   { "filesystem" => {
    #       "/dev/disk" => {
    #         "size" => "10mb"
    #       },
    #       "map - autohome" => {
    #         "size" => "10mb"
    #       }
    #     },
    #     "network" => {
    #       "interfaces" => {
    #         "eth0" => {...},
    #         "eth1" => {...}
    #       }
    #     }
    #   },
    #   ["network/interfaces/eth0", ["filesystem", "/dev/disk"]])
    # will capture the eth0 and /dev/disk subtrees.
    def self.filter(data, whitelist = nil)
      return data if whitelist.nil?

      new_data = {}
      whitelist.each do |item|
        add_data(data, new_data, item)
      end
      new_data
    end

    # Walk the data has according to the keys provided by the whitelisted item
    # and add the data to the whitelisting result.
    def self.add_data(data, new_data, item)
      parts = to_array(item)

      all_data = data
      filtered_data = new_data
      parts[0..-2].each do |part|
        unless all_data[part]
          Chef::Log.warn("Could not find whitelist attribute #{item}.")
          return nil
        end

        filtered_data[part] ||= {}
        filtered_data = filtered_data[part]
        all_data = all_data[part]
      end

      # Note: You can't do all_data[parts[-1]] here because the value
      # may be false-y
      unless all_data.key?(parts[-1])
        Chef::Log.warn("Could not find whitelist attribute #{item}.")
        return nil
      end

      filtered_data[parts[-1]] = all_data[parts[-1]]
      new_data
    end

    private_class_method :add_data

    # Accepts a String or an Array, and returns an Array of String keys that
    # are used to traverse the data hash. Strings are split on "/", Arrays are
    # assumed to contain exact keys (that is, Array elements will not be split
    # by "/").
    def self.to_array(item)
      return item if item.kind_of? Array

      parts = item.split("/")
      parts.shift if !parts.empty? && parts[0].empty?
      parts
    end

    private_class_method :to_array

  end
end
