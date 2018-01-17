#
# Author:: Dheeraj Dubey (<dheeraj.dubey@msystechnologies.com>)
# Copyright:: Copyright 2008-2016, Chef Software Inc.
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
require "iso8601"

class Chef
  module Mixin
    module SecToDur
       # Converts the number of seconds to an ISO8601 duration format and returns it.
       # Ref : https://github.com/arnau/ISO8601/blob/master/lib/iso8601/duration.rb#L18-L23
       # e.g.
       # ISO8601::Duration.new(65707200)
       # returns 'P65707200S'
      def sec_to_dur(seconds)
        ISO8601::Duration.new(seconds.to_i).to_s
      end
     end
  end
end
