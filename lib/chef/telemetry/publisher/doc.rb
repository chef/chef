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

class Chef
  module Telemetry
    module Publisher
      class Doc
        def publish(metrics)
          metrics.each do |metric|
            Chef::Log.warn("Telemetry[#{metric.name}]  Value: #{metric.value.inspect}")
          end
        end
      end
    end
  end
end
