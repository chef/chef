#
# Copyright 2012-2016, Chef Software, Inc.
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

#
# This is the chef client build with FIPS mode enabled.
#
current_file = __FILE__
chef_project_contents = IO.read(File.expand_path("../chef.rb", current_file))
self.instance_eval chef_project_contents

name "chef-fips"
friendly_name "Chef Client with FIPS OpenSSL"

if windows?
  # NOTE: Ruby DevKit fundamentally CANNOT be installed into "Program Files"
  #       Native gems will use gcc which will barf on files with spaces,
  #       which is only fixable if everyone in the world fixes their Makefiles
  install_dir "#{default_root}/opscode/#{name}"
  package_name "chef-fips"
else
  install_dir "#{default_root}/#{name}"
end

override :ruby, version: "2.1.7"

# Global FIPS override flag.
override :fips, enabled: true

override :chef, version: "local_source"
override :ohai, version: "master"

msi_upgrade_code = "819F5DB3-B818-4358-BB2B-54B8171D0A26"
project_location_dir = "chef-fips"

# Use chef's scripts for everything.
resources_path "#{resources_path}/../chef"
