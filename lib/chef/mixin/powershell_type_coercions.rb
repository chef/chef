#
# Author:: Adam Edwards (<adamed@opscode.com>)
# Author:: Jay Mundrawala (<jdm@chef.io>)
# Copyright:: Copyright (c) 2015 Chef Software, Inc.
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
    module PowershellTypeCoercions
      def type_coercions
        @type_coercions ||= {
          Fixnum => { :type => lambda { |x| x.to_s }, :single_quoted => false },
          Float => { :type => lambda { |x| x.to_s }, :single_quoted => false },
          FalseClass => { :type => lambda { |x| '$false' }, :single_quoted => false },
          TrueClass => { :type => lambda { |x| '$true' }, :single_quoted => false }
        }
      end

      def translate_type(value)
        translation = type_coercions[value.class]
        should_quote = true
        translated_value = nil

        if translation
          should_quote = translation[:single_quoted]
          translated_value = translation[:type].call(value)
        else
          translated_value = value.to_s
        end

        translated_value = "'#{translated_value}'" if should_quote
        translated_value
      end

    end
  end
end
