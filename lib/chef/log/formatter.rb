#
# Chef::Log::Formatter
#
# A custom Logger::Formatter implementation for Chef.
#
# Author:: Adam Jacob (<adam@hjksolutions.com>)
# Copyright:: Copyright (c) 2008 HJK Solutions, LLC
# License:: GNU General Public License version 2 or later
# 
# This program and entire repository is free software; you can
# redistribute it and/or modify it under the terms of the GNU 
# General Public License as published by the Free Software 
# Foundation; either version 2 of the License, or any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
#

require 'logger'
require 'time'

class Chef
  class Log
    class Formatter < Logger::Formatter
      @@show_time = true
      
      def self.show_time=(show=false)
        @@show_time = show
      end
      
      # Prints a log message as '[time] severity: message' if Chef::Log::Formatter.show_time == true.
      # Otherwise, doesn't print the time.
      def call(severity, time, progname, msg)
        if @@show_time
          sprintf("[%s] %s: %s\n", time.rfc2822(), severity, msg2str(msg))
        else
          sprintf("%s: %s\n", severity, msg2str(msg))
        end
      end
      
      # Converts some argument to a Logger.severity() call to a string.  Regular strings pass through like
      # normal, Exceptions get formatted as "message (class)\nbacktrace", and other random stuff gets 
      # put through "object.inspect"
      def msg2str(msg)
        case msg
        when ::String
          msg
        when ::Exception
          "#{ msg.message } (#{ msg.class })\n" <<
            (msg.backtrace || []).join("\n")
        else
          msg.inspect
        end
      end
    end
  end
end