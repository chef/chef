#
# Author:: Joe Williams (joe@joetify.com)
# Author:: Nuo Yan (nuo@opscode.com)
# Copyright:: Copyright (c) 2009 Opscode, Inc.
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

require 'chef/node'

class StatusController < ApplicationController

  respond_to :html
  before_filter :login_required

  def index
    begin
      @status = Chef::Node.list(true)
      if session[:environment]
        @status = Chef::Node.list_by_environment(session[:environment],true)
      else
        @status = Chef::Node.list(true)
      end
    rescue => e
      Chef::Log.error("#{e}\n#{e.backtrace.join("\n")}")
      @status = {}
      flash[:error] = "Could not list status"
    end
  end

end
