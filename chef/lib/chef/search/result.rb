#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2008 Opscode, Inc.
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

require 'extlib'

class Chef
  class Search
    class Result

      def initialize
        proc = lambda do |h,k| 
            newhash = Mash.new(&proc)
            h.each do |pk, pv| 
              rx = /^#{k.to_s}_/ 
              if pk =~ rx 
                newhash[ pk.gsub(rx,'') ] = pv 
              end 
            end 
            newhash 
          end 
        @internal = Mash.new(&proc) 
      end

      def method_missing(symbol, *args, &block)
        @internal.send(symbol, *args, &block)
      end

      # Serialize this object as a hash 
      def to_json(*a)
        result = {
          'json_class' => self.class.name,
          'results' => @internal
        }
        result.to_json(*a)
      end
      
      # Create a Chef::Search::Result from JSON
      def self.json_create(o)
        result = self.new
        o['results'].each do |k,v|
          result[k] = v
        end
        result
      end
    end
  end
end


