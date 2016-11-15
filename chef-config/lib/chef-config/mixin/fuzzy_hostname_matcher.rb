#
# Copyright:: Copyright 2016, Chef Software Inc.
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

require "fuzzyurl"

module ChefConfig
  module Mixin
    module FuzzyHostnameMatcher

      def fuzzy_hostname_match_any?(hostname, matches)
        if (hostname != nil) && (matches != nil)
          return matches.to_s.split(/\s*,\s*/).compact.any? do |m|
            fuzzy_hostname_match?(hostname, m)
          end
        end

        false
      end

      def fuzzy_hostname_match?(hostname, match)
        # Do greedy matching by adding wildcard if it is not specified
        match = "*" + match if !match.start_with?("*")
        Fuzzyurl.matches?(Fuzzyurl.mask(hostname: match), hostname)
      end

    end
  end
end
