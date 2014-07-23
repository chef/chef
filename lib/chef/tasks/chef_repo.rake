#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2008, 2009 Opscode, Inc.
# Copyright:: Copyright (c) 2014, Chef Software, Inc.
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
TOPDIR = '.'
require 'rake'

desc "By default, print deprecation notice"
task :default do
  puts deprecation_notice
end

desc "Install the latest copy of the repository on this Chef Server"
task :install do
  puts deprecation_notice
  puts 'The `install` rake task, which included the `update`, `roles`, and'
  puts '`upload_cookbooks` rake tasks is replaced by the `knife upload`'
  puts 'sub-command. The notion of "installing" the chef-repo to the Chef'
  puts 'Server. Previously the `install` task would manage server and'
  puts 'client configuration. This will not work at all on Chef Server 11+'
  puts 'and client configuration should be managed with the `chef-client`'
  puts 'cookbook.'
end

desc "Update your repository from source control"
task :update do
  puts deprecation_notice
  puts 'The `update` rake task previously updated the chef-repo from'
  puts 'the detected version control system, either svn or git. However,'
  puts 'it has not been recommended for users for years. Most users in'
  puts 'the community use `git`, so the Subversion functionality is not'
  puts 'required, and `git pull` is sufficient for many workflows. The'
  puts 'world of git workflows is rather different now than it was when'
  puts 'this rake task was created.'
end

desc "Create a new cookbook (with COOKBOOK=name, optional CB_PREFIX=site-)"
task :new_cookbook do
  cb = ENV['COOKBOOK'] || 'my_cookbook_name'
  puts deprecation_notice
  puts 'The `new_cookbook` rake task is replaced by the ChefDK cookbook'
  puts 'generator. To generate a new cookbook run:'
  puts
  puts "chef generate cookbook #{ENV['COOKBOOK']}"
  puts
  puts 'Or, if you are not using ChefDK, use `knife cookbook create`:'
  puts
  puts "knife cookbook create #{ENV['COOKBOOK']}"
end

desc "Create a new self-signed SSL certificate for FQDN=foo.example.com"
task :ssl_cert do
  puts deprecation_notice
  puts 'The `ssl_cert` rake task is superseded by using the CHEF-maintained'
  puts '`openssl` cookbook\'s `openssl_x509` resource which can generate'
  puts 'self-signed certificate chains as convergent resources.'
  puts
  puts 'https://supermarket.getchef.com/cookbooks/openssl'
end

desc "Build cookbook metadata.json from metadata.rb"
task :metadata do
  puts deprecation_notice
  puts 'The `metadata` rake task is not recommended. Cookbook'
  puts '`metadata.json` is automatically generated from `metadata.rb`'
  puts 'by `knife` when uploading cookbooks to the Chef Server.'
end

desc "Update roles"
task :roles do
  puts deprecation_notice
  puts 'The `roles` rake task is not recommended. If you are using Ruby'
  puts 'role files (roles/*.rb), you can upload them all with:'
  puts
  puts 'knife role from file roles/*'
  puts
  puts 'If you are using JSON role files (roles/*.json), you can upload'
  puts 'them all with:'
  puts
  puts 'knife upload roles/*.json'
end

desc "Update a specific role"
task :role do
  puts deprecation_notice
  puts 'The `role` rake task is not recommended. If you are using Ruby'
  puts 'role files, you can upload a single role with:'
  puts
  puts 'knife role from file rolename.rb'
  puts
  puts 'If you are using JSON role files, you can upload a single role with'
  puts
  puts 'knife upload roles/rolename.json'
end

desc "Upload all cookbooks"
task :upload_cookbooks do
  puts deprecation_notice
  puts deprecated_cookbook_upload
end

desc "Upload a single cookbook"
task :upload_cookbook do
  puts deprecation_notice
  puts deprecated_cookbook_upload
end

desc "Test all cookbooks"
task :test_cookbooks do
  puts deprecation_notice
  puts 'The `test_cookbooks` rake task is no longer recommended. Previously'
  puts 'it only performed a syntax check, and did no other kind of testing,'
  puts 'and the Chef Community has a rich ecosystem of testing tools for'
  puts 'various purposes:'
  puts
  puts '- knife cookbook test will perform a syntax check, as this task did'
  puts '  before.'
  puts '- rubocop and foodcritic will perform lint checking for Ruby and'
  puts '  Chef cookbook style according to community standards.'
  puts '- ChefSpec will perform unit testing'
  puts '- Test Kitchen will perform convergence and post-convergence'
  puts '  testing on virtual machines.'
end

desc "Test a single cookbook"
task :test_cookbook => [:test_cookbooks]

namespace :databag do
  desc "Upload a single databag"
  task :upload do
    puts deprecation_notice
    puts 'The `data_bags:upload` task is not recommended. You should use'
    puts 'the `knife upload` sub-command for uploading data bag items.'
    puts
    puts 'knife upload data_bags/bagname/itemname.json'
  end

  desc "Upload all databags"
  task :upload_all do
    puts deprecation_notice
    puts 'The `data_bags:upload_all` task is not recommended. You should'
    puts 'use the `knife upload` sub-command for uploading data bag items.'
    puts
    puts 'knife upload data_bags/*'
  end

  desc "Create a databag"
  task :create do
    puts deprecation_notice
    puts deprecated_data_bag_creation
  end

  desc "Create a databag item stub"
  task :create_item do
    puts deprecation_notice
    puts deprecated_data_bag_creation
  end
end

def deprecation_notice
  %Q[*************************************************
NOTICE: Chef Repository Rake Tasks Are Deprecated
*************************************************
]

end

def deprecated_cookbook_upload
  %Q[
The `upload_cookbook` and `upload_cookbooks` rake tasks are not
recommended. These tasks are replaced by other, better workflow
tools, such as `knife cookbook upload`, `knife upload`, or `berks`
]
end

def deprecated_data_bag_creation
  %Q[
The `data_bags:create` and `data_bags:create_item` tasks are not
recommended. You should create data bag items as JSON files in the data_bags
directory, with a sub-directory for each bag, and use `knife upload` to
upload them. For example, if you have a data bags named `users`, with
`finn`, and `jake` items, you would have:

./data_bags/users/finn.json
./data-bags/users/jake.json
]
end
