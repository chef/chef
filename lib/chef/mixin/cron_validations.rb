#
# Copyright:: Copyright 2020, Chef Software Inc.
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
    # a collection of methods for validating cron times. Used in the various cron-like resources
    module CronValidations
      # validate a provided value is between two other provided values
      # we also allow * as a valid input
      # @param spec the value to validate
      # @param min the lowest value allowed
      # @param max the highest value allowed
      # @return [Boolean] valid or not?
      def self.validate_numeric(spec, min, max)
        return true if spec == "*"

        #  binding.pry
        if spec.respond_to? :to_int
          return false unless spec >= min && spec <= max

          return true
        end

        # Lists of invidual values, ranges, and step values all share the validity range for type
        spec.split(%r{\/|-|,}).each do |x|
          next if x == "*"
          return false unless x =~ /^\d+$/

          x = x.to_i
          return false unless x >= min && x <= max
        end
        true
      end

      # validate the provided month value to be jan - dec, 1 - 12, or *
      # @param spec the value to validate
      # @return [Boolean] valid or not?
      def self.validate_month(spec)
        return true if spec == "*"

        if spec.respond_to? :to_int
          validate_numeric(spec, 1, 12)
        elsif spec.respond_to? :to_str
          return true if spec == "*"
          # Named abbreviations are permitted but not as part of a range or with stepping
          return true if %w{jan feb mar apr may jun jul aug sep oct nov dec}.include? spec.downcase

          # 1-12 are legal for months
          validate_numeric(spec, 1, 12)
        else
          false
        end
      end

      # validate the provided day of the week is sun-sat, 0-7, or *
      # @param spec the value to validate
      # @return [Boolean] valid or not?
      def self.validate_dow(spec)
        return true if spec == "*"

        if spec.respond_to? :to_int
          validate_numeric(spec, 0, 7)
        elsif spec.respond_to? :to_str
          return true if spec == "*"
          # Named abbreviations are permitted but not as part of a range or with stepping
          return true if %w{sun mon tue wed thu fri sat}.include? spec.downcase

          # 0-7 are legal for days of week
          validate_numeric(spec, 0, 7)
        else
          false
        end
      end
    end
  end
end
