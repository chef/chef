#
# Author:: Jesse Proudman (<jesse.proudman@blueboxgrp.com>)
# Copyright:: Copyright (c) 2010 Blue Box Group
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
    class BlueboxImagesList < Knife

      banner "knife bluebox images list"

      def highline
        @highline ||= HighLine.new
      end

      def run
        require 'fog'
        require 'highline'

        bluebox = Fog::Bluebox.new(
          :bluebox_customer_id => Chef::Config[:knife][:bluebox_customer_id],
          :bluebox_api_key => Chef::Config[:knife][:bluebox_api_key]
        )

        images  = bluebox.images.inject({}) { |h,i| h[i.id] = i.description; h }

        image_list = [ highline.color('ID', :bold), highline.color('Name', :bold) ]

        bluebox.images.each do |server|
          image_list << server.id.to_s
          image_list << server.description
        end
        puts highline.list(image_list, :columns_across, 2)

      end
    end
  end
end
