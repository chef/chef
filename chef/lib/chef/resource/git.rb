#
# Author:: Daniel DeLeo (<dan@kallistec.com>)
# Author:: John Keiser (<jkeiser@opscode.com>)
# Copyright:: Copyright (c) 2008 Opscode, Inc.
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
    class Git < Chef::Resource::Scm

      def initialize(name, run_context=nil)
        super
        @resource_name = :git
        @provider = Chef::Provider::Git
        @additional_remotes = Hash[]
      end

      def additional_remotes(arg=nil)
        set_or_return(
          :additional_remotes,
          arg,
          :kind_of => Hash
        )
      end
      
      def development_mode(arg=nil)
        set_or_return(
          :development_mode,
          arg,
          :kind_of =>  [TrueClass, FalseClass]
        )
      end
      
      def update_method(arg=nil)
        real_arg = arg.kind_of?(String) ? arg.to_sym : arg
        set_or_return(
          :update_method,
          real_arg,
          :equal_to => [ :reset_merge, :reset_hard, :reset_clean, :rebase ]
        )
      end

      def revision(arg=nil)
        result = super(arg)
        if arg.nil?
          result || branch || "HEAD"
        end
      end

      def branch(arg=nil)
        set_or_return(
          :branch,
          arg,
          :kind_of => String
        )
      end

      def git_timeout(arg=nil)
        set_or_return(
          :git_timeout,
          arg,
          :kind_of => Numeric
        )
      end
      
      alias :reference :revision

      alias :repo :repository
    end
  end
end
