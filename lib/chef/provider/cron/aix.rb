#
# Author:: Kaustubh Deorukhkar (<kaustubh@clogeny.com>)
# Copyright:: Copyright (c) 2013 Opscode, Inc.
#

require "chef/provider/cron/unix"

class Chef
  class Provider
    class Cron
      class Aix < Chef::Provider::Cron::Unix

        private

        # For AIX we ignore env vars/[ :mailto, :path, :shell, :home ]
        def get_crontab_entry
          if env_vars_are_set?
            raise Chef::Exceptions::Cron, "Aix cron entry does not support environment variables. Please set them in script and use script in cron."
          end

          newcron = ""
          newcron << "# Chef Name: #{new_resource.name}\n"
          newcron << "#{@new_resource.minute} #{@new_resource.hour} #{@new_resource.day} #{@new_resource.month} #{@new_resource.weekday}"

          newcron << " #{@new_resource.command}\n"
          newcron
        end

        def env_vars_are_set?
          @new_resource.environment.length > 0 || !@new_resource.mailto.nil? || !@new_resource.path.nil? || !@new_resource.shell.nil? || !@new_resource.home.nil?
        end
      end
    end
  end
end
