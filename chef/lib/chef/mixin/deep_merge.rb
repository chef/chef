#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2009 Opscode, Inc.
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

class Chef
  module Mixin
    class DeepMerge
      def self.merge(first, second)
        first = first.to_hash if first.kind_of?(Mash)
        second = second.to_hash if second.kind_of?(Mash)
        # Originally From: http://www.ruby-forum.com/topic/142809
        # Author: Stefan Rusterholz
        merger = proc do |key,v1,v2| 
            v1.respond_to?(:keys) && v2.respond_to?(:keys) ? v1.merge(v2, &merger) : v2 
          end

        Mash.new(first.merge(second, &merger))
      end
    end
  end
end
