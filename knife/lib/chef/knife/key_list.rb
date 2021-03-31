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
    # Service class for UserKeyList and ClientKeyList, used to list keys.
    # Implements common functionality of knife [user | org client] key list.
    #
    # @author Tyler Cloke
    #
    # @attr_accessor [Hash] cli input, see UserKeyList and ClientKeyList for what could populate it
    class KeyList

      attr_accessor :config

      def initialize(actor, list_method, ui, config)
        @actor = actor
        @list_method = list_method
        @ui = ui
        @config = config
      end

      def expired_and_non_expired_msg
        <<~EOS
          You cannot pass both --only-expired and --only-non-expired.
          Please pass one or none.
        EOS
      end

      def display_info(string)
        @ui.output(string)
      end

      def colorize(string)
        @ui.color(string, :cyan)
      end

      def run
        if @config[:only_expired] && @config[:only_non_expired]
          raise Chef::Exceptions::KeyCommandInputError, expired_and_non_expired_msg
        end

        # call proper list function
        keys = Chef::Key.send(@list_method, @actor)
        if @config[:with_details]
          max_length = 0
          keys.each do |key|
            key["name"] = key["name"] + ":"
            max_length = key["name"].length if key["name"].length > max_length
          end
          keys.each do |key|
            next if !key["expired"] && @config[:only_expired]
            next if key["expired"] && @config[:only_non_expired]

            display = "#{colorize(key["name"].ljust(max_length))} #{key["uri"]}"
            display = "#{display} (expired)" if key["expired"]
            display_info(display)
          end
        else
          keys.each do |key|
            next if !key["expired"] && @config[:only_expired]
            next if key["expired"] && @config[:only_non_expired]

            display_info(key["name"])
          end
        end
      end

    end
  end
end
