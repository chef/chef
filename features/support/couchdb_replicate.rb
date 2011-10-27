#
# Author:: Tim Hinderliter (<tim@opscode.com>)
# Copyright:: Copyright (c) 2010 Opscode, Inc.
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

# Under high load with lots of replications going on, CouchDB builtin
# replication (through the builtin '$DB/_replicate' endpoint) can crash, causing
# further replications to fail by timing out. This then requires a restart of
# CouchDB.
#
# This code is a manual implementation of CouchDB replication, using standard
# bulk GET's and PUT's. We use RestClient and JSON parsing.

require 'rubygems'
require 'rest-client'
require 'chef/log'
require 'chef/json_compat'

# Bulk GET all documents in the given db, using the given page size.
# Calls the required block for each page size, passing in an array of
# rows.
def bulk_get_paged(db, page_size)
  last_key = nil

  paged_rows = nil
  until (paged_rows && paged_rows.length == 0) do
    url = "#{db}/_all_docs?limit=100&include_docs=true"
    if last_key
      url += "&startkey=#{CGI.escape(last_key.to_json)}&skip=1"
    end
    #puts "bulk_get_paged: url = #{url}"

    paged_results_str = RestClient.get(url)

    # Pass :create_additions=>false so JSON parser does *not* expand
    # custom classes (such as Chef::Node, etc), and instead sticks only
    # to Array, Hash, String, etc.
    paged_results = Chef::JSONCompat.from_json(paged_results_str, :create_additions => false)
    paged_rows = paged_results['rows']

    if paged_rows.length > 0
      yield paged_rows
      last_key = paged_rows.last['key']
    end
  end
end

# Replicate a (set of) source databases to a (set of) target databases. Uses
# manual bulk GET/POST as Couch's internal _replicate endpoint crashes and
# starts to time out after some number of runs.
def replicate_dbs(replication_specs, delete_source_dbs = false)
  replication_specs = [replication_specs].flatten

  Chef::Log.debug "replicate_dbs: replication_specs = #{replication_specs.inspect}, delete_source_dbs = #{delete_source_dbs}"

  replication_specs.each do |spec|
    source_db = spec[:source_db]
    target_db = spec[:target_db]

    # Delete and re-create the target db
    begin
      Chef::Log.debug("Deleting #{target_db}, if exists")
      RestClient.delete(target_db)
    rescue RestClient::ResourceNotFound => e
    end

    # Sometimes Couch returns a '412 Precondition Failed' when creating a database,
    # via a PUT to its URL, as the DELETE from the previous step has not yet finished.
    # This condition disappears if you try again. So here we try up to 10 times if
    # PreconditionFailed occurs. See
    #   http://tickets.opscode.com/browse/CHEF-1788 and
    #   http://tickets.opscode.com/browse/CHEF-1764.
    #
    # According to https://issues.apache.org/jira/browse/COUCHDB-449, setting the
    # 'X-Couch-Full-Commit: true' header on the DELETE should work around this issue,
    # but it does not.
    db_created = nil
    max_tries = 10
    num_tries = 1
    while !db_created && num_tries <= max_tries
      begin
        Chef::Log.debug("Creating #{target_db}")
        RestClient.put(target_db, nil)
        db_created = true
      rescue RestClient::PreconditionFailed => e
        if num_tries <= max_tries
          Chef::Log.debug("In creating #{target_db} try #{num_tries}/#{max_tries}, got #{e}; try again")
          sleep 0.25
        else
          Chef::Log.error("In creating #{target_db}, tried #{max_tries} times: got #{e}; giving up")
        end
      end
      num_tries += 1
    end

    Chef::Log.debug("Replicating #{source_db} to #{target_db} using bulk (batch) method")
    bulk_get_paged(source_db, 100) do |paged_rows|
      #puts "incoming paged_rows is #{paged_rows.inspect}"
      paged_rows = paged_rows.map do |row|
        doc_in_row = row['doc']
        doc_in_row.delete '_rev'
        doc_in_row
      end

      RestClient.post("#{target_db}/_bulk_docs", Chef::JSONCompat.to_json({"docs" => paged_rows}), :content_type => "application/json")
    end

    # Delete the source if asked to..
    if delete_source_dbs
      Chef::Log.debug("Deleting #{source_db}")
      RestClient.delete(source_db)
    end
  end
end