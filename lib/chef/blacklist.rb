
require "chef/exceptions"

class Chef
  class Blacklist

    # filter takes two arguments - the data you want to filter, and a blacklisted array
    # of keys you want discluded. You can capture a subtree of the data to filter by
    # providing a "/"-delimited string of keys. If some key includes "/"-characters,
    # you must provide an array of keys instead.
    #
    # Blacklist.filter(
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
    # will exclude the eth0 and /dev/disk subtrees.
    def self.filter(data, blacklist = nil)
      return data if blacklist.nil?

      blacklist.each do |item|
        Chef::Log.warn("Removing item #{item}")
        remove_data(data, item)
      end
      data
    end

    # Walk the data according to the keys provided by the blacklisted item
    # to get a reference to the item that will be removed.
    def self.remove_data(data, item)
      parts = to_array(item)

      item_ref = data
      parts[0..-2].each do |part|
        unless item_ref[part]
          Chef::Log.warn("Could not find blacklist attribute #{item}.")
          return nil
        end

        item_ref = item_ref[part]
      end

      unless item_ref.key?(parts[-1])
        Chef::Log.warn("Could not find blacklist attribute #{item}.")
        return nil
      end

      item_ref.delete(parts[-1])
      data
    end

    private_class_method :remove_data

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
