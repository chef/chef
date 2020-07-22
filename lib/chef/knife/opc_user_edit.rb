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
require_relative "../mixin/root_rest"

module Opc
  class OpcUserEdit < Chef::Knife
    category "CHEF ORGANIZATION MANAGEMENT"
    banner "knife opc user edit USERNAME"

    option :input,
      long: "--input FILENAME",
      short: "-i FILENAME",
      description: "Name of file to use for PUT or POST"

    option :filename,
      long: "--filename FILENAME",
      short: "-f FILENAME",
      description: "Write private key to FILENAME rather than STDOUT"

    include Chef::Mixin::RootRestv0

    def run
      user_name = @name_args[0]

      if user_name.nil?
        show_usage
        ui.fatal("You must specify a user name")
        exit 1
      end

      original_user = root_rest.get("users/#{user_name}")
      if config[:input]
        edited_user = JSON.parse(IO.read(config[:input]))
      else
        edited_user = edit_data(original_user)
      end
      if original_user != edited_user
        result = root_rest.put("users/#{user_name}", edited_user)
        ui.msg("Saved #{user_name}.")
        unless result["private_key"].nil?
          if config[:filename]
            File.open(config[:filename], "w") do |f|
              f.print(result["private_key"])
            end
          else
            ui.msg result["private_key"]
          end
        end
      else
        ui.msg("User unchanged, not saving.")
      end
    end
  end
end
