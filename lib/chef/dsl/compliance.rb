#
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
#

class Chef
  module DSL
    module Compliance

      # @see Chef::Compliance::ProfileCollection#include_profile
      def include_profile(*args)
        run_context.profile_collection.include_profile(*args)
      end

      # @see Chef::Compliance::WaiverCollection#include_waiver
      def include_waiver(*args)
        run_context.waiver_collection.include_waiver(*args)
      end

      # @see Chef::Compliance::inputCollection#include_input
      def include_input(*args)
        run_context.input_collection.include_input(*args)
      end
    end
  end
end
