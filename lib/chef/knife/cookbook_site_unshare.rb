#
# Author:: Stephen Delano (<stephen@chef.io>)
# Author:: Tim Hinderliter (<tim@chef.io>)
# Copyright:: Copyright 2010-2016, Chef Software Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require "chef/knife"

class Chef
  class Knife
    class CookbookSiteUnshare < Knife

      deps do
        require "chef/json_compat"
      end

      banner "knife cookbook site unshare COOKBOOK"
      category "cookbook site"

      option :supermarket_site,
        :short => "-m SUPERMARKET_SITE",
        :long => "--supermarket-site SUPERMARKET_SITE",
        :description => "Supermarket Site",
        :default => "https://supermarket.chef.io",
        :proc => Proc.new { |supermarket| Chef::Config[:knife][:supermarket_site] = supermarket }

      def run
        @cookbook_name = @name_args[0]
        if @cookbook_name.nil?
          show_usage
          ui.fatal "You must provide the name of the cookbook to unshare"
          exit 1
        end

        confirm "Do you really want to unshare all versions of the cookbook #{@cookbook_name}"

        begin
          rest.delete "#{config[:supermarket_site]}/api/v1/cookbooks/#{@name_args[0]}"
        rescue Net::HTTPServerException => e
          raise e unless e.message =~ /Forbidden/
          ui.error "Forbidden: You must be the maintainer of #{@cookbook_name} to unshare it."
          exit 1
        end

        ui.info "Unshared all versions of the cookbook #{@cookbook_name}"
      end

    end
  end
end
