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
# This is a clone of the Chef project that we can install on the Chef build and
# test machines. As such this project definition is just a thin wrapper around
# `config/project/chef.rb`.
#
current_file = __FILE__
chef_project_contents = IO.read(File.expand_path("../chef.rb", __FILE__))
self.instance_eval chef_project_contents

name "angrychef"
friendly_name "Angry Chef Client"

if windows?
  # NOTE: Ruby DevKit fundamentally CANNOT be installed into "Program Files"
  #       Native gems will use gcc which will barf on files with spaces,
  #       which is only fixable if everyone in the world fixes their Makefiles
  install_dir "#{default_root}/opscode/#{name}"
  package_name "angrychef"
else
  install_dir "#{default_root}/#{name}"
end

resources_path "#{resources_path}/../chef"

msi_upgrade_code = "D7FDDC1A-7668-404E-AD2F-61F875632A9C"
project_location_dir = "angrychef"
