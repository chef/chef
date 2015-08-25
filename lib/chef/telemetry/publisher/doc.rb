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
# Telemtry::Publisher::Doc class prints telemetry data using Chef::Log API
#
require 'pp'

class Chef
  module Telemetry
    module Publisher
      class Doc
        def publish(metrics)
          desc = "Telemetry Data:"
          metrics.each do |metric|
            desc << "\nMetric[#{metric.name}]\t Value: "
            desc << PP.pp(metric.value, "")
          end
          Chef::Log.info(desc)
        end
      end
    end
  end
end
