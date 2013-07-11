require 'chef/platform'

class Chef
  module ChefFS
    def self.windows?
      Chef::Platform.windows?
    end
  end
end
