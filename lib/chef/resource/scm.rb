#
# Author:: Daniel DeLeo (<dan@kallistec.com>)
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

require "chef/resource"

class Chef
  class Resource
    class Scm < Chef::Resource
      identity_attr :destination

      state_attrs :revision

      default_action :sync
      allowed_actions :checkout, :export, :sync, :diff, :log

      def initialize(name, run_context = nil)
        super
        @destination = name
        @enable_submodules = false
        @enable_checkout = true
        @revision = "HEAD"
        @remote = "origin"
        @ssh_wrapper = nil
        @depth = nil
        @checkout_branch = "deploy"
        @environment = nil
      end

      def destination(arg = nil)
        set_or_return(
          :destination,
          arg,
          :kind_of => String
        )
      end

      def repository(arg = nil)
        set_or_return(
          :repository,
          arg,
          :kind_of => String
        )
      end

      def revision(arg = nil)
        set_or_return(
          :revision,
          arg,
          :kind_of => String
        )
      end

      def user(arg = nil)
        set_or_return(
          :user,
          arg,
          :kind_of => [String, Integer]
        )
      end

      def group(arg = nil)
        set_or_return(
          :group,
          arg,
          :kind_of => [String, Integer]
        )
      end

      def svn_username(arg = nil)
        set_or_return(
          :svn_username,
          arg,
          :kind_of => String
        )
      end

      property :svn_password, String, sensitive: true, desired_state: false

      def svn_arguments(arg = nil)
        @svn_arguments, arg = nil, nil if arg == false
        set_or_return(
          :svn_arguments,
          arg,
          :kind_of => String
        )
      end

      def svn_info_args(arg = nil)
        @svn_info_args, arg = nil, nil if arg == false
        set_or_return(
          :svn_info_args,
          arg,
          :kind_of => String)
      end

      # Capistrano and git-deploy use ``shallow clone''
      def depth(arg = nil)
        set_or_return(
          :depth,
          arg,
          :kind_of => Integer
        )
      end

      def enable_submodules(arg = nil)
        set_or_return(
          :enable_submodules,
          arg,
          :kind_of => [TrueClass, FalseClass]
        )
      end

      def enable_checkout(arg = nil)
        set_or_return(
          :enable_checkout,
          arg,
          :kind_of => [TrueClass, FalseClass]
        )
      end

      def remote(arg = nil)
        set_or_return(
          :remote,
          arg,
          :kind_of => String
        )
      end

      def ssh_wrapper(arg = nil)
        set_or_return(
          :ssh_wrapper,
          arg,
          :kind_of => String
        )
      end

      def timeout(arg = nil)
        set_or_return(
          :timeout,
          arg,
          :kind_of => Integer
        )
      end

      def checkout_branch(arg = nil)
        set_or_return(
          :checkout_branch,
          arg,
          :kind_of => String
        )
      end

      def environment(arg = nil)
        set_or_return(
          :environment,
          arg,
          :kind_of => [ Hash ]
        )
      end

      alias :env :environment
    end
  end
end
