#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2010 Opscode, Inc.
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

class Chef
  class Handler

    attr_accessor :config

    def initialize(config={})
      @config = config
      @config[:path] ||= "/var/chef/reports"
      @config
    end

    def build_report_data(node, runner, start_time, end_time, elapsed_time, exception=nil)
      data = Hash.new
      data[:node] = node if node
      if runner
        data[:resources] = {
          :all => runner.run_context.resource_collection.all_resources,
          :updated => runner.run_context.resource_collection.inject([]) { |m, r| m << r if r.updated; m }
        }
      end
      if exception
        data[:success] = false 
        data[:exception] = {
          :message => exception.message,
          :backtrace => exception.backtrace
        }
      else
        data[:success] = true
      end
      data[:elapsed_time] = elapsed_time 
      data[:start_time] = start_time
      data[:end_time] = end_time
      data
    end

    def build_report_dir
      unless File.exists?(config[:path])
        FileUtils.mkdir_p(config[:path])
        File.chmod(octal_mode("0700"), config[:path])
      end
    end

  end
end
