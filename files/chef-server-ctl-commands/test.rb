#
# Copyright:: Copyright (c) 2012 Opscode, Inc.
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

add_command "test", "Run the API test suite against localhost.", 2 do
  ENV["PATH"] = "#{File.join(base_path, "bin")}:#{ENV['PATH']}"
  pedant_args = ARGV[3..-1]
  pedant_args = ["--smoke"] unless pedant_args.any?
  Dir.chdir(File.join(base_path, "embedded", "service", "chef-pedant"))
  pedant_config = File.join(etc_path, "pedant_config.rb")
  bundle = File.join(base_path, "embedded", "bin", "bundle")
  exec("#{bundle} exec ./chef-pedant -c #{pedant_config} #{pedant_args.join(' ')}")
end
