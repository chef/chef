#
# Author:: Tim Hinderliter (<tim@opscode.com>)
# Author:: Christopher Walters (<cw@opscode.com>)
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

# This class is the consistent interface for a node to obtain its
# cookbooks by name.
#
# This class is basically a glorified Hash, but since there are
# several ways this cookbook information is collected,
# (e.g. CookbookLoader for solo, hash of auto-vivified Cookbook
# objects for lazily-loaded remote cookbooks), it gets transformed
# into this.
class Chef
  class CookbookCollection < Hash
    
    # The input is a mapping of cookbook name to Cookbook object. We simply
    # extract them
    def populate(cookbooks)
      cookbooks.each{ |cookbook_name, cookbook| self[cookbook_name] = cookbook }
    end
    
  end
end
