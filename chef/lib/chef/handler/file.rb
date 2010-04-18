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
    class File < Chef::Handler

      def new(config={})
        config[:path] ||= "/tmp" 
        super(config)
      end

      def report(node, runner, time)
        data = Hash.new
        data[:node] = node 
        data[:resources] = {
          :all => runner.collection.all_resources,
          :updated => runner.collection.inject([]) { |m, r| m << r if r.updated; m }
        }
        data[:time] = time
        File.open(File.join(config[:path], "report.txt"), "w") do |f|
          f.print data.to_json
        end
      end

      def exception(node, runner, exception=nil)
      end

    end
  end
end
