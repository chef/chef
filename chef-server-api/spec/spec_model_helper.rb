#
# Author:: Tim Hinderliter (<tim@opscode.com>)
# Copyright:: Copyright (c) 2011 Opscode, Inc.
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

# Set of methods to create model objects for spec tests.
# None of these methods save or otherwise commit the objects they
# create; they simply initialize the respective model object and
# set its name (and other important attributes, where appropriate).

def make_node(name)
  res = Chef::Node.new
  res.name(name)
  res
end

def make_role(name)
  res = Chef::Role.new
  res.name(name)
  res
end

def make_environment(name)
  res = Chef::Environment.new
  res.name(name)
  res
end

def make_cookbook(name, version)
  res = Chef::CookbookVersion.new(name)
  res.version = version
  res
end

def make_runlist(*items)
  res = Chef::RunList.new
  items.each do |item|
    res << item
  end
  res
end

def stub_checksum(checksum, present = true)
  Chef::Checksum.should_receive(:new).with(checksum).and_return do
    obj = stub(Chef::Checksum)
    obj.should_receive(:storage).and_return do
      storage = stub("storage")
      if present
        storage.should_receive(:file_location).and_return("/var/chef/checksums/#{checksum[0..1]}/#{checksum}")
      else
        storage.should_receive(:file_location).and_raise(Errno::ENOENT)
      end
      storage
    end
    obj
  end
end

# Take an Array of cookbook_versions,
# And return a hash like:
# {
#   "cookbook_name" => [CookbookVersion, CookbookVersion],
# }
def make_filtered_cookbook_hash(*array_cookbook_versions)
  array_cookbook_versions.inject({}) do |res, cookbook_version|
    res[cookbook_version.name] ||= Array.new
    res[cookbook_version.name] << cookbook_version
    res
  end
end
