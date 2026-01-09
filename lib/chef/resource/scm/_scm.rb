#
# Author:: Daniel DeLeo (<dan@kallistec.com>)
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

default_action :sync
allowed_actions :checkout, :export, :sync, :diff, :log

property :destination, String,
  description: "The location path to which the source is to be cloned, checked out, or exported. Default value: the name of the resource block.",
  name_property: true

property :repository, String,
  description: "The URI of the code repository."

property :revision, String,
  description: "The revision to checkout.",
  default: "HEAD"

property :user, [String, Integer],
  description: "The system user that will own the checked-out code.",
  default_description: "`HOME` environment variable of the user running #{ChefUtils::Dist::Infra::CLIENT}"

property :group, [String, Integer],
  description: "The system group that will own the checked-out code."

property :timeout, Integer,
  description: "The amount of time (in seconds) to wait before timing out.",
  desired_state: false

property :environment, [Hash, nil],
  description: "A Hash of environment variables in the form of ({'ENV_VARIABLE' => 'VALUE'}).",
  default: nil

alias :env :environment
