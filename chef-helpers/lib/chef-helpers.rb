#
# Copyright:: Copyright 2015-2018, Chef Software Inc.
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

require 'chef-helpers/architecture'
require 'chef-helpers/os'
require 'chef-helpers/platform_family'
require 'chef-helpers/platform'
require 'chef-helpers/introspection'
require 'chef-helpers/service'
require 'chef-helpers/which'
require 'chef-helpers/path_sanity'

module ChefHelpers
  # FIXME: we need a policy around when we can add methods here and should probably be careful
  # since this is likely to become breaking changes by injecting methods everywhere.
  extend ChefHelpers::Architecture
  extend ChefHelpers::OS
  extend ChefHelpers::PlatformFamily
  extend ChefHelpers::Platform
  extend ChefHelpers::Introspection
  extend ChefHelpers::Which
  include ChefHelpers::Architecture
  include ChefHelpers::OS
  include ChefHelpers::PlatformFamily
  include ChefHelpers::Platform
  include ChefHelpers::Introspection
  include ChefHelpers::Which
  # ChefHelpers::Service is deliberately excluded
end
