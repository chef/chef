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
          Fixnum => { :type => lambda { |x| x.to_s }},
          Float => { :type => lambda { |x| x.to_s }},
          FalseClass => { :type => lambda { |x| '$false' }},
          TrueClass => { :type => lambda { |x| '$true' }},
          Hash => {:type => Proc.new { |x| translate_hash(x)}},
          Array => {:type => Proc.new { |x| translate_array(x)}}
        }
      end

      def translate_type(value)
        translation = type_coercions[value.class]

        if translation
          translation[:type].call(value)
        elsif value.respond_to? :to_psobject
          "(#{value.to_psobject})"
        else
          safe_string(value.to_s)
        end
      end

      private

      def translate_hash(x)
        translated = x.inject([]) do |memo, (k,v)|
          memo << "#{k}=#{translate_type(v)}"
        end
        "@{#{translated.join(';')}}"
      end

      def translate_array(x)
        translated = x.map do |v|
          translate_type(v)
        end
        "@(#{translated.join(',')})"
      end

      def unsafe?(s)
        ["'", '#', '`', '"'].any? do |x|
          s.include? x
        end
      end

      def safe_string(s)
        # do we need to worry about binary data?
        if unsafe?(s)
          encoded_str = Base64.strict_encode64(s.encode("UTF-8"))
          "([System.Text.Encoding]::UTF8.GetString("\
               "[System.Convert]::FromBase64String('#{encoded_str}')"\
          "))"
        else
          "'#{s}'"
        end
      end
    end
  end
end
