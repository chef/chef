require "secret/store/data_bag"
require "secret/store/encrypted_data_bag"

class Chef
  class Secret
    class Store
      def read
        raise "Secret store #{self} does not support read"
      end

      def write
        raise "Secret store #{self} does not support write"
      end
    end
  end
end
