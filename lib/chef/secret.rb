require "secret/store"
require "chef/mixin/convert_to_class_name"

class Chef
  class Secret
    include Chef::Mixin::ConvertToClassName

    def initialize(type = "data_bag")
      @store = Object.const_get("Chef::Secret::Store::#{convert_to_class_name(type.to_s)}").new
    rescue NameError
      raise "Unsupported Secret Store '#{type}'"
    end

    def store
      @store
    end

    def read(arg)
      @store.read(arg)
    end

    def write(arg)
      @store.write(arg)
    end
  end
end

