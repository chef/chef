#
# Author:: Daniel DeLeo (<dan@kallistec.com>)
# Author:: Tyler Cloke (<tyler@chef.io>)
# Copyright:: Copyright 2008-2016, Chef Software Inc.
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

require "chef/resource/scm"

class Chef
  class Resource
    class Subversion < Chef::Resource::Scm
      allowed_actions :force_export

      def initialize(name, run_context = nil)
        super
        @svn_arguments = "--no-auth-cache"
        @svn_info_args = "--no-auth-cache"
        @svn_binary = nil
      end

      # Override exception to strip password if any, so it won't appear in logs and different Chef notifications
      def custom_exception_message(e)
        "#{self} (#{defined_at}) had an error: #{e.class.name}: #{svn_password ? e.message.gsub(svn_password, "[hidden_password]") : e.message}"
      end

      def svn_binary(arg = nil)
        set_or_return(:svn_binary, arg, :kind_of => [String])
      end
    end
  end
end
