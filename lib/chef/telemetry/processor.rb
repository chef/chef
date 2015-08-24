#
# Author:: Ranjib Dey (<ranjib@linux.com>)
# Copyright:: Copyright (c) 2015 Chef Inc.
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
# Telemetry::Processor class provides API for chef run related metrics gathering
#

class Chef
  module Telemetry
    class Processor
      class Metric < Struct.new(:name, :hook, :value); end

      def self.create(publishers)
        processor = Chef::Telemetry::Processor.new
        publishers.each do |publisher|
          processor.add_publisher(publisher)
        end
        Chef.event_handler do
          on :run_completed do
            processor.gather
            processor.publish
          end
        end
        processor
      end

      def initialize
        @metrics = []
        @publishers = []
      end

      def add_metric(name, &block)
        @metrics << Metric.new(name, block)
      end

      def add_publisher(publisher)
        @publishers << publisher
      end

      def gather
        @metrics.each do |metric|
          metric.value = metric.hook.call
        end
      end

      def publish
        @publishers.each do |publisher|
          publisher.publish(@metrics)
        end
      end
    end
  end
end
