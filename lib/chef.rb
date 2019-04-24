#
# Author:: Adam Jacob (<adam@chef.io>)
# Copyright:: Copyright 2008-2017, Chef Software Inc.
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

require "chef/version"

# Ensure that this loads ahead of anything that
# might cause rubygems to hit Gem.load_yaml, including
# evaluating gemspecs. When load_yaml is invoked,
# it stubs out  the YAML::Syck namespace. This causes
# r18n to break, which expects either YAML::Syck to be there
# and fully defined (particularly, the Syck::PrivateType class),
# or for it to not be there at all.
#
# When it's not - because it's a stub - r18n explodes on loading.
# Ensuring chef_core/text and r18n are loaded first prevents this.
require "chef_core/text"

require "chef/nil_argument"
require "chef/mash"
require "chef/exceptions"
require "chef/log"
require "chef/config"
require "chef/providers"
require "chef/resources"

require "chef/daemon"

require "chef/run_status"
require "chef/handler"
require "chef/handler/json_file"
require "chef/event_dispatch/dsl"
require "chef/chef_class"
