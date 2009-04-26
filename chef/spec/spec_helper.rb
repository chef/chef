#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2008 Opscode, Inc.
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

$:.unshift(File.join(File.dirname(__FILE__), "..", "lib"))

require 'chef'

chef_lib_path = File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib'))
Dir[
  File.expand_path(
    File.join(
      chef_lib_path, 'chef', '**', '*.rb'
    )
  )
].sort.each do |lib|
  lib_short_path = lib.match("^#{chef_lib_path}#{File::SEPARATOR}(.+)$")[1]
  require lib_short_path
end
Dir[File.join(File.dirname(__FILE__), 'lib', '**', '*.rb')].sort.each { |lib| require lib }

Chef::Config.log_level(:fatal)
