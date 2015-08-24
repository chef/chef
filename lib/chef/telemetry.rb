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
    extend self

    def enabled?
      Chef::Config[:enable_telemetry]
    end

    def publishers
      if Chef::Config[:telemetry][:publish_using].empty?
        [ Chef::Telemetry::Publisher::Doc.new ]
      else
        Chef::Config[:telemetry][:publish_using]
      end
    end

    def enabled_builtin_metrics
      %i(resource recipe gc process client_run cookbook).select do |metric|
        Chef::Config[:telemetry][metric]
      end
    end

    def load
      unless Chef.telemetry_processor
        processor = Chef::Telemetry::Processor.create(publishers)
        Chef.set_telemetry_processor(processor)
      end
      gather_builtin_metrics
    end

    def gather_builtin_metrics
      metrics = enabled_builtin_metrics
      Chef.telemetry do |meter|
        meter.add_metric 'builtin' do
          resource_metric = {}
          cookbook_metric = Hash.new(0)
          recipe_metric = Hash.new(0)
          Chef.run_context.resource_collection.all_resources.each do |r|
            resource_metric["#{r.resource_name}[#{r.name}]"] = r.elapsed_time if metrics.include?(:resource)
            cookbook_metric[r.cookbook_name] += r.elapsed_time if metrics.include?(:cookbook)
            recipe_metric["#{r.cookbook_name}::#{r.recipe_name}"] += r.elapsed_time if metrics.include?(:recipe)
          end
          value = {}
          value['resource'] = resource_metric if metrics.include?(:resource)
          value['cookbook'] = cookbook_metric if metrics.include?(:cookbook)
          value['recipe'] = recipe_metric if metrics.include?(:recipe)
          value
        end
      end
    end
  end
end
