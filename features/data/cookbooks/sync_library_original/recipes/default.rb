#
# Cookbook Name:: attribute_settings 
# Recipe:: default 
#
# Copyright 2009, Opscode
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

class Chef::Recipe
  include SyncLibrary
end

# Run the library code
go

$sync_library_global ||= 2
$sync_library_global  -= 1
exit(2) if $sync_library_global == 0

