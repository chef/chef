#
# Author:: Nimisha Sharad (<nimisha.sharad@msystechnologies.com>)
# Copyright:: Copyright 2008-2016, Chef Software Inc.
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

require "chef/resource"

class Chef
  class Resource
    class WindowsTask < Chef::Resource

      provides :windows_task, os: "windows"

      allowed_actions :create, :delete, :run, :end, :change, :enable, :disable
      default_action :create

      def initialize(name, run_context = nil)
        super
        @resource_name = :windows_task
        @task_name = name
        @action = :create
      end

      property :task_name, String, regex: [/\A[^\/\:\*\?\<\>\|]+\z/]
      property :command, String
      property :cwd, String
      property :user, String, default: 'SYSTEM'
      property :password, String
      property :run_level, equal_to: [:highest, :limited], default: :limited
      property :force, [TrueClass, FalseClass], default: false
      property :interactive_enabled, [TrueClass, FalseClass], default: false
      property :frequency_modifier, [Integer, String], default: 1
      property :frequency, equal_to: [:minute,
                                       :hourly,
                                       :daily,
                                       :weekly,
                                       :monthly,
                                       :once,
                                       :on_logon,
                                       :onstart,
                                       :on_idle], default: :hourly
      property :start_day, String
      property :start_time, String
      property :day, [String, Integer]
      property :months, String
      property :idle_time, Integer
      property :random_delay, String
      property :execution_time_limit, String

      attr_accessor :exists, :status, :enabled

      def after_created
        if random_delay
          if [:on_logon, :onstart, :on_idle].include? frequency
            raise ArgumentError, "`random_delay` property is not supported with frequency: #{frequency}"
          end
        end
      end

    end
  end
end
