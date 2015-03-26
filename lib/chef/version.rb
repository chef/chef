
# Author:: Daniel DeLeo (<dan@opscode.com>)
# Copyright:: Copyright (c) 2010-2011 Opscode, Inc.
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

class Chef
  CHEF_ROOT = File.dirname(File.expand_path(File.dirname(__FILE__)))
  VERSION = '12.2.0.rc.2'
end

#
# NOTE: the Chef::Version class is defined in version_class.rb
#
# NOTE: DO NOT Use the Chef::Version class on Chef::VERSIONs.  The
#       Chef::Version class is for _cookbooks_ only, and cannot handle
#       pre-release chef-client versions like "10.14.0.rc.2".  Please
#       use Rubygem's Gem::Version class instead.
#
