#
# Author:: Seth Chisamore (<schisamo@opscode.com>)
# Copyright:: Copyright 2011 Opscode, Inc.
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

require 'chef/win32/file'

class Chef
  module Win32
    class File

      # Objects of class Chef::Win32::File::Stat encapsulate common status
      # information for Chef::Win32::File objects. The information
      # is recorded at the moment the Chef::Win32::File::Stat object is
      # created; changes made to the file after that point will not be reflected.
      class Info
        include Chef::Win32::File::Helpers

        NANOS_SINCE_JAN_1601 = 116444736000000000

        # http://msdn.microsoft.com/en-us/library/windows/desktop/aa363788(v=vs.85).aspx
        def initialize(file_name)
          raise Errno::ENOENT, file_name unless ::File.exist?(file_name)
          @file_info = retrieve_file_info(file_name)
        end

        def volume_serial_number
          @file_info[:dw_volume_serial_number]
        end

        def index
          reconstitute_integer(@file_info[:n_file_index_high], @file_info[:n_file_index_low])
        end

        def last_access_time
          parse_time(@file_info[:ft_last_access_time])
        end

        def creation_time
          parse_time(@file_info[:ft_creation_time])
        end

        def last_write_time
          parse_time(@file_info[:ft_last_write_time])
        end

        def number_of_links
          @file_info[:n_number_of_links]
        end

        def size
          reconstitute_integer(@file_info[:n_file_size_high], @file_info[:n_file_size_low])
        end

        ##############################
        # ::File::Stat compat
        alias :atime :last_access_time
        alias :mtime :last_write_time
        alias :ctime :creation_time

        # we're faking it here, but this is in the spirit of ino in *nix
        #
        # from MSDN:
        #
        # "The identifier (low and high parts) and the volume serial number
        # uniquely identify a file on a single computer. To determine whether
        # two open handles represent the same file, combine the identifier
        # and the volume serial number for each file and compare them.""
        #
        def ino
          volume_serial_number + index
        end
        ##############################

        private

        # TODO move these functions to common Chef::Win32 library

        # combines high order and low order parts of a number
        def reconstitute_integer(high_order, low_order)
          high_order * (2**32) + low_order
        end

        # given a +Chef::Win32::API::File::FILETIME+ structure convert into a
        # Ruby +Time+ object.
        #
        def parse_time(file_time_struct)
          unless file_time_struct.kind_of?(Chef::Win32::API::File::FILETIME)
            raise ArgumentError, "invalid FILETIME struct"
          end
          wtime_to_time(reconstitute_integer(file_time_struct[:dw_high_date_time],
            file_time_struct[:dw_low_date_time]))
        end

        # Convert 64-bit FILETIME integer into Time object.
        #
        # FILETIME structure contains a 64-bit value representing the number
        # of 100-nanosecond intervals since January 1, 1601 (UTC).
        #
        # http://msdn.microsoft.com/en-us/library/ms724284(VS.85).aspx
        #
        def wtime_to_time(wtime)
          Time.at((wtime - NANOS_SINCE_JAN_1601) / 10000000)
        end
      end
    end
  end
end
