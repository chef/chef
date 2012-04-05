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
#

class SearchEntriesController < ApplicationController

  respond_to :html
  before_filter :login_required

  def index
    @s = Chef::Search.new
    @entries = @s.search(params[:search_id])
  end

  def show
    @s = Chef::Search.new
    @entry = @s.search(params[:search_id], "id:'#{params[:search_id]}_#{params[:id]}'").first
  end

  def create
    @to_index = params
    @to_index.delete(:controller)
    @to_index["index_name"] = params[:search_id]
    @to_index["id"] = "#{params[:search_id]}_#{params[:id]}"
    @to_index.delete(:search_id)
    Chef::Queue.send_msg(:queue, :index, @to_index)
    redirect_to search_url
  end

  def update
    create
  end

  def destroy
    @s = Chef::Search.new
    @entries = @s.search(params[:id])
    @entries.each do |entry|
      Chef::Queue.send_msg(:queue, :remove, entry)
    end
    @status = 202
    redirect_to search_url
  end

end
