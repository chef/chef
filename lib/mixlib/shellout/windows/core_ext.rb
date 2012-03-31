#--
# Author:: Daniel DeLeo (<dan@opscode.com>)
# Author:: John Keiser (<jkeiser@opscode.com>)
# Copyright:: Copyright (c) 2011, 2012 Opscode, Inc.
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

require 'win32/process'
require 'windows/handle'
require 'windows/process'
require 'windows/synchronize'

# Override module Windows::Process.CreateProcess to fix bug when
# using both app_name and command_line
#
module Windows
  module Process
    API.new('CreateProcess', 'SPPPLLLPPP', 'B')
  end
end

#
# Override Win32::Process.create to take a proper environment hash
# so that variables can contain semicolons
# (submitted patch to owner)
#
module Process
  def create(args)
    unless args.kind_of?(Hash)
      raise TypeError, 'Expecting hash-style keyword arguments'
    end

    valid_keys = %w/
      app_name command_line inherit creation_flags cwd environment
      startup_info thread_inherit process_inherit close_handles with_logon
      domain password
    /

    valid_si_keys = %/
      startf_flags desktop title x y x_size y_size x_count_chars
      y_count_chars fill_attribute sw_flags stdin stdout stderr
    /

    # Set default values
    hash = {
      'app_name'       => nil,
      'creation_flags' => 0,
      'close_handles'  => true
    }

    # Validate the keys, and convert symbols and case to lowercase strings.
    args.each{ |key, val|
      key = key.to_s.downcase
      unless valid_keys.include?(key)
        raise ArgumentError, "invalid key '#{key}'"
      end
      hash[key] = val
    }

    si_hash = {}

    # If the startup_info key is present, validate its subkeys
    if hash['startup_info']
      hash['startup_info'].each{ |key, val|
        key = key.to_s.downcase
        unless valid_si_keys.include?(key)
          raise ArgumentError, "invalid startup_info key '#{key}'"
        end
        si_hash[key] = val
      }
    end

    # The +command_line+ key is mandatory unless the +app_name+ key
    # is specified.
    unless hash['command_line']
      if hash['app_name']
        hash['command_line'] = hash['app_name']
        hash['app_name'] = nil
      else
        raise ArgumentError, 'command_line or app_name must be specified'
      end
    end

    # The environment string should be passed as an array of A=B paths, or
    # as a string of ';' separated paths.
    if hash['environment']
      env = hash['environment']
      if !env.respond_to?(:join)
        # Backwards compat for ; separated paths
        env = hash['environment'].split(File::PATH_SEPARATOR)
      end
      # The argument format is a series of null-terminated strings, with an additional null terminator.
      env = env.map { |e| e + "\0" }.join("") + "\0"
      if hash['with_logon']
        env = env.multi_to_wide(e)
      end
      env = [env].pack('p*').unpack('L').first
    else
      env = nil
    end

    startinfo = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
    startinfo = startinfo.pack('LLLLLLLLLLLLSSLLLL')
    procinfo  = [0,0,0,0].pack('LLLL')

    # Process SECURITY_ATTRIBUTE structure
    process_security = 0
    if hash['process_inherit']
      process_security = [0,0,0].pack('LLL')
      process_security[0,4] = [12].pack('L') # sizeof(SECURITY_ATTRIBUTE)
      process_security[8,4] = [1].pack('L')  # TRUE
    end

    # Thread SECURITY_ATTRIBUTE structure
    thread_security = 0
    if hash['thread_inherit']
      thread_security = [0,0,0].pack('LLL')
      thread_security[0,4] = [12].pack('L') # sizeof(SECURITY_ATTRIBUTE)
      thread_security[8,4] = [1].pack('L')  # TRUE
    end

    # Automatically handle stdin, stdout and stderr as either IO objects
    # or file descriptors.  This won't work for StringIO, however.
    ['stdin', 'stdout', 'stderr'].each{ |io|
      if si_hash[io]
        if si_hash[io].respond_to?(:fileno)
          handle = get_osfhandle(si_hash[io].fileno)
        else
          handle = get_osfhandle(si_hash[io])
        end

        if handle == INVALID_HANDLE_VALUE
          raise Error, get_last_error
        end

        # Most implementations of Ruby on Windows create inheritable
        # handles by default, but some do not. RF bug #26988.
        bool = SetHandleInformation(
          handle,
          HANDLE_FLAG_INHERIT,
          HANDLE_FLAG_INHERIT
        )

        raise Error, get_last_error unless bool

        si_hash[io] = handle
        si_hash['startf_flags'] ||= 0
        si_hash['startf_flags'] |= STARTF_USESTDHANDLES
        hash['inherit'] = true
      end
    }

    # The bytes not covered here are reserved (null)
    unless si_hash.empty?
      startinfo[0,4]  = [startinfo.size].pack('L')
      startinfo[8,4]  = [si_hash['desktop']].pack('p*') if si_hash['desktop']
      startinfo[12,4] = [si_hash['title']].pack('p*') if si_hash['title']
      startinfo[16,4] = [si_hash['x']].pack('L') if si_hash['x']
      startinfo[20,4] = [si_hash['y']].pack('L') if si_hash['y']
      startinfo[24,4] = [si_hash['x_size']].pack('L') if si_hash['x_size']
      startinfo[28,4] = [si_hash['y_size']].pack('L') if si_hash['y_size']
      startinfo[32,4] = [si_hash['x_count_chars']].pack('L') if si_hash['x_count_chars']
      startinfo[36,4] = [si_hash['y_count_chars']].pack('L') if si_hash['y_count_chars']
      startinfo[40,4] = [si_hash['fill_attribute']].pack('L') if si_hash['fill_attribute']
      startinfo[44,4] = [si_hash['startf_flags']].pack('L') if si_hash['startf_flags']
      startinfo[48,2] = [si_hash['sw_flags']].pack('S') if si_hash['sw_flags']
      startinfo[56,4] = [si_hash['stdin']].pack('L') if si_hash['stdin']
      startinfo[60,4] = [si_hash['stdout']].pack('L') if si_hash['stdout']
      startinfo[64,4] = [si_hash['stderr']].pack('L') if si_hash['stderr']
    end

    if hash['with_logon']
      logon  = multi_to_wide(hash['with_logon'])
      domain = multi_to_wide(hash['domain'])
      app    = hash['app_name'].nil? ? nil : multi_to_wide(hash['app_name'])
      cmd    = hash['command_line'].nil? ? nil : multi_to_wide(hash['command_line'])
      cwd    = multi_to_wide(hash['cwd'])
      passwd = multi_to_wide(hash['password'])

      hash['creation_flags'] |= CREATE_UNICODE_ENVIRONMENT

      process_ran = CreateProcessWithLogonW(
        logon,                  # User
        domain,                 # Domain
        passwd,                 # Password
        LOGON_WITH_PROFILE,     # Logon flags
        app,                    # App name
        cmd,                    # Command line
        hash['creation_flags'], # Creation flags
        env,                    # Environment
        cwd,                    # Working directory
        startinfo,              # Startup Info
        procinfo                # Process Info
      )
    else
      process_ran = CreateProcess(
        hash['app_name'],       # App name
        hash['command_line'],   # Command line
        process_security,       # Process attributes
        thread_security,        # Thread attributes
        hash['inherit'],        # Inherit handles?
        hash['creation_flags'], # Creation flags
        env,                    # Environment
        hash['cwd'],            # Working directory
        startinfo,              # Startup Info
        procinfo                # Process Info
      )
    end

    # TODO: Close stdin, stdout and stderr handles in the si_hash unless
    # they're pointing to one of the standard handles already. [Maybe]
    if !process_ran
      raise_last_error("CreateProcess()")
    end

    # Automatically close the process and thread handles in the
    # PROCESS_INFORMATION struct unless explicitly told not to.
    if hash['close_handles']
      CloseHandle(procinfo[0,4].unpack('L').first)
      CloseHandle(procinfo[4,4].unpack('L').first)
    end

    ProcessInfo.new(
      procinfo[0,4].unpack('L').first, # hProcess
      procinfo[4,4].unpack('L').first, # hThread
      procinfo[8,4].unpack('L').first, # hProcessId
      procinfo[12,4].unpack('L').first # hThreadId
    )
  end

  def self.raise_last_error(operation)
    error_string = "#{operation} failed: #{get_last_error}"
    last_error_code = GetLastError()
    if ERROR_CODE_MAP.has_key?(last_error_code)
      raise ERROR_CODE_MAP[last_error_code], error_string
    else
      raise Error, error_string
    end
  end

  # List from ruby/win32/win32.c
  ERROR_CODE_MAP = {
    ERROR_INVALID_FUNCTION => Errno::EINVAL,
    ERROR_FILE_NOT_FOUND => Errno::ENOENT,
    ERROR_PATH_NOT_FOUND => Errno::ENOENT,
    ERROR_TOO_MANY_OPEN_FILES => Errno::EMFILE,
    ERROR_ACCESS_DENIED => Errno::EACCES,
    ERROR_INVALID_HANDLE => Errno::EBADF,
    ERROR_ARENA_TRASHED => Errno::ENOMEM,
    ERROR_NOT_ENOUGH_MEMORY => Errno::ENOMEM,
    ERROR_INVALID_BLOCK => Errno::ENOMEM,
    ERROR_BAD_ENVIRONMENT => Errno::E2BIG,
    ERROR_BAD_FORMAT => Errno::ENOEXEC,
    ERROR_INVALID_ACCESS => Errno::EINVAL,
    ERROR_INVALID_DATA => Errno::EINVAL,
    ERROR_INVALID_DRIVE => Errno::ENOENT,
    ERROR_CURRENT_DIRECTORY => Errno::EACCES,
    ERROR_NOT_SAME_DEVICE => Errno::EXDEV,
    ERROR_NO_MORE_FILES => Errno::ENOENT,
    ERROR_WRITE_PROTECT => Errno::EROFS,
    ERROR_BAD_UNIT => Errno::ENODEV,
    ERROR_NOT_READY => Errno::ENXIO,
    ERROR_BAD_COMMAND => Errno::EACCES,
    ERROR_CRC => Errno::EACCES,
    ERROR_BAD_LENGTH => Errno::EACCES,
    ERROR_SEEK => Errno::EIO,
    ERROR_NOT_DOS_DISK => Errno::EACCES,
    ERROR_SECTOR_NOT_FOUND => Errno::EACCES,
    ERROR_OUT_OF_PAPER => Errno::EACCES,
    ERROR_WRITE_FAULT => Errno::EIO,
    ERROR_READ_FAULT => Errno::EIO,
    ERROR_GEN_FAILURE => Errno::EACCES,
    ERROR_LOCK_VIOLATION => Errno::EACCES,
    ERROR_SHARING_VIOLATION => Errno::EACCES,
    ERROR_WRONG_DISK => Errno::EACCES,
    ERROR_SHARING_BUFFER_EXCEEDED => Errno::EACCES,
#    ERROR_BAD_NETPATH => Errno::ENOENT,
#    ERROR_NETWORK_ACCESS_DENIED => Errno::EACCES,
#    ERROR_BAD_NET_NAME => Errno::ENOENT,
    ERROR_FILE_EXISTS => Errno::EEXIST,
    ERROR_CANNOT_MAKE => Errno::EACCES,
    ERROR_FAIL_I24 => Errno::EACCES,
    ERROR_INVALID_PARAMETER => Errno::EINVAL,
    ERROR_NO_PROC_SLOTS => Errno::EAGAIN,
    ERROR_DRIVE_LOCKED => Errno::EACCES,
    ERROR_BROKEN_PIPE => Errno::EPIPE,
    ERROR_DISK_FULL => Errno::ENOSPC,
    ERROR_INVALID_TARGET_HANDLE => Errno::EBADF,
    ERROR_INVALID_HANDLE => Errno::EINVAL,
    ERROR_WAIT_NO_CHILDREN => Errno::ECHILD,
    ERROR_CHILD_NOT_COMPLETE => Errno::ECHILD,
    ERROR_DIRECT_ACCESS_HANDLE => Errno::EBADF,
    ERROR_NEGATIVE_SEEK => Errno::EINVAL,
    ERROR_SEEK_ON_DEVICE => Errno::EACCES,
    ERROR_DIR_NOT_EMPTY => Errno::ENOTEMPTY,
#    ERROR_DIRECTORY => Errno::ENOTDIR,
    ERROR_NOT_LOCKED => Errno::EACCES,
    ERROR_BAD_PATHNAME => Errno::ENOENT,
    ERROR_MAX_THRDS_REACHED => Errno::EAGAIN,
#    ERROR_LOCK_FAILED => Errno::EACCES,
    ERROR_ALREADY_EXISTS => Errno::EEXIST,
    ERROR_INVALID_STARTING_CODESEG => Errno::ENOEXEC,
    ERROR_INVALID_STACKSEG => Errno::ENOEXEC,
    ERROR_INVALID_MODULETYPE => Errno::ENOEXEC,
    ERROR_INVALID_EXE_SIGNATURE => Errno::ENOEXEC,
    ERROR_EXE_MARKED_INVALID => Errno::ENOEXEC,
    ERROR_BAD_EXE_FORMAT => Errno::ENOEXEC,
    ERROR_ITERATED_DATA_EXCEEDS_64k => Errno::ENOEXEC,
    ERROR_INVALID_MINALLOCSIZE => Errno::ENOEXEC,
    ERROR_DYNLINK_FROM_INVALID_RING => Errno::ENOEXEC,
    ERROR_IOPL_NOT_ENABLED => Errno::ENOEXEC,
    ERROR_INVALID_SEGDPL => Errno::ENOEXEC,
    ERROR_AUTODATASEG_EXCEEDS_64k => Errno::ENOEXEC,
    ERROR_RING2SEG_MUST_BE_MOVABLE => Errno::ENOEXEC,
    ERROR_RELOC_CHAIN_XEEDS_SEGLIM => Errno::ENOEXEC,
    ERROR_INFLOOP_IN_RELOC_CHAIN => Errno::ENOEXEC,
    ERROR_FILENAME_EXCED_RANGE => Errno::ENOENT,
    ERROR_NESTING_NOT_ALLOWED => Errno::EAGAIN,
#    ERROR_PIPE_LOCAL => Errno::EPIPE,
    ERROR_BAD_PIPE => Errno::EPIPE,
    ERROR_PIPE_BUSY => Errno::EAGAIN,
    ERROR_NO_DATA => Errno::EPIPE,
    ERROR_PIPE_NOT_CONNECTED => Errno::EPIPE,
    ERROR_OPERATION_ABORTED => Errno::EINTR,
#    ERROR_NOT_ENOUGH_QUOTA => Errno::ENOMEM,
    ERROR_MOD_NOT_FOUND => Errno::ENOENT,
    WSAEINTR => Errno::EINTR,
    WSAEBADF => Errno::EBADF,
#    WSAEACCES => Errno::EACCES,
    WSAEFAULT => Errno::EFAULT,
    WSAEINVAL => Errno::EINVAL,
    WSAEMFILE => Errno::EMFILE,
    WSAEWOULDBLOCK => Errno::EWOULDBLOCK,
    WSAEINPROGRESS => Errno::EINPROGRESS,
    WSAEALREADY => Errno::EALREADY,
    WSAENOTSOCK => Errno::ENOTSOCK,
    WSAEDESTADDRREQ => Errno::EDESTADDRREQ,
    WSAEMSGSIZE => Errno::EMSGSIZE,
    WSAEPROTOTYPE => Errno::EPROTOTYPE,
    WSAENOPROTOOPT => Errno::ENOPROTOOPT,
    WSAEPROTONOSUPPORT => Errno::EPROTONOSUPPORT,
    WSAESOCKTNOSUPPORT => Errno::ESOCKTNOSUPPORT,
    WSAEOPNOTSUPP => Errno::EOPNOTSUPP,
    WSAEPFNOSUPPORT => Errno::EPFNOSUPPORT,
    WSAEAFNOSUPPORT => Errno::EAFNOSUPPORT,
    WSAEADDRINUSE => Errno::EADDRINUSE,
    WSAEADDRNOTAVAIL => Errno::EADDRNOTAVAIL,
    WSAENETDOWN => Errno::ENETDOWN,
    WSAENETUNREACH => Errno::ENETUNREACH,
    WSAENETRESET => Errno::ENETRESET,
    WSAECONNABORTED => Errno::ECONNABORTED,
    WSAECONNRESET => Errno::ECONNRESET,
    WSAENOBUFS => Errno::ENOBUFS,
    WSAEISCONN => Errno::EISCONN,
    WSAENOTCONN => Errno::ENOTCONN,
    WSAESHUTDOWN => Errno::ESHUTDOWN,
    WSAETOOMANYREFS => Errno::ETOOMANYREFS,
#    WSAETIMEDOUT => Errno::ETIMEDOUT,
    WSAECONNREFUSED => Errno::ECONNREFUSED,
    WSAELOOP => Errno::ELOOP,
    WSAENAMETOOLONG => Errno::ENAMETOOLONG,
    WSAEHOSTDOWN => Errno::EHOSTDOWN,
    WSAEHOSTUNREACH => Errno::EHOSTUNREACH,
#    WSAEPROCLIM => Errno::EPROCLIM,
#    WSAENOTEMPTY => Errno::ENOTEMPTY,
    WSAEUSERS => Errno::EUSERS,
    WSAEDQUOT => Errno::EDQUOT,
    WSAESTALE => Errno::ESTALE,
    WSAEREMOTE => Errno::EREMOTE
  }

  module_function :create
end
