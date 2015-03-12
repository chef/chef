#
# Author:: Adam Edwards (<adamed@getchef.com>)
#
# Copyright:: Copyright (c) 2014 Chef Software, Inc.
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

require 'chef/json_compat'

class Chef
class Util
class Powershell
  class CmdletResult
    attr_reader :output_format

    def initialize(status, streams, output_format)
      @status = status
      @output_format = output_format
      @streams = streams
    end

    def stdout
      @status.stdout
    end
    
    def stderr
      @status.stderr
    end

    def stream(name)
      @streams[name].read
    end

    def return_value
      if output_format == :object
        Chef::JSONCompat.parse(stream(:json))
      elsif output_format == :json
        stream(:json)
      else
        @status.stdout
      end
    end

    def succeeded?
      @succeeded = @status.status.exitstatus == 0
    end
  end
end
end
end
