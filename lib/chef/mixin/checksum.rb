#
# Author:: Adam Jacob (<adam@chef.io>)
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

require_relative "../digester"

class Chef
  module Mixin
    module Checksum

      def checksum(file)
        Chef::Digester.checksum_for_file(file)
      end

      def short_cksum(checksum)
        return "none" if checksum.nil?

        checksum.slice(0, 6)
      end

      def checksum_match?(ref_checksum, diff_checksum)
        return false if ref_checksum.nil? || diff_checksum.nil?

        ref_checksum.casecmp?(diff_checksum)
      end
    end
  end
end
