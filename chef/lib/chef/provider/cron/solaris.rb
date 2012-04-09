#
# Author:: Bryan McLellan (btm@loftninjas.org)
# Author:: Toomas Pelberg (toomasp@gmx.net)
# Copyright:: Copyright (c) 2009 Bryan McLellan
# Copyright:: Copyright (c) 2010 Toomas Pelberg
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

require 'chef/log'
require 'chef/provider'

class Chef
  class Provider
    class Cron
      class Solaris < Chef::Provider::Cron

        private

        def read_crontab
          crontab = nil
          status = popen4("crontab -l #{@new_resource.user}") do |pid, stdin, stdout, stderr|
            crontab = stdout.read
          end
          if status.exitstatus > 1
            raise Chef::Exceptions::Cron, "Error determining state of #{@new_resource.name}, exit: #{status.exitstatus}"
          end
          crontab
        end

        def write_crontab(crontab)
          tempcron = Tempfile.new("chef-cron")
          tempcron << crontab
          tempcron.flush
          tempcron.chmod(0644)
          status = run_command(:command => "/usr/bin/crontab #{tempcron.path}",:user => @new_resource.user)
          tempcron.close!
          if status.exitstatus > 0
            raise Chef::Exceptions::Cron, "Error updating state of #{@new_resource.name}, exit: #{status.exitstatus}"
          end
        end
      end
    end
  end
end
