#
# Cookbook Name:: runit
# Attribute File:: sv_bin
#
# Copyright 2008-2009, Opscode, Inc.
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

default[:runit][:sv_bin] = "/opt/chef-server/embedded/bin/sv"
default[:runit][:chpst_bin] = "/opt/chef-server/embedded/bin/chpst"
default[:runit][:service_dir] = "/opt/chef-server/service"
default[:runit][:sv_dir] = "/opt/chef-server/sv"

