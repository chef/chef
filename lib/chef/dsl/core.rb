#--
# Author:: Adam Jacob (<adam@chef.io>)
# Author:: Christopher Walters (<cw@chef.io>)
# Copyright:: Copyright 2008-2016, 2009-2015 Chef Software, Inc.
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

require "chef/mixin/shell_out"
require "chef/mixin/powershell_out"
require "chef/dsl/declare_resource"

class Chef
  module DSL
    # This is the "Core DSL" with various bits of Sugar that are mixed into core providers as well
    # as user LWRPs.  This module deliberately does not mixin the Resources or Defintions DSL bits
    # so that cookbooks are not injeting random things into the samespace of core providers.
    #
    # - If you are writing cookbooks:  you have come to the wrong place, please inject things into
    #   Chef::DSL::Recipe instead.
    #
    # - If you are writing core chef:  you have come to the right place, please drop your DSL modules
    #   into here.
    #
    module Core
      include Chef::Mixin::ShellOut
      include Chef::Mixin::PowershellOut
      include Chef::DSL::DeclareResource
    end
  end
end
