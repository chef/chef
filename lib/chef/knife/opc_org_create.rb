#
# Author:: Steven Danna (<steve@chef.io>)
# Copyright:: Copyright 2011-2016 Chef Software, Inc.
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

module Opc
  class OpcOrgCreate < Chef::Knife
    category "CHEF ORGANIZATION MANAGEMENT"
    banner "knife opc org create ORG_SHORT_NAME ORG_FULL_NAME (options)"

    option :filename,
      long: "--filename FILENAME",
      short: "-f FILENAME",
      description: "Write validator private key to FILENAME rather than STDOUT"

    option :association_user,
      long: "--association_user USERNAME",
      short: "-a USERNAME",
      description: "Invite USERNAME to the new organization after creation"

    attr_accessor :org_name, :org_full_name

    deps do
      require_relative "../org"
      require_relative "../org/group_operations"
    end

    def run
      @org_name, @org_full_name = @name_args

      if !org_name || !org_full_name
        ui.fatal "You must specify an ORG_NAME and an ORG_FULL_NAME"
        show_usage
        exit 1
      end

      org = Chef::Org.from_hash({ "name" => org_name,
                                  "full_name" => org_full_name }).create
      if config[:filename]
        File.open(config[:filename], "w") do |f|
          f.print(org.private_key)
        end
      else
        ui.msg org.private_key
      end

      if config[:association_user]
        org.associate_user(config[:association_user])
        org.add_user_to_group("admins", config[:association_user])
        org.add_user_to_group("billing-admins", config[:association_user])
      end
    end
  end
end
