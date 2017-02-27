#--
# Author:: Daniel DeLeo (<dan@chef.io>)
# Copyright:: Copyright 2013-2016, Chef Software Inc.
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

require "chef/http/json_output"

class Chef
  class HTTP

    # A Middleware-ish thing that takes an HTTP response, parses it as JSON if
    # possible, and converts it into an appropriate model object if it contains
    # a `json_class` key.
    class JSONToModelOutput < JSONOutput
      def initialize(opts = {})
        opts[:inflate_json_class] = true if !opts.has_key?(:inflate_json_class)
        super
      end
    end
  end
end
