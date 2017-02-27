#
# Author:: Thom May (<thom@chef.io>)
# Copyright:: Copyright 2015-2016, Chef Software, Inc.
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

require "chef/http"
require "chef/http/authenticator"
require "chef/http/decompressor"
require "chef/http/cookie_manager"
require "chef/http/validate_content_length"

class Chef
  class HTTP

    class SimpleJSON < HTTP

      use JSONInput
      use JSONOutput
      use CookieManager
      use Decompressor
      use RemoteRequestID

      # ValidateContentLength should come after Decompressor
      # because the order of middlewares is reversed when handling
      # responses.
      use ValidateContentLength

    end
  end
end
