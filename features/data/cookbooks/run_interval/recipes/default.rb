#
# Cookbook Name:: run_interval
# Recipe:: default
#
# Copyright 2009, 2010, Opscode
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

# Force chef-client to exit once this cookbook has been applied twice.
# The test depends on chef having run twice, so this number is tied to
# run_interval.feature!

$run_interval_global ||= 2

$run_interval_global -= 1
exit(2) if $run_interval_global == 0
