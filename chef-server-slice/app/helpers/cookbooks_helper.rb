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

module Merb
  module ChefServerSlice
    module CookbooksHelper
      def syntax_highlight(code)
        if File.exists?(code)
          tokens = CodeRay.scan_file(code, :ruby)
        else
          tokens = CodeRay.scan(code, :ruby)
        end
        return CodeRay.encode_tokens(tokens, :span)
      end
    end
  end
end
