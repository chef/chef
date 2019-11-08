#
# Copyright:: Copyright 2015-2019, Chef Software Inc.
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

require_relative "chef-utils/dsl/architecture"
require_relative "chef-utils/dsl/introspection"
require_relative "chef-utils/dsl/os"
require_relative "chef-utils/dsl/path_sanity"
require_relative "chef-utils/dsl/platform"
require_relative "chef-utils/dsl/platform_family"
require_relative "chef-utils/dsl/service"
require_relative "chef-utils/dsl/train_helpers"
require_relative "chef-utils/dsl/which"
require_relative "chef-utils/mash"

# This is the Chef Infra Client DSL, not everytihng needs to go in here
module ChefUtils
  include ChefUtils::DSL::Architecture
  include ChefUtils::DSL::OS
  include ChefUtils::DSL::PlatformFamily
  include ChefUtils::DSL::Platform
  include ChefUtils::DSL::Introspection
  # FIXME: include ChefUtils::DSL::Which in Chef 16.0
  # FIXME: include ChefUtils::DSL::PathSanity in Chef 16.0
  # FIXME: include ChefUtils::DSL::TrainHelpers in Chef 16.0
  # ChefUtils::DSL::Service is deliberately excluded

  CANARY = 1 # used as a guard for requires
  extend self
end
