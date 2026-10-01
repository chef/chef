#
# Author:: Bryan McLellan (btm@loftninjas.org)
# Author:: Toomas Pelberg (toomasp@gmx.net)
# Copyright:: Copyright 2009-2016, Bryan McLellan
# Copyright:: Copyright 2010-2016, Toomas Pelberg
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

require_relative "../../log"
require_relative "../../provider"
require_relative "../cron"

class Chef
  class Provider
    class Cron
      class Unix < Chef::Provider::Cron
        provides :cron, os: "solaris2"

        private

        def read_crontab
          crontab = shell_out(%w{/usr/bin/crontab -l}, user: @new_resource.user)
          # ponytail: Mixlib::ShellOut::Helper::FakeShellOut (returned here
          # instead of a real Mixlib::ShellOut when running over Target
          # Mode) only defines `exitstatus` on itself, not on its `.status`
          # OpenStruct -- `.status.exitstatus` silently resolves to nil
          # there, so use `.exitstatus` directly; real Mixlib::ShellOut
          # exposes the identical accessor, so this is safe for both paths.
          status = crontab.exitstatus

          logger.trace crontab.format_for_exception if status > 0

          if status > 1
            raise Chef::Exceptions::Cron, "Error determining state of #{@new_resource.name}, exit: #{status}"
          end
          return nil if status > 0

          crontab.stdout.chomp << "\n"
        end

        def write_crontab(crontab)
          tempcron = Tempfile.new("chef-cron")
          tempcron << crontab
          tempcron.flush
          tempcron.chmod(0644)
          # ponytail: in Target Mode, `shell_out` runs the given command
          # *remotely* over Train, but Tempfile.new always writes to the
          # *local* controller filesystem -- so `crontab <local tempfile
          # path>` fails remotely with "no such file" (surfaced as a
          # generic, message-less exit 1). Upload the tempfile content to a
          # throwaway remote path first and point crontab at that instead;
          # local (non-Target-Mode) runs are unaffected since crontab_path
          # just equals tempcron.path there.
          crontab_path = tempcron.path
          remote_tempdir = nil
          if Chef::Config.target_mode?
            remote_tempdir = ::TargetIO::Dir.mktmpdir("chef-cron")
            crontab_path = ::File.join(remote_tempdir, "crontab")
            ::TargetIO::File.upload(tempcron.path, crontab_path)
          end
          exit_status = 0
          error_message = ""
          begin
            crontab_write = shell_out("/usr/bin/crontab", crontab_path, user: @new_resource.user)
            stderr = crontab_write.stderr
            # ponytail: see read_crontab's comment above -- same
            # FakeShellOut `.status.exitstatus` vs `.exitstatus` gap.
            exit_status = crontab_write.exitstatus
            # solaris9, 10 on some failures for example invalid 'mins' in crontab fails with exit code of zero :(
            if stderr && stderr.include?("errors detected in input, no crontab file generated")
              error_message = stderr
              exit_status = 1
            end
          rescue Chef::Exceptions::Exec => e
            logger.trace(e.message)
            exit_status = 1
            error_message = e.message
          rescue ArgumentError => e
            # usually raised on invalid user.
            logger.trace(e.message)
            exit_status = 1
            error_message = e.message
          end
          tempcron.close!
          ::TargetIO::FileUtils.rm_rf(remote_tempdir) if remote_tempdir
          if exit_status > 0
            raise Chef::Exceptions::Cron, "Error updating state of #{@new_resource.name}, exit: #{exit_status}, message: #{error_message}"
          end
        end

      end
    end
  end
end
