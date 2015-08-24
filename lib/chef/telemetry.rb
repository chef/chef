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
# Telemetry class provides API for chef run related metrics gathering
#
require 'chef/telemetry/processor'
require 'chef/telemetry/publisher/doc'

class Chef
  module Telemetry
    def self.enabled?
      Chef::Config[:enable_telemetry]
    end

    def self.publishers
      if Chef::Config[:telemetry][:publish_using].empty?
        [ Chef::Telemetry::Publisher::Doc.new ]
      else
        Chef::Config[:telemetry][:publish_using]
      end
    end

    def self.create_processor
      Chef::Log.debug('Telemetry. Loading processor')
      processor = Chef::Telemetry::Processor.new
      publishers.each do |publisher|
        processor.add_publisher(publisher)
      end
      processor
    end

    def self.load
      processor = create_processor unless Chef.telemetry_processor
      if Chef::Config[:telemetry][:resource]
        gather_resource_metrics(processor)
      end
      Chef.event_handler do
        on :run_completed do
          processor.gather
          processor.publish
        end
      end
      Chef.set_telemetry_processor(processor)
    end

    def self.gather_resource_metrics(processor)
      processor.add_metric 'resource' do
        metric = {}
        Chef.run_context.resource_collection.all_resources.each do |r|
          metric["#{r.resource_name}[#{r.name}]"] = r.elapsed_time
        end
        metric
      end
    end
  end
end
