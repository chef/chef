#
# Author:: Steven Danna (steve@chef.io)
# Copyright:: Copyright (c) Chef Software Inc
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

require_relative "json_compat"
require_relative "mixin/params_validate"
require_relative "server_api"
require_relative "group"

class Chef
  class Org < Group

    include Chef::Mixin::ParamsValidate

    def initialize(name)
      @name = name
      @full_name = ""
      # The Chef API returns the private key of the validator
      # client on create
      @private_key = nil
      @guid = nil
    end

    def chef_rest
      @chef_rest ||= Chef::ServerAPI.new(Chef::Config[:chef_server_root])
    end

    def name(arg = nil)
      set_or_return(:name, arg,
        regex: /^[a-z0-9\-_]+$/)
    end

    def full_name(arg = nil)
      set_or_return(:full_name,
        arg, kind_of: String)
    end

    def private_key(arg = nil)
      set_or_return(:private_key,
        arg, kind_of: String)
    end

    def guid(arg = nil)
      set_or_return(:guid,
        arg, kind_of: String)
    end

    def to_h
      result = {
        "name" => @name,
        "full_name" => @full_name,
      }
      result["private_key"] = @private_key if @private_key
      result["guid"] = @guid if @guid
      result
    end

    alias_method :to_hash, :to_h

    def to_json(*a)
      Chef::JSONCompat.to_json(to_h, *a)
    end

    def create
      payload = { name: name, full_name: full_name }
      new_org = chef_rest.post("organizations", payload)
      Chef::Org.from_hash(to_h.merge(new_org))
    end

    def update
      payload = { name: name, full_name: full_name }
      new_org = chef_rest.put("organizations/#{name}", payload)
      Chef::Org.from_hash(to_h.merge(new_org))
    end

    def destroy
      chef_rest.delete("organizations/#{@name}")
    end

    def save
      create
    rescue Net::HTTPClientException => e
      if e.response.code == "409"
        update
      else
        raise e
      end
    end

    def associate_user(username)
      request_body = { user: username }
      response = chef_rest.post "organizations/#{@name}/association_requests", request_body
      association_id = response["uri"].split("/").last
      chef_rest.put "users/#{username}/association_requests/#{association_id}", { response: "accept" }
    end

    def dissociate_user(username)
      chef_rest.delete "organizations/#{name}/users/#{username}"
    end

    # Class methods
    def self.from_hash(org_hash)
      org = Chef::Org.new(org_hash["name"])
      org.full_name org_hash["full_name"]
      org.private_key org_hash["private_key"] if org_hash.key?("private_key")
      org.guid org_hash["guid"] if org_hash.key?("guid")
      org
    end

    def self.from_json(json)
      Chef::Org.from_hash(Chef::JSONCompat.from_json(json))
    end

    def self.load(org_name)
      response = Chef::ServerAPI.new(Chef::Config[:chef_server_root]).get("organizations/#{org_name}")
      Chef::Org.from_hash(response)
    end

    def self.list(inflate = false)
      orgs = Chef::ServerAPI.new(Chef::Config[:chef_server_root]).get("organizations")
      if inflate
        orgs.inject({}) do |org_map, (name, _url)|
          org_map[name] = Chef::Org.load(name)
          org_map
        end
      else
        orgs
      end
    end
  end
end
