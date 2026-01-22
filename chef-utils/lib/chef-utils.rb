# frozen_string_literal: true
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

require_relative "chef-utils/dsl/architecture"
require_relative "chef-utils/dsl/backend"
require_relative "chef-utils/dsl/cloud"
require_relative "chef-utils/dsl/introspection"
require_relative "chef-utils/dsl/os"
require_relative "chef-utils/dsl/default_paths"
require_relative "chef-utils/dsl/path_sanity"
require_relative "chef-utils/dsl/platform"
require_relative "chef-utils/dsl/platform_family"
require_relative "chef-utils/dsl/platform_version"
require_relative "chef-utils/dsl/service"
require_relative "chef-utils/dsl/train_helpers"
require_relative "chef-utils/dsl/virtualization"
require_relative "chef-utils/dsl/which"
require_relative "chef-utils/dsl/windows"
require_relative "chef-utils/mash"

# This is the Chef Infra Client DSL, not everything needs to go in here
module ChefUtils
  include ChefUtils::DSL::Architecture
  include ChefUtils::DSL::Cloud
  include ChefUtils::DSL::DefaultPaths
  include ChefUtils::DSL::Introspection
  include ChefUtils::DSL::OS
  include ChefUtils::DSL::Platform
  include ChefUtils::DSL::PlatformFamily
  include ChefUtils::DSL::PlatformVersion
  include ChefUtils::DSL::TrainHelpers
  include ChefUtils::DSL::Virtualization
  include ChefUtils::DSL::Which
  include ChefUtils::DSL::Windows
  # ChefUtils::DSL::Service is deliberately excluded

  CANARY = 1 # used as a guard for requires
  extend self
end
