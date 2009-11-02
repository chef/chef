#
# Author:: Nuo Yan (<nuo@opscode.com>)
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


class ChefServerWebui::Users < ChefServerWebui::Application
  provides :json
  provides :html
  
  # GET /users
  def index
    render
  end

  # GET /users/:id
  def show
    render
  end

  # GET /users/:id/edit
  def edit
    render 
  end

  # GET /users/new
  def new
    render
  end
  
  # POST /users
  def create
    
  end

  # PUT /users/:id
  def update
    
  end

  # DELETE /users/:id
  def destroy
  end

end

