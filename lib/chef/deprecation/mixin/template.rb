#
# Author:: Serdar Sutay (<serdar@opscode.com>)
# Copyright:: Copyright (c) 2013 Opscode, Inc.
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
  module Deprecation
    module Mixin
      # == Deprecation::Provider::Mixin::Template
      # This module contains the deprecated functions of
      # Chef::Mixin::Template. These functions are refactored to different
      # components. They are frozen and will be removed in Chef 12.
      #

      module Template
        def render_template(template, context)
          begin
            eruby = Erubis::Eruby.new(template)
            output = eruby.evaluate(context)
          rescue Object => e
            raise TemplateError.new(e, template, context)
          end
          Tempfile.open("chef-rendered-template") do |tempfile|
            tempfile.print(output)
            tempfile.close
            yield tempfile
          end
        end
      end
    end
  end
end

