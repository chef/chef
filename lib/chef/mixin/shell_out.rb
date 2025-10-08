#--
# Author:: Daniel DeLeo (<dan@chef.io>)
# Copyright:: Copyright (c) Chef Software Inc.
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

require "mixlib/shellout/helper" unless defined?(Mixlib::ShellOut::Helper)
require_relative "chef_utils_wiring" unless defined?(Chef::Mixin::ChefUtilsWiring)

class Chef
  module Mixin
    module ShellOut
      include Mixlib::ShellOut::Helper
      include Chef::Mixin::ChefUtilsWiring
    end
  end
end
