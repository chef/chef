# Copyright:: Copyright 2018, Chef Software, Inc
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

require "chef/cookbook_loader"
require "chef/cookbook/file_vendor"
require "chef/cookbook/file_system_file_vendor"
require "chef/resource/lwrp_base"
require "chef/run_context"
require "chef/node"
require "chef/resources"
require "chef/json_compat"

module ResourceInspector
  def self.extract_resource(resource, complete = false)
    data = {}
    data[:description] = resource.description
    # data[:deprecated] = resource.deprecated || false
    data[:actions] = resource.allowed_actions
    data[:examples] = resource.examples
    data[:introduced] = resource.introduced

    properties = unless complete
                   resource.properties.reject { |_, k| k.options[:declared_in] == Chef::Resource }
                 else
                   resource.properties
                 end

    data[:properties] = properties.each_with_object([]) do |(n, k), acc|
      opts = k.options
      acc << { name: n, description: opts[:description], introduced: opts[:introduced], is: opts[:is], deprecated: opts[:deprecated] || false }
    end
    data
  end

  def self.extract_cookbook(path, complete)
    path = File.expand_path(path)
    dir, name = File.split(path)
    Chef::Cookbook::FileVendor.fetch_from_disk(path)
    loader = Chef::CookbookLoader.new(dir)
    cookbooks = loader.load_cookbooks
    resources = cookbooks[name].files_for(:resources)

    resources.each_with_object({}) do |r, res|
      pth = r["full_path"]
      cur = Chef::Resource::LWRPBase.build_from_file(name, pth, Chef::RunContext.new(Chef::Node.new, nil, nil))
      res[cur.resource_name] = extract_resource(cur, complete)
    end
  end

  # If we're given no resources, dump all of Chef's built ins
  # otherwise, if we have a path then extract all the resources from the cookbook
  # or else do a list of built in resources
  #
  #  @param complete [TrueClass, FalseClass] Whether to show properties defined in the base Resource class
  def self.inspect(arguments = [], complete: false)
    output = if arguments.empty?
               ObjectSpace.each_object(Class).select { |k| k < Chef::Resource }.each_with_object({}) { |klass, acc| acc[klass.resource_name] = extract_resource(klass) }
             else
               arguments.each_with_object({}) do |arg, acc|
                 if File.directory?(arg)
                   extract_cookbook(arg, complete).each { |k, v| acc[k] = v }
                 else
                   r = Chef::ResourceResolver.resolve(arg.to_sym, canonical: nil)
                   acc[r.resource_name] = extract_resource(r, complete)
                 end
               end
             end

    puts Chef::JSONCompat.to_json_pretty(output)
  end

  def self.start
    inspect(ARGV, complete: true)
  end

end
