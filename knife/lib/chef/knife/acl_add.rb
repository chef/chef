#
# Author:: Steven Danna (steve@chef.io)
# Author:: Jeremiah Snapp (jeremiah@chef.io)
# Copyright:: Copyright (c) Chef Software Inc.
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

require_relative "../knife"

class Chef
  class Knife
    class AclAdd < Chef::Knife
      category "acl"
      banner "knife acl add MEMBER_TYPE MEMBER_NAME OBJECT_TYPE OBJECT_NAME PERMS"

      deps do
        require_relative "acl_base"
        include Chef::Knife::AclBase
      end

      def run
        member_type, member_name, object_type, object_name, perms = name_args

        if name_args.length != 5
          show_usage
          ui.fatal "You must specify the member type [client|group], member name, object type, object name and perms"
          exit 1
        end

        unless %w{client group}.include?(member_type)
          ui.fatal "ERROR: To enforce best practice, knife-acl can only add a client or a group to an ACL."
          ui.fatal "       See the knife-acl README for more information."
          exit 1
        end
        validate_perm_type!(perms)
        validate_member_name!(member_name)
        validate_object_name!(object_name)
        validate_object_type!(object_type)
        validate_member_exists!(member_type, member_name)

        add_to_acl!(member_type, member_name, object_type, object_name, perms)
      end
    end
  end
end
