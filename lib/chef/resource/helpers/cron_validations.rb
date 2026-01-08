#
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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
  module ResourceHelpers
    # a collection of methods for validating cron times. Used in the various cron-like resources
    module CronValidations
      # validate a provided value is between two other provided values
      # we also allow * as a valid input
      # @param spec the value to validate
      # @param min the lowest value allowed
      # @param max the highest value allowed
      # @return [Boolean] valid or not?
      def validate_numeric(spec, min, max)
        return true if spec == "*"

        if spec.respond_to? :to_int
          return spec.between?(min, max)
        end

        # Lists of individual values, ranges, and step values all share the validity range for type
        spec.split(%r{\/|-|,}).each do |x|
          next if x == "*"
          return false unless /^\d+$/.match?(x)

          x = x.to_i
          return false unless x.between?(min, max)
        end
        true
      end

      # validate the provided month value to be jan - dec, 1 - 12, or *
      # @param spec the value to validate
      # @return [Boolean] valid or not?
      def validate_month(spec)
        return true if spec == "*"

        if spec.respond_to? :to_int
          validate_numeric(spec, 1, 12)
        elsif spec.respond_to? :to_str
          # Named abbreviations are permitted but not as part of a range or with stepping
          return true if %w{jan feb mar apr may jun jul aug sep oct nov dec}.include? spec.downcase

          # 1-12 are legal for months
          validate_numeric(spec, 1, 12)
        else
          false
        end
      end

      # validate the provided day of the week is sun-sat, sunday-saturday, 0-7, or *
      # Added crontab param to check cron resource
      # @param spec the value to validate
      # @return [Boolean] valid or not?
      def validate_dow(spec)
        spec = spec.to_s
        spec == "*" ||
          validate_numeric(spec, 0, 7) ||
          %w{sun mon tue wed thu fri sat}.include?(spec.downcase) ||
          %w{sunday monday tuesday wednesday thursday friday saturday}.include?(spec.downcase)
      end

      # validate the day of the month is 1-31
      # @param spec the value to validate
      # @return [Boolean] valid or not?
      def validate_day(spec)
        validate_numeric(spec, 1, 31)
      end

      # validate the hour is 0-23
      # @param spec the value to validate
      # @return [Boolean] valid or not?
      def validate_hour(spec)
        validate_numeric(spec, 0, 23)
      end

      # validate the minute is 0-59
      # @param spec the value to validate
      # @return [Boolean] valid or not?
      def validate_minute(spec)
        validate_numeric(spec, 0, 59)
      end

      extend self
    end
  end
end
