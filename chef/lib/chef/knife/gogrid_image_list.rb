#
# Author:: Steve Lum (<steve.lum@gmail.com>)
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

require 'chef/knife'
require 'json'

class Chef
  class Knife
    class GogridImageList < Knife

      banner "knife gogrid image list (options)"

      def h
        @highline ||= HighLine.new
      end

      def run 
        require 'fog'
        require 'highline'
        require 'net/ssh/multi'
        require 'readline'

        connection = Fog::GoGrid::Compute.new(
          :go_grid_api_key => Chef::Config[:knife][:go_grid_api_key],
          :go_grid_shared_secret => Chef::Config[:knife][:go_grid_shared_secret] 
        )

        images  = connection.images.inject({}) { |h,i| h[i.id] = i.description; h }

        image_list = [ h.color('id', :bold), h.color('friendly_name', :bold), h.color('name', :bold) ]
        #image_list = [ h.color('friendly_name', :bold), h.color('name', :bold) ]

        connection.images.each do |image|
          #image_list << image.id.to_s
          image_list << image.server_id.to_s
          #image_list << image.server_id
          image_list << image.friendly_name
          image_list << image.name
        end
        puts h.list(image_list, :columns_across, 3)

      end
    end
  end
end
