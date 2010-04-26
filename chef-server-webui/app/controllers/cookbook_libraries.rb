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

require 'chef' / 'mixin' / 'checksum'
require 'chef' / 'cookbook_loader'

class CookbookLibraries < Application
  
  provides :html
  before :login_required 
  
  include Chef::Mixin::Checksum
  
  def load_cookbook_libs()
    @lib_files = load_cookbook_segment(params[:cookbook_id], :libraries)
  end
  
  def index
    load_cookbook_libs()
    render 
  end
  
end


