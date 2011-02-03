#
# Author:: Daniel DeLeo (<dan@opscode.com>)
# Author:: Seth Falcon (<seth@opscode.com>)
# Author:: Chris Walters (<cw@opscode.com>)
# Copyright:: Copyright (c) 2010-2011 Opscode, Inc.
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

module Chef
  module Expander

    # VNODES is the number of queues in rabbit that are available for subscribing.
    # The name comes from riak, where the data ring (160bits) is chunked into
    # many vnodes; vnodes outnumber physical nodes, so one node hosts several
    # vnodes. That is the same design we use here.
    #
    # See the notes on topic queue benchmarking before adjusting this value.
    VNODES = 1024

    SHARED_CONTROL_QUEUE_NAME = "chef-search-control--shared"
    BROADCAST_CONTROL_EXCHANGE_NAME = 'chef-search-control--broadcast'

  end
end
