#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Christopher Walters (<cw@opscode.com>)
# Author:: Christopher Brown (<cb@opscode.com>)
# Author:: Tim Hinderliter (<tim@opscode.com>)
# Copyright:: Copyright (c) 2008-2011 Opscode, Inc.
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

class Chef
  class Client
    module NotificationRegistry
      #
      # Add a listener for the 'client run started' event.
      #
      # @param notification_block The callback (takes |run_status| parameter).
      # @yieldparam [Chef::RunStatus] run_status The run status.
      #
      def when_run_starts(&notification_block)
        run_start_notifications << notification_block
      end

      #
      # Add a listener for the 'client run success' event.
      #
      # @param notification_block The callback (takes |run_status| parameter).
      # @yieldparam [Chef::RunStatus] run_status The run status.
      #
      def when_run_completes_successfully(&notification_block)
        run_completed_successfully_notifications << notification_block
      end

      #
      # Add a listener for the 'client run failed' event.
      #
      # @param notification_block The callback (takes |run_status| parameter).
      # @yieldparam [Chef::RunStatus] run_status The run status.
      #
      def when_run_fails(&notification_block)
        run_failed_notifications << notification_block
      end

      #
      # Clears all listeners for client run status events.
      #
      # Primarily for testing purposes.
      #
      # @api private
      #
      def clear_notifications
        @run_start_notifications = nil
        @run_completed_successfully_notifications = nil
        @run_failed_notifications = nil
      end

      #
      # TODO These seem protected to me.
      #

      #
      # Listeners to be run when the client run starts.
      #
      # @return [Array<Proc>]
      #
      # @api private
      #
      def run_start_notifications
        @run_start_notifications ||= []
      end

      #
      # Listeners to be run when the client run completes successfully.
      #
      # @return [Array<Proc>]
      #
      # @api private
      #
      def run_completed_successfully_notifications
        @run_completed_successfully_notifications ||= []
      end

      #
      # Listeners to be run when the client run fails.
      #
      # @return [Array<Proc>]
      #
      # @api private
      #
      def run_failed_notifications
        @run_failed_notifications ||= []
      end
    end
  end
end
