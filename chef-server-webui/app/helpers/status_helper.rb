#
# Author:: Joe Williams (joe@joetify.com)
# Copyright:: Copyright (c) 2009 Opscode, Inc.
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
require 'chef' / 'node'

module Merb
  module StatusHelper
    def time_difference_in_hms(unix_time)
      now = Time.now.to_i
      difference = now - unix_time.to_i
      hours = (difference / 3600).to_i
      difference = difference % 3600
      minutes = (difference / 60).to_i
      seconds = (difference % 60)
      return [hours, minutes, seconds]
    end
    
  end
end
