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

Before do
  system("mkdir -p #{tmpdir}")
  cdb = Chef::CouchDB.new(Chef::Config[:couchdb_url])
  cdb.create_db
  Chef::Node.create_design_document
  Chef::Role.create_design_document
  Chef::Role.sync_from_disk_to_couchdb
  Chef::OpenIDRegistration.create_design_document
end

After do
  r = Chef::REST.new(Chef::Config[:couchdb_url])
  r.delete_rest("#{Chef::Config[:couchdb_database]}/")
  system("rm -rf #{tmpdir}")
end
