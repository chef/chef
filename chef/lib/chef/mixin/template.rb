#
# Author:: Adam Jacob (<adam@hjksolutions.com>)
# Copyright:: Copyright (c) 2008 HJK Solutions, LLC
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

require 'tempfile'
require 'erubis'

class Chef
  module Mixin
    module Template
    
      # Render a template with Erubis.  Takes a template as a string, and a 
      # context hash.  
      def render_template(template, context)
        eruby = Erubis::Eruby.new(template)
        output = eruby.evaluate(context)
        final_tempfile = Tempfile.new("chef-rendered-template")
        final_tempfile.print(output)
        final_tempfile.close
        final_tempfile
      end
      
    end
  end
end
