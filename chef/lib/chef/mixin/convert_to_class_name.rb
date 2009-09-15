#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Christopher Walters (<cw@opscode.com>)
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
#

class Chef
  module Mixin
    module ConvertToClassName

      def convert_to_class_name(str, mod=nil)
        rname = nil
        regexp = %r{^(.+?)(_(.+))?$}
        
        mn = str.match(regexp)
        if mn
          rname = "#{mod ? "#{mod.to_s}::" : ''}#{mn[1].capitalize}"

          while mn && mn[3]
            mn = mn[3].match(regexp)          
            rname << mn[1].capitalize if mn
          end
        end

        rname
      end
      
    end
  end
end
