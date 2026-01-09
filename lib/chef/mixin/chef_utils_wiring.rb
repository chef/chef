#--
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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

require_relative "../log"
require_relative "../config"
require_relative "../chef_class"

class Chef
  module Mixin
    # Common Dependency Injection wiring for ChefUtils-related modules
    module ChefUtilsWiring
      private

      def __config
        Chef::Config
      end

      def __log
        Chef::Log
      end

      def __transport_connection
        Chef.run_context&.transport_connection
      end
    end
  end
end
