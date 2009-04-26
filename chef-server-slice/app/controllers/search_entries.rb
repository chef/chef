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

require 'chef' / 'search'
require 'chef' / 'queue'

class ChefServerSlice::SearchEntries < ChefServerSlice::Application
  
  provides :html, :json
    
  def index
    @s = Chef::Search.new
    @entries = @s.search(params[:search_id])
    display @entries
  end

  def show
    @s = Chef::Search.new
    @entry = @s.search(params[:search_id], "id:'#{params[:search_id]}_#{params[:id]}'").first
    display @entry
  end
  
  def create
    @to_index = params
    @to_index.delete(:controller)
    @to_index["index_name"] = params[:search_id]
    @to_index["id"] = "#{params[:search_id]}_#{params[:id]}"
    @to_index.delete(:search_id)
    Chef::Queue.send_msg(:queue, :index, @to_index)
    if content_type == :html
      redirect url(:search)
    else
      @status = 202
      display @to_index
    end
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
    if content_type == :html
      redirect url(:search)
    else
      display @entries
    end
  end
  
end
