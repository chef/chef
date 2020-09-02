#
# Author:: Snehal Dwivedi (sdwivedi@chef.io)
# Copyright:: Copyright (c) 2008-2016 Chef Software, Inc.
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

# common methods of User and UserV1
class Chef
  class Userable

    def initialize
      @name = ""
      @password = nil
      @admin = false
      @username = nil
      @display_name = nil
      @first_name = nil
      @middle_name = nil
      @last_name = nil
      @email = nil
      @public_key = nil
      @private_key = nil
      @create_key = nil
    end

    def chef_root_rest_v0
      @chef_root_rest_v22 ||= Chef::ServerAPI.new(Chef::Config[:chef_server_root], { api_version: "0" })
    end

    def chef_root_rest_v1
      @chef_root_rest_v22 ||= Chef::ServerAPI.new(Chef::Config[:chef_server_root], { api_version: "1" })
    end

    def name(arg = nil)
      set_or_return(:name, arg,
        regex: /^[a-z0-9\-_]+$/)
    end

    def admin(arg = nil)
      set_or_return(:admin,
        arg, kind_of: [TrueClass, FalseClass])
    end

    def username(arg = nil)
      set_or_return(:username, arg,
        regex: /^[a-z0-9\-_]+$/)
    end

    def display_name(arg = nil)
      set_or_return(:display_name,
        arg, kind_of: String)
    end

    def first_name(arg = nil)
      set_or_return(:first_name,
        arg, kind_of: String)
    end

    def middle_name(arg = nil)
      set_or_return(:middle_name,
        arg, kind_of: String)
    end

    def last_name(arg = nil)
      set_or_return(:last_name,
        arg, kind_of: String)
    end

    def email(arg = nil)
      set_or_return(:email,
        arg, kind_of: String)
    end

    def create_key(arg = nil)
      set_or_return(:create_key, arg,
        kind_of: [TrueClass, FalseClass])
    end

    def public_key(arg = nil)
      set_or_return(:public_key,
        arg, kind_of: String)
    end

    def private_key(arg = nil)
      set_or_return(:private_key,
        arg, kind_of: String)
    end

    def password(arg = nil)
      set_or_return(:password,
        arg, kind_of: String)
    end
  end
end
