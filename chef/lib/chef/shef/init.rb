# Author:: Daniel DeLeo (<dan@kallistec.com>)
# Copyright:: Copyright (c) 2009 Daniel DeLeo
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

require File.dirname(__FILE__) + "/../../chef"
require File.dirname(__FILE__) + "/../../chef/client"

unless defined?(Shef::JUST_TESTING_MOVE_ALONG) && Shef::JUST_TESTING_MOVE_ALONG
  Shef.configure_irb

  Shef.client

  Shef::GREETING = begin
      " #{Etc.getlogin}@#{Shef.client[:node].name}"
    rescue NameError
      ""
    end
  
  version
  puts

  puts "run ``help'' for help, ``exit'' or ^D to quit."
  puts
  puts "Ohai2u#{Shef::GREETING}!"
end