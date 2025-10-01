#
# Author:: Tyler Cloke (<tyler@chef.io>)
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

require "chef/key" unless defined?(Chef::Key)
require "chef/json_compat" unless defined?(Chef::JSONCompat)
require "chef/exceptions" unless defined?(Chef::Exceptions)

class Chef
  class Knife
    # Service class for UserKeyEdit and ClientKeyEdit,
    # Implements common functionality of knife [user | org client] key edit.
    #
    # @author Tyler Cloke
    #
    # @attr_accessor [Hash] cli input, see UserKeyEdit and ClientKeyEdit for what could populate it
    class KeyEdit

      attr_accessor :config

      def initialize(original_name, actor, actor_field_name, ui, config)
        @original_name = original_name
        @actor = actor
        @actor_field_name = actor_field_name
        @ui = ui
        @config = config
      end

      def public_key_and_create_key_error_msg
        <<~EOS
          You passed both --public-key and --create-key. Only pass one, or the other, or neither.
          Do not pass either if you do not want to change the public_key field of your key.
          Pass --public-key if you want to update the public_key field of your key from a specific public key.
          Pass --create-key if you want the server to generate a new key and use that to update the public_key field of your key.
        EOS
      end

      def edit_data(key)
        @ui.edit_data(key)
      end

      def edit_hash(key)
        @ui.edit_hash(key)
      end

      def display_info(input)
        @ui.info(input)
      end

      def display_private_key(private_key)
        @ui.msg(private_key)
      end

      def output_private_key_to_file(private_key)
        File.open(@config[:file], "w") do |f|
          f.print(private_key)
        end
      end

      def update_key_from_hash(output)
        Chef::Key.from_hash(output).update(@original_name)
      end

      def run
        key = Chef::Key.new(@actor, @actor_field_name)
        if @config[:public_key] && @config[:create_key]
          raise Chef::Exceptions::KeyCommandInputError, public_key_and_create_key_error_msg
        end

        if @config[:create_key]
          key.create_key(true)
        end

        if @config[:public_key]
          key.public_key(File.read(File.expand_path(@config[:public_key])))
        end

        if @config[:key_name]
          key.name(@config[:key_name])
        else
          key.name(@original_name)
        end

        if @config[:expiration_date]
          key.expiration_date(@config[:expiration_date])
        end

        output = edit_hash(key)
        key = update_key_from_hash(output)

        to_display = "Updated key: #{key.name}"
        to_display << " (formally #{@original_name})" if key.name != @original_name
        display_info(to_display)
        if key.private_key
          if @config[:file]
            output_private_key_to_file(key.private_key)
          else
            display_private_key(key.private_key)
          end
        end
      end
    end
  end
end
