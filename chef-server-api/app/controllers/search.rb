#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Christopher Brown (<cb@opscode.com>)
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


require 'chef/solr_query'

class Search < Application
  provides :json

  before :authenticate_every
  before :is_admin, :only => [:reindex]

  def index
    indexes = valid_indexes
    display(indexes.inject({}) { |r,i| r[i] = absolute_url(:search_show, i); r })
  end

  def valid_indexes
    indexes = Chef::DataBag.cdb_list(false)
    indexes += %w{ role node client environment}
  end

  def show
    unless valid_indexes.include?(params[:id])
      raise NotFound, "I don't know how to search for #{params[:id]} data objects."
    end
    params[:type] = params.delete(:id)
    display(Chef::SolrQuery.from_params(params).search)
  rescue Chef::Exceptions::QueryParseError => e
    # we set status rather than raising BadRequest to avoid a
    # stacktrace in the server log
    self.status = 400
    e_msg = e.message.gsub(/\n/, " ")
    msg = "invalid search query: '#{params[:q]}' #{e_msg}"
    Chef::Log.warn("400 #{msg}")
    display({ "error" => [msg] })
  end

  def reindex
    display(Chef::SolrQuery.new.rebuild_index)
  end

end
