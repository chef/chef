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

#require 'chef' / 'search'
#require 'chef' / 'queue'

class ChefServerWebui::Search < ChefServerWebui::Application
  
  provides :html
  before :login_required 
    
  def index
    @s = Chef::Search.new
    @search_indexes = @s.list_indexes
    render
  end

  def show
    @s = Chef::Search.new
    
    query = params[:q].nil? ? "*" : (params[:q].empty? ? "*" : params[:q])
    attributes = params[:a].nil? ? [] : params[:a].split(",").collect { |a| a.to_sym }
    @results = @s.search(params[:id], query, attributes)
   
    render
  end

  def destroy
    @s = Chef::Search.new
    @entries = @s.search(params[:id], "*")
    @entries.each do |entry|
      Chef::Queue.send_msg(:queue, :remove, entry)
    end
    @status = 202
    redirect url(:search)
  end
  
end
