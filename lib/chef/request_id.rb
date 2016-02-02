# Author:: Prajakta Purohit (<prajakta@chef.io>)
# Copyright:: Copyright 2009-2016, Chef Software Inc.
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

require "securerandom"
require "singleton"

class Chef
  class RequestID
    include Singleton

    def reset_request_id
      @request_id = nil
    end

    def request_id
      @request_id ||= generate_request_id
    end

    def generate_request_id
      SecureRandom.uuid
    end
  end
end
