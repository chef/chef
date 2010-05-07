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
require 'chef' / 'mixin' / 'find_preferred_file'

class CookbookTemplates < Application
  
  provides :html
  before :login_required 
  
  include Chef::Mixin::Checksum
  include Chef::Mixin::FindPreferredFile
  
  # def load_cookbook_templates()
  #   @cl = Chef::CookbookLoader.new
  #   @cookbook = @cl[params[:cookbook_id]]
  #   raise NotFound unless @cookbook
  #   
  #   @templates = Hash.new
  #   @cookbook.template_files.each do |tf|
  #     full = File.expand_path(tf)
  #     name = File.basename(full)
  #     tf =~ /^.+#{params[:cookbook_id]}[\\|\/]templates[\\|\/](.+?)[\\|\/]#{name}/
  #     singlecopy = $1
  #     @templates[full] = {
  #       :name => name,
  #       :singlecopy => singlecopy,
  #       :file => full,
  #     }
  #   end
  #   @templates
  # end
  
  def index
    @templates = load_cookbook_files(params[:cookbook_id], :template)
    display @templates
  end
  
end
