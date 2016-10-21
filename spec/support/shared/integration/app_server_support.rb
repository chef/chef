#
# Author:: John Keiser (<jkeiser@chef.io>)
# Author:: Ho-Sheng Hsiao (<hosh@chef.io>)
# Copyright:: Copyright 2012-2016 Chef Software, Inc.
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

require "rack"
require "stringio"

module AppServerSupport
  def start_app_server(app, port)
    server = nil
    thread = Thread.new do
      Rack::Handler::WEBrick.run(app,
        :Port => 9018,
        :AccessLog => [],
        :Logger => WEBrick::Log.new(StringIO.new, 7)
      ) do |found_server|
        server = found_server
      end
    end
    Timeout.timeout(30) do
      sleep(0.01) until server && server.status == :Running
    end
    [server, thread]
  end
end
