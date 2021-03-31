#
# Author:: Steven Danna (<steve@chef.io>)
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
    class UserEdit < Knife

      banner "knife user edit USER (options)"

      option :input,
        long: "--input FILENAME",
        short: "-i FILENAME",
        description: "Name of file to use for PUT or POST"

      option :filename,
        long: "--filename FILENAME",
        short: "-f FILENAME",
        description: "Write private key to FILENAME rather than STDOUT"

      def run
        @user_name = @name_args[0]

        if @user_name.nil?
          show_usage
          ui.fatal("You must specify a user name")
          exit 1
        end
        original_user = root_rest.get("users/#{@user_name}")
        edited_user = get_updated_user(original_user)
        if original_user != edited_user
          result = root_rest.put("users/#{@user_name}", edited_user)
          ui.msg("Saved #{@user_name}.")
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

    private

    # Check the options for ex: input or filename
    # Read Or Open file to update user information
    # return updated user
    def get_updated_user(original_user)
      if config[:input]
        edited_user = JSON.parse(IO.read(config[:input]))
      elsif config[:filename]
        file = config[:filename]
        unless File.exist?(file) ? File.writable?(file) : File.writable?(File.dirname(file))
          ui.fatal "File #{file} is not writable.  Check permissions."
          exit 1
        else
          output = Chef::JSONCompat.to_json_pretty(original_user)
          File.open(file, "w") do |f|
            f.sync = true
            f.puts output
            f.close
            raise "Please set EDITOR environment variable. See https://docs.chef.io/knife_setup/ for details." unless system("#{config[:editor]} #{f.path}")

            edited_user = JSON.parse(IO.read(f.path))
          end
        end
      else
        edited_user = JSON.parse(edit_data(original_user, false))
      end
    end
  end
end
